"""Final iOS payloads must contain device binaries compatible with Info.plist."""
import importlib.util
import os
from pathlib import Path
import plistlib
import shutil
import struct
import subprocess
import sys
import tempfile
import unittest

REPO_KIND = 'ditmesh'
SOURCE = Path(__file__).with_name("native_payload.py")
sys.path.insert(0, str(SOURCE.parent))
spec = importlib.util.spec_from_file_location('ios_payload_under_test', SOURCE)
native = importlib.util.module_from_spec(spec)
spec.loader.exec_module(native)


def packed_version(major, minor=0, patch=0):
    return major << 16 | minor << 8 | patch


def macho(platform=2, minimum=(14, 0, 0), *, cpu=0x100000c, legacy=False):
    version = packed_version(*minimum)
    command = (struct.pack('<IIII', 0x25, 16, version, 0) if legacy else
               struct.pack('<IIIIII', 0x32, 24, platform, version, 0, 0))
    return struct.pack('<IIIIIIII', 0xfeedfacf, cpu, 0, 6, 1, len(command), 0, 0) + command


def fat(device, simulator):
    offset = 48
    return (struct.pack('>II', 0xcafebabe, 2) +
            struct.pack('>IIIII', 0x100000c, 0, offset, len(device), 0) +
            struct.pack('>IIIII', 0x1000007, 0, offset + len(device), len(simulator), 0) +
            device + simulator)


class IosPayloadTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='ios payload ')
        self.addCleanup(self.temp.cleanup)
        self.app = Path(self.temp.name) / 'Runner.app'
        self.app.mkdir()
        self.info = {'MinimumOSVersion': '14.0'}
        self.write_info()
        self.entry = self.app / 'Runner'
        self.entry.write_bytes(macho())

    def write_info(self):
        (self.app / 'Info.plist').write_bytes(plistlib.dumps(self.info))

    def check(self):
        # The real final app includes Info.plist even when a caller omits the
        # explicit iOS flag, so it must not fall back to CPU-only checking.
        return native.check_tree(self.app, 'macho', 'arm64', 'Runner')

    def test_valid_device_binary_matches_app_minimum(self):
        self.assertEqual(len(self.check()), 1)

    def test_older_device_minimum_is_compatible(self):
        self.entry.write_bytes(macho(minimum=(13, 0, 0)))
        self.assertEqual(len(self.check()), 1)

    def test_legacy_arm64_device_declaration_remains_supported(self):
        self.entry.write_bytes(macho(legacy=True))
        self.assertEqual(len(self.check()), 1)

    def test_arm64_simulator_is_not_an_ios_device_binary(self):
        self.entry.write_bytes(macho(platform=7))
        with self.assertRaisesRegex(ValueError, 'iOS device'):
            self.check()

    def test_device_binary_cannot_require_newer_os_than_app(self):
        self.entry.write_bytes(macho(minimum=(18, 0, 0)))
        with self.assertRaisesRegex(ValueError, 'requires iOS'):
            self.check()

    def test_every_embedded_library_is_checked(self):
        plugin = self.app / 'Frameworks/Plugin.framework/Plugin'
        plugin.parent.mkdir(parents=True)
        plugin.write_bytes(macho(platform=7))
        with self.assertRaisesRegex(ValueError, 'iOS device'):
            self.check()

    def test_fat_binary_cannot_hide_a_simulator_slice(self):
        self.entry.write_bytes(fat(macho(), macho(platform=7, cpu=0x1000007)))
        with self.assertRaisesRegex(ValueError, 'iOS device'):
            self.check()

    def test_missing_load_command_version_is_rejected(self):
        self.entry.write_bytes(struct.pack('<IIIIIIII', 0xfeedfacf, 0x100000c, 0, 6, 0, 0, 0, 0))
        with self.assertRaisesRegex(ValueError, 'minimum-OS declaration'):
            self.check()

    def test_truncated_load_command_is_rejected(self):
        self.entry.write_bytes(macho()[:-4])
        with self.assertRaisesRegex(ValueError, 'load command'):
            self.check()

    def test_duplicate_version_commands_are_rejected(self):
        payload = bytearray(macho())
        struct.pack_into('<II', payload, 16, 2, 48)
        self.entry.write_bytes(payload + payload[32:])
        with self.assertRaisesRegex(ValueError, 'minimum-OS declaration'):
            self.check()

    def test_wrong_platform_cannot_use_a_legacy_device_command(self):
        payload = bytearray(macho(legacy=True))
        struct.pack_into('<I', payload, 32, 0x24)
        self.entry.write_bytes(payload)
        with self.assertRaisesRegex(ValueError, 'iOS device'):
            self.check()

    def test_malformed_app_minimum_is_rejected(self):
        for value in [None, 14, '', '14.x', '14.0.0.1']:
            with self.subTest(value=value):
                self.info = {} if value is None else {'MinimumOSVersion': value}
                self.write_info()
                with self.assertRaisesRegex(ValueError, 'MinimumOSVersion'):
                    self.check()

    @unittest.skipUnless(sys.platform == 'darwin' and shutil.which('xcrun'), 'requires Apple SDKs')
    def test_real_clang_device_and_simulator_libraries(self):
        source = Path(self.temp.name) / 'fixture.c'
        source.write_text('int fixture(void) { return 1; }')
        cases = [('iphoneos', 'arm64-apple-ios14.0', True),
                 ('iphonesimulator', 'arm64-apple-ios14.0-simulator', False),
                 ('iphoneos', 'arm64-apple-ios18.0', False)]
        for sdk, target, allowed in cases:
            with self.subTest(target=target):
                subprocess.run(['xcrun', '--sdk', sdk, 'clang', '-target', target,
                                '-dynamiclib', str(source), '-o', str(self.entry)],
                               check=True, capture_output=True)
                if allowed:
                    self.assertEqual(len(self.check()), 1)
                else:
                    with self.assertRaises(ValueError):
                        self.check()

    @unittest.skipUnless(sys.platform == 'darwin', 'iOS packager needs Apple tools')
    def test_local_packager_checks_embedded_runtime_before_archiving(self):
        for platform, minimum, allowed in [(2, (14, 0, 0), True),
                                            (7, (14, 0, 0), False),
                                            (2, (18, 0, 0), False)]:
            with self.subTest(platform=platform, minimum=minimum), tempfile.TemporaryDirectory() as temp:
                root = Path(temp)
                scripts = root / 'tool/ci'
                scripts.mkdir(parents=True)
                names = ['package_artifacts.sh', 'common.sh', 'native_payload.py', 'assert_no_test_hooks.sh']
                if REPO_KIND == 'ditmesh':
                    names += ['release_version.sh', 'macos_runtime.py', 'windows_manifest.py']
                for name in names:
                    shutil.copy2(SOURCE.parent / name, scripts / name)
                app_root = root if REPO_KIND == 'toxee' else root / 'apps/ditmesh'
                app_root.mkdir(parents=True, exist_ok=True)
                (app_root / 'pubspec.yaml').write_text('version: 0.1.0+1\n')
                app = app_root / 'build/ios/iphoneos/Runner.app'
                app.mkdir(parents=True)
                (app / 'Runner').write_bytes(macho())
                (app / 'Runner').chmod(0o755)
                info = {'MinimumOSVersion': '14.0', 'CFBundleExecutable': 'Runner',
                        'CFBundleIdentifier': 'com.toxee.app' if REPO_KIND == 'toxee' else 'icu.agentx.ditmesh',
                        'CFBundleShortVersionString': '0.1.0', 'CFBundleVersion': '1'}
                (app / 'Info.plist').write_bytes(plistlib.dumps(info))
                # toxee injects the staged FFI just before packaging; DitMesh's
                # FFI already lives inside the built application bundle.
                ffi_root = root / 'build/native-artifacts/ios' if REPO_KIND == 'toxee' else app / 'Frameworks'
                ffi_binary = ffi_root / 'tim2tox_ffi.framework/tim2tox_ffi'
                ffi_binary.parent.mkdir(parents=True)
                ffi_binary.write_bytes(macho(platform=platform, minimum=minimum) +
                                       b'tim2tox_ffi_av_backend_toxav')
                env = {key: value for key, value in os.environ.items()
                       if not key.startswith(('GITHUB_', 'IOS_', 'TOXEE_', 'DITMESH_'))}
                result = subprocess.run(['bash', str(scripts / 'package_artifacts.sh'), '--target', 'ios'],
                                        cwd=root, env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode == 0, allowed, result.stdout + result.stderr)
                self.assertEqual(bool(list((root / 'dist/ios').glob('*.ipa'))), allowed)
                if not allowed:
                    self.assertIn('iOS', result.stderr)



if __name__ == '__main__':
    unittest.main()

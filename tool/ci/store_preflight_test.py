"""Distribution requests must never fall back to validation artifacts."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class StorePreflightTests(unittest.TestCase):
    def test_unconfigured_distribution_channels_fail_before_build_or_packaging(self):
        for target in ('ios', 'macos', 'windows', 'linux'):
            with self.subTest(target=target):
                result = subprocess.run(['bash', str(ROOT / 'tool/ci/package_artifacts.sh'),
                                         '--target', target, '--mode', 'distribution'],
                                        capture_output=True, text=True, check=False)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('distribution is not configured', result.stderr)

    def test_explicit_android_distribution_requires_credentials_without_tag(self):
        env = {key: value for key, value in os.environ.items()
               if not key.startswith('DITMESH_ANDROID_') and key != 'GITHUB_REF_TYPE'}
        result = subprocess.run(['bash', str(ROOT / 'tool/ci/package_artifacts.sh'),
                                 '--target', 'android', '--mode', 'distribution'],
                                env=env, capture_output=True, text=True, check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('release signing', result.stderr)

    @unittest.skipUnless(shutil.which('cmake'), 'CMake required')
    def test_wix_architecture_configuration_cannot_be_renamed_to_arm(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / 'payload'
            source.mkdir()
            (source / 'ditmesh.exe').write_bytes(b'fixture; not an architecture test')
            for arch in ('x64', 'arm64'):
                build = Path(tmp) / arch
                result = subprocess.run(['cmake', '-S', str(ROOT / 'tool/ci/windows-installer'),
                                         '-B', str(build), f'-DDITMESH_INSTALLER_SOURCE_DIR={source}',
                                         '-DDITMESH_RELEASE_VERSION=1.2.3',
                                         f'-DDITMESH_PACKAGE_ARCH={arch}'],
                                        capture_output=True, text=True, check=False)
                if arch == 'x64':
                    self.assertEqual(result.returncode, 0, result.stderr)
                    config = (build / 'CPackConfig.cmake').read_text()
                    self.assertIn('set(CPACK_WIX_ARCHITECTURE "x64")', config)
                    self.assertIn('set(CPACK_WIX_SIZEOF_VOID_P "8")', config)
                else:
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn('only the validated Windows x64', result.stderr)


if __name__ == '__main__':
    unittest.main()

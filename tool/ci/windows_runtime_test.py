"""Exercise the real install rules with stand-in toolchain redistributables."""
from pathlib import Path
import subprocess
import tempfile
import unittest

RUNTIME = Path(__file__).with_name('windows_runtime.cmake').resolve()
REQUIRED = ('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')


class WindowsRuntimeTest(unittest.TestCase):
    def configure(self, libraries):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        modules = root / 'modules'
        modules.mkdir()
        paths = []
        for name in libraries:
            path = root / name
            path.write_bytes(name.encode())
            paths.append(path.as_posix())
        # Only discovery is replaced: the package's validation and actual
        # cmake --install rules execute unchanged on this non-Windows host.
        (modules / 'InstallRequiredSystemLibraries.cmake').write_text(
            'set(CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS "' + ';'.join(paths) + '")\n'
            'set(CMAKE_MSVC_ARCH x64)\n')
        (root / 'CMakeLists.txt').write_text(f'''cmake_minimum_required(VERSION 3.16)
project(runtime_fixture LANGUAGES NONE)
set(MSVC TRUE)
set(MSVC_TOOLSET_VERSION 143)
set(CMAKE_CXX_COMPILER_VERSION 19.44)
set(INSTALL_BUNDLE_LIB_DIR "${{CMAKE_INSTALL_PREFIX}}")
list(PREPEND CMAKE_MODULE_PATH "{modules.as_posix()}")
include("{RUNTIME.as_posix()}")
''')
        output = root / 'installed with spaces'
        build = root / 'build'
        result = subprocess.run(['cmake', '-S', str(root), '-B', str(build),
                                 '-DCMAKE_INSTALL_PREFIX=' + str(output)],
                                capture_output=True, text=True)
        return result, build, output

    def test_installs_runtime_and_notice_next_to_runner(self):
        result, build, output = self.configure(REQUIRED)
        self.assertEqual(result.returncode, 0, result.stderr)
        installed = subprocess.run(['cmake', '--install', str(build), '--config', 'Release'],
                                   capture_output=True, text=True)
        self.assertEqual(installed.returncode, 0, installed.stderr)
        for name in REQUIRED:
            self.assertEqual((output / name).read_bytes(), name.encode())
        notice = (output / 'licenses/MSVC-runtime.txt').read_text()
        self.assertIn('Microsoft', notice)
        self.assertIn('143', notice)

    def test_debug_configuration_does_not_install_release_runtime(self):
        result, build, output = self.configure(REQUIRED)
        self.assertEqual(result.returncode, 0, result.stderr)
        installed = subprocess.run(['cmake', '--install', str(build), '--config', 'Debug'],
                                   capture_output=True, text=True)
        self.assertEqual(installed.returncode, 0, installed.stderr)
        self.assertFalse(output.exists())

    def test_debug_runtime_cannot_be_added_to_release(self):
        result, _, _ = self.configure(REQUIRED + ('msvcp140d.dll',))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Debug MSVC runtimes', result.stderr)

    def test_missing_required_runtime_fails_configuration(self):
        result, _, _ = self.configure(REQUIRED[:-1])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('vcruntime140_1.dll', result.stderr)


if __name__ == '__main__':
    unittest.main()

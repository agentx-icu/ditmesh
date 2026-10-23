"""Real upstream JNI CMake fixture: host JDK discovery must not alter desktop assets."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from urllib.parse import unquote, urlparse


ROOT = Path(__file__).resolve().parents[2]


class DesktopJniTest(unittest.TestCase):
    def test_optional_upstream_jni_excluded_without_losing_other_native_assets(self):
        configuration = Path(os.environ.get('DITMESH_TEST_PACKAGE_CONFIG', ROOT / '.dart_tool/package_config.json'))
        package = next(p for p in json.loads(configuration.read_text())['packages'] if p['name'] == 'jni')
        uri = urlparse(package['rootUri'])
        plugin = Path(unquote(uri.path)) if uri.scheme == 'file' else configuration.parent / unquote(package['rootUri'])
        with tempfile.TemporaryDirectory(prefix='desktop JNI policy ') as directory:
            work = Path(directory)
            (work / 'FindJNI.cmake').write_text('set(JNI_FOUND TRUE)\nset(JNI_LIBRARIES "")\nset(JNI_INCLUDE_DIRS "")\n')
            (work / 'other.c').write_text('int native_fixture(void) { return 42; }\n')
            (work / 'CMakeLists.txt').write_text('''cmake_minimum_required(VERSION 3.16)
project(desktop_jni_policy LANGUAGES C CXX)
list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}")
if(APPLY_DESKTOP_POLICY)
  include("${POLICY}")
endif()
add_subdirectory("${JNI_PLUGIN}" "${CMAKE_CURRENT_BINARY_DIR}/jni")
if(APPLY_DESKTOP_POLICY)
  if(TARGET jni OR jni_bundled_libraries)
    message(FATAL_ERROR "Unused desktop JNI leaked from host JDK discovery")
  endif()
else()
  if(NOT TARGET jni OR NOT jni_bundled_libraries)
    message(FATAL_ERROR "Fixture did not reproduce optional host JDK contamination")
  endif()
endif()
add_library(other_native SHARED other.c)
install(TARGETS other_native LIBRARY DESTINATION lib RUNTIME DESTINATION bin)
''')
            for isolated in (False, True):
                build = work / ('isolated' if isolated else 'polluted')
                result = subprocess.run(['cmake', '-S', str(work), '-B', str(build),
                                         f'-DAPPLY_DESKTOP_POLICY={"ON" if isolated else "OFF"}',
                                         f'-DPOLICY={ROOT / "tool/ci/desktop_jni.cmake"}',
                                         f'-DJNI_PLUGIN={plugin.resolve() / "linux"}'],
                                        capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                if isolated:
                    subprocess.run(['cmake', '--build', str(build)], check=True, capture_output=True)
                    subprocess.run(['cmake', '--install', str(build), '--prefix', str(work / 'installed')],
                                   check=True, capture_output=True)
                    installed = [p.name for p in (work / 'installed').rglob('*') if p.is_file()]
                    self.assertTrue(any('other_native' in name for name in installed))
                    self.assertFalse(any('dartjni' in name for name in installed))


if __name__ == '__main__':
    unittest.main()

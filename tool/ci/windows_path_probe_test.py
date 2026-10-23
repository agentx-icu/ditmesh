from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import Mock, patch

import windows_path_probe as probe


class WindowsPathProbeTests(unittest.TestCase):
    def test_project_matches_pinned_ffi_cpp20_and_release_dynamic_crt(self):
        # file_io_compat.cpp uses C++20 char8_t/std::u8string on Windows.
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            ffi = root / 'pinned FFI/file_io_compat.cpp'
            probe.fixture_project(root, root / 'positive.manifest', root / 'negative.manifest', ffi)
            cmake = (root / 'CMakeLists.txt').read_text()
            self.assertIn('set(CMAKE_CXX_STANDARD 20)', cmake)
            self.assertIn('set(CMAKE_CXX_STANDARD_REQUIRED ON)', cmake)
            self.assertIn('set(CMAKE_MSVC_RUNTIME_LIBRARY MultiThreadedDLL)', cmake)
            self.assertIn(ffi.as_posix(), cmake)
            self.assertIn('foreach(target IN ITEMS positive negative)', cmake)

    def test_ordinary_host_is_refused_before_any_file_or_process_mutation(self):
        with tempfile.TemporaryDirectory() as directory:
            evidence = Path(directory) / 'must-not-exist'
            with patch.dict(probe.os.environ, {'GITHUB_ACTIONS': 'false', 'RUNNER_ENVIRONMENT': 'self-hosted'}), \
                    patch.object(probe.subprocess, 'Popen') as process:
                with self.assertRaisesRegex(ValueError, 'disposable GitHub-hosted Windows'):
                    probe.probe(Path(directory) / 'app.exe', evidence)
                self.assertFalse(evidence.exists())
                process.assert_not_called()

    def test_timeout_ends_only_owned_command_tree_and_preserves_output(self):
        process = Mock(pid=12345)
        process.communicate.side_effect = [subprocess.TimeoutExpired(['owned'], 1), ('bounded output', None)]
        with tempfile.TemporaryDirectory() as directory, patch.object(probe.subprocess, 'Popen', return_value=process), \
                patch.object(probe.subprocess, 'run') as terminate:
            log = Path(directory) / 'timeout.log'
            with self.assertRaisesRegex(ValueError, 'timed out'):
                probe.run(['owned'], log, timeout=1)
            self.assertEqual(terminate.call_args.args[0], ['taskkill', '/PID', '12345', '/T', '/F'])
            self.assertEqual(log.read_text(), 'bounded output')

    def test_nonzero_command_is_not_converted_to_success_and_log_is_retained(self):
        process = Mock(returncode=17)
        process.communicate.return_value = ('specific compiler failure', None)
        with tempfile.TemporaryDirectory() as directory, patch.object(probe.subprocess, 'Popen', return_value=process):
            log = Path(directory) / 'failed.log'
            code, output = probe.run(['owned'], log)
            self.assertEqual(code, 17)
            self.assertEqual(output, log.read_text())


if __name__ == '__main__':
    unittest.main()

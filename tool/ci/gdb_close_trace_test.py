import unittest
from gdb_close_trace import COMMANDS, scoped_line


class ScopedTraceTests(unittest.TestCase):
    def test_no_arguments_locals_or_signal_suppression(self):
        self.assertIn('set print frame-arguments none', COMMANDS)
        self.assertIn('handle SIGSEGV stop print pass', COMMANDS)
        for unsafe in (' full', 'info locals', 'info args', 'show environment', 'detach', 'signal 0', ' nopass', 'generate-core-file'):
            self.assertNotIn(unsafe, COMMANDS)

    def test_markers_signals_frames_and_modules(self):
        self.assertEqual(scoped_line('GDB_TRACE_READY\n'), 'GDB_TRACE_READY')
        self.assertEqual(scoped_line('Thread 1 "do not publish name" received signal SIGSEGV, Segmentation fault.'), 'signal SIGSEGV')
        self.assertEqual(scoped_line('#0  0x00000100 in function (...) from C:\\smoke\\native.dll'), '#0  0x00000100 in function (...) from C:\\smoke\\native.dll')
        self.assertEqual(scoped_line('0x00000100  0x00000200  Yes (*)  C:\\Program Files\\smoke\\native.dll'), 'module 0x00000100 0x00000200 native.dll')

    def test_unstructured_output_is_excluded(self):
        for line in ('warning: arbitrary app debug string contains secret', 'Thread 1 "secret runtime name":', 'TOKEN=secret', 'some source text', 'rax = 0x1234'):
            self.assertIsNone(scoped_line(line))

    def test_unknown_exception_code_is_scoped(self):
        self.assertEqual(scoped_line('warning: unknown target exception 0xc000041d at 0x1234'), 'windows_exception 0xc000041d')
        self.assertEqual(scoped_line('gdb: unknown target exception 0xc000041d at 0x1234'), 'windows_exception 0xc000041d')


if __name__ == '__main__':
    unittest.main()

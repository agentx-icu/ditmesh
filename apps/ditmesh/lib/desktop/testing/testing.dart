/// Plugin-free doubles for the desktop shell. Tests (and a test-mode
/// orchestrator) build a `DesktopShellController` on these so nothing ever
/// reaches `window_manager`, `tray_manager` or `screen_retriever`.
library;

export 'fake_screen_api.dart';
export 'fake_tray_api.dart';
export 'fake_window_api.dart';
export 'in_memory_key_value_store.dart';

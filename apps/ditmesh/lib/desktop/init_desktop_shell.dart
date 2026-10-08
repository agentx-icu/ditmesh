import '../l10n/generated/s.dart';
import 'desktop_platform.dart';
import 'desktop_shell_controller.dart';
import 'real/screen_retriever_api.dart';
import 'real/tray_manager_api.dart';
import 'real/window_manager_api.dart';
import 'screen_api.dart';
import 'tray_api.dart';
import 'window_api.dart';

/// Builds the [DesktopShellController] on the real plugins and runs its
/// startup. Call it after `WidgetsFlutterBinding.ensureInitialized()` and
/// before `runApp` (see `lib/desktop/README.md`).
///
/// On Android / iOS / web nothing is initialised and no plugin channel is
/// touched; the returned controller is inert state that still tracks the
/// unread count so callers need no platform branches of their own.
///
/// The optional API parameters exist for tests and for the orchestrator's
/// own fakes; production passes only [config]. [strings] pins the initial
/// language (default: the platform locale via `currentS()`); `AppServices`
/// re-labels the shell through `updateStrings` once the user's choice loads.
Future<DesktopShellController> initDesktopShell(
  DesktopShellConfig config, {
  WindowApi? window,
  TrayApi? tray,
  ScreenApi? screen,
  S? strings,
}) async {
  final controller = DesktopShellController(
    config: config,
    window: window ?? WindowManagerApi(),
    tray: tray ?? TrayManagerApi(),
    screen: screen ?? ScreenRetrieverApi(),
    strings: strings,
  );
  await controller.initialize();
  return controller;
}

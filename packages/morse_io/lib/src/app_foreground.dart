import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Whether the app is in the foreground, and when that changes.
///
/// [SidetoneSink] uses it to release its idle voice while the app is in the
/// background. Injected so tests drive transitions without a binding.
abstract interface class AppForeground {
  bool get isForeground;

  /// Reports every foreground/background transition to [onChange] until the
  /// returned callback is called.
  VoidCallback listen(void Function(bool foreground) onChange);
}

/// Production [AppForeground] on top of the widgets binding.
///
/// Mobile only (Android / iOS): there an app is backgrounded by the OS and,
/// on iOS, kept running by any live audio output. On desktop a minimised
/// window may legitimately keep sounding, so it always reports foreground.
/// Also always foreground when no binding exists (pure unit tests).
///
/// `inactive` counts as foreground: iOS reports it for Control Center and
/// incoming-call banners, which must not cut the tone.
final class BindingAppForeground implements AppForeground {
  const BindingAppForeground({this.platformOverride});

  final TargetPlatform? platformOverride;

  bool get _mobile {
    if (kIsWeb) return false;
    final platform = platformOverride ?? defaultTargetPlatform;
    return platform == TargetPlatform.android ||
        platform == TargetPlatform.iOS;
  }

  static WidgetsBinding? get _binding {
    try {
      return WidgetsBinding.instance;
    } on Object {
      return null;
    }
  }

  static bool isForegroundState(AppLifecycleState? state) =>
      state == null ||
      state == AppLifecycleState.resumed ||
      state == AppLifecycleState.inactive;

  @override
  bool get isForeground =>
      !_mobile || isForegroundState(_binding?.lifecycleState);

  @override
  VoidCallback listen(void Function(bool foreground) onChange) {
    if (!_mobile || _binding == null) return () {};
    final listener = AppLifecycleListener(
      onStateChange: (state) => onChange(isForegroundState(state)),
    );
    return listener.dispose;
  }
}

import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the display (and so the app) awake while a session needs it.
///
/// On a phone the auto-lock timer backgrounds the app after 30 s - 5 min
/// without a touch, which stops microphone capture and mutes the sidetone.
/// Hands-free sessions (decoding a radio through the microphone) hold this
/// while they run. Injected so tests never reach the platform channel.
abstract interface class ScreenWakeApi {
  /// Never throws: a platform without the plugin simply keeps its timer.
  Future<void> keepOn(bool on);
}

/// Production [ScreenWakeApi] on `wakelock_plus` (iOS `idleTimerDisabled`,
/// Android `FLAG_KEEP_SCREEN_ON`, desktop power assertions). The flag is
/// per window, so it ends with the app and needs no permission.
///
/// Every instance shares one [SerializedScreenWake]: the flag is process
/// wide, so toggles from all screens must be ordered against each other.
final class WakelockScreenWake implements ScreenWakeApi {
  const WakelockScreenWake();

  static final SerializedScreenWake _shared = SerializedScreenWake(
    (on) => WakelockPlus.toggle(enable: on),
  );

  @override
  Future<void> keepOn(bool on) => _shared.keepOn(on);
}

/// Platform call that switches the keep-awake flag; may throw.
typedef ScreenWakeToggle = Future<void> Function(bool on);

/// [ScreenWakeApi] that never lets two platform toggles overlap.
///
/// On Linux `wakelock_plus` stores its inhibit handle only after an
/// asynchronous DBus reply, so a disable issued while an enable is in flight
/// finds no handle and the display then stays awake for good. Here a toggle
/// starts only after the previous one completed, and requests made in the
/// meantime coalesce to the last requested state. The returned future
/// completes once the platform matches the latest request.
final class SerializedScreenWake implements ScreenWakeApi {
  SerializedScreenWake(this._toggle);

  final ScreenWakeToggle _toggle;

  /// The state last confirmed by the platform; null until the first toggle
  /// succeeds or after a failure (unknown, so the next request applies).
  bool? _applied;
  bool _wanted = false;
  Future<void>? _drain;

  @override
  Future<void> keepOn(bool on) {
    _wanted = on;
    final Future<void>? running = _drain;
    if (running != null) {
      return running;
    }
    if (_applied == on) {
      return Future<void>.value();
    }
    return _drain = _run();
  }

  Future<void> _run() async {
    try {
      while (_applied != _wanted) {
        final bool target = _wanted;
        try {
          // Future.sync: even a synchronous throw yields first, so `_drain`
          // is assigned before this loop can finish.
          await Future<void>.sync(() => _toggle(target));
          _applied = target;
        } on Object catch (e) {
          _applied = null;
          debugPrint(
            'morse_io: wakelock ${target ? 'enable' : 'disable'} failed: $e',
          );
          if (_wanted == target) {
            return;
          }
        }
      }
    } finally {
      _drain = null;
    }
  }
}

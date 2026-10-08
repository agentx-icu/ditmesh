import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import 'sink.dart';

/// The haptic primitives [HapticSink] relies on. Injected so tests never
/// touch platform channels.
abstract interface class HapticApi {
  /// True when the device can start a vibration of arbitrary length and
  /// cancel it early (Android `Vibrator`, iOS `CHHapticEngine`).
  Future<bool> supportsContinuousVibration();

  /// One-shot, fixed-length feedback (Flutter's `HapticFeedback.heavyImpact`).
  Future<void> heavyImpact();

  /// Start vibrating for up to [duration]; may be ended early by [cancel].
  Future<void> vibrate(Duration duration);

  Future<void> cancel();
}

/// Production [HapticApi]: `HapticFeedback` for impacts, the `vibration`
/// plugin for duration-accurate pulses.
final class FlutterHapticApi implements HapticApi {
  const FlutterHapticApi();

  @override
  Future<bool> supportsContinuousVibration() async {
    try {
      return await Vibration.hasVibrator() &&
          await Vibration.hasCustomVibrationsSupport();
    } on Object {
      // MissingPluginException on platforms without the plugin, or any
      // other channel failure: fall back to impacts.
      return false;
    }
  }

  @override
  Future<void> heavyImpact() => HapticFeedback.heavyImpact();

  @override
  Future<void> vibrate(Duration duration) =>
      Vibration.vibrate(duration: duration.inMilliseconds);

  @override
  Future<void> cancel() => Vibration.cancel();
}

/// Renders key-down as vibration on Android / iOS; a no-op elsewhere.
///
/// Two strategies, picked in [prepare]:
/// * **continuous** (preferred when [HapticApi.supportsContinuousVibration]):
///   [on] starts a vibration of [maxPulse] and [off] cancels it, so the pulse
///   length tracks the element length.
/// * **impact**: [on] fires one heavy impact, [off] does nothing. Dits and
///   dahs feel identical, but it works on every phone.
///
/// Platform gating uses [defaultTargetPlatform] unless [platformOverride] is
/// given (tests, or an app that wants to force the choice).
final class HapticSink implements MorseSink {
  HapticSink({
    HapticApi? api,
    TargetPlatform? platformOverride,
    this.preferContinuous = true,
    this.maxPulse = const Duration(seconds: 3),
  })  : _api = api ?? const FlutterHapticApi(),
        _platformOverride = platformOverride;

  final HapticApi _api;
  final TargetPlatform? _platformOverride;

  /// Use start/cancel vibration when the device supports it.
  final bool preferContinuous;

  /// Upper bound of a continuous pulse if [off] never arrives.
  final Duration maxPulse;

  bool _continuous = false;
  bool _isOn = false;

  TargetPlatform get _platform => _platformOverride ?? defaultTargetPlatform;

  /// Whether this sink does anything on the current platform.
  bool get isEnabled =>
      _platform == TargetPlatform.android || _platform == TargetPlatform.iOS;

  /// True after [prepare] chose the start/cancel strategy.
  bool get usesContinuousVibration => _continuous;

  @override
  Future<void> prepare() async {
    if (!isEnabled) {
      return;
    }
    _continuous = preferContinuous && await _api.supportsContinuousVibration();
  }

  @override
  void on() {
    if (!isEnabled || _isOn) {
      return;
    }
    _isOn = true;
    if (_continuous) {
      unawaited(_swallow(_api.vibrate(maxPulse)));
    } else {
      unawaited(_swallow(_api.heavyImpact()));
    }
  }

  @override
  void off() {
    if (!isEnabled || !_isOn) {
      return;
    }
    _isOn = false;
    if (_continuous) {
      unawaited(_swallow(_api.cancel()));
    }
  }

  @override
  Future<void> dispose() async {
    off();
  }

  /// Platform-channel failures must never surface on the keying hot path.
  static Future<void> _swallow(Future<void> future) =>
      future.catchError((Object _) {});
}

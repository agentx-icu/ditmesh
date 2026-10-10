import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:torch_light/torch_light.dart';

import 'sink.dart';

/// Camera-torch primitives used by [FlashSink]. Injected for tests.
abstract interface class TorchApi {
  Future<bool> isAvailable();
  Future<void> enable();
  Future<void> disable();
}

/// Production [TorchApi] on top of the `torch_light` plugin (Android / iOS).
final class TorchLightApi implements TorchApi {
  const TorchLightApi();

  @override
  Future<bool> isAvailable() async {
    try {
      return await TorchLight.isTorchAvailable();
    } on Object {
      // MissingPluginException on desktop, or a camera-less device.
      return false;
    }
  }

  @override
  Future<void> enable() => TorchLight.enableTorch();

  @override
  Future<void> disable() => TorchLight.disableTorch();
}

/// Light output: a [ValueListenable] any widget can paint from (all five
/// platforms) plus an optional camera torch on Android / iOS.
///
/// The listenable flips synchronously in [on] / [off]; the torch calls are
/// fire-and-forget and their errors are swallowed because the torch is a
/// best-effort extra on top of the screen flash. Torch use is gated by
/// [useTorch], platform (mobile only, [platformOverride] for tests) and the
/// availability probe done in [prepare].
final class FlashSink implements MorseSink {
  FlashSink({
    this.useTorch = false,
    TorchApi? torchApi,
    TargetPlatform? platformOverride,
  }) : _torch = torchApi ?? const TorchLightApi(),
       _platformOverride = platformOverride;

  /// Ask for the camera torch in addition to the screen flash.
  final bool useTorch;

  final TorchApi _torch;
  final TargetPlatform? _platformOverride;
  final ValueNotifier<bool> _isOn = ValueNotifier<bool>(false);
  bool _torchActive = false;
  bool _disposed = false;

  /// True while the key is down. Drive a [FlashOverlay] or any custom paint.
  ValueListenable<bool> get isOn => _isOn;

  /// True when [prepare] found a usable torch and it will follow the key.
  bool get torchActive => _torchActive;

  TargetPlatform get _platform => _platformOverride ?? defaultTargetPlatform;

  bool get _isMobile =>
      _platform == TargetPlatform.android || _platform == TargetPlatform.iOS;

  @override
  Future<void> prepare() async {
    if (!useTorch || !_isMobile) {
      _torchActive = false;
      return;
    }
    try {
      _torchActive = await _torch.isAvailable();
    } on Object {
      _torchActive = false;
    }
  }

  @override
  void on() {
    if (_disposed || _isOn.value) {
      return;
    }
    _isOn.value = true;
    if (_torchActive) {
      unawaited(_swallow(_torch.enable()));
    }
  }

  @override
  void off() {
    if (_disposed || !_isOn.value) {
      return;
    }
    _isOn.value = false;
    if (_torchActive) {
      unawaited(_swallow(_torch.disable()));
    }
  }

  @override
  Future<void> dispose() async {
    off();
    _disposed = true;
    _isOn.dispose();
  }

  static Future<void> _swallow(Future<void> future) =>
      future.catchError((Object _) {});
}

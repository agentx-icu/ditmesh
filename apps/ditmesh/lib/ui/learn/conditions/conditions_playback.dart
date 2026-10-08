import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';

/// Plays receive practice under simulated radio conditions (F11): renders
/// the round with [RadioRenderer] and hands the WAV to a [ClipPlayer] on the
/// shared audio engine (engine leases), so the low-latency keying sidetone
/// is never replaced. Audio only: an unaffected flash or haptic track would
/// give the answer away.
final class ConditionsPlayback with WidgetsBindingObserver {
  ConditionsPlayback({
    ClipPlayer? player,
    ConditionsRender render = renderInIsolate,
    this.stopInBackground = false,
  }) : _player = player ?? SoloudClipPlayer(),
       _render = render {
    if (stopInBackground) WidgetsBinding.instance.addObserver(this);
  }

  final ClipPlayer _player;
  final ConditionsRender _render;

  /// Stop on its own when the app leaves the foreground (the preset
  /// preview; a drill screen manages this itself).
  final bool stopInBackground;
  bool _disposed = false;

  /// Bumped by [stop] / [dispose]: a rendering that finishes afterwards is
  /// dropped instead of starting late.
  int _generation = 0;

  bool get isPlaying => _player.isPlaying;

  /// `true` when a rendering starts, `false` when it ends or is stopped.
  Stream<bool> get playing => _player.playing;

  /// Renders off the UI isolate, then plays [text] under [scenario].
  /// Returns false when a stop or dispose dropped it before it started (no
  /// `playing` event follows then). Throws when the audio engine cannot
  /// play the clip.
  Future<bool> play(String text, RadioScenario scenario) async {
    if (_disposed) return false;
    final generation = ++_generation;
    final (wav, length) = await _render(text, scenario);
    if (_disposed || generation != _generation) return false;
    await _player.play(wav, length: length);
    return true;
  }

  /// Renders on a background isolate: a long round is millions of samples.
  static Future<(Uint8List, Duration)> renderInIsolate(
    String text,
    RadioScenario scenario,
  ) => Isolate.run(() => renderNow(text, scenario));

  /// Synchronous rendering (tests, where isolates do not run).
  static Future<(Uint8List, Duration)> renderNow(
    String text,
    RadioScenario scenario,
  ) async {
    final samples = RadioRenderer.render(text, scenario);
    return (RadioRenderer.wav(samples), RadioRenderer.lengthOf(samples));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      unawaited(stop());
    }
  }

  Future<void> stop() {
    _generation++;
    return _disposed ? Future<void>.value() : _player.stop();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    if (stopInBackground) WidgetsBinding.instance.removeObserver(this);
    await _player.dispose();
  }
}

/// Turns a round into WAV bytes and their length.
typedef ConditionsRender =
    Future<(Uint8List, Duration)> Function(String text, RadioScenario scenario);

/// What the preset preview keys: audio only, never shown as text.
const String kConditionsPreviewText = 'CQ CQ DE DL1ABC K';

/// User-facing name of a preset.
String radioPresetLabel(S s, RadioPreset preset) => switch (preset) {
  RadioPreset.clear => s.conditionsClear,
  RadioPreset.light => s.conditionsLight,
  RadioPreset.radio => s.conditionsRadio,
};

/// One-line description of a preset.
String radioPresetHint(S s, RadioPreset preset) => switch (preset) {
  RadioPreset.clear => s.conditionsClearHint,
  RadioPreset.light => s.conditionsLightHint,
  RadioPreset.radio => s.conditionsRadioHint,
};

import 'package:flutter/foundation.dart';
import 'package:morse_io/morse_io.dart';

import '../../training/training_settings.dart';

/// Everything a Learn screen needs to make Morse perceivable, built once per
/// screen from the current [TrainingSettings].
///
/// * [player] renders drills (receive practice, settings sample).
/// * [sink] is the same modality bundle for real-time keying, so send
///   practice sounds exactly like receive practice.
/// * [flash] is non-null when a screen flash should be painted; wrap the
///   screen body in a `FlashOverlay` fed with it.
/// * [clock] is the timeline every key event and decoder tick must share.
final class LearnPlayback {
  LearnPlayback({
    required this.sink,
    required this.clock,
    required this.flash,
    required Future<void> Function() dispose,
    this.sidetone,
  }) : player = MorsePlayer(sink: sink, clock: clock),
       _dispose = dispose;

  final MorseSink sink;
  final MorsePlayer player;
  final Clock clock;
  final ValueListenable<bool>? flash;

  /// The sidetone sink when sound is on, for live retuning.
  final SidetoneSink? sidetone;

  final Future<void> Function() _dispose;
  bool _disposed = false;

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await player.dispose();
    await _dispose();
  }
}

/// Creates a [LearnPlayback] for a settings snapshot. Screens receive one of
/// these so tests inject fakes (recording sink, fake clock) and the app uses
/// the real device modalities.
abstract interface class LearnPlaybackFactory {
  Future<LearnPlayback> create(TrainingSettings settings);
}

/// Real modalities: SoLoud sidetone, screen flash (+ optional torch on
/// mobile) and vibration, gated by the settings and by platform inside the
/// sinks themselves. Falls back to the screen flash when every modality is
/// off so a drill is never silently invisible.
final class DevicePlaybackFactory implements LearnPlaybackFactory {
  const DevicePlaybackFactory({this.clock});

  /// Shared timeline; defaults to [SystemClock.shared].
  final Clock? clock;

  @override
  Future<LearnPlayback> create(TrainingSettings settings) async {
    final sinks = <MorseSink>[];
    SidetoneSink? sidetone;
    FlashSink? flash;
    if (settings.soundEnabled) {
      sidetone = SidetoneSink(frequencyHz: settings.trainer.toneHz);
      sinks.add(sidetone);
    }
    if (settings.flashEnabled) {
      flash = FlashSink();
      sinks.add(flash);
    }
    if (settings.hapticEnabled) {
      // Vibration exists on phones only; a haptic-only profile restored on a
      // desktop must fall back to the flash below, not to nothing.
      final haptic = HapticSink();
      if (haptic.isEnabled) {
        sinks.add(haptic);
      }
    }
    if (sinks.isEmpty) {
      flash = FlashSink();
      sinks.add(flash);
    }
    final composite = CompositeSink(sinks);
    // A sidetone that fails to initialise (no audio device, sandbox denial)
    // must not take the drill down with it: drop it and keep the others.
    try {
      await composite.prepare();
    } on Object {
      if (sidetone != null) {
        sinks.remove(sidetone);
        // Idempotent after a failed prepare; makes sure the sink never keeps
        // the shared audio engine alive.
        await sidetone.dispose();
        sidetone = null;
        if (sinks.isEmpty) {
          flash = FlashSink();
          sinks.add(flash);
        }
        await CompositeSink(sinks).prepare();
      }
    }
    final effective = CompositeSink(sinks);
    return LearnPlayback(
      sink: effective,
      clock: clock ?? SystemClock.shared,
      flash: flash?.isOn,
      sidetone: sidetone,
      dispose: effective.dispose,
    );
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:morse_io/morse_io.dart';

/// Builds the [MorsePlayer] a reference / translator screen plays through.
///
/// Screens take one of these in their constructor so tests can inject a
/// player driven by a `FakeClock` and a `RecordingSink`; the app uses
/// [createSidetoneMorsePlayer].
typedef MorsePlayerFactory = MorsePlayer Function();

/// `MorsePlayer` is final and does not expose its sink, so the sink a
/// factory built for a player is remembered here. That lets the screens
/// retune the tone, share the sink with a hand key, and dispose it together
/// with the player.
final Expando<MorseSink> _sinks = Expando<MorseSink>('reference player sink');

/// Default [MorsePlayerFactory]: a sidetone player at [frequencyHz].
///
/// The sidetone engine is prepared in the background; until it is ready the
/// sink's `on` / `off` are no-ops, so an early tap is silent but harmless.
/// A failed prepare (no audio device, headless CI) is logged and playback
/// continues silently while the pattern highlight still shows progress.
MorsePlayer createSidetoneMorsePlayer({
  double frequencyHz = 700,
  Clock? clock,
}) {
  final SidetoneSink sink = SidetoneSink(frequencyHz: frequencyHz);
  unawaited(
    sink.prepare().catchError((Object e) {
      debugPrint('ditmesh reference: sidetone prepare failed: $e');
    }),
  );
  return attachReferenceSink(MorsePlayer(sink: sink, clock: clock), sink);
}

/// Records that [player] renders through [sink]; returns [player].
///
/// Custom factories (and tests) call this so [referenceSinkOf],
/// [retuneReferencePlayer] and [disposeReferencePlayer] work for their
/// player too.
MorsePlayer attachReferenceSink(MorsePlayer player, MorseSink sink) {
  _sinks[player] = sink;
  return player;
}

/// The sink attached to [player], or null when the factory did not attach
/// one.
MorseSink? referenceSinkOf(MorsePlayer player) => _sinks[player];

/// Retunes the sidetone behind [player] to [frequencyHz]; no-op for other
/// sinks.
void retuneReferencePlayer(MorsePlayer player, double frequencyHz) {
  final MorseSink? sink = _sinks[player];
  if (sink is SidetoneSink) {
    sink.frequencyHz = frequencyHz;
  }
}

/// Stops and disposes [player] and the sink attached to it.
Future<void> disposeReferencePlayer(MorsePlayer player) async {
  final MorseSink? sink = _sinks[player];
  _sinks[player] = null;
  await player.dispose();
  await sink?.dispose();
}

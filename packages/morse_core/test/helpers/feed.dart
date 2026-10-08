import 'dart:math';

import 'package:morse_core/morse_core.dart';

/// Multiplicative jitter factor for one element (1.0 = exact).
typedef JitterFn = double Function(MorseElement element);

/// Replay a timeline into [decoder] as keyDown/keyUp calls.
///
/// Gaps are advanced in [tickStep] increments with a `tick()` call at each
/// step so the timer-driven boundary resolution path is exercised the same
/// way a real app would. Returns the timestamp at the end of the timeline.
Duration feedTimeline(
  MorseDecoder decoder,
  List<MorseElement> elements, {
  JitterFn? jitter,
  Duration start = const Duration(milliseconds: 500),
  Duration tickStep = const Duration(milliseconds: 10),
}) {
  Duration now = start;
  for (final MorseElement e in elements) {
    final double factor = jitter == null ? 1 : jitter(e);
    final Duration d = Duration(
        microseconds: (e.duration.inMicroseconds * factor).round());
    if (e.on) {
      decoder.keyDown(now);
      now += d;
      decoder.keyUp(now);
    } else {
      final Duration end = now + d;
      while (now + tickStep < end) {
        now += tickStep;
        decoder.tick(now);
      }
      now = end;
      decoder.tick(now);
    }
  }
  return now;
}

/// Uniform jitter in `[1 - amplitude, 1 + amplitude]` from a seeded RNG.
///
/// Every element independently hits any factor in the band with equal
/// probability, so a 3-dit dah or char gap sits at exactly `3 (1 - amplitude)`
/// as often as anywhere else. That is a much harsher model than a human
/// fist, where large deviations are rare.
JitterFn uniformJitter(double amplitude, {int seed = 42}) {
  final Random rng = Random(seed);
  return (MorseElement _) => 1 + (rng.nextDouble() * 2 - 1) * amplitude;
}

/// Triangular jitter bounded at `±amplitude` (sum of two uniform draws, so
/// the density peaks at 1.0 and falls linearly to zero at the bounds).
///
/// This approximates a human fist: most elements are close to nominal, the
/// extremes are rare but still reached. The amplitude is a hard bound, never
/// exceeded.
JitterFn triangularJitter(double amplitude, {int seed = 42}) {
  final Random rng = Random(seed);
  return (MorseElement _) =>
      1 + (rng.nextDouble() + rng.nextDouble() - 1) * amplitude;
}

/// Decode an entire timeline in one go and return the flushed text.
String decodeTimeline(
  List<MorseElement> elements, {
  DecoderConfig config = const DecoderConfig(),
  JitterFn? jitter,
}) {
  final MorseDecoder decoder = MorseDecoder(config: config);
  try {
    feedTimeline(decoder, elements, jitter: jitter);
    return decoder.flush();
  } finally {
    decoder.dispose();
  }
}

/// Levenshtein edit distance between two strings.
int editDistance(String a, String b) {
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  List<int> prev = List<int>.generate(b.length + 1, (int i) => i);
  List<int> cur = List<int>.filled(b.length + 1, 0);
  for (int i = 1; i <= a.length; i++) {
    cur[0] = i;
    for (int j = 1; j <= b.length; j++) {
      final int cost = a[i - 1] == b[j - 1] ? 0 : 1;
      cur[j] = min(min(cur[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
    }
    final List<int> tmp = prev;
    prev = cur;
    cur = tmp;
  }
  return prev[b.length];
}

/// `1 - editDistance / expected.length`, clamped to `[0, 1]`.
double accuracy(String expected, String actual) {
  final int d = editDistance(expected, actual);
  return (1 - d / expected.length).clamp(0.0, 1.0);
}

/// Render the decoder's character/word/unknown events as one string, using
/// U+FFFD for unknown patterns so each committed symbol occupies one code unit
/// (keeps the edit distance metric per-character).
String renderEvents(Iterable<DecodeEvent> events) {
  final StringBuffer sb = StringBuffer();
  for (final DecodeEvent e in events) {
    switch (e.kind) {
      case DecodeEventKind.character:
        sb.write(e.text);
      case DecodeEventKind.word:
        sb.write(' ');
      case DecodeEventKind.unknownPattern:
        sb.write('�');
      case DecodeEventKind.element:
        break;
    }
  }
  return sb.toString();
}

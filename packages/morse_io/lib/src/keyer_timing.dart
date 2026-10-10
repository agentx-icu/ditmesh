import 'package:morse_core/morse_core.dart';

/// The three durations an automatic keyer needs, as explicit values.
///
/// Kept separate from `MorseTiming` so the keyer can be unit-tested with
/// literal durations; the app converts with [KeyerTiming.fromMorseTiming].
final class KeyerTiming {
  /// All three durations must be positive. (Not asserted in the constructor:
  /// `Duration` comparisons are not allowed in constant expressions.)
  const KeyerTiming({required this.dit, required this.dah, required this.gap});

  /// PARIS timing from one dit: dah = 3 dit, inter-element gap = 1 dit.
  factory KeyerTiming.standard(Duration dit) =>
      KeyerTiming(dit: dit, dah: dit * 3, gap: dit);

  /// PARIS timing from words per minute (`dit = 1200 / wpm` ms).
  factory KeyerTiming.fromWpm(double wpm) {
    assert(wpm > 0, 'wpm must be positive');
    return KeyerTiming.standard(
      Duration(microseconds: (1200000 / wpm).round()),
    );
  }

  /// Element timing of [timing]; Farnsworth stretching does not affect the
  /// keyer because it only spaces characters, which a keyer never does.
  factory KeyerTiming.fromMorseTiming(MorseTiming timing) =>
      KeyerTiming(dit: timing.dit, dah: timing.dah, gap: timing.intraGap);

  final Duration dit;
  final Duration dah;

  /// Inter-element (intra-character) gap.
  final Duration gap;

  Duration durationOf(MorseElementKind kind) => switch (kind) {
    MorseElementKind.dit => dit,
    MorseElementKind.dah => dah,
    MorseElementKind.intraGap => gap,
    MorseElementKind.charGap => gap * 3,
    MorseElementKind.wordGap => gap * 7,
  };

  @override
  String toString() =>
      'KeyerTiming(dit: ${dit.inMilliseconds}ms, '
      'dah: ${dah.inMilliseconds}ms, gap: ${gap.inMilliseconds}ms)';

  @override
  bool operator ==(Object other) =>
      other is KeyerTiming &&
      other.dit == dit &&
      other.dah == dah &&
      other.gap == gap;

  @override
  int get hashCode => Object.hash(dit, dah, gap);
}

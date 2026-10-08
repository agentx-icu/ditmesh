/// One step of a Morse timeline: either key-down (dit/dah) or key-up (a gap).
enum MorseElementKind {
  dit,
  dah,

  /// Gap between elements inside one character (1 unit).
  intraGap,

  /// Gap between characters (3 units nominal, stretched under Farnsworth).
  charGap,

  /// Gap between words (7 units nominal, stretched under Farnsworth).
  wordGap,
}

/// A single on/off segment with its wall-clock duration.
///
/// Audio, haptic and flash renderers all consume the same `List<MorseElement>`
/// so the three modalities stay sample-accurate with each other.
final class MorseElement {
  const MorseElement(this.kind, this.duration);

  final MorseElementKind kind;
  final Duration duration;

  /// True while the key is down (dit or dah).
  bool get on => kind == MorseElementKind.dit || kind == MorseElementKind.dah;

  @override
  String toString() => 'MorseElement(${kind.name}, ${duration.inMilliseconds}ms)';

  @override
  bool operator ==(Object other) =>
      other is MorseElement && other.kind == kind && other.duration == duration;

  @override
  int get hashCode => Object.hash(kind, duration);
}

/// An RST signal report: readability 1-5, strength 1-9, tone 1-9 (CW).
final class RstReport {
  /// Throws [RangeError] for a value outside its scale.
  RstReport({
    required this.readability,
    required this.strength,
    this.tone = 9,
  }) {
    if (readability < 1 || readability > 5) {
      throw RangeError.range(readability, 1, 5, 'readability');
    }
    if (strength < 1 || strength > 9) {
      throw RangeError.range(strength, 1, 9, 'strength');
    }
    if (tone < 1 || tone > 9) {
      throw RangeError.range(tone, 1, 9, 'tone');
    }
  }

  /// Parses `579`, `5NN` (cut numbers) or a two-digit phone report `59`
  /// (tone 9 assumed). Returns null when [text] is not a report.
  static RstReport? tryParse(String text) {
    final t = text
        .trim()
        .toUpperCase()
        .replaceAll('N', '9')
        .replaceAll('T', '0');
    if (!RegExp(r'^[1-5][1-9][1-9]?$').hasMatch(t)) {
      return null;
    }
    return RstReport(
      readability: int.parse(t[0]),
      strength: int.parse(t[1]),
      tone: t.length == 3 ? int.parse(t[2]) : 9,
    );
  }

  final int readability;
  final int strength;
  final int tone;

  /// `579`.
  @override
  String toString() => '$readability$strength$tone';

  /// Contest spelling with 9 as `N`: `5NN`.
  String get cut => toString().replaceAll('9', 'N');

  @override
  bool operator ==(Object other) =>
      other is RstReport &&
      other.readability == readability &&
      other.strength == strength &&
      other.tone == tone;

  @override
  int get hashCode => Object.hash(readability, strength, tone);
}

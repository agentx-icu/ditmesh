/// Attempt / correct counters for one symbol.
final class CharStats {
  const CharStats({this.attempts = 0, this.correct = 0})
    : assert(attempts >= 0, 'attempts must be >= 0'),
      assert(
        correct >= 0 && correct <= attempts,
        'correct must be within 0..attempts',
      );

  static const CharStats empty = CharStats();

  final int attempts;
  final int correct;

  int get misses => attempts - correct;

  /// Fraction correct in 0..1; 0 when there were no attempts.
  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  CharStats withResult({required bool correct}) => CharStats(
    attempts: attempts + 1,
    correct: this.correct + (correct ? 1 : 0),
  );

  CharStats operator +(CharStats other) => CharStats(
    attempts: attempts + other.attempts,
    correct: correct + other.correct,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'attempts': attempts,
    'correct': correct,
  };

  factory CharStats.fromJson(Map<String, Object?> json) => CharStats(
    attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    correct: (json['correct'] as num?)?.toInt() ?? 0,
  );

  /// Merges two per-symbol stat maps by adding counters.
  static Map<String, CharStats> merge(
    Map<String, CharStats> a,
    Map<String, CharStats> b,
  ) {
    final out = Map<String, CharStats>.of(a);
    for (final entry in b.entries) {
      out[entry.key] = (out[entry.key] ?? CharStats.empty) + entry.value;
    }
    return out;
  }

  static Map<String, Object?> mapToJson(Map<String, CharStats> stats) =>
      <String, Object?>{
        for (final entry in stats.entries) entry.key: entry.value.toJson(),
      };

  static Map<String, CharStats> mapFromJson(Map<String, Object?>? json) =>
      <String, CharStats>{
        if (json != null)
          for (final entry in json.entries)
            entry.key: CharStats.fromJson(entry.value! as Map<String, Object?>),
      };

  @override
  String toString() => 'CharStats($correct/$attempts)';

  @override
  bool operator ==(Object other) =>
      other is CharStats &&
      other.attempts == attempts &&
      other.correct == correct;

  @override
  int get hashCode => Object.hash(attempts, correct);
}

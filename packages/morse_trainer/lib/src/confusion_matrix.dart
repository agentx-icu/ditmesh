/// Counts of "target symbol was answered as X".
///
/// The missing-answer case (a deletion) is recorded under
/// [ConfusionMatrix.missed] as the answered symbol; inserted symbols with no
/// target are recorded under [missed] as the target.
final class ConfusionMatrix {
  ConfusionMatrix() : _counts = <String, Map<String, int>>{};

  ConfusionMatrix._(this._counts);

  /// Key used for "nothing" on either side of a confusion.
  static const String missed = '';

  final Map<String, Map<String, int>> _counts;

  /// Records that [target] was answered as [answered] ([missed] when absent).
  void record(String target, String? answered, {int times = 1}) {
    final row = _counts.putIfAbsent(target, () => <String, int>{});
    final key = answered ?? missed;
    row[key] = (row[key] ?? 0) + times;
  }

  /// Records an inserted [answered] symbol that had no target.
  void recordInsertion(String answered, {int times = 1}) =>
      record(missed, answered, times: times);

  int count(String target, String? answered) =>
      _counts[target]?[answered ?? missed] ?? 0;

  /// All targets that have at least one recorded answer (may include [missed]).
  Iterable<String> get targets => _counts.keys;

  /// Answered-symbol -> count for one target (unmodifiable view).
  Map<String, int> rowFor(String target) =>
      Map<String, int>.unmodifiable(_counts[target] ?? const <String, int>{});

  /// Total answers recorded for [target].
  int totalFor(String target) =>
      _counts[target]?.values.fold<int>(0, (a, b) => a + b) ?? 0;

  /// Number of wrong answers (anything but [target] itself) for [target].
  int errorsFor(String target) => totalFor(target) - count(target, target);

  /// The wrong answer given most often for [target], or null if never wrong.
  ///
  /// Ties resolve to the lexically smallest key so the result is stable.
  String? mostConfusedWith(String target) {
    final row = _counts[target];
    if (row == null) {
      return null;
    }
    String? best;
    var bestCount = 0;
    final keys = row.keys.toList()..sort();
    for (final key in keys) {
      if (key == target) {
        continue;
      }
      final c = row[key]!;
      if (c > bestCount) {
        bestCount = c;
        best = key;
      }
    }
    return best;
  }

  bool get isEmpty => _counts.isEmpty;

  /// Adds every count of [other] into this matrix.
  void merge(ConfusionMatrix other) {
    for (final target in other._counts.keys) {
      for (final entry in other._counts[target]!.entries) {
        record(target, entry.key, times: entry.value);
      }
    }
  }

  /// A deep copy.
  ConfusionMatrix copy() => ConfusionMatrix()..merge(this);

  Map<String, Object?> toJson() => <String, Object?>{
    for (final entry in _counts.entries)
      entry.key: Map<String, Object?>.of(entry.value),
  };

  factory ConfusionMatrix.fromJson(Map<String, Object?>? json) {
    final counts = <String, Map<String, int>>{};
    if (json != null) {
      for (final entry in json.entries) {
        final row = entry.value! as Map<String, Object?>;
        counts[entry.key] = <String, int>{
          for (final cell in row.entries)
            cell.key: (cell.value! as num).toInt(),
        };
      }
    }
    return ConfusionMatrix._(counts);
  }

  @override
  String toString() => 'ConfusionMatrix($_counts)';
}

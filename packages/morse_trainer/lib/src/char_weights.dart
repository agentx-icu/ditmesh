import 'dart:math';

import 'char_stats.dart';

/// Per-symbol drill weights: shaky symbols and freshly unlocked ones come up
/// more often.
///
/// Weight formula: `w = max(floor, 1 + k * (1 - accuracy))`, multiplied by
/// [recentBoost] for symbols in the recently-unlocked set. A symbol with no
/// data is treated as having [unknownAccuracy] (0 by default) so it gets the
/// highest weight until it has been drilled.
final class CharWeights {
  CharWeights._(Map<String, double> weights, this.defaultWeight)
    : _weights = Map<String, double>.unmodifiable(weights);

  /// Every symbol weighs 1.
  factory CharWeights.uniform() => CharWeights._(const <String, double>{}, 1);

  /// Explicit weights; symbols not listed weigh [defaultWeight].
  factory CharWeights.explicit(
    Map<String, double> weights, {
    double defaultWeight = 1,
  }) {
    if (defaultWeight < 0 || !defaultWeight.isFinite) {
      throw ArgumentError.value(
        defaultWeight,
        'defaultWeight',
        'must be finite and >= 0',
      );
    }
    for (final entry in weights.entries) {
      if (entry.value < 0 || !entry.value.isFinite) {
        throw ArgumentError.value(
          entry.value,
          'weights[${entry.key}]',
          'weights must be finite and >= 0',
        );
      }
    }
    return CharWeights._(weights, defaultWeight);
  }

  /// Builds weights from accuracy in 0..1 per symbol.
  factory CharWeights.fromAccuracy(
    Map<String, double> accuracy, {
    double k = 2,
    double floor = 1,
    Set<String> recent = const <String>{},
    double recentBoost = 2,
    double unknownAccuracy = 0,
  }) {
    assert(k >= 0, 'k must be >= 0');
    assert(floor >= 0, 'floor must be >= 0');
    assert(recentBoost >= 1, 'recentBoost must be >= 1');
    double base(double acc) {
      final clamped = acc.clamp(0.0, 1.0);
      return max(floor, 1 + k * (1 - clamped));
    }

    final weights = <String, double>{};
    final symbols = <String>{...accuracy.keys, ...recent};
    for (final symbol in symbols) {
      final w = base(accuracy[symbol] ?? unknownAccuracy);
      weights[symbol] = recent.contains(symbol) ? w * recentBoost : w;
    }
    return CharWeights._(weights, base(unknownAccuracy));
  }

  /// Builds weights from attempt counters. A symbol with fewer than
  /// [minAttempts] attempts is treated as unknown.
  factory CharWeights.fromStats(
    Map<String, CharStats> stats, {
    double k = 2,
    double floor = 1,
    Set<String> recent = const <String>{},
    double recentBoost = 2,
    double unknownAccuracy = 0,
    int minAttempts = 1,
  }) {
    final accuracy = <String, double>{
      for (final entry in stats.entries)
        if (entry.value.attempts >= minAttempts)
          entry.key: entry.value.accuracy,
    };
    return CharWeights.fromAccuracy(
      accuracy,
      k: k,
      floor: floor,
      recent: recent,
      recentBoost: recentBoost,
      unknownAccuracy: unknownAccuracy,
    );
  }

  final Map<String, double> _weights;

  /// Weight applied to symbols without an explicit entry.
  final double defaultWeight;

  /// Symbols that carry an explicit weight.
  Iterable<String> get symbols => _weights.keys;

  double weightOf(String symbol) => _weights[symbol] ?? defaultWeight;

  /// Weight of each symbol in [chars], in the same order.
  List<double> weightsFor(Iterable<String> chars) =>
      chars.map(weightOf).toList(growable: false);

  /// Draws one symbol from [chars] with probability proportional to weight.
  ///
  /// Falls back to a uniform draw when every weight is zero. Throws
  /// [ArgumentError] when [chars] is empty.
  String pick(Random random, List<String> chars) {
    if (chars.isEmpty) {
      throw ArgumentError.value(chars, 'chars', 'must not be empty');
    }
    final weights = weightsFor(chars);
    final total = weights.fold<double>(0, (a, b) => a + b);
    if (total <= 0) {
      return chars[random.nextInt(chars.length)];
    }
    var r = random.nextDouble() * total;
    for (var i = 0; i < chars.length; i++) {
      r -= weights[i];
      if (r < 0) {
        return chars[i];
      }
    }
    return chars.last;
  }

  /// Draws [count] symbols with replacement.
  List<String> pickMany(Random random, List<String> chars, int count) =>
      List<String>.generate(count, (_) => pick(random, chars), growable: false);

  Map<String, Object?> toJson() => <String, Object?>{
    'default': defaultWeight,
    'weights': Map<String, Object?>.of(_weights),
  };

  factory CharWeights.fromJson(Map<String, Object?> json) {
    final raw = json['weights'] as Map<String, Object?>? ?? const {};
    return CharWeights._(<String, double>{
      for (final entry in raw.entries)
        entry.key: (entry.value! as num).toDouble(),
    }, (json['default'] as num?)?.toDouble() ?? 1);
  }

  @override
  String toString() => 'CharWeights($_weights, default $defaultWeight)';
}

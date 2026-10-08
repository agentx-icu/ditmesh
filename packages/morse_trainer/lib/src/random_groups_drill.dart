import 'dart:math';

import 'char_weights.dart';
import 'drill.dart';
import 'morse_text.dart';

/// Classic Koch drill: groups of random symbols from the known set.
///
/// Symbol choice is weighted by [weights] so weak or newly unlocked symbols
/// appear more often. Groups are joined with single spaces.
final class RandomGroupsDrill implements DrillGenerator {
  RandomGroupsDrill({
    required Iterable<String> chars,
    this.groupCount = 5,
    this.groupSize = 5,
    CharWeights? weights,
  }) : assert(groupCount > 0, 'groupCount must be positive'),
       assert(groupSize > 0, 'groupSize must be positive'),
       chars = List<String>.unmodifiable(
         chars.map(MorseText.normalizeChar).toSet(),
       ),
       weights = weights ?? CharWeights.uniform() {
    if (this.chars.isEmpty) {
      throw ArgumentError.value(chars, 'chars', 'must not be empty');
    }
  }

  /// Builds a drill that produces about [totalChars] symbols in groups of
  /// [groupSize] (rounded up to whole groups).
  factory RandomGroupsDrill.forLength({
    required Iterable<String> chars,
    required int totalChars,
    int groupSize = 5,
    CharWeights? weights,
  }) => RandomGroupsDrill(
    chars: chars,
    groupSize: groupSize,
    groupCount: max(1, (totalChars / groupSize).ceil()),
    weights: weights,
  );

  /// Distinct, normalised symbol pool in insertion order.
  final List<String> chars;
  final int groupCount;
  final int groupSize;
  final CharWeights weights;

  @override
  String get kind => 'groups';

  /// Total symbols each generated drill contains.
  int get totalChars => groupCount * groupSize;

  @override
  Drill generate(Random random) {
    final groups = List<String>.generate(
      groupCount,
      (_) => weights.pickMany(random, chars, groupSize).join(),
      growable: false,
    );
    return Drill.fromText(groups.join(' '), kind: kind);
  }
}

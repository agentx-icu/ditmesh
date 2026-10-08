import 'dart:math';

import 'package:morse_core/morse_core.dart';

import 'confusion_matrix.dart';
import 'drill.dart';
import 'morse_text.dart';

/// Two symbols drilled against each other, e.g. `S` / `H`.
final class ConfusablePair {
  const ConfusablePair(this.a, this.b, {this.mistakes = 0});

  final String a;
  final String b;

  /// How often the trainee has answered one as the other.
  final int mistakes;

  @override
  bool operator ==(Object other) =>
      other is ConfusablePair &&
      other.a == a &&
      other.b == b &&
      other.mistakes == mistakes;

  @override
  int get hashCode => Object.hash(a, b, mistakes);

  @override
  String toString() => 'ConfusablePair($a/$b, $mistakes)';
}

/// Minimal-pair drill: each group mixes the two symbols of one confusable
/// pair (`SHSSH`), so the ear has to tell exactly those two apart.
///
/// Pairs come from two sources, both restricted to [chars]:
///  * the trainee's own [ConfusionMatrix] - any two symbols they have mixed
///    up, ranked by how often;
///  * pattern neighbours - symbols one element apart (`S ...` / `H ....`,
///    `U ..-` / `V ...-`, `K -.-` / `M --`), which is where beginners slip.
///
/// The [maxPairs] best pairs are kept; a group picks one pair, weighted by
/// `1 + mistakes`, and fills [groupSize] symbols from it at random.
final class ConfusableDrill implements DrillGenerator {
  ConfusableDrill({
    required Iterable<String> chars,
    ConfusionMatrix? confusion,
    this.groupCount = 1,
    this.groupSize = 5,
    this.maxPairs = 4,
  }) : assert(groupCount > 0, 'groupCount must be positive'),
       assert(groupSize > 0, 'groupSize must be positive'),
       assert(maxPairs > 0, 'maxPairs must be positive'),
       pairs = List<ConfusablePair>.unmodifiable(
         rankPairs(chars, confusion).take(maxPairs),
       );

  final int groupCount;
  final int groupSize;
  final int maxPairs;

  /// The pairs this drill uses, most confused first.
  final List<ConfusablePair> pairs;

  @override
  String get kind => 'confusables';

  /// False when [chars] holds no confusable pair at all.
  bool get canGenerate => pairs.isNotEmpty;

  /// Every distinct symbol the drill can emit.
  Set<String> get chars => <String>{
    for (final p in pairs) ...<String>[p.a, p.b],
  };

  @override
  Drill generate(Random random) {
    if (!canGenerate) {
      throw StateError('ConfusableDrill has no pair for the allowed symbols');
    }
    final groups = List<String>.generate(groupCount, (_) {
      final pair = _pickPair(random);
      final group = List<String>.generate(
        groupSize,
        (_) => random.nextBool() ? pair.a : pair.b,
      );
      // A one-symbol group is never a contrast; force both in when possible.
      if (groupSize >= 2 && group.toSet().length == 1) {
        group[random.nextInt(groupSize)] = group.first == pair.a
            ? pair.b
            : pair.a;
      }
      return group.join();
    });
    return Drill.fromText(groups.join(' '), kind: kind);
  }

  ConfusablePair _pickPair(Random random) {
    final total = pairs.fold<int>(0, (sum, p) => sum + 1 + p.mistakes);
    var roll = random.nextInt(total);
    for (final pair in pairs) {
      roll -= 1 + pair.mistakes;
      if (roll < 0) {
        return pair;
      }
    }
    return pairs.last;
  }

  /// All confusable pairs inside [chars], most confused first.
  ///
  /// Pairs with recorded mistakes rank by mistake count; pattern neighbours
  /// without mistakes follow in the order their symbols appear in [chars].
  /// Each unordered pair appears once.
  static List<ConfusablePair> rankPairs(
    Iterable<String> chars,
    ConfusionMatrix? confusion,
  ) {
    final symbols = <String>[
      ...<String>{...chars.map(MorseText.normalizeChar)},
    ];
    final index = <String, int>{
      for (var i = 0; i < symbols.length; i++) symbols[i]: i,
    };
    final mistakes = <(int, int), int>{};
    void add(String x, String y, int count) {
      final ix = index[x];
      final iy = index[y];
      if (ix == null || iy == null || ix == iy) {
        return;
      }
      final key = ix < iy ? (ix, iy) : (iy, ix);
      mistakes[key] = (mistakes[key] ?? 0) + count;
    }

    if (confusion != null) {
      for (final target in confusion.targets) {
        confusion.rowFor(target).forEach((answered, count) {
          add(target, answered, count);
        });
      }
    }
    for (var i = 0; i < symbols.length; i++) {
      for (var j = i + 1; j < symbols.length; j++) {
        if (areNeighbours(symbols[i], symbols[j])) {
          add(symbols[i], symbols[j], 0);
        }
      }
    }
    final keys = mistakes.keys.toList()
      ..sort((x, y) {
        final byMistakes = mistakes[y]!.compareTo(mistakes[x]!);
        if (byMistakes != 0) return byMistakes;
        final byFirst = x.$1.compareTo(y.$1);
        return byFirst != 0 ? byFirst : x.$2.compareTo(y.$2);
      });
    return <ConfusablePair>[
      for (final k in keys)
        ConfusablePair(symbols[k.$1], symbols[k.$2], mistakes: mistakes[k]!),
    ];
  }

  /// Whether the Morse patterns of [x] and [y] are one element apart: one
  /// dit/dah changed, added or removed (edit distance 1).
  static bool areNeighbours(String x, String y) {
    final px = patternOf(x);
    final py = patternOf(y);
    if (px == null || py == null || px == py) {
      return false;
    }
    return _editDistanceIsOne(px, py);
  }

  /// `.`/`-` pattern for a symbol or bracketed prosign, or null.
  static String? patternOf(String symbol) => symbol.length > 1
      ? MorseAlphabet.encodeProsign(symbol)
      : MorseAlphabet.encodeChar(symbol);

  static bool _editDistanceIsOne(String s, String t) {
    if ((s.length - t.length).abs() > 1) {
      return false;
    }
    if (s.length == t.length) {
      var diff = 0;
      for (var i = 0; i < s.length; i++) {
        if (s[i] != t[i] && ++diff > 1) return false;
      }
      return diff == 1;
    }
    final longer = s.length > t.length ? s : t;
    final shorter = s.length > t.length ? t : s;
    for (var i = 0; i < longer.length; i++) {
      if (longer.substring(0, i) + longer.substring(i + 1) == shorter) {
        return true;
      }
    }
    return false;
  }
}

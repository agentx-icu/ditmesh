import 'dart:math';

import 'package:morse_core/morse_core.dart';

import 'koch_course.dart';
import 'morse_text.dart';
import 'session_score.dart';
import 'word_lists.dart';

/// One tier of the placement check (functional spec §8.3).
final class PlacementTier {
  PlacementTier({
    required this.index,
    required List<String> symbols,
    required List<String> rounds,
    required this.effectiveWpm,
  }) : symbols = List<String>.unmodifiable(symbols),
       rounds = List<String>.unmodifiable(rounds);

  final int index;

  /// Koch symbols this tier verifies (empty for the word tier).
  final List<String> symbols;

  /// The texts played, in order (groups of up to five symbols, or words).
  final List<String> rounds;
  final double effectiveWpm;

  int get symbolCount =>
      rounds.fold(0, (n, r) => n + MorseText.symbols(r).length);
}

/// Per-symbol evidence gathered during placement.
final class PlacementEvidence {
  const PlacementEvidence({this.correct = 0, this.wrong = 0});

  final int correct;
  final int wrong;

  /// Verified: at least two unassisted correct copies and no wrong one.
  bool get verified => correct >= 2 && wrong == 0;
}

/// Outcome of a placement check. A suggestion, never an unlock: nothing is
/// applied until the learner adopts it.
final class PlacementResult {
  const PlacementResult({
    required this.suggestedLesson,
    required this.verifiedPrefix,
    required this.tiersPassed,
    required this.evidence,
  });

  /// Earliest lesson whose new symbol is not verified (1 = start over).
  final int suggestedLesson;

  /// Length of the continuously verified Koch prefix.
  final int verifiedPrefix;
  final int tiersPassed;
  final Map<String, PlacementEvidence> evidence;
}

/// The placement assessment: tiers over the actual Koch order (derived from
/// the course, not hard-coded), each symbol twice, shuffled by seed; then a
/// short-word tier. Character speed 20 WPM; effective 5, 8, 12, 16, 20.
final class PlacementAssessment {
  PlacementAssessment({
    required this.course,
    required this.seed,
    this.characterWpm = 20,
    List<double> effectiveTiers = defaultEffectiveTiers,
  }) : effectiveTiers = List<double>.unmodifiable(effectiveTiers) {
    _tiers = _buildTiers();
  }

  static const List<double> defaultEffectiveTiers = <double>[5, 8, 12, 16, 20];
  static const double passAccuracy = 0.90;
  static const int groupSize = 5;
  static const int wordTierSymbols = 20;

  final KochCourse course;
  final int seed;
  final double characterWpm;
  final List<double> effectiveTiers;
  late final List<PlacementTier> _tiers;
  final Map<String, (int, int)> _evidence = <String, (int, int)>{};
  int _tier = 0;
  int _passed = 0;
  bool _stopped = false;

  List<PlacementTier> get tiers => _tiers;
  int get currentTierIndex => _tier;
  bool get isFinished => _stopped || _tier >= _tiers.length;
  PlacementTier? get currentTier => isFinished ? null : _tiers[_tier];

  MorseTiming timingFor(PlacementTier tier) => MorseTiming(
    wpm: characterWpm,
    farnsworthWpm: tier.effectiveWpm < characterWpm ? tier.effectiveWpm : null,
  );

  List<PlacementTier> _buildTiers() {
    final order = course.order;
    final random = Random(seed);
    final bounds = <(int, int)>[
      (0, 10),
      (10, 20),
      (20, 30),
      (30, order.length),
    ];
    final tiers = <PlacementTier>[];
    for (final (start, end) in bounds) {
      if (start >= order.length) break;
      final symbols = order.sublist(start, min(end, order.length));
      final pool = <String>[...symbols, ...symbols]..shuffle(random);
      final rounds = <String>[
        for (var i = 0; i < pool.length; i += groupSize)
          pool.sublist(i, min(i + groupSize, pool.length)).join(),
      ];
      tiers.add(
        PlacementTier(
          index: tiers.length,
          symbols: symbols,
          rounds: rounds,
          effectiveWpm:
              effectiveTiers[min(tiers.length, effectiveTiers.length - 1)],
        ),
      );
    }
    // Short words from the whole alphabet, at least 20 symbols.
    final words =
        WordLists.commonWords
            .where((w) => w.length <= 4 && MorseText.usesOnly(w, order.toSet()))
            .toList()
          ..shuffle(random);
    final picked = <String>[];
    var n = 0;
    for (final w in words) {
      if (n >= wordTierSymbols) break;
      picked.add(w);
      n += w.length;
    }
    if (picked.isNotEmpty) {
      tiers.add(
        PlacementTier(
          index: tiers.length,
          symbols: const <String>[],
          rounds: picked,
          effectiveWpm:
              effectiveTiers[min(tiers.length, effectiveTiers.length - 1)],
        ),
      );
    }
    return tiers;
  }

  /// Records a finished tier: [answers] align with the tier's rounds;
  /// [assisted] rounds (replayed) never verify a symbol. Returns whether the
  /// tier passed; a failed tier ends the assessment.
  bool recordTier(List<String> answers, {Set<int> assisted = const <int>{}}) {
    final tier = currentTier;
    if (tier == null) throw StateError('placement finished');
    var total = 0;
    var correct = 0;
    var inserted = 0;
    for (var i = 0; i < tier.rounds.length; i++) {
      final answer = i < answers.length ? answers[i] : '';
      final score = SessionScore.evaluate(tier.rounds[i], answer);
      total += score.totalChars;
      correct += score.correctChars;
      inserted += score.insertions;
      if (assisted.contains(i)) continue;
      for (final pair in score.alignment) {
        final t = pair.target;
        if (t == null) continue;
        final (c, w) = _evidence[t] ?? (0, 0);
        _evidence[t] = pair.isMatch ? (c + 1, w) : (c, w + 1);
      }
    }
    final strict = total + inserted == 0 ? 0.0 : correct / (total + inserted);
    final ok = strict >= passAccuracy;
    if (ok) _passed++;
    _tier++;
    if (!ok) _stopped = true;
    return ok;
  }

  /// Stops early (the learner skipped the rest).
  void stop() => _stopped = true;

  PlacementResult result() {
    final order = course.order;
    var prefix = 0;
    while (prefix < order.length) {
      final e = _evidence[order[prefix]];
      if (e == null || !(e.$1 >= 2 && e.$2 == 0)) break;
      prefix++;
    }
    final int lesson;
    if (prefix >= order.length) {
      lesson = course.lessonCount;
    } else {
      // The lesson that introduces the first unverified symbol.
      lesson = course.clampLesson(course.lessonFor(order[prefix]) ?? 1);
    }
    return PlacementResult(
      suggestedLesson: lesson,
      verifiedPrefix: prefix,
      tiersPassed: _passed,
      evidence: <String, PlacementEvidence>{
        for (final e in _evidence.entries)
          e.key: PlacementEvidence(correct: e.value.$1, wrong: e.value.$2),
      },
    );
  }
}

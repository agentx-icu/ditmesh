import 'dart:math';

import 'exercise.dart';
import 'session_summary.dart';

enum SpeedAdviceKind {
  /// Not enough comparable, unassisted evidence; no change proposed.
  insufficient,

  /// Results are solid but not enough for a change either way.
  hold,

  /// Raise the effective (Farnsworth) speed by 1 WPM.
  increaseEffective,

  /// Effective already equals character speed: raise both by 1 WPM.
  increaseBoth,

  /// Lower the effective speed by 1 WPM (or practise weak symbols first).
  decrease,
}

/// A recommendation. Never applied automatically; the app persists
/// [characterWpm] / [effectiveWpm] only after the learner taps Apply.
final class SpeedAdvice {
  const SpeedAdvice({
    required this.kind,
    required this.characterWpm,
    required this.effectiveWpm,
    required this.samples,
    this.evidenceKey,
    this.weightedAccuracy,
  });

  final SpeedAdviceKind kind;

  /// Proposed speeds (equal to the current ones for insufficient / hold).
  final double characterWpm;
  final double effectiveWpm;

  /// Comparable attempts used.
  final int samples;

  /// Identifies the evidence batch (id of the newest attempt used), so one
  /// batch yields at most one recommendation.
  final String? evidenceKey;
  final double? weightedAccuracy;

  bool get isChange =>
      kind == SpeedAdviceKind.increaseEffective ||
      kind == SpeedAdviceKind.increaseBoth ||
      kind == SpeedAdviceKind.decrease;
}

/// Initial speed algorithm (functional spec §4.3). Thresholds are product
/// defaults, centralised here.
abstract final class SpeedRecommender {
  static const Duration window = Duration(days: 14);
  static const int latest = 5;
  static const int minSamples = 3;
  static const int minSymbols = 50;
  static const double raiseWeighted = 0.95;
  static const double raiseEach = 0.90;
  static const double lowerBelow = 0.80;
  static const double minCharacterWpm = 10;
  static const double maxCharacterWpm = 40;
  static const double minEffectiveWpm = 5;

  /// Sources whose copying is comparable receive evidence. Sending, QSO
  /// semantics, placement and recordings never are.
  static const Set<ExerciseSource> receiveSources = <ExerciseSource>{
    ExerciseSource.course,
    ExerciseSource.review,
    ExerciseSource.focus,
    ExerciseSource.chat,
    ExerciseSource.material,
  };

  /// Evaluates [history] (oldest first) for the current speeds.
  /// [currentLesson] restricts course evidence to the current symbol set so
  /// new symbols and a higher speed are never combined.
  static SpeedAdvice evaluate(
    List<SessionSummary> history, {
    required double characterWpm,
    required double effectiveWpm,
    required DateTime now,
    int? currentLesson,
  }) {
    final eff = min(effectiveWpm, characterWpm);
    final since = now.subtract(window);
    final comparable = history.where((s) {
      final source = s.source;
      return s.id != null &&
          source != null &&
          receiveSources.contains(source) &&
          s.isKnownUnassisted &&
          s.completed &&
          s.characterWpm == characterWpm &&
          s.effectiveWpm != null &&
          min(s.effectiveWpm!, characterWpm) == eff &&
          !s.at.isBefore(since) &&
          s.totalChars >= minSymbols &&
          (currentLesson == null ||
              source != ExerciseSource.course ||
              s.lesson == currentLesson);
    }).toList();
    SpeedAdvice same(SpeedAdviceKind kind, int n, {String? key, double? acc}) =>
        SpeedAdvice(
          kind: kind,
          characterWpm: characterWpm,
          effectiveWpm: eff,
          samples: n,
          evidenceKey: key,
          weightedAccuracy: acc,
        );
    if (comparable.isEmpty) return same(SpeedAdviceKind.insufficient, 0);
    // Identical kind: the drill kind of the newest comparable attempt.
    final kind = comparable.last.drillKind;
    final ofKind = comparable.where((s) => s.drillKind == kind).toList();
    final recent = ofKind.sublist(max(0, ofKind.length - latest));
    if (recent.length < minSamples) {
      return same(SpeedAdviceKind.insufficient, recent.length);
    }
    final key = recent.last.id;
    var weightSum = 0;
    var weighted = 0.0;
    for (final s in recent) {
      weightSum += s.totalChars;
      weighted += s.strictAccuracy * s.totalChars;
    }
    final acc = weighted / weightSum;
    final last3 = recent.sublist(recent.length - minSamples);
    if (last3.every((s) => s.strictAccuracy < lowerBelow)) {
      final lowered = eff - 1;
      if (lowered < minEffectiveWpm) {
        return same(SpeedAdviceKind.hold, recent.length, key: key, acc: acc);
      }
      return SpeedAdvice(
        kind: SpeedAdviceKind.decrease,
        characterWpm: characterWpm,
        effectiveWpm: lowered,
        samples: recent.length,
        evidenceKey: key,
        weightedAccuracy: acc,
      );
    }
    final raise =
        acc >= raiseWeighted &&
        recent.every((s) => s.strictAccuracy >= raiseEach);
    if (!raise) {
      return same(SpeedAdviceKind.hold, recent.length, key: key, acc: acc);
    }
    if (eff < characterWpm) {
      return SpeedAdvice(
        kind: SpeedAdviceKind.increaseEffective,
        characterWpm: characterWpm,
        effectiveWpm: min(characterWpm, eff + 1),
        samples: recent.length,
        evidenceKey: key,
        weightedAccuracy: acc,
      );
    }
    if (characterWpm + 1 > maxCharacterWpm) {
      return same(SpeedAdviceKind.hold, recent.length, key: key, acc: acc);
    }
    return SpeedAdvice(
      kind: SpeedAdviceKind.increaseBoth,
      characterWpm: characterWpm + 1,
      effectiveWpm: characterWpm + 1,
      samples: recent.length,
      evidenceKey: key,
      weightedAccuracy: acc,
    );
  }
}

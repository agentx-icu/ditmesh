import 'alignment.dart';
import 'char_stats.dart';
import 'confusion_matrix.dart';
import 'morse_text.dart';

/// Result of comparing what was sent ([target]) with what the trainee copied
/// ([answer]).
///
/// Symbols are compared after [MorseText.tokenize] with spaces removed, and
/// aligned with [SequenceAligner] so a single missed or extra character does
/// not shift the rest of the copy out of place.
///
/// [accuracy] is correctly copied symbols divided by symbols sent; it ignores
/// inserted symbols, so typing extra characters can raise it. [strictAccuracy]
/// also counts insertions against the copy and is what gates Koch lessons
/// (see `KochCourse.passes`).
final class SessionScore {
  SessionScore._({
    required this.target,
    required this.answer,
    required this.alignment,
    required this.correctChars,
    required this.substitutions,
    required this.insertions,
    required this.deletions,
    required Map<String, CharStats> charStats,
    required this.confusion,
    required this.at,
    required this.elapsed,
    required this.lesson,
    required this.drillKind,
  }) : charStats = Map<String, CharStats>.unmodifiable(charStats);

  /// Scores [answer] against [target].
  ///
  /// [at], [elapsed], [lesson] and [drillKind] are optional bookkeeping that
  /// travels with the score into progress history.
  factory SessionScore.evaluate(
    String target,
    String answer, {
    DateTime? at,
    Duration? elapsed,
    int? lesson,
    String? drillKind,
  }) {
    final targetSymbols = MorseText.symbols(target);
    final answerSymbols = MorseText.symbols(answer);
    final alignment = SequenceAligner.align(targetSymbols, answerSymbols);

    var correct = 0;
    var substitutions = 0;
    var insertions = 0;
    var deletions = 0;
    final stats = <String, CharStats>{};
    final confusion = ConfusionMatrix();

    for (final pair in alignment) {
      switch (pair.op) {
        case AlignmentOp.match:
          correct++;
        case AlignmentOp.substitution:
          substitutions++;
        case AlignmentOp.insertion:
          insertions++;
          confusion.recordInsertion(pair.answer!);
          continue;
        case AlignmentOp.deletion:
          deletions++;
      }
      final t = pair.target!;
      stats[t] = (stats[t] ?? CharStats.empty).withResult(
        correct: pair.isMatch,
      );
      confusion.record(t, pair.answer);
    }

    return SessionScore._(
      target: target,
      answer: answer,
      alignment: alignment,
      correctChars: correct,
      substitutions: substitutions,
      insertions: insertions,
      deletions: deletions,
      charStats: stats,
      confusion: confusion,
      at: at,
      elapsed: elapsed,
      lesson: lesson,
      drillKind: drillKind,
    );
  }

  /// Joins separately scored rounds without re-aligning them across round
  /// boundaries (a copy that runs into the next round cannot borrow its
  /// symbols).
  factory SessionScore.combine(
    List<SessionScore> parts, {
    DateTime? at,
    Duration? elapsed,
    int? lesson,
    String? drillKind,
  }) {
    final alignment = <AlignedPair>[];
    final stats = <String, CharStats>{};
    final confusion = ConfusionMatrix();
    var correct = 0, subs = 0, ins = 0, del = 0;
    for (final p in parts) {
      alignment.addAll(p.alignment);
      correct += p.correctChars;
      subs += p.substitutions;
      ins += p.insertions;
      del += p.deletions;
      for (final e in p.charStats.entries) {
        stats[e.key] = (stats[e.key] ?? CharStats.empty) + e.value;
      }
      confusion.merge(p.confusion);
    }
    return SessionScore._(
      target: parts.map((p) => p.target).join(' '),
      answer: parts.map((p) => p.answer).join(' '),
      alignment: alignment,
      correctChars: correct,
      substitutions: subs,
      insertions: ins,
      deletions: del,
      charStats: stats,
      confusion: confusion,
      at: at,
      elapsed: elapsed,
      lesson: lesson,
      drillKind: drillKind,
    );
  }

  final String target;
  final String answer;

  /// Column-by-column alignment of target symbols against answer symbols.
  final List<AlignedPair> alignment;

  final int correctChars;
  final int substitutions;
  final int insertions;
  final int deletions;

  /// Per target symbol: attempts (= occurrences in target) and correct copies.
  final Map<String, CharStats> charStats;

  final ConfusionMatrix confusion;

  final DateTime? at;
  final Duration? elapsed;
  final int? lesson;
  final String? drillKind;

  /// Symbols in the target (spaces excluded).
  int get totalChars => correctChars + substitutions + deletions;

  /// Correct copies / symbols sent; 0 when nothing was sent.
  double get accuracy => totalChars == 0 ? 0 : correctChars / totalChars;

  /// Correct copies / (symbols sent + inserted symbols).
  double get strictAccuracy {
    final denominator = totalChars + insertions;
    return denominator == 0 ? 0 : correctChars / denominator;
  }

  int get errors => substitutions + insertions + deletions;

  bool get isPerfect => errors == 0 && totalChars > 0;

  /// Symbol -> accuracy for every symbol that occurred in the target.
  Map<String, double> get perCharAccuracy => <String, double>{
    for (final entry in charStats.entries) entry.key: entry.value.accuracy,
  };

  /// Symbols copied below [threshold] accuracy, worst first.
  List<String> weakChars({double threshold = 1.0}) {
    final weak =
        charStats.entries.where((e) => e.value.accuracy < threshold).toList()
          ..sort((a, b) {
            final byAcc = a.value.accuracy.compareTo(b.value.accuracy);
            return byAcc != 0 ? byAcc : a.key.compareTo(b.key);
          });
    return weak.map((e) => e.key).toList(growable: false);
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'target': target,
    'answer': answer,
    'at': at?.toIso8601String(),
    'elapsedMs': elapsed?.inMilliseconds,
    'lesson': lesson,
    'drillKind': drillKind,
    // Derived values are included for consumers that only read JSON.
    'totalChars': totalChars,
    'correctChars': correctChars,
    'accuracy': accuracy,
  };

  /// Rebuilds a score from [toJson] output by re-evaluating target vs answer.
  factory SessionScore.fromJson(Map<String, Object?> json) {
    final atRaw = json['at'] as String?;
    final elapsedMs = (json['elapsedMs'] as num?)?.toInt();
    return SessionScore.evaluate(
      json['target'] as String,
      json['answer'] as String,
      at: atRaw == null ? null : DateTime.parse(atRaw),
      elapsed: elapsedMs == null ? null : Duration(milliseconds: elapsedMs),
      lesson: (json['lesson'] as num?)?.toInt(),
      drillKind: json['drillKind'] as String?,
    );
  }

  @override
  String toString() =>
      'SessionScore($correctChars/$totalChars, +$insertions ins, '
      '${(accuracy * 100).toStringAsFixed(1)}%)';
}

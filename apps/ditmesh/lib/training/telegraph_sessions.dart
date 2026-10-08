import 'dart:math';

import 'package:morse_core/morse_core.dart';
import 'package:morse_trainer/morse_trainer.dart';

import 'receive_session.dart';
import 'training_controller.dart';

/// Chinese telegraph-code practice on top of the controller (F13); an
/// extension so the controller stays within the size gate.
extension TelegraphSessions on TrainingController {
  /// Name of the codebook-recall statistics document.
  static const String recallDoc = 'telegraph_recall';

  /// Digit copying of real codes from [chars] (the curated list by
  /// default) in [codebook]. Scored as Morse digits under the usual
  /// policy: only learned digits reach SRS; it never counts toward the
  /// lesson. The codebook and table version are stored with the attempt.
  ReceiveSession startTelegraphDigitsSession(
    TelegraphCodebook codebook, {
    Iterable<String>? chars,
    Iterable<String>? codes,
    Random? random,
    DateTime Function()? now,
  }) {
    final t = trainerSettings;
    final generator = codes != null
        ? TelegraphDigitsDrill.ofCodes(codes, codebook: codebook)
        : TelegraphDigitsDrill(
            chars: chars ?? TelegraphCurriculum.introductoryFor(codebook),
            codebook: codebook,
          );
    return ReceiveSession(
      kind: ReceiveDrillKind.numbers,
      generator: generator,
      chars: TelegraphDigitsDrill.digitSymbols.toList()..sort(),
      timing: t.toTiming(),
      charBudget: t.sessionLengthChars,
      timeBudget: t.sessionLengthSeconds == null
          ? null
          : Duration(seconds: t.sessionLengthSeconds!),
      lesson: currentLesson,
      source: ExerciseSource.focus,
      sourceRef: TelegraphCurriculum.sourceRef(codebook),
      random: random ?? Random(),
      now: now ?? DateTime.now,
    );
  }

  /// Digit-copy accuracy of past telegraph sessions in [codebook]:
  /// (attempts, accuracy 0..1).
  (int, double) telegraphDigitsResults(TelegraphCodebook codebook) {
    var n = 0;
    var total = 0;
    var correct = 0;
    for (final h in progress.history) {
      if (TelegraphCurriculum.codebookOf(h.sourceRef) != codebook) continue;
      n++;
      total += h.totalChars;
      correct += h.correctChars;
    }
    return (n, total == 0 ? 0 : correct / total);
  }

  Future<TelegraphRecallStats> readTelegraphRecall() async =>
      TelegraphRecallStats.fromJson(await readDoc(recallDoc));

  /// Adds one answered recall round to the mapping statistics (a separate
  /// document: never Morse statistics, unlocks or speed advice).
  Future<TelegraphRecallStats> recordTelegraphRecall(
    TelegraphCodebook codebook,
    List<(String char, bool correct, bool assisted)> answers,
  ) => docTransaction(() async {
    final raw = await readDoc(recallDoc);
    if (TelegraphRecallStats.isNewer(raw)) {
      throw StateError('recall statistics written by a newer version');
    }
    var stats = TelegraphRecallStats.fromJson(raw);
    for (final (char, correct, assisted) in answers) {
      stats = stats.record(
        codebook,
        char,
        correct: correct,
        assisted: assisted,
      );
    }
    await writeDoc(recallDoc, stats.toJson());
    return stats;
  });
}

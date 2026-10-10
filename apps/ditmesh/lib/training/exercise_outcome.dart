import 'package:morse_core/morse_core.dart';
import 'package:morse_trainer/morse_trainer.dart';

/// What recording an exercise did to the learner's state.
final class ReceiveOutcome {
  const ReceiveOutcome({
    required this.score,
    required this.passed,
    this.saved = true,
    this.credit = ExerciseCredit.none,
    this.duplicate = false,
    this.exerciseId,
  });

  final SessionScore score;

  /// What the exercise was credited with (spec §3.3).
  final ExerciseCredit credit;

  /// The exercise id was already committed; nothing was credited again.
  final bool duplicate;
  final String? exerciseId;

  ReceiveOutcome withSaved(bool saved) => ReceiveOutcome(
    score: score,
    passed: passed,
    saved: saved,
    credit: credit,
    duplicate: duplicate,
    exerciseId: exerciseId,
  );

  /// Whether the attempt was assisted (no SRS or speed evidence).
  bool get assisted => credit.activity && !credit.receiveStats;

  /// False when writing progress failed. The session still counts in memory
  /// and is written by [TrainingController.retryProgressSave] or the next
  /// successful save.
  final bool saved;

  /// Whether the score meets the Koch pass mark.
  final bool passed;
}

/// The pure part of `TrainingController.recordExercise`: builds the
/// exercise record, applies [CreditPolicy] and returns the progress to
/// commit in one write.
(TrainerProgress, ReceiveOutcome) applyExercise(
  TrainerProgress progress, {
  required KochCourse course,
  required DateTime now,
  required SessionScore score,
  required String id,
  required ExerciseSource source,
  required Set<Assistance> assistance,
  required bool answered,
  required bool completed,
  required MorseTiming timing,
  required double toneHz,
  required Set<String> learned,
  int? lesson,
  Duration? active,
  String? sourceRef,
}) {
  if (progress.hasCommitted(id)) {
    return (
      progress,
      ReceiveOutcome(
        score: score,
        passed: false,
        duplicate: true,
        exerciseId: id,
      ),
    );
  }
  final credit = CreditPolicy.decide(
    source: source,
    completed: completed,
    answered: answered,
    assistance: assistance,
  );
  final summary = SessionSummary.exercise(
    score,
    id: id,
    source: source,
    at: score.at ?? now,
    assistance: assistance,
    lesson: lesson ?? score.lesson ?? progress.currentLesson,
    characterWpm: timing.wpm,
    effectiveWpm: timing.isFarnsworth ? timing.farnsworthWpm : timing.wpm,
    toneHz: toneHz,
    completed: completed,
    active: active,
    sourceRef: sourceRef,
  );
  final next = progress.recordExercise(
    score,
    summary,
    credit: credit,
    now: now,
    learned: learned,
  );
  return (
    next,
    ReceiveOutcome(
      score: score,
      passed: course.passes(score),
      credit: credit,
      exerciseId: id,
    ),
  );
}

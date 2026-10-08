import 'receive_session.dart';
import 'training_controller.dart';

/// Recording a finished [ReceiveSession]; an extension so the controller
/// stays within the size gate. Exported by `training_controller.dart`.
extension ReceiveSessionRecording on TrainingController {
  /// Folds a finished receive session into progress (stats, streak, SRS,
  /// confusion) and, for lesson sessions, applies the Koch unlock rule.
  /// A session played under radio conditions (F11) is recorded with its
  /// scenario and earns activity only.
  Future<ReceiveOutcome> recordReceiveSession(ReceiveSession session) {
    final score = session.finish();
    return recordExercise(
      score: score,
      id: session.id,
      source: session.source,
      assistance: session.assistance,
      answered: session.hasAnswers,
      lesson: session.lesson,
      timing: session.timing,
      active: session.activeElapsed,
      planStepId: session.planStepId,
      sourceRef: session.sourceRef,
      learned: session.learnedChars,
      countsTowardLesson: session.countsTowardLesson,
      conditions: session.conditions,
    );
  }
}

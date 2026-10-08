import 'package:morse_trainer/morse_trainer.dart';

import 'drill_catalog.dart';
import 'send_session.dart';
import 'training_controller.dart';

/// Free send practice targets (re-exported by `training_controller.dart`).
extension SendPracticeStart on TrainingController {
  /// One short target (a word if the learned set allows, else a group).
  SendSession startSendSession() {
    final chars = learnedChars;
    final words = WordDrill.commonWords(
      allowedChars: chars.toSet(),
      wordCount: 1,
    );
    final generator = words.hasCandidates
        ? words
        : RandomGroupsDrill(
            chars: chars,
            groupCount: 1,
            groupSize: TrainingController.sendTargetChars,
            weights: DrillCatalog(
              course: course,
              progress: progress,
              settings: trainerSettings,
            ).weights(),
          );
    return SendSession(
      target: generator.generate(random).text,
      timing: trainerSettings.toTiming(),
      now: now,
      lesson: currentLesson,
    );
  }
}

import 'package:morse_trainer/morse_trainer.dart';

import 'receive_session.dart';
import 'training_controller.dart';

/// Receive practice over a [TrainingMaterial] (functional spec §9.2): the
/// usual session and scoring, never a lesson unlock; learned-symbol copies
/// update weaknesses and SRS, other symbols are practised freely.
extension MaterialPractice on TrainingController {
  /// Null when no item is usable in the chosen mode.
  ReceiveSession? startMaterialSession(
    TrainingMaterial material, {
    required bool learnedOnly,
  }) {
    final learned = learnedChars.toSet();
    final drill = MaterialDrill(
      material,
      allowed: learnedOnly ? learned : null,
    );
    if (!drill.canGenerate) return null;
    final symbols = <String>{
      for (final item in drill.items) ...MorseText.charSet(item),
    };
    final t = trainerSettings;
    return ReceiveSession(
      kind: ReceiveDrillKind.words,
      generator: drill,
      chars: [
        ...course.order.where(symbols.contains),
        ...(symbols.difference(course.order.toSet()).toList()..sort()),
      ],
      timing: t.toTiming(),
      charBudget: t.sessionLengthChars,
      lesson: currentLesson,
      source: ExerciseSource.material,
      sourceRef: 'material:${material.id}',
      random: random,
      now: now,
    );
  }

  /// Entries that cannot be used in learned-only mode.
  int unavailableLearnedOnly(TrainingMaterial material) =>
      material.normalizedItems.length -
      material.itemsWithin(learnedChars.toSet()).length;
}

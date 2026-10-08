import 'package:flutter/material.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../training/training_controller.dart';
import '../../../training/training_plan.dart';
import '../learn_playback.dart';
import '../receive/receive_drill_screen.dart';
import '../send/send_practice_screen.dart';

/// Opens the drill screen for one daily-plan step. The step's content is
/// frozen by the plan (speeds, seed, pool); completion is recorded by the
/// controller in the same write as the exercise.
Future<void> openPlanStep(
  BuildContext context, {
  required TrainingController controller,
  required LearnPlaybackFactory playback,
  required PlanStep step,
}) async {
  final navigator = Navigator.of(context);
  if (step.kind == PlanStepKind.send) {
    final session = await controller.startPlanSendStep(step);
    await navigator.push(
      MaterialPageRoute<Object?>(
        builder: (_) => SendPracticeScreen(
          controller: controller,
          playback: playback,
          session: session,
          nextSession: () => controller.startPlanSendStep(step),
        ),
      ),
    );
    return;
  }
  final session = await controller.startPlanReceiveStep(step);
  await navigator.push(
    MaterialPageRoute<Object?>(
      builder: (_) => ReceiveDrillScreen(
        controller: controller,
        playback: playback,
        session: session,
      ),
    ),
  );
}

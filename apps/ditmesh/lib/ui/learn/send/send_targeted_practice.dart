import 'package:flutter/material.dart';

import '../../../training/send_session.dart';
import '../../../training/training_controller.dart';
import '../learn_playback.dart';
import 'send_practice_screen.dart';

/// Opens three fresh attempts at [text] with [template]'s speed and lesson
/// (targeted practice from the rhythm timeline).
Future<void> openTargetedSendPractice(
  BuildContext context, {
  required TrainingController controller,
  required LearnPlaybackFactory playback,
  required SendSession template,
  required String text,
}) async {
  SendSession make() => SendSession(
    target: text,
    timing: template.nominalTiming,
    now: controller.now,
    lesson: template.lesson,
  );
  await Navigator.of(context).push(
    MaterialPageRoute<Object?>(
      builder: (_) => SendPracticeScreen(
        controller: controller,
        playback: playback,
        session: make(),
        nextSession: () async => make(),
        maxAttempts: 3,
      ),
    ),
  );
}

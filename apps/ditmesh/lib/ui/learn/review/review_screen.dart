import 'package:flutter/material.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/receive_session.dart';
import '../../../training/training_controller.dart';
import '../learn_playback.dart';
import '../receive/receive_drill_screen.dart';

/// SRS review: a receive drill over the due symbols, weighted by weakness
/// (`TrainingController.startReviewSession`). Never advances the lesson.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.controller,
    required this.playback,
  });

  final TrainingController controller;
  final LearnPlaybackFactory playback;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final ReceiveSession _session = widget.controller.startReviewSession();

  @override
  Widget build(BuildContext context) => ReceiveDrillScreen(
    controller: widget.controller,
    playback: widget.playback,
    session: _session,
    title: context.s.learnReviewTitle,
  );
}

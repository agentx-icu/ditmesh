import 'package:flutter/material.dart';

import '../../i18n/l10n_extension.dart';
import '../../training/training_controller.dart';

/// Tells the learner a finished session could not be written and offers to
/// write it again. The session already counts in memory, so the retry only
/// rewrites the current progress and can never credit it twice.
void showProgressSaveFailed(
  BuildContext context,
  TrainingController controller,
) {
  final s = context.s;
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      content: Text(s.learnProgressSaveFailed),
      duration: const Duration(seconds: 10),
      action: SnackBarAction(
        label: s.actionRetry,
        onPressed: () async {
          final saved = await controller.retryProgressSave();
          if (!saved && context.mounted) {
            showProgressSaveFailed(context, controller);
          }
        },
      ),
    ),
  );
}

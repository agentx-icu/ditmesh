import 'package:flutter/material.dart';

import '../../i18n/l10n_extension.dart';
import '../../training/training_controller.dart';

/// Ruled notebook / instrument readout for the angular styles.
class StyledGoalCard extends StatelessWidget {
  const StyledGoalCard({super.key, required this.controller});
  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = context.s;
    final progress = s.learnDailyGoalProgress(
      controller.charsToday,
      controller.dailyGoal,
    );
    final percent = s.learnAccuracyPercent(
      (controller.dailyGoalFraction * 100).round(),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.learnDailyGoalTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(progress, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            Semantics(
              label: progress,
              value: percent,
              child: LinearProgressIndicator(
                value: controller.dailyGoalFraction.clamp(0, 1),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: Text(percent)),
            const Divider(height: 24),
            Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.local_fire_department_outlined, size: 20),
                Text(
                  controller.streak > 0
                      ? s.learnStreakDays(controller.streak)
                      : s.learnNoStreak,
                ),
              ],
            ),
            if (controller.dailyGoalMet) ...[
              const SizedBox(height: 8),
              Text(s.learnDailyGoalMet, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

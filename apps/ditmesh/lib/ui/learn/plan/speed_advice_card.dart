import 'dart:async';

import 'package:flutter/material.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/training_controller.dart';
import '../../../training/training_plan.dart';

/// A pending speed recommendation (functional spec §4.3). Settings change
/// only on Apply; Not now hides this evidence batch.
class SpeedAdviceCard extends StatelessWidget {
  const SpeedAdviceCard({super.key, required this.controller});

  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    final advice = controller.pendingSpeedAdvice;
    if (advice == null) return const SizedBox.shrink();
    final s = context.s;
    final theme = Theme.of(context);
    final headline = switch (advice.kind) {
      SpeedAdviceKind.increaseEffective => s.learnSpeedAdviceRaise(
        advice.effectiveWpm.round(),
      ),
      SpeedAdviceKind.increaseBoth => s.learnSpeedAdviceRaiseBoth(
        advice.characterWpm.round(),
      ),
      _ => s.learnSpeedAdviceLower(advice.effectiveWpm.round()),
    };
    return Card(
      key: const ValueKey('speed-advice-card'),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  advice.kind == SpeedAdviceKind.decrease
                      ? Icons.trending_down
                      : Icons.trending_up,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(headline, style: theme.textTheme.titleSmall),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              s.learnSpeedAdviceBody(
                advice.samples,
                ((advice.weightedAccuracy ?? 0) * 100).round(),
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: <Widget>[
                TextButton(
                  onPressed: () => unawaited(
                    _quietly(controller.dismissSpeedAdvice(advice)),
                  ),
                  child: Text(s.learnSpeedAdviceDismiss),
                ),
                FilledButton(
                  key: const ValueKey('speed-advice-apply'),
                  onPressed: () =>
                      unawaited(_quietly(controller.applySpeedAdvice(advice))),
                  child: Text(s.learnSpeedAdviceApply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _quietly(Future<void> f) async {
    try {
      await f;
    } on Object {
      // A failed settings write reverts in the controller.
    }
  }
}

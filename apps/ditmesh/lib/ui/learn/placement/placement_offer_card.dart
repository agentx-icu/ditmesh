import 'package:flutter/material.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/training_controller.dart';

/// For a brand-new learner: start from zero, or check the current level
/// first (functional spec §8.3). Skippable; gone after the first session.
class PlacementOfferCard extends StatelessWidget {
  const PlacementOfferCard({
    super.key,
    required this.controller,
    required this.onFromZero,
    required this.onCheckLevel,
  });

  final TrainingController controller;
  final VoidCallback onFromZero;
  final VoidCallback onCheckLevel;

  static bool shows(TrainingController c) =>
      c.progress.lifetimeSessions == 0 && c.currentLesson == 1;

  @override
  Widget build(BuildContext context) {
    if (!shows(controller)) return const SizedBox.shrink();
    final s = context.s;
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('placement-offer'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(s.placementOfferTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(s.placementOfferBody, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton(
                  onPressed: onFromZero,
                  child: Text(s.placementFromZero),
                ),
                OutlinedButton(
                  key: const ValueKey('placement-check'),
                  onPressed: onCheckLevel,
                  child: Text(s.placementCheckLevel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

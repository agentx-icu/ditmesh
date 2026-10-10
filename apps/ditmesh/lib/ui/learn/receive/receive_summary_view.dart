import 'package:flutter/material.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/receive_session.dart';
import '../../../training/training_controller.dart';
import 'receive_widgets.dart';

/// End-of-session card: accuracy, pass state, weak symbols and the most
/// frequent confusions. Rendered after the controller has recorded the
/// session.
class ReceiveSummaryView extends StatelessWidget {
  const ReceiveSummaryView({
    super.key,
    required this.session,
    required this.outcome,
  });

  final ReceiveSession session;
  final ReceiveOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = context.s;
    final score = outcome.score;
    final weak = score.weakChars();
    final confusions = session.confusionPairs();

    final String verdict;
    final IconData verdictIcon;
    if (outcome.passed) {
      verdict = s.learnLessonPassed;
      verdictIcon = Icons.check_circle_outline;
    } else {
      verdict = s.learnLessonNotPassed;
      verdictIcon = Icons.trending_up;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          s.learnSessionSummary,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        // The strict figure is what the Koch unlock rule uses, so the number
        // shown always agrees with the pass/fail colour.
        Text(
          formatAccuracy(s, score.strictAccuracy),
          style: theme.textTheme.displayMedium?.copyWith(
            color: outcome.passed ? scheme.primary : scheme.error,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          s.learnCharsSent(score.totalChars),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(verdictIcon, color: scheme.primary),
            const SizedBox(width: 8),
            Flexible(child: Text(verdict, style: theme.textTheme.titleSmall)),
          ],
        ),
        if (weak.isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          _Section(
            title: s.learnWeakChars,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final c in weak.take(10))
                  Chip(
                    label: Text(
                      '$c ${formatAccuracy(s, score.perCharAccuracy[c] ?? 0)}',
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (confusions.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _Section(
            title: s.learnConfusions,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final (target, answered, count) in confusions)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${confusedAs(s, target, answered)}  ×$count',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

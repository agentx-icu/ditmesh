import 'package:flutter/material.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';
import '../receive/receive_widgets.dart';
import '../receive/round_result_view.dart';
import 'send_tips.dart';

/// Finished send attempt: copy accuracy of the decoded text against the
/// target, measured speed, and every rhythm issue with a plain-language tip.
class SendResultView extends StatelessWidget {
  const SendResultView({super.key, required this.diagnostics});

  final SendDiagnostics diagnostics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = context.s;
    final score = diagnostics.score;
    final issues = diagnostics.issues.toList()
      ..sort((a, b) => b.severity.index.compareTo(a.severity.index));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Wrap, not Row: with large accessibility fonts (or narrow phones)
        // the speed drops under the percentage instead of overflowing.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 12,
          children: <Widget>[
            Text(
              formatAccuracy(s, score.accuracy),
              style: theme.textTheme.displaySmall?.copyWith(
                color: score.accuracy >= 0.9 ? scheme.primary : scheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                formatWpm(s, diagnostics.measuredWpm),
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          s.learnSendThis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        AlignedSymbols(alignment: score.alignment, showTarget: true),
        const SizedBox(height: 8),
        Text(
          s.learnYourSending,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        AlignedSymbols(alignment: score.alignment, showTarget: false),
        const SizedBox(height: 20),
        Text(
          s.learnSendIssues,
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        if (issues.isEmpty)
          Row(
            children: <Widget>[
              Icon(Icons.check_circle_outline, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(s.learnSendClean, style: theme.textTheme.bodyLarge),
              ),
            ],
          )
        else
          for (final issue in issues) _IssueTile(issue: issue),
      ],
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.issue});

  final SendIssue issue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = context.s;
    final color = switch (issue.severity) {
      SendSeverity.minor => scheme.tertiary,
      SendSeverity.moderate => scheme.primary,
      SendSeverity.severe => scheme.error,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.graphic_eq, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  s.learnIssueHeadline(
                    titleFor(s, issue.kind),
                    severityLabel(s, issue.severity),
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                Text(tipFor(s, issue), style: theme.textTheme.bodyMedium),
                Text(
                  detailFor(s, issue),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

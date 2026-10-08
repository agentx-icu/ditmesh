import 'package:flutter/material.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';

/// End of a simulated QSO: flow completion, fields right first time,
/// repeats, hints and sending rhythm, kept apart from copying accuracy.
class QsoSummaryView extends StatelessWidget {
  const QsoSummaryView({
    super.key,
    required this.session,
    required this.sendingWpm,
    required this.onDone,
  });

  final QsoSession session;
  final double? sendingWpm;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Icon(
          Icons.emoji_events_outlined,
          size: 48,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          s.learnQsoStageDone,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          s.learnQsoSummaryFields(session.firstTryStages, session.answerStages),
        ),
        Text(s.learnQsoSummaryRepeats(session.repeats)),
        Text(s.learnQsoSummaryHints(session.hints)),
        if (sendingWpm != null)
          Text(s.learnQsoSummaryRhythm(sendingWpm!.round())),
        const SizedBox(height: 12),
        Text(
          s.learnQsoSummaryNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const ValueKey('qso-done'),
          onPressed: onDone,
          autofocus: true,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(s.learnDone),
        ),
      ],
    );
  }
}

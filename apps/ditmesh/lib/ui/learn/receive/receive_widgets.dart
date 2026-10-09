import 'package:flutter/material.dart';

import '../../../i18n/l10n_extension.dart';

/// Whole-percent accuracy (`0.923` -> `92%`) in the current locale.
String formatAccuracy(S s, double accuracy) =>
    s.learnAccuracyPercent((accuracy * 100).round());

/// One confusion pair: "K heard as M", or "K missed" when nothing was
/// answered for the target.
String confusedAs(S s, String target, String answered) => answered.isEmpty
    ? s.learnConfusedMissed(target)
    : s.learnConfusedAs(target, answered);

/// "Playing" / "Ready" with the Replay button. They share a line when it
/// fits; on a narrow phone, a long language or large text Replay wraps below
/// so the status is never cut off (same as MorseCQ).
class PlaybackStatusRow extends StatelessWidget {
  const PlaybackStatusRow({
    super.key,
    required this.playing,
    required this.onReplay,
    required this.replayLabel,
  });

  final bool playing;
  final VoidCallback? onReplay;
  final String replayLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = context.s;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              playing ? Icons.volume_up : Icons.volume_off_outlined,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                playing ? s.learnListen : s.learnReady,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: onReplay,
          icon: const Icon(Icons.replay),
          label: Text(replayLabel),
        ),
      ],
    );
  }
}

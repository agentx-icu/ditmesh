import 'package:flutter/material.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../i18n/l10n_extension.dart';
import 'stats_math.dart';
import 'stats_model.dart';
import 'stats_palette.dart';
import 'stats_widgets.dart';

/// Every course symbol in Koch order, coloured by accuracy bucket with an
/// attempt-count badge. Symbols past the current lesson are outlined only.
/// Tapping a cell opens [CharDetailSheet].
class CharGrid extends StatelessWidget {
  const CharGrid({super.key, required this.snapshot});

  final StatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final learned = snapshot.learnedChars.toSet();
    final s = context.s;
    return StatsSection(
      title: s.statsCharsTitle,
      subtitle: s.statsCharsSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final c in snapshot.course.order)
                CharCell(
                  char: c,
                  stats: snapshot.statsFor(c),
                  learned: learned.contains(c),
                  onTap: () => CharDetailSheet.show(context, snapshot, c),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const BucketLegend(),
        ],
      ),
    );
  }
}

/// A single grid cell.
class CharCell extends StatelessWidget {
  const CharCell({
    super.key,
    required this.char,
    required this.stats,
    required this.learned,
    this.onTap,
  });

  final String char;
  final CharStats stats;
  final bool learned;
  final VoidCallback? onTap;

  AccuracyBucket get bucket =>
      bucketFor(stats.accuracy, attempts: stats.attempts);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = context.s;
    final palette = StatsPalette(scheme);
    final b = bucket;
    final background = palette.bucketBackground(b);
    final foreground = palette.bucketForeground(b);
    final wide = char.length > 1;
    // Grows with the text size so the glyph and its attempt badge stay
    // inside the cell (a fixed 40 px box clipped them from 2x text).
    final double side = MediaQuery.textScalerOf(
      context,
    ).scale(40).clamp(40.0, 72.0);
    final semantics = stats.attempts == 0
        ? '$char, ${s.statsCharsNotStarted}'
        : '$char, ${formatPercent(s, stats.accuracy)}, '
              '${s.statsAttempts(stats.attempts)}';
    return Semantics(
      button: true,
      label: semantics,
      child: Material(
        color: learned || stats.attempts > 0 ? background : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: wide ? side * 1.4 : side,
            height: side,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: learned ? null : Border.all(color: scheme.outlineVariant),
            ),
            child: Stack(
              children: <Widget>[
                Center(
                  // A prosign ("<BT>") at 3x is wider than the capped cell:
                  // shrink it rather than wrap it out of the cell.
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        char,
                        maxLines: 1,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: learned || stats.attempts > 0
                              ? foreground
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                if (stats.attempts > 0)
                  Positioned(
                    right: 2,
                    bottom: 1,
                    child: Text(
                      _badge(stats.attempts),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: foreground,
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _badge(int n) => n >= 1000 ? '${n ~/ 1000}k' : '$n';
}

/// Colour key for [CharGrid].
class BucketLegend extends StatelessWidget {
  const BucketLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = context.s;
    final palette = StatsPalette(theme.colorScheme);
    final items = <(AccuracyBucket, String)>[
      (AccuracyBucket.none, s.statsBucketNone),
      (AccuracyBucket.weak, s.statsBucketWeak),
      (AccuracyBucket.fair, s.statsBucketFair),
      (AccuracyBucket.good, s.statsBucketGood),
      (AccuracyBucket.strong, s.statsBucketStrong),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          s.statsBucketLegendTitle,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        for (final (bucket, label) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: palette.bucketBackground(bucket),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text(label, style: theme.textTheme.labelSmall),
            ],
          ),
      ],
    );
  }
}

/// Bottom sheet with one character's lifetime stats, SRS box and confusions.
class CharDetailSheet extends StatelessWidget {
  const CharDetailSheet({
    super.key,
    required this.snapshot,
    required this.char,
  });

  final StatsSnapshot snapshot;
  final String char;

  static Future<void> show(
    BuildContext context,
    StatsSnapshot snapshot,
    String char,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => CharDetailSheet(snapshot: snapshot, char: char),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = context.s;
    final palette = StatsPalette(scheme);
    final stats = snapshot.statsFor(char);
    final bucket = bucketFor(stats.accuracy, attempts: stats.attempts);
    final lesson = snapshot.course.lessonFor(char);
    final card = snapshot.progress.srs.cardFor(char);
    final confusions = snapshot.confusionsFor(char);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: palette.bucketBackground(bucket),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    char,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: palette.bucketForeground(bucket),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        stats.attempts == 0
                            ? s.statsCharsNotStarted
                            : formatPercent(s, stats.accuracy),
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        stats.attempts == 0
                            ? (lesson == null
                                  ? s.statsNotInCourse
                                  : s.statsLessonIntroduced(lesson))
                            : s.statsCorrectOf(stats.correct, stats.attempts),
                        style: muted,
                      ),
                      if (stats.attempts > 0 && lesson != null)
                        Text(s.statsLessonIntroduced(lesson), style: muted),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(s.statsSrsTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            if (card == null)
              Text(s.statsSrsNotTracked, style: muted)
            else
              _SrsRow(
                card: card,
                maxBox: snapshot.progress.srs.maxBox,
                now: snapshot.now,
              ),
            const SizedBox(height: 20),
            Text(s.statsConfusionsTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            if (confusions.isEmpty)
              Text(s.statsConfusionsNone, style: muted)
            else
              for (final c in confusions)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: <Widget>[
                      Container(
                        constraints: const BoxConstraints(minWidth: 32),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.isMissed ? s.statsConfusionMissed : c.answered,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(s.statsTimes(c.count), style: muted),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _SrsRow extends StatelessWidget {
  const _SrsRow({required this.card, required this.maxBox, required this.now});

  final SrsCard card;
  final int maxBox;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = context.s;
    final palette = StatsPalette(scheme);
    final dueDays = daysBetween(now, card.dueAt.toLocal());
    final due = card.isDue(now) || dueDays <= 0
        ? s.statsSrsDueNow
        : s.statsSrsDueIn(dueDays);
    return Row(
      children: <Widget>[
        for (var b = 0; b <= maxBox; b++)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              width: 18,
              height: 10,
              decoration: BoxDecoration(
                color: b <= card.box
                    ? palette.sequential((b + 1) / (maxBox + 1))
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${s.statsSrsBox(card.box, maxBox)} / $due',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

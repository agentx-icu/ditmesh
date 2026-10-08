import 'package:flutter/material.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../i18n/l10n_extension.dart';
import 'stats_model.dart';

/// Card wrapper every dashboard section uses: title, optional subtitle, body.
class StatsSection extends StatelessWidget {
  const StatsSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: theme.textTheme.titleMedium),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// One headline number with a label above and a detail line below.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.detail,
    this.icon,
  });

  final String label;
  final String value;
  final String? detail;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: '$label: $value${detail == null ? '' : ', $detail'}',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.headlineSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (detail != null) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                detail!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Formats a duration as `Xh Ym`, `Ym` or `Zs` for the practice tile.
String formatPracticeDuration(S s, Duration d) {
  if (d.inHours >= 1) {
    return s.statsDurationHoursMinutes(d.inHours, d.inMinutes.remainder(60));
  }
  if (d.inMinutes >= 1) {
    return s.statsDurationMinutes(d.inMinutes);
  }
  return s.statsDurationSeconds(d.inSeconds);
}

/// Accuracy fraction as a percentage: one decimal, none from 99.5% up
/// (`0.9236` -> `92.4%`, `0.997` -> `100%`).
String formatPercent(S s, double fraction) =>
    s.statsPercent((fraction * 100).toStringAsFixed(fraction >= 0.995 ? 0 : 1));

/// [formatPercent], or the no-data placeholder for a null accuracy.
String formatPercentOrNoData(S s, double? fraction) =>
    fraction == null ? s.statsNoData : formatPercent(s, fraction);

/// The overview tile grid: lesson, accuracy, practice, streak, daily goal.
class OverviewTiles extends StatelessWidget {
  const OverviewTiles({super.key, required this.snapshot});

  final StatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final snap = snapshot;
    final tiles = <Widget>[
      StatTile(
        icon: Icons.school_outlined,
        label: s.statsTileLesson,
        value: s.statsLessonOf(snap.currentLesson, snap.lessonCount),
        detail: s.statsCharsLearned(snap.learnedChars.length),
      ),
      StatTile(
        icon: Icons.track_changes_outlined,
        label: s.statsTileAccuracy,
        value: formatPercentOrNoData(s, snap.accuracyLast7Days),
        detail: s.statsAccuracyDetail(
          formatPercentOrNoData(s, snap.accuracyAllTime),
        ),
      ),
      StatTile(
        icon: Icons.timer_outlined,
        label: s.statsTilePractice,
        value: formatPracticeDuration(s, snap.totalPracticeTime),
        detail:
            '${s.statsCharsCopied(snap.totalChars)} / '
            '${s.statsSessions(snap.sessionCount)}',
      ),
      StatTile(
        icon: Icons.local_fire_department_outlined,
        label: s.statsTileStreak,
        value: s.statsDays(snap.currentStreak),
        detail: s.statsBestStreak(snap.bestStreak),
      ),
      StatTile(
        icon: Icons.flag_outlined,
        label: s.statsTileDailyGoal,
        value: s.statsGoalProgress(snap.charsToday, snap.dailyGoal),
        detail: snap.dailyGoalMet
            ? s.statsGoalMet
            : s.statsGoalRemaining(snap.dailyGoal - snap.charsToday),
      ),
    ];
    return StatsSection(
      title: s.statsOverviewTitle,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 560
              ? 3
              : (constraints.maxWidth >= 340 ? 2 : 1);
          const gap = 8.0;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: <Widget>[
              for (final t in tiles) SizedBox(width: width, child: t),
            ],
          );
        },
      ),
    );
  }
}

/// Compact card the Learn home can embed: three numbers and an optional
/// "View statistics" action. Renders sensibly for a fresh identity too.
class StatsSummaryCard extends StatelessWidget {
  const StatsSummaryCard({
    super.key,
    required this.progress,
    this.course,
    this.now,
    this.onOpen,
  });

  final TrainerProgress progress;
  final KochCourse? course;

  /// Injected clock for tests; defaults to `DateTime.now()`.
  final DateTime? now;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = context.s;
    final snap = StatsSnapshot.from(progress, course: course, now: now);
    final accuracy = snap.accuracyLast7Days ?? snap.accuracyAllTime;
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      s.statsSummaryTitle,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (onOpen != null)
                    Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 8),
              if (snap.isEmpty)
                Text(s.statsEmptyTitle, style: theme.textTheme.bodyMedium)
              else
                Row(
                  children: <Widget>[
                    _SummaryStat(
                      label: s.statsTileAccuracy,
                      value: formatPercentOrNoData(s, accuracy),
                    ),
                    _SummaryStat(
                      label: s.statsTileStreak,
                      value: s.statsDays(snap.currentStreak),
                    ),
                    _SummaryStat(
                      label: s.statsSessions(snap.sessionCount),
                      value: '${snap.sessionCount}',
                    ),
                  ],
                ),
              if (onOpen != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  s.statsSummaryOpen,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(value, style: theme.textTheme.titleLarge),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Shown for a fresh identity with no sessions in history.
class StatsEmptyState extends StatelessWidget {
  const StatsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = context.s;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.insights_outlined, size: 56, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                s.statsEmptyTitle,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                s.statsEmptyBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                s.statsEmptyCallToAction,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

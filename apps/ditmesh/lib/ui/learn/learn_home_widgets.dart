import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:morse_core/morse_core.dart';

import '../../i18n/l10n_extension.dart';
import '../../training/training_controller.dart';
import '../appearance/radio_mascot.dart';
import '../appearance/style_tokens.dart';
import '../appearance/ui_style.dart';
import 'goal_ring.dart';
import 'styled_goal_card.dart';

export 'goal_ring.dart' show GoalRing;

/// Koch position: lesson n / total, the learned set with the newest symbol
/// highlighted.
class LessonCard extends StatefulWidget {
  const LessonCard({super.key, required this.controller, this.onContinue});

  final TrainingController controller;
  final VoidCallback? onContinue;

  @override
  State<LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<LessonCard> {
  bool _expanded = false;

  TrainingController get controller => widget.controller;
  VoidCallback? get onContinue => widget.onContinue;

  double _labelWidth(BuildContext context, String char) {
    final painter = TextPainter(
      text: TextSpan(
        text: char,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width + 20;
    painter.dispose();
    return width;
  }

  Widget _continueButton(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: onContinue,
      icon: const Icon(Icons.play_arrow),
      label: Text(context.s.learnContinueLesson),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = context.s;
    final learned = controller.learnedChars;
    final classic =
        StyleTokens.of(context)?.style == UiStyle.classic ||
        StyleTokens.of(context) == null;
    final collapsible = classic && learned.length > 10;
    // Keep the newest symbol visible first in the compact set. Expanding
    // restores the complete teaching order.
    final visible = collapsible && !_expanded
        ? learned.sublist(learned.length - 10).reversed.toList()
        : learned;
    final newest = controller.newestChar;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.learnLessonCardTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (StyleTokens.of(context)?.style == UiStyle.cartoon)
                  const RadioMascot(size: 48),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              s.learnLessonOf(controller.currentLesson, controller.lessonCount),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: controller.lessonCount == 0
                  ? 0
                  : controller.currentLesson / controller.lessonCount,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 12),
            if (classic && onContinue != null) ...[
              _continueButton(context),
              const SizedBox(height: 8),
            ],
            Text(
              s.learnCharsLearned(learned.length),
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: classic ? 4 : 8),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final c in visible)
                    LearnedCharChip(
                      char: c,
                      isNewest: c == newest,
                      accuracy: controller.accuracyOf(c),
                      width: math.max(
                        math.max(
                          ((constraints.maxWidth - 24) / 5).clamp(36.0, 52.0),
                          MediaQuery.textScalerOf(context).scale(
                                theme.textTheme.titleMedium?.fontSize ?? 16,
                              ) +
                              20,
                        ),
                        _labelWidth(context, c),
                      ),
                    ),
                ],
              ),
            ),
            if (collapsible)
              TextButton(
                key: const ValueKey('learned-chars-toggle'),
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded
                      ? s.learnShowFewerChars
                      : s.learnShowAllChars(learned.length),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              controller.isCourseComplete
                  ? s.learnCourseComplete
                  : s.learnNewestCharIs(newest),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (!classic && onContinue != null) ...[
              const SizedBox(height: 16),
              _continueButton(context),
            ],
          ],
        ),
      ),
    );
  }
}

/// One learned symbol. The newest is filled with the primary colour; the
/// others tint by lifetime accuracy so weak symbols stand out at a glance.
class LearnedCharChip extends StatelessWidget {
  const LearnedCharChip({
    super.key,
    required this.char,
    required this.isNewest,
    this.accuracy,
    this.width = 52,
  });

  final String char;
  final bool isNewest;
  final double? accuracy;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = StyleTokens.of(context);
    final styled = tokens != null && tokens.style != UiStyle.classic;
    final Color background;
    final Color foreground;
    if (isNewest) {
      background = styled ? tokens.newest : scheme.primary;
      foreground = styled ? tokens.onNewest : scheme.onPrimary;
    } else if (accuracy != null && accuracy! < 0.9) {
      background = scheme.errorContainer;
      foreground = scheme.onErrorContainer;
    } else {
      background = scheme.surfaceContainerHighest;
      foreground = scheme.onSurface;
    }
    return Semantics(
      label: isNewest ? context.s.learnCharNewSemantics(char) : char,
      child: Container(
        width: width,
        constraints: BoxConstraints(minWidth: 36, minHeight: styled ? 68 : 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(tokens?.chipRadius ?? 8),
          border: isNewest ? Border.all(color: scheme.primary, width: 2) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              char,
              style: theme.textTheme.titleMedium?.copyWith(
                color: foreground,
                fontWeight: isNewest ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (styled) ...[
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  MorseEncoder.toPattern(char),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Daily goal ring plus streak.
class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({super.key, required this.controller});

  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = context.s;
    final streak = controller.streak;
    final tokens = StyleTokens.of(context);
    final styled = tokens != null && tokens.style != UiStyle.classic;
    if (tokens?.style == UiStyle.paper || tokens?.style == UiStyle.radio) {
      return StyledGoalCard(controller: controller);
    }
    return Card(
      color: tokens?.style == UiStyle.cartoon ? tokens?.receiveSurface : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            GoalRing(
              fraction: controller.dailyGoalFraction,
              size: styled ? 72 : 88,
              child: Text(
                s.learnAccuracyPercent(
                  (controller.dailyGoalFraction * 100).round(),
                ),
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    s.learnDailyGoalTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.learnDailyGoalProgress(
                      controller.charsToday,
                      controller.dailyGoal,
                    ),
                    style: theme.textTheme.titleMedium,
                  ),
                  if (controller.dailyGoalMet)
                    Text(
                      s.learnDailyGoalMet,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.local_fire_department,
                        size: 20,
                        color: streak > 0 ? scheme.tertiary : scheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          streak > 0
                              ? s.learnStreakDays(streak)
                              : s.learnNoStreak,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The four entry points into practice.
class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    required this.dueCount,
    required this.onContinueLesson,
    required this.onReceivePractice,
    required this.onSendPractice,
    required this.onReview,
    this.showContinue = true,
    this.onQso,
    this.qsoFromLesson,
    this.onMaterials,
    this.onTelegraph,
  });

  /// Opens My materials.
  final VoidCallback? onMaterials;

  /// Opens Chinese telegraph-code practice (F13).
  final VoidCallback? onTelegraph;

  /// Opens the QSO simulator; null while it is locked.
  final VoidCallback? onQso;

  /// Shown as the unlock lesson while [onQso] is null.
  final int? qsoFromLesson;

  final int dueCount;
  final VoidCallback onContinueLesson;
  final VoidCallback onReceivePractice;
  final VoidCallback onSendPractice;
  final VoidCallback onReview;
  final bool showContinue;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (showContinue)
          FilledButton.icon(
            onPressed: onContinueLesson,
            icon: const Icon(Icons.play_arrow),
            label: Text(s.learnContinueLesson),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
        if (showContinue) const SizedBox(height: 10),
        _ActionTile(
          icon: Icons.hearing,
          label: s.learnReceivePractice,
          onTap: onReceivePractice,
          color: StyleTokens.of(context)?.receiveSurface,
        ),
        _ActionTile(
          icon: Icons.touch_app_outlined,
          label: s.learnSendPractice,
          onTap: onSendPractice,
          color: StyleTokens.of(context)?.sendSurface,
        ),
        _ActionTile(
          icon: Icons.replay,
          label: s.learnReviewDue,
          trailing: s.learnReviewDueCount(dueCount),
          onTap: onReview,
        ),
        if (onMaterials != null)
          _ActionTile(
            icon: Icons.library_books_outlined,
            label: s.materialsTitle,
            onTap: onMaterials,
          ),
        if (onTelegraph != null)
          _ActionTile(
            icon: Icons.translate,
            label: s.telegraphTitle,
            onTap: onTelegraph,
          ),
        _ActionTile(
          icon: Icons.cell_tower,
          label: s.learnQsoAction,
          trailing: onQso == null && qsoFromLesson != null
              ? s.learnQsoLocked(qsoFromLesson!)
              : null,
          onTap: onQso,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.color,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: color,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        minTileHeight: 56,
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: trailing == null
            ? Text(label)
            : Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 4,
                children: [
                  Text(label),
                  Text(trailing!, style: theme.textTheme.labelLarge),
                ],
              ),
        trailing: trailing == null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}

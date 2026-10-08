import 'dart:async';

import 'package:flutter/material.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/training_controller.dart';
import '../../../training/training_plan.dart';
import '../learn_playback.dart';
import 'plan_labels.dart';
import 'plan_launcher.dart';

/// "Today's plan" (functional spec §4.1): budget, steps with reasons and
/// results, Start / Continue, and the end-of-plan summary. Free practice and
/// the daily symbol goal stay available beside it.
class TodayPlanCard extends StatefulWidget {
  const TodayPlanCard({
    super.key,
    required this.controller,
    required this.playback,
  });

  final TrainingController controller;
  final LearnPlaybackFactory playback;

  @override
  State<TodayPlanCard> createState() => _TodayPlanCardState();
}

class _TodayPlanCardState extends State<TodayPlanCard>
    with WidgetsBindingObserver {
  bool _busy = false;

  TrainingController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _armMidnight();
    // Making the plan commits progress, which notifies the home's builder:
    // never during this build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _c.todayPlan == null) unawaited(_ensure());
    });
  }

  Timer? _midnight;

  /// Rebuild at the next local midnight even while the app stays open.
  void _armMidnight() {
    _midnight?.cancel();
    final now = _c.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(next.difference(now) + const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {});
      _armMidnight();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the background, possibly on a new local day.
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  @override
  void dispose() {
    _midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _ensure() async {
    try {
      await _c.ensureTodayPlan();
    } on Object {
      // The plan still exists in memory; a failed write is retried by the
      // next successful save.
    }
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on Object {
      // Save failures leave the in-memory plan usable.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start(PlanStep step) => _guard(() async {
    // A card still showing yesterday's plan: make today's instead.
    if (_c.todayPlan?.stepById(step.id) == null) {
      await _ensure();
      return;
    }
    if (!mounted) return;
    await openPlanStep(
      context,
      controller: _c,
      playback: widget.playback,
      step: step,
    );
  });

  bool _ensuring = false;

  /// A new local day (or a reset) leaves no plan for today: make one after
  /// this frame, never during the build.
  void _ensureLater() {
    if (_ensuring) return;
    _ensuring = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted && _c.todayPlan == null) await _ensure();
      _ensuring = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final plan = _c.todayPlan;
    if (plan == null) {
      _ensureLater();
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final next = plan.nextStep;
    final started = plan.steps.any((st) => st.state != PlanStepState.pending);
    final earlier = _c.unfinishedEarlierPlan;
    return Card(
      key: const ValueKey('today-plan-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(s.learnPlanTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              s.learnPlanSummary(
                plan.estimatedMinutes.round(),
                plan.doneCount,
                plan.steps.length,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _BudgetSelector(
              value: plan.budgetMinutes,
              onChanged: _busy || plan.isComplete
                  ? null
                  : (m) => _guard(() => _c.setPlanBudget(m)),
              started: started,
            ),
            if (plan.hasStaleSteps) ...<Widget>[
              const SizedBox(height: 8),
              Text(s.learnPlanStale, style: theme.textTheme.bodySmall),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _busy ? null : () => _guard(_c.refreshPlan),
                  child: Text(s.learnPlanUpdate),
                ),
              ),
            ],
            const SizedBox(height: 8),
            for (final step in plan.steps)
              _StepTile(
                step: DailyPlanBuilder.effectiveStep(step, _c.currentLesson),
                isNext: identical(step, next),
                sendDone: step.kind == PlanStepKind.send
                    ? _c.sendAttemptsFor(step)
                    : null,
                onTap: step.isDone || _busy ? null : () => _start(step),
              ),
            const SizedBox(height: 8),
            if (next != null)
              FilledButton.icon(
                key: const ValueKey('plan-start'),
                onPressed: _busy ? null : () => _start(next),
                icon: const Icon(Icons.play_arrow),
                label: Text(started ? s.learnPlanContinue : s.learnPlanStart),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              )
            else
              _CompleteSummary(controller: _c),
            if (_c.speedAdvice.kind == SpeedAdviceKind.insufficient) ...[
              const SizedBox(height: 8),
              Text(
                s.learnSpeedAdviceInsufficient,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (earlier != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                s.learnPlanEarlier(earlier.doneCount, earlier.steps.length),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BudgetSelector extends StatelessWidget {
  const _BudgetSelector({
    required this.value,
    required this.onChanged,
    required this.started,
  });

  final int value;
  final ValueChanged<int>? onChanged;
  final bool started;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Semantics(
      label: s.learnPlanBudget,
      child: SegmentedButton<int>(
        segments: <ButtonSegment<int>>[
          for (final m in DailyPlanBuilder.budgets)
            ButtonSegment<int>(
              value: m,
              label: Text(s.learnPlanBudgetMinutes(m)),
            ),
        ],
        selected: <int>{value},
        showSelectedIcon: false,
        onSelectionChanged: onChanged == null
            ? null
            : (v) => onChanged!(v.first),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.step,
    required this.isNext,
    required this.onTap,
    this.sendDone,
  });

  final PlanStep step;
  final bool isNext;
  final int? sendDone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final String status;
    if (step.isDone) {
      final acc = step.accuracy;
      status = acc == null
          ? s.learnPlanStepDone
          : s.learnPlanStepDonePercent((acc * 100).round());
    } else if (sendDone != null) {
      status = s.learnPlanSendProgress(sendDone!, step.charBudget);
    } else {
      status = s.learnPlanBudgetMinutes(step.minutes.ceil());
    }
    // Not a ListTile: a trailing status would not fit 320 px at large text.
    return Semantics(
      button: onTap != null,
      selected: isNext,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  step.isDone ? Icons.check_circle : PlanLabels.icon(step.kind),
                  color: step.isDone || isNext
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        PlanLabels.title(s, step),
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        PlanLabels.reason(s, step),
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        status,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompleteSummary extends StatelessWidget {
  const _CompleteSummary({required this.controller});

  final TrainingController controller;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final weak = controller.planWeakSymbols();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.emoji_events_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.learnPlanComplete,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          weak.isEmpty
              ? s.learnPlanAllGood
              : s.learnPlanNeedsWork(weak.join(' ')),
        ),
        const SizedBox(height: 4),
        Text(s.learnPlanTomorrow, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

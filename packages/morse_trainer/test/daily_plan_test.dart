import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

void main() {
  final course = KochCourse();
  const settings = PlanSettings(
    characterWpm: 20,
    effectiveWpm: 8,
    toneHz: 700,
    groupSize: 5,
  );

  PlanInputs inputs({
    int budget = 10,
    int lesson = 10,
    List<String> due = const ['K', 'M', 'R'],
    ConfusionMatrix? confusion,
    Map<String, CharStats> stats = const {},
    int seed = 42,
    DateTime? now,
  }) => PlanInputs(
    now: now ?? DateTime(2026, 10, 3, 8),
    profileKey: 'profile',
    budgetMinutes: budget,
    lesson: lesson,
    course: course,
    due: due,
    charStats: stats,
    confusion: confusion ?? ConfusionMatrix(),
    settings: settings,
    seed: seed,
  );

  ConfusionMatrix confused() => ConfusionMatrix()
    ..record('S', 'U', times: 4)
    ..record('U', 'S', times: 1);

  test('fixed inputs give the same plan', () {
    final a = DailyPlanBuilder.build(inputs(confusion: confused()));
    final b = DailyPlanBuilder.build(inputs(confusion: confused()));
    expect(a.toJson(), b.toJson());
  });

  test('priority order and the 3/2/3/2 split for 10 minutes', () {
    final plan = DailyPlanBuilder.build(inputs(confusion: confused()));
    expect(plan.steps.map((s) => s.kind), [
      PlanStepKind.review,
      PlanStepKind.focus,
      PlanStepKind.course,
      PlanStepKind.send,
    ]);
    expect(plan.steps[0].minutes, 3);
    expect(plan.steps[1].minutes, 2);
    expect(plan.steps[1].reason, PlanReason.confusions);
    expect(plan.steps[1].pool.take(2), ['S', 'U']);
  });

  test('no empty review: unavailable categories are redistributed', () {
    final plan = DailyPlanBuilder.build(inputs(due: const []));
    expect(plan.steps.map((s) => s.kind), [
      PlanStepKind.course,
      PlanStepKind.send,
    ]);
    // 10 minutes spread over course (3) and send (2): x2.
    expect(plan.steps[1].minutes, closeTo(4, 1e-9));
    expect(plan.steps.every((s) => s.pool.isNotEmpty), isTrue);
  });

  test('a single due symbol is topped up to a two-symbol pool', () {
    final plan = DailyPlanBuilder.build(inputs(due: const ['K']));
    final review = plan.steps.first;
    expect(review.pool, hasLength(2));
    expect(review.pool.first, 'K');
  });

  test('focus pools contain learned symbols only', () {
    final m = ConfusionMatrix()..record('X', 'Y', times: 9);
    final plan = DailyPlanBuilder.build(inputs(lesson: 3, confusion: m));
    expect(plan.steps.any((s) => s.kind == PlanStepKind.focus), isFalse);
    final learned = course.charSetForLesson(3);
    for (final step in plan.steps) {
      expect(learned.containsAll(step.pool), isTrue);
    }
  });

  test('short budgets keep the unlock rule honest', () {
    final five = DailyPlanBuilder.build(
      inputs(budget: 5, confusion: confused()),
    );
    final c5 = five.steps.firstWhere((s) => s.kind == PlanStepKind.course);
    expect(c5.charBudget, lessThan(course.minCharsPerSession));
    expect(c5.unlockEligible, isFalse);
    expect(c5.reason, PlanReason.courseConsolidate);

    final ten = DailyPlanBuilder.build(inputs(confusion: confused()));
    final c10 = ten.steps.firstWhere((s) => s.kind == PlanStepKind.course);
    expect(c10.charBudget, greaterThanOrEqualTo(course.minCharsPerSession));
    expect(c10.unlockEligible, isTrue);
    expect(c10.reason, PlanReason.courseChallenge);
  });

  test('a course step for an old lesson can no longer unlock', () {
    final plan = DailyPlanBuilder.build(inputs(due: const []));
    final step = plan.steps.firstWhere((s) => s.kind == PlanStepKind.course);
    expect(DailyPlanBuilder.effectiveStep(step, 10).unlockEligible, isTrue);
    final moved = DailyPlanBuilder.effectiveStep(step, 11);
    expect(moved.unlockEligible, isFalse);
    expect(moved.reason, PlanReason.courseOutdated);
    expect(moved.lesson, 10);
  });

  test('completion is idempotent and survives JSON', () {
    var plan = DailyPlanBuilder.build(inputs());
    final id = plan.steps.first.id;
    plan = plan.start(id).complete(id, exerciseId: 'ex1', accuracy: 0.9);
    plan = plan.complete(id, exerciseId: 'ex2', accuracy: 0.1);
    final back = DailyPlan.fromJson(plan.toJson());
    expect(back.steps.first.resultRef, 'ex1');
    expect(back.steps.first.accuracy, 0.9);
    expect(back.doneCount, 1);
    expect(back.nextStep!.id, plan.steps[1].id);
  });

  test('local day keys follow the local calendar across DST', () {
    // 2026-03-29 is the EU spring-forward day; the key is calendar based.
    final plan = DailyPlanBuilder.build(inputs(now: DateTime(2026, 3, 29, 23)));
    expect(plan.date, '2026-03-29');
    expect(plan.isFor(DateTime(2026, 3, 30, 0, 30)), isFalse);
    expect(plan.isFor(DateTime(2026, 3, 29, 0, 1)), isTrue);
  });

  test('refreshPending keeps started steps and flags are cleared', () {
    var plan = DailyPlanBuilder.build(inputs());
    final first = plan.steps.first.id;
    plan = plan.start(first).markPendingStale();
    expect(plan.hasStaleSteps, isTrue);
    final refreshed = DailyPlanBuilder.refreshPending(plan, inputs(lesson: 12));
    expect(refreshed.steps.first.id, first);
    expect(refreshed.steps.first.state, PlanStepState.active);
    expect(refreshed.hasStaleSteps, isFalse);
    final ids = refreshed.steps.map((s) => s.id).toSet();
    expect(ids, hasLength(refreshed.steps.length));
    final course12 = refreshed.steps.firstWhere(
      (s) => s.kind == PlanStepKind.course,
    );
    expect(course12.lesson, 12);
  });

  test('progress keeps today plan and moves an older one aside', () {
    final yesterday = DailyPlanBuilder.build(
      inputs(now: DateTime(2026, 10, 2, 8)),
    );
    final today = DailyPlanBuilder.build(inputs(seed: 7));
    final p = TrainerProgress().withDailyPlan(yesterday).withDailyPlan(today);
    expect(p.dailyPlan!.id, today.id);
    expect(p.previousPlan!.id, yesterday.id);
    final back = TrainerProgress.fromJson(p.toJson());
    expect(back.dailyPlan!.date, '2026-10-03');
    expect(back.previousPlan!.date, '2026-10-02');
  });

  test('started steps freeze seed and speeds; refresh updates the plan', () {
    var plan = DailyPlanBuilder.build(inputs());
    final first = plan.steps.first;
    plan = plan.start(first.id);
    expect(plan.steps.first.settings, settings);
    const faster = PlanSettings(
      characterWpm: 22,
      effectiveWpm: 10,
      toneHz: 700,
      groupSize: 5,
    );
    final refreshed = DailyPlanBuilder.refreshPending(
      plan,
      PlanInputs(
        now: DateTime(2026, 10, 3, 9),
        profileKey: 'profile',
        budgetMinutes: 15,
        lesson: 10,
        course: course,
        due: const ['K', 'M'],
        charStats: const {},
        confusion: ConfusionMatrix(),
        settings: faster,
        seed: plan.seed,
      ),
    );
    expect(refreshed.budgetMinutes, 15);
    expect(refreshed.settings, faster);
    final kept = refreshed.stepById(first.id)!;
    expect(refreshed.settingsOf(kept), settings);
    expect(kept.seed, first.seed);
    final ids = refreshed.steps.map((s) => s.seed).toSet();
    expect(ids, hasLength(refreshed.steps.length));
  });

  test('legacy started steps keep the speeds they started with', () {
    final plan = DailyPlanBuilder.build(
      inputs(),
    ).start(DailyPlanBuilder.build(inputs()).steps.first.id);
    final json = plan.toJson();
    // A file from before steps carried a snapshot.
    for (final step in json['steps']! as List<Object?>) {
      (step! as Map<String, Object?>).remove('settings');
    }
    final back = DailyPlan.fromJson(json);
    expect(back.steps.first.settings, settings);
    expect(back.steps[1].settings, isNull, reason: 'pending stays open');
  });
}

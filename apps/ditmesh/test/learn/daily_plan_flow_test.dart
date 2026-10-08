import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/training/training_plan.dart';
import 'package:ditmesh/training/training_settings.dart';
import 'package:ditmesh/ui/learn/plan/speed_advice_card.dart';
import 'package:ditmesh/ui/learn/plan/today_plan_card.dart';

import 'helpers/fake_playback.dart';
import 'helpers/l10n.dart';
import 'helpers/test_controller.dart';

Future<TestTraining> _training({TrainerProgress? progress, TestClock? clock}) =>
    TestTraining.create(
      progress: progress ?? TrainerProgress(currentLesson: 10),
      clock: clock,
    );

Future<void> _answerAll(dynamic session) async {
  while (!session.isComplete) {
    session.submit(session.currentDrill.text);
  }
}

void main() {
  test('today plan is made once and survives a restart', () async {
    final t = await _training();
    final plan = await t.controller.ensureTodayPlan();
    expect(t.controller.todayPlan!.id, plan.id);
    expect(await t.controller.ensureTodayPlan(), same(t.controller.todayPlan));

    // A new controller over the same store resumes the same plan.
    final stored = TrainerProgress.fromJson(
      jsonDecode(t.progressStore.storedJson!) as Map<String, Object?>,
    );
    final again = await TestTraining.create(progress: stored, clock: t.clock);
    expect(again.controller.todayPlan!.id, plan.id);
    expect(again.controller.todayPlan!.toJson(), plan.toJson());
  });

  test('a new local day makes a new plan; yesterday is inspect-only', () async {
    final t = await _training();
    final first = await t.controller.ensureTodayPlan();
    t.clock.advance(const Duration(days: 1));
    expect(t.controller.todayPlan, isNull);
    expect(t.controller.unfinishedEarlierPlan!.id, first.id);
    final second = await t.controller.ensureTodayPlan();
    expect(second.id, isNot(first.id));
    expect(t.controller.progress.previousPlan!.id, first.id);
  });

  test('completing a step credits the exercise once and marks it', () async {
    final t = await _training();
    final c = t.controller;
    final plan = await c.ensureTodayPlan();
    final step = plan.steps.firstWhere((s) => s.kind == PlanStepKind.course);
    final session = await c.startPlanReceiveStep(step);
    expect(session.planStepId, step.id);
    expect(session.timing.wpm, plan.settings.characterWpm);
    await _answerAll(session);
    final outcome = await c.recordReceiveSession(session);
    expect(outcome.credit.unlock, isTrue);
    expect(c.todayPlan!.stepById(step.id)!.isDone, isTrue);
    expect(c.todayPlan!.stepById(step.id)!.resultRef, session.id);
    final sessions = c.progress.lifetimeSessions;

    final again = await c.recordReceiveSession(session);
    expect(again.duplicate, isTrue);
    expect(c.progress.lifetimeSessions, sessions);
  });

  test(
    'changing the lesson flags pending steps; update rebuilds them',
    () async {
      final t = await _training();
      final c = t.controller;
      await c.ensureTodayPlan();
      await c.setLesson(12);
      expect(c.todayPlan!.hasStaleSteps, isTrue);
      await c.refreshPlan();
      expect(c.todayPlan!.hasStaleSteps, isFalse);
      final course = c.todayPlan!.steps.firstWhere(
        (s) => s.kind == PlanStepKind.course,
      );
      expect(course.lesson, 12);
    },
  );

  test('an old-lesson course step can no longer unlock', () async {
    final t = await _training();
    final c = t.controller;
    final plan = await c.ensureTodayPlan();
    final step = plan.steps.firstWhere((s) => s.kind == PlanStepKind.course);
    await c.setLesson(11);
    final session = await c.startPlanReceiveStep(step);
    expect(session.countsTowardLesson, isFalse);
    await _answerAll(session);
    final outcome = await c.recordReceiveSession(session);
    expect(outcome.advanced, isFalse);
    expect(c.currentLesson, 11);
  });

  test('send steps complete after their number of targets', () async {
    final t = await _training();
    final c = t.controller;
    final plan = await c.ensureTodayPlan();
    final step = plan.steps.firstWhere((s) => s.kind == PlanStepKind.send);
    for (var i = 0; i < step.charBudget; i++) {
      final session = await c.startPlanSendStep(step)
        ..keyDown(Duration.zero)
        ..keyUp(const Duration(milliseconds: 60));
      await c.recordSendSession(session);
      final done = c.todayPlan!.stepById(step.id)!.isDone;
      expect(done, i == step.charBudget - 1);
    }
    // Sending never touches receive statistics.
    expect(c.progress.charStats, isEmpty);
  });

  test('a changed budget regenerates an untouched plan', () async {
    final t = await _training();
    final c = t.controller;
    await c.ensureTodayPlan();
    await c.setPlanBudget(15);
    expect(c.settings.planMinutes, 15);
    expect(c.todayPlan!.budgetMinutes, 15);
  });

  test('speed advice changes settings only on apply', () async {
    final now = kTestNow;
    final history = <SessionSummary>[
      for (var i = 0; i < 3; i++)
        SessionSummary(
          at: now.subtract(Duration(hours: i + 1)),
          totalChars: 60,
          correctChars: 60,
          drillKind: 'review',
          lesson: 10,
          id: 'ex$i',
          source: ExerciseSource.review,
          characterWpm: 20,
          effectiveWpm: 8,
          insertions: 0,
          assistance: const {},
        ),
    ].reversed.toList();
    final t = await _training(
      progress: TrainerProgress(currentLesson: 10, history: history),
    );
    final c = t.controller;
    final advice = c.pendingSpeedAdvice!;
    expect(advice.kind, SpeedAdviceKind.increaseEffective);
    expect(c.trainerSettings.farnsworthWpm, 8);
    await c.applySpeedAdvice(advice);
    expect(c.trainerSettings.farnsworthWpm, 9);
    expect(c.pendingSpeedAdvice, isNull, reason: 'batch already used');
  });

  testWidgets('the plan card lists steps and starts the next one', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final t = await _training();
    await tester.pumpWidget(
      l10nApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SpeedAdviceCard(controller: t.controller),
                AnimatedBuilder(
                  animation: t.controller,
                  builder: (_, _) => TodayPlanCard(
                    controller: t.controller,
                    playback: FakeLearnPlaybackFactory(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(en.learnPlanTitle), findsOneWidget);
    expect(find.text(en.learnPlanStepCourse(10)), findsOneWidget);
    expect(find.text(en.learnPlanStepSend), findsOneWidget);
    expect(find.byKey(const ValueKey('speed-advice-card')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('plan-start')));
    await tester.pumpAndSettle();
    expect(find.text(en.learnReceiveTitle), findsOneWidget);
    expect(t.controller.todayPlan!.steps.first.state, PlanStepState.active);
  });

  test('plan settings snapshot uses effective <= character speed', () async {
    final t = await TestTraining.create(
      progress: TrainerProgress(currentLesson: 4),
      settings: const TrainingSettings(
        trainer: TrainerSettings(characterWpm: 18, farnsworthWpm: null),
      ),
    );
    final plan = await t.controller.ensureTodayPlan();
    expect(plan.settings.effectiveWpm, 18);
    expect(TrainingController.qsoFromLesson, 30);
  });

  test('blank submissions earn no credit and do not complete a step', () async {
    final t = await _training();
    final c = t.controller;
    final plan = await c.ensureTodayPlan();
    final step = plan.steps.firstWhere((s) => s.kind == PlanStepKind.course);
    final session = await c.startPlanReceiveStep(step);
    while (!session.isComplete) {
      session.submit('   ');
    }
    final outcome = await c.recordReceiveSession(session);
    expect(outcome.credit.activity, isFalse);
    expect(c.progress.lifetimeSessions, 0);
    expect(c.progress.srs.cards, isEmpty);
    expect(c.todayPlan!.stepById(step.id)!.isDone, isFalse);
  });

  test('a started step replays the same content after a refresh', () async {
    final t = await _training();
    final c = t.controller;
    final plan = await c.ensureTodayPlan();
    final step = plan.steps.firstWhere((s) => s.kind == PlanStepKind.course);
    final first = (await c.startPlanReceiveStep(step)).currentDrill.text;
    await c.setLesson(12);
    await c.refreshPlan();
    final again = c.todayPlan!.stepById(step.id)!;
    expect((await c.startPlanReceiveStep(again)).currentDrill.text, first);
  });

  testWidgets('the plan card makes a new plan after midnight', (tester) async {
    final t = await _training();
    await t.controller.ensureTodayPlan();
    await tester.pumpWidget(
      l10nApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AnimatedBuilder(
              animation: t.controller,
              builder: (_, _) => TodayPlanCard(
                controller: t.controller,
                playback: FakeLearnPlaybackFactory(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final yesterday = t.controller.todayPlan!.id;
    t.clock.advance(const Duration(days: 1));
    // Any rebuild on the new day (here: a notification) fetches a plan.
    await t.controller.setDailyGoal(120);
    await tester.pumpAndSettle();
    expect(t.controller.todayPlan, isNotNull);
    expect(t.controller.todayPlan!.id, isNot(yesterday));
    expect(find.text(en.learnPlanTitle), findsOneWidget);
  });
}

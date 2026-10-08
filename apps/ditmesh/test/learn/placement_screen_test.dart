import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/ui/learn/placement/placement_screen.dart';

import 'helpers/fake_playback.dart';
import 'helpers/l10n.dart';
import 'helpers/test_controller.dart';

void main() {
  testWidgets('placement suggests a lesson and changes nothing until adopted', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final t = await TestTraining.create();
    final c = t.controller;
    // Same seed as the screen: the test knows what will be played.
    final expected = PlacementAssessment(course: c.course, seed: 5);
    await tester.pumpWidget(
      l10nApp(
        home: PlacementScreen(
          controller: c,
          playback: FakeLearnPlaybackFactory(),
          seed: 5,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('placement-start')));
    await tester.pump();
    for (final round in expected.tiers.first.rounds) {
      await tester.enterText(find.byType(TextField), round);
      await tester.tap(find.byKey(const ValueKey('placement-submit')));
      await tester.pump();
    }
    expect(find.text(en.placementTierPassed), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('placement-next-tier')));
    await tester.pump();
    for (var i = 0; i < expected.tiers[1].rounds.length; i++) {
      await tester.tap(find.byKey(const ValueKey('placement-submit')));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    final lesson = c.course.lessonFor(c.course.order[10])!;
    expect(find.text(en.placementSuggestion(lesson)), findsOneWidget);
    expect(c.currentLesson, 1, reason: 'nothing applied yet');
    // Placement is activity only: no SRS, no stats.
    expect(c.progress.history.single.source, ExerciseSource.placement);
    expect(c.progress.charStats, isEmpty);
    await tester.tap(find.byKey(const ValueKey('placement-adopt')));
    await tester.pumpAndSettle();
    expect(c.currentLesson, lesson);
  });

  testWidgets('blank placement answers earn no activity credit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final t = await TestTraining.create();
    await tester.pumpWidget(
      l10nApp(
        home: PlacementScreen(
          controller: t.controller,
          playback: FakeLearnPlaybackFactory(),
          seed: 5,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('placement-start')));
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(const ValueKey('placement-submit')));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text(en.placementSuggestion(1)), findsOneWidget);
    expect(t.controller.progress.lifetimeSessions, 0);
  });
}

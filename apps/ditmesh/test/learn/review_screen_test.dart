import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/training/receive_session.dart';
import 'package:ditmesh/ui/learn/receive/receive_drill_screen.dart';
import 'package:ditmesh/ui/learn/review/review_screen.dart';

import 'helpers/fake_playback.dart';
import 'helpers/l10n.dart';
import 'helpers/test_controller.dart';

void main() {
  testWidgets('hosts a receive drill over the review pool under its own title', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final TestTraining t = await TestTraining.create(settings: kShortSettings);
    addTearDown(t.controller.dispose);
    final FakeLearnPlaybackFactory playback = FakeLearnPlaybackFactory();

    await tester.pumpWidget(
      l10nApp(
        home: ReviewScreen(controller: t.controller, playback: playback),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(en.learnReviewTitle), findsOneWidget);
    final ReceiveDrillScreen drill = tester.widget<ReceiveDrillScreen>(
      find.byType(ReceiveDrillScreen),
    );
    expect(drill.session.kind, ReceiveDrillKind.review);
    expect(drill.session.countsTowardLesson, isFalse);
    expect(drill.session.chars.toSet(), t.controller.learnedChars.toSet());
    expect(playback.created.single, kShortSettings);

    // The same session survives rebuilds: the screen does not start another.
    await tester.pumpWidget(
      l10nApp(
        home: ReviewScreen(controller: t.controller, playback: playback),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<ReceiveDrillScreen>(find.byType(ReceiveDrillScreen)).session,
      same(drill.session),
    );
  });
}

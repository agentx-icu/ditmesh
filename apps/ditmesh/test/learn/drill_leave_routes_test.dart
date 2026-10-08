// Mobile review, wave 2 (T4 follow-up): the placement assessment and the
// telegraph recall deck record a session only when it finishes, so leaving
// them half-way through Android back, predictive back or the iOS swipe must
// ask first, like the receive and send drills do.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:ditmesh/ui/learn/placement/placement_screen.dart';
import 'package:ditmesh/ui/learn/telegraph/telegraph_recall_screen.dart';

import 'helpers/fake_playback.dart';
import 'helpers/l10n.dart';
import 'helpers/test_controller.dart';

/// Plain pumps instead of `pumpAndSettle`: a placement round keeps the fake
/// player's timers alive. One frame to start the route transition, one past
/// its end (the Cupertino back transition takes 500 ms), one more for the
/// navigator to drop the finished route.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

/// Android back while a drill may be playing (no `pumpAndSettle`).
Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await _settle(tester);
}

/// Android back on a quiet screen: let the route transition finish.
Future<void> _systemBackSettled(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

Future<TestTraining> _open(
  WidgetTester tester,
  Widget Function(TestTraining t) screen,
) async {
  tester.view.physicalSize = const Size(390, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final TestTraining t = await TestTraining.create();
  await tester.pumpWidget(
    l10nApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => screen(t))),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return t;
}

void main() {
  group('placement', () {
    Widget screen(TestTraining t) => PlacementScreen(
      controller: t.controller,
      playback: FakeLearnPlaybackFactory(),
      seed: 5,
    );

    testWidgets('leaves freely from the intro', (tester) async {
      await _open(tester, screen);
      await _systemBackSettled(tester);
      expect(find.text(en.learnLeaveDrillTitle), findsNothing);
      expect(find.byType(PlacementScreen), findsNothing);
    });

    testWidgets('asks mid-tier; cancel stays, confirm leaves', (tester) async {
      await _open(tester, screen);
      await tester.tap(find.byKey(const ValueKey('placement-start')));
      await tester.pump();

      await _systemBack(tester);
      expect(find.text(en.learnLeaveDrillTitle), findsOneWidget);
      await tester.tap(find.text(en.actionCancel));
      await _settle(tester);
      expect(find.byType(PlacementScreen), findsOneWidget);

      await _systemBack(tester);
      await tester.tap(find.text(en.learnLeaveDrillConfirm));
      await _settle(tester);
      expect(find.byType(PlacementScreen), findsNothing);
    });
  });

  group('telegraph recall', () {
    Widget screen(TestTraining t) => TelegraphRecallScreen(
      controller: t.controller,
      codebook: TelegraphCodebook.taiwan,
      cards: 2,
      random: Random(1),
    );

    Future<void> answerCard(WidgetTester tester, int index) async {
      if (index.isEven) {
        // Character to code: type four digits, then check.
        await tester.enterText(
          find.byKey(const Key('telegraph-code-field')),
          '0000',
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('telegraph-check')));
      } else {
        // Code to character: pick a choice.
        await tester.tap(find.byType(OutlinedButton).first);
      }
      await tester.pump();
      await tester.tap(find.byKey(const Key('telegraph-next')));
      await _settle(tester);
    }

    testWidgets('leaves freely before the first card', (tester) async {
      await _open(tester, screen);
      await _systemBackSettled(tester);
      expect(find.text(en.learnLeaveDrillTitle), findsNothing);
      expect(find.byType(TelegraphRecallScreen), findsNothing);
    });

    testWidgets('asks when the first card has an answer typed', (tester) async {
      await _open(tester, screen);
      await tester.enterText(
        find.byKey(const Key('telegraph-code-field')),
        '12',
      );
      await tester.pump();
      await _systemBack(tester);
      expect(find.text(en.learnLeaveDrillTitle), findsOneWidget);
      await tester.tap(find.text(en.learnLeaveDrillConfirm));
      await tester.pumpAndSettle();
      expect(find.byType(TelegraphRecallScreen), findsNothing);
    });

    testWidgets('asks after a card was answered; confirm leaves', (
      tester,
    ) async {
      await _open(tester, screen);
      await answerCard(tester, 0);

      await _systemBack(tester);
      expect(find.text(en.learnLeaveDrillTitle), findsOneWidget);
      await tester.tap(find.text(en.actionCancel));
      await tester.pumpAndSettle();
      expect(find.byType(TelegraphRecallScreen), findsOneWidget);

      await _systemBack(tester);
      await tester.tap(find.text(en.learnLeaveDrillConfirm));
      await tester.pumpAndSettle();
      expect(find.byType(TelegraphRecallScreen), findsNothing);
    });

    testWidgets('leaves freely once the deck is done', (tester) async {
      await _open(tester, screen);
      await answerCard(tester, 0);
      await answerCard(tester, 1);
      await _systemBackSettled(tester);
      expect(find.text(en.learnLeaveDrillTitle), findsNothing);
      expect(find.byType(TelegraphRecallScreen), findsNothing);
    });
  });
}

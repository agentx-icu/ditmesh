import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:ditmesh/training/receive_session.dart';
import 'package:ditmesh/training/send_session.dart';
import 'package:ditmesh/training/training_settings.dart';
import 'package:ditmesh/ui/learn/receive/receive_drill_screen.dart';
import 'package:ditmesh/ui/learn/receive/receive_summary_view.dart';
import 'package:ditmesh/ui/learn/send/send_practice_screen.dart';
import 'package:ditmesh/ui/learn/send/send_result_view.dart';

import 'helpers/fake_playback.dart';
import 'helpers/l10n.dart';
import 'helpers/test_controller.dart';

final class _FakeWake implements ScreenWakeApi {
  final List<bool> calls = <bool>[];

  @override
  Future<void> keepOn(bool on) async => calls.add(on);
}

/// Pushes [screen] over a launcher page so popping it has somewhere to go.
Future<void> _open(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    l10nApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<Object?>(builder: (_) => screen)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// Android back / predictive back: the platform asks the navigator to pop.
Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

Future<void> _setLifecycle(WidgetTester tester, AppLifecycleState s) async {
  tester.binding.handleAppLifecycleStateChanged(s);
  await tester.pump();
}

/// iOS interactive back: a drag from the left edge across most of the
/// screen, released.
Future<void> _edgeSwipeBack(WidgetTester tester) async {
  final TestGesture gesture = await tester.startGesture(const Offset(5, 400));
  for (int i = 0; i < 10; i++) {
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

Finder get _dialog => find.text(en.learnLeaveDrillTitle);

void main() {
  group('receive drill', () {
    late TestTraining t;
    late ReceiveSession session;
    late _FakeWake wake;

    Future<void> pump(WidgetTester tester) async {
      t = await TestTraining.create(settings: kShortSettings);
      addTearDown(t.controller.dispose);
      session = t.controller.startLessonSession();
      wake = _FakeWake();
      await _open(
        tester,
        ReceiveDrillScreen(
          controller: t.controller,
          playback: FakeLearnPlaybackFactory(),
          session: session,
          screenWake: wake,
        ),
      );
    }

    Future<void> answerRound(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField), session.currentDrill.text);
      await tester.tap(find.widgetWithText(FilledButton, en.learnSubmit));
      await tester.pumpAndSettle();
      expect(session.roundCount, 1);
    }

    testWidgets('back before any answer leaves without asking', (tester) async {
      await pump(tester);
      await _systemBack(tester);
      expect(_dialog, findsNothing);
      expect(find.byType(ReceiveDrillScreen), findsNothing);
    });

    testWidgets('back after an answered round asks; cancel stays, confirm '
        'leaves without saving', (tester) async {
      await pump(tester);
      await answerRound(tester);

      await _systemBack(tester);
      expect(_dialog, findsOneWidget);
      expect(find.text(en.learnLeaveDrillBody), findsOneWidget);
      await tester.tap(find.text(en.actionCancel));
      await tester.pumpAndSettle();
      expect(_dialog, findsNothing);
      expect(find.byType(ReceiveDrillScreen), findsOneWidget);

      // The AppBar back button goes through the same guard.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(_dialog, findsOneWidget);
      await tester.tap(find.text(en.learnLeaveDrillConfirm));
      await tester.pumpAndSettle();
      expect(find.byType(ReceiveDrillScreen), findsNothing);
      expect(t.progressStore.saveCount, 0);
    });

    // A guarded Cupertino route turns its back swipe off entirely (it
    // checks the pop disposition), so the swipe neither leaves nor asks;
    // the back button is the way out and that one asks.
    testWidgets(
      'iOS edge swipe cannot leave a guarded drill, but leaves an unguarded '
      'one',
      (tester) async {
        await pump(tester);
        await answerRound(tester);
        await _edgeSwipeBack(tester);
        expect(find.byType(ReceiveDrillScreen), findsOneWidget);
        expect(_dialog, findsNothing);
        expect(session.roundCount, 1);

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(_dialog, findsOneWidget);
        await tester.tap(find.text(en.actionCancel));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(FilledButton, en.learnFinish));
        await tester.pumpAndSettle();
        expect(find.byType(ReceiveSummaryView), findsOneWidget);
        await _edgeSwipeBack(tester);
        expect(find.byType(ReceiveDrillScreen), findsNothing);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      'iOS edge swipe leaves a drill with nothing to lose',
      (tester) async {
        await pump(tester);
        await _edgeSwipeBack(tester);
        expect(_dialog, findsNothing);
        expect(find.byType(ReceiveDrillScreen), findsNothing);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets('after the summary back leaves without asking', (tester) async {
      await pump(tester);
      await answerRound(tester);
      await tester.tap(find.widgetWithText(FilledButton, en.learnFinish));
      await tester.pumpAndSettle();
      expect(find.byType(ReceiveSummaryView), findsOneWidget);
      await _systemBack(tester);
      expect(_dialog, findsNothing);
      expect(find.byType(ReceiveDrillScreen), findsNothing);
      expect(t.progressStore.saveCount, 1);
    });

    testWidgets('keeps the screen on until the summary, not in background', (
      tester,
    ) async {
      await pump(tester);
      expect(wake.calls, <bool>[true]);
      await _setLifecycle(tester, AppLifecycleState.inactive);
      expect(wake.calls, <bool>[true], reason: 'iOS banners keep the UI');
      await _setLifecycle(tester, AppLifecycleState.hidden);
      await _setLifecycle(tester, AppLifecycleState.paused);
      expect(wake.calls, <bool>[true, false]);
      await _setLifecycle(tester, AppLifecycleState.hidden);
      await _setLifecycle(tester, AppLifecycleState.inactive);
      await _setLifecycle(tester, AppLifecycleState.resumed);
      expect(wake.calls, <bool>[true, false, true]);

      await answerRound(tester);
      await tester.tap(find.widgetWithText(FilledButton, en.learnFinish));
      await tester.pumpAndSettle();
      expect(wake.calls, <bool>[true, false, true, false]);
      await tester.tap(find.widgetWithText(FilledButton, en.learnDone));
      await tester.pumpAndSettle();
      expect(wake.calls, <bool>[true, false, true, false]);
    });

    testWidgets('leaving mid-drill releases the screen', (tester) async {
      await pump(tester);
      await _systemBack(tester);
      expect(wake.calls, <bool>[true, false]);
    });
  });

  group('send practice', () {
    late TestTraining t;
    late FakeLearnPlaybackFactory playback;
    late _FakeWake wake;

    Future<void> pump(WidgetTester tester) async {
      t = await TestTraining.create(
        settings: const TrainingSettings(keyerMode: KeyerMode.straight),
      );
      addTearDown(t.controller.dispose);
      playback = FakeLearnPlaybackFactory();
      wake = _FakeWake();
      await _open(
        tester,
        SendPracticeScreen(
          controller: t.controller,
          playback: playback,
          session: SendSession(
            target: 'E',
            timing: const MorseTiming(wpm: 20),
            now: () => t.clock.now,
            lesson: 1,
          ),
          screenWake: wake,
        ),
      );
    }

    Future<void> keyOneMark(WidgetTester tester) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(StraightKeyButton)),
      );
      await tester.pump();
      playback.clock.advance(const Duration(milliseconds: 60));
      await tester.pump();
      await gesture.up();
      await tester.pump();
    }

    testWidgets('back before keying leaves without asking', (tester) async {
      await pump(tester);
      await _systemBack(tester);
      expect(_dialog, findsNothing);
      expect(find.byType(SendPracticeScreen), findsNothing);
    });

    testWidgets('back with keyed input asks; confirm leaves unsaved', (
      tester,
    ) async {
      await pump(tester);
      await keyOneMark(tester);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(_dialog, findsOneWidget);
      await tester.tap(find.text(en.actionCancel));
      await tester.pumpAndSettle();
      expect(find.byType(SendPracticeScreen), findsOneWidget);

      await _systemBack(tester);
      expect(_dialog, findsOneWidget);
      await tester.tap(find.text(en.learnLeaveDrillConfirm));
      await tester.pumpAndSettle();
      expect(find.byType(SendPracticeScreen), findsNothing);
      expect(t.controller.progress.history, isEmpty);
    });

    testWidgets('restart clears the guard; the result view never asks', (
      tester,
    ) async {
      await pump(tester);
      await keyOneMark(tester);
      await tester.tap(find.text(en.learnRestart));
      await tester.pumpAndSettle();
      await keyOneMark(tester);
      await tester.tap(find.text(en.learnDone));
      await tester.pumpAndSettle();
      expect(find.byType(SendResultView), findsOneWidget);
      await _systemBack(tester);
      expect(_dialog, findsNothing);
      expect(find.byType(SendPracticeScreen), findsNothing);
    });

    testWidgets('keeps the screen on while practising', (tester) async {
      await pump(tester);
      expect(wake.calls, <bool>[true]);
      await _setLifecycle(tester, AppLifecycleState.hidden);
      await _setLifecycle(tester, AppLifecycleState.paused);
      expect(wake.calls, <bool>[true, false]);
      await _setLifecycle(tester, AppLifecycleState.hidden);
      await _setLifecycle(tester, AppLifecycleState.inactive);
      await _setLifecycle(tester, AppLifecycleState.resumed);
      expect(wake.calls, <bool>[true, false, true]);

      await keyOneMark(tester);
      await tester.tap(find.text(en.learnDone));
      await tester.pumpAndSettle();
      expect(wake.calls, <bool>[true, false, true, false]);
      // The result (with the rhythm timeline) is taller than the phone.
      await tester.ensureVisible(find.text(en.learnTryAnother));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.learnTryAnother));
      await tester.pumpAndSettle();
      expect(wake.calls, <bool>[true, false, true, false, true]);
      await _systemBack(tester);
      expect(find.byType(SendPracticeScreen), findsNothing);
      expect(wake.calls, <bool>[true, false, true, false, true, false]);
    });
  });
}

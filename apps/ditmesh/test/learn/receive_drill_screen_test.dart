import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:ditmesh/training/chat_copy_session.dart';
import 'package:ditmesh/training/receive_session.dart';
import 'package:ditmesh/ui/learn/receive/answer_keypad.dart';
import 'package:ditmesh/ui/learn/receive/receive_drill_screen.dart';
import 'package:ditmesh/ui/learn/receive/receive_summary_view.dart';
import 'package:ditmesh/ui/learn/receive/round_result_view.dart';

import 'helpers/fake_playback.dart';
import 'helpers/l10n.dart';
import 'helpers/test_controller.dart';

Future<void> _setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<(TestTraining, ReceiveSession, FakeLearnPlaybackFactory)> _pump(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  await _setSize(tester, size);
  final t = await TestTraining.create(settings: kShortSettings);
  addTearDown(t.controller.dispose);
  final playback = FakeLearnPlaybackFactory();
  final session = t.controller.startFocusSession(<String>['K', 'M'])!;
  await tester.pumpWidget(
    l10nApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<Object?>(
                  builder: (_) => ReceiveDrillScreen(
                    controller: t.controller,
                    playback: playback,
                    session: session,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return (t, session, playback);
}

void main() {
  testWidgets('plays the drill through the player on open', (tester) async {
    final (_, session, playback) = await _pump(tester);
    expect(playback.created.single, kShortSettings);
    expect(find.text(en.learnListen), findsOneWidget);
    // The first element keys the sink immediately; the rest follow the clock.
    expect(playback.sink.events.first.on, isTrue);
    final total = MorseEncoder.totalDuration(session.currentTimeline);
    playback.clock.advance(total + const Duration(milliseconds: 1));
    await tester.pump();
    final marks = session.currentTimeline.where((e) => e.on).length;
    expect(playback.sink.events.where((e) => e.on).length, marks);
    expect(playback.sink.isOn, isFalse);
    expect(find.text(en.learnReady), findsOneWidget);
  });

  testWidgets('replay plays the same round again', (tester) async {
    final (_, session, playback) = await _pump(tester);
    final total = MorseEncoder.totalDuration(session.currentTimeline);
    playback.clock.advance(total + const Duration(milliseconds: 1));
    await tester.pump();
    final before = playback.sink.events.length;
    await tester.tap(find.text(en.learnReplay));
    await tester.pump();
    playback.clock.advance(total + const Duration(milliseconds: 1));
    expect(playback.sink.events.length, before * 2);
  });

  testWidgets(
    'typed answer -> score -> finish -> summary -> progress recorded',
    (tester) async {
      final (t, session, _) = await _pump(tester);
      final target = session.currentDrill.text;

      await tester.enterText(find.byType(TextField), target);
      await tester.tap(find.widgetWithText(FilledButton, en.learnSubmit));
      await tester.pumpAndSettle();

      expect(find.byType(RoundResultView), findsOneWidget);
      expect(find.text(en.learnRoundPerfect), findsOneWidget);
      // Budget of 5 chars is spent after one round of 5.
      expect(session.isComplete, isTrue);
      await tester.tap(find.widgetWithText(FilledButton, en.learnFinish));
      await tester.pumpAndSettle();

      expect(find.byType(ReceiveSummaryView), findsOneWidget);
      expect(find.text(en.learnAccuracyPercent(100)), findsOneWidget);
      // 5 chars is below the 50-char Koch minimum, so no unlock.
      expect(find.text(en.learnLessonNotPassed), findsOneWidget);
      expect(t.progressStore.saveCount, 1);
      expect(t.controller.progress.history.single.totalChars, 5);
      expect(t.controller.progress.charsOn(kTestNow), 5);

      await tester.tap(find.widgetWithText(FilledButton, en.learnDone));
      await tester.pumpAndSettle();
      expect(find.byType(ReceiveDrillScreen), findsNothing);
    },
  );

  testWidgets('keypad is restricted to the learned set and edits the answer', (
    tester,
  ) async {
    final (_, session, _) = await _pump(tester);
    final keypad = tester.widget<AnswerKeypad>(find.byType(AnswerKeypad));
    expect(keypad.chars, <String>['K', 'M']);
    expect(
      find.descendant(of: find.byType(AnswerKeypad), matching: find.text('R')),
      findsNothing,
    );

    Finder key(String label) => find.descendant(
      of: find.byType(AnswerKeypad),
      matching: find.text(label),
    );
    await tester.tap(key('K'));
    await tester.tap(key('M'));
    await tester.tap(key(en.learnSpace));
    await tester.tap(key('K'));
    await tester.tap(key('⌫'));
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'KM ');

    // Every key is at least 48 dp on both axes (touch target).
    final keys = find.descendant(
      of: find.byType(AnswerKeypad),
      matching: find.byType(InkWell),
    );
    expect(keys, findsNWidgets(4));
    for (final element in keys.evaluate()) {
      final size = element.size!;
      expect(size.height, greaterThanOrEqualTo(AnswerKeypad.keySize));
      expect(size.width, greaterThanOrEqualTo(AnswerKeypad.keySize));
    }
    expect(session.roundCount, 0);
  });

  testWidgets('wrong copy shows misses and the confusion pair', (tester) async {
    final (t, session, _) = await _pump(tester);
    final target = session.currentDrill.text;
    final wrong = target.split('').map((c) => c == 'K' ? 'M' : 'K').join();
    await tester.enterText(find.byType(TextField), wrong);
    await tester.tap(find.widgetWithText(FilledButton, en.learnSubmit));
    await tester.pumpAndSettle();
    expect(find.text(en.learnRoundPerfect), findsNothing);
    expect(find.textContaining('of 5 correct'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.learnFinish));
    await tester.pumpAndSettle();
    expect(find.text(en.learnConfusions), findsOneWidget);
    expect(find.textContaining('heard as'), findsWidgets);
    expect(t.controller.progress.confusion.isEmpty, isFalse);
  });

  testWidgets('disposing the screen releases the playback', (tester) async {
    final (_, _, playback) = await _pump(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(playback.disposeCalls, 1);
    expect(playback.sink.isOn, isFalse);
  });
}

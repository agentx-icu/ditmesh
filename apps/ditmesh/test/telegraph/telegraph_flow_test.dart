import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/telegraph_sessions.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/ui/chat/message_bubble.dart';
import 'package:ditmesh/ui/learn/telegraph/telegraph_recall_screen.dart';
import 'package:ditmesh/ui/telegraph/telegraph_interpret_sheet.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../learn/helpers/l10n.dart';
import '../learn/helpers/test_controller.dart';

ChatMessage _msg(String text) => ChatMessage(
  id: 'm1',
  conversationId: 'c2c_${'A' * 64}',
  senderId: 'A' * 64,
  text: text,
  timestamp: DateTime.utc(2026, 10, 4),
  status: MessageStatus.received,
  isMine: false,
);

Widget _bubble(ChatMessage m, {bool training = false}) => l10nApp(
  home: Scaffold(
    body: MessageBubble(
      message: m,
      trainingMode: training,
      revealed: false,
      playing: false,
      onPlay: () {},
      onReveal: () {},
    ),
  ),
);

void main() {
  group('digit copying', () {
    test('records codebook and table version, never counts toward the '
        'lesson', () async {
      final t = await TestTraining.create(settings: kShortSettings);
      addTearDown(t.controller.dispose);
      final c = t.controller;
      final session = c.startTelegraphDigitsSession(TelegraphCodebook.taiwan);
      expect(session.countsTowardLesson, isFalse);
      expect(session.source, ExerciseSource.focus);
      expect(session.currentDrill.text, matches(RegExp(r'^\d{4}$')));
      final lesson = c.currentLesson;
      while (!session.isComplete) {
        session.submit(session.currentDrill.text);
      }
      await c.recordReceiveSession(session);
      expect(c.currentLesson, lesson);
      expect(c.progress.history.last.sourceRef, TelegraphCurriculum.sourceRef(TelegraphCodebook.taiwan));
      final (n, acc) = c.telegraphDigitsResults(TelegraphCodebook.taiwan);
      expect(n, 1);
      expect(acc, 1.0);
      expect(c.telegraphDigitsResults(TelegraphCodebook.mainland).$1, 0);
    });

    test('a message\'s groups can be drilled as they are', () async {
      final t = await TestTraining.create(settings: kShortSettings);
      addTearDown(t.controller.dispose);
      final s = t.controller.startTelegraphDigitsSession(
        TelegraphCodebook.mainland,
        codes: TelegraphGroups.parse('CQ 0022 123').where((x) => x.isGroup).map((x) => x.source),
      );
      expect(s.currentDrill.text, '0022');
    });
  });

  test('recall statistics live apart from Morse progress', () async {
    final t = await TestTraining.create(settings: kShortSettings);
    addTearDown(t.controller.dispose);
    final c = t.controller;
    final before = c.progress.charStats;
    final historyBefore = c.progress.history.length;
    await c.recordTelegraphRecall(TelegraphCodebook.mainland, [
      ('中', true, false),
      ('国', true, true),
    ]);
    final stats = await c.readTelegraphRecall();
    expect(stats.answered(TelegraphCodebook.mainland), 2);
    expect(stats.accuracy(TelegraphCodebook.mainland), 1.0);
    expect(c.progress.charStats, before);
    expect(c.progress.history.length, historyBefore);
  });

  group('chat interpretation', () {
    testWidgets('offered only for visible four-digit groups', (tester) async {
      await tester.pumpWidget(_bubble(_msg('599 TU')));
      expect(find.byKey(const ValueKey('learn-menu-m1')), findsNothing);
      await tester.pumpWidget(_bubble(_msg('0022 0948'), training: true));
      expect(find.byKey(const ValueKey('learn-menu-m1')), findsNothing,
          reason: 'hidden text is not interpreted');
      await tester.pumpWidget(_bubble(_msg('CQ 0022 12345 9999')));
      await tester.tap(find.byKey(const ValueKey('learn-menu-m1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.telegraphInterpretAction));
      await tester.pumpAndSettle();
      expect(find.byType(TelegraphInterpretation), findsOneWidget);
      expect(find.text('中'), findsOneWidget);
      expect(find.text(en.telegraphMalformed), findsOneWidget);
      expect(find.text(en.telegraphUnresolved), findsOneWidget);
      expect(find.text(en.telegraphNotCode), findsOneWidget);
      // The message itself is unchanged underneath.
      expect(find.text('CQ 0022 12345 9999', findRichText: true), findsWidgets);
    });

    testWidgets('the codebook switch re-reads the groups', (tester) async {
      final tw = ChineseTelegraphCode.codeOf('國', codebook: TelegraphCodebook.taiwan)!;
      await tester.pumpWidget(l10nApp(home: Scaffold(body: TelegraphInterpretation(text: tw))));
      await tester.tap(find.byKey(const ValueKey('codebook-taiwan')));
      await tester.pump();
      expect(find.text('國'), findsOneWidget);
    });
  });

  testWidgets('recall: correct, wrong and revealed answers', (tester) async {
    final t = await TestTraining.create(settings: kShortSettings);
    addTearDown(t.controller.dispose);
    await tester.pumpWidget(
      l10nApp(
        home: TelegraphRecallScreen(
          controller: t.controller,
          codebook: TelegraphCodebook.mainland,
          cards: 2,
        ),
      ),
    );
    // Card 1: character -> code.
    final char = tester.widget<Text>(find.byKey(const Key('telegraph-prompt'))).data!;
    final code = ChineseTelegraphCode.codeOf(char)!;
    await tester.enterText(find.byKey(const Key('telegraph-code-field')), code);
    await tester.pump();
    await tester.tap(find.byKey(const Key('telegraph-check')));
    await tester.pump();
    expect(find.text(en.telegraphCorrect), findsOneWidget);
    await tester.tap(find.byKey(const Key('telegraph-next')));
    await tester.pump();
    // Card 2: reveal, then answer: assisted.
    await tester.tap(find.byKey(const Key('telegraph-reveal')));
    await tester.pump();
    expect(find.text(en.telegraphRevealAssisted), findsOneWidget);
    final shown = tester.widget<Text>(find.byKey(const Key('telegraph-prompt'))).data!;
    final answer = ChineseTelegraphCode.charsOf(shown).first;
    await tester.tap(find.byKey(Key('telegraph-choice-$answer')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('telegraph-next')));
    await tester.runAsync(() => t.controller.flush());
    await tester.pumpAndSettle();
    expect(find.text(en.telegraphRecallSummary(1, 2)), findsOneWidget);
    expect(find.text(en.telegraphRecallAssisted(1)), findsOneWidget);
  });
}

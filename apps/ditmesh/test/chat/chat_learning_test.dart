import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/training_controller_host.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/learn/learn_playback.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../learn/helpers/fake_playback.dart';
import '../learn/helpers/test_controller.dart';
import 'test_support.dart';

ConversationTarget _ann() => ConversationTarget(
  id: 'c2c_$kPeerKey',
  title: 'Ann',
  kind: ConversationKind.c2c,
);

Future<(ChatHarness, TestTraining)> _pump(
  WidgetTester tester, {
  bool listenOnly = false,
  bool autoPlay = false,
}) async {
  final t = await TestTraining.create(
    progress: TrainerProgress(currentLesson: 40),
  );
  late final TrainingControllerHost host;
  final h = await pumpChat(tester, (h) {
    h.addAnn();
    h.settings
      ..listenOnly = listenOnly
      ..autoPlay = autoPlay;
    host = TrainingControllerHost(
      h.identity,
      factory: (_) async => t.controller,
    );
    return MultiProvider(
      providers: [
        Provider<TrainingControllerHost?>.value(value: host),
        Provider<LearnPlaybackFactory>.value(value: FakeLearnPlaybackFactory()),
      ],
      child: ConversationScreen(target: _ann()),
    );
  });
  addTearDown(host.dispose);
  return (h, t);
}

Future<void> _openMenu(WidgetTester tester, String item) async {
  await tester.tap(find.byTooltip(s.chatMessageLearnActions).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('listen-only hides text and dots/dashes, also for semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, listenOnly: true);
    expect(find.text('CQ CQ DE ANN'), findsNothing);
    expect(find.text(s.chatListenOnlyHidden), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('CQ CQ DE ANN')), findsNothing);
    expect(find.textContaining('-.-.'), findsNothing);
    await tester.tap(find.text(s.chatReveal));
    await tester.pumpAndSettle();
    expect(find.text('CQ CQ DE ANN'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('practising a message never sends or touches the draft', (
    tester,
  ) async {
    final (h, t) = await _pump(tester, autoPlay: true);
    final before = await h.service.loadHistory('c2c_$kPeerKey');
    await _openMenu(tester, s.chatPracticeMessage);
    expect(find.text(s.chatPracticeTitle), findsOneWidget);
    // Auto-play is paused while practising.
    expect(h.settings.autoPlay, isFalse);
    await tester.tap(find.byKey(const ValueKey('chat-practice-play')));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'CQ CQ DE ANN');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('chat-practice-submit')));
    await tester.pumpAndSettle();
    expect(find.text(s.learnAccuracyPercent(100)), findsOneWidget);

    final record = t.controller.progress.history.single;
    expect(record.source, ExerciseSource.chat);
    expect(record.sourceRef, contains('c2c_$kPeerKey'));
    expect(record.isKnownUnassisted, isTrue);
    // No outbound message, no draft.
    final after = await h.service.loadHistory('c2c_$kPeerKey');
    expect(after.length, before.length);
    expect(after.where((m) => m.isMine), isEmpty);
    expect(h.service.conversations.single.draft, isEmpty);

    await tester.tap(find.text(s.learnDone));
    await tester.pumpAndSettle();
    expect(h.settings.autoPlay, isTrue, reason: 'restored after practice');
  });

  testWidgets('a revealed attempt is assisted and leaves SRS alone', (
    tester,
  ) async {
    final (_, t) = await _pump(tester);
    await _openMenu(tester, s.chatPracticeMessage);
    await tester.tap(find.text(s.chatReveal));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'CQ CQ DE ANN');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('chat-practice-submit')));
    await tester.pumpAndSettle();
    final record = t.controller.progress.history.single;
    expect(record.assistance, contains(Assistance.reveal));
    expect(t.controller.progress.srs.cards, isEmpty);
    expect(t.controller.progress.charStats, isEmpty);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/group_practice.dart';
import 'package:ditmesh/ui/groups/practice/group_practice_session_page.dart';
import 'package:ditmesh/ui/learn/chat_copy/chat_copy_screen.dart';
import 'package:ditmesh/ui/learn/learn_playback.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:provider/provider.dart';

import 'learn/helpers/fake_playback.dart';
import 'learn/helpers/l10n.dart';
import 'learn/helpers/test_controller.dart';

GroupPracticeAttempt _attempt(String id, int correct) => GroupPracticeAttempt(
  exerciseId: id,
  at: DateTime.utc(2026, 10, 4),
  correct: correct,
  total: 5,
  assisted: false,
);

void main() {
  group('book', () {
    final session = GroupPracticeSession(
      id: 's1',
      conversationId: 'group_tox_1',
      title: 'CW net',
      role: GroupPracticeRole.participant,
      createdAt: DateTime.utc(2026, 10, 4),
    );

    test('rounds dedupe by message; attempts dedupe by exercise id', () {
      var b = GroupPracticeBook.empty.add(session);
      b = b.addRound('s1', roundId: 'r1', messageId: 'm1', messageAt: DateTime.utc(2026));
      b = b.addRound('s1', roundId: 'r2', messageId: 'm1', messageAt: DateTime.utc(2026));
      expect(b.byId('s1')!.rounds, hasLength(1));
      b = b.recordAttempt('s1', 'r1', _attempt('ex_1', 3));
      b = b.recordAttempt('s1', 'r1', _attempt('ex_1', 3)); // same attempt
      b = b.recordAttempt('s1', 'r1', _attempt('ex_2', 5)); // a repeat
      final r = b.byId('s1')!.rounds.single;
      expect(r.attempts.map((a) => a.exerciseId), ['ex_1', 'ex_2']);
      expect(r.state, GroupRoundState.done);
      final sum = b.byId('s1')!.summary;
      expect(sum.attempts, 2);
      expect(sum.accuracy, 1.0, reason: 'the latest attempt is the result');
    });

    test('an unavailable source is never turned into a completed round', () {
      var b = GroupPracticeBook.empty.add(session);
      b = b.addRound('s1', roundId: 'r1', messageId: 'm1', messageAt: DateTime.utc(2026));
      b = b.setRoundState('s1', 'r1', GroupRoundState.unavailable);
      b = b.recordAttempt('s1', 'r1', _attempt('ex_1', 5));
      expect(b.byId('s1')!.rounds.single.state, GroupRoundState.unavailable);
      expect(b.byId('s1')!.summary.done, 0);
      expect(b.byId('s1')!.summary.unavailable, 1);
    });

    test('json round trip and restart through the controller', () async {
      var b = GroupPracticeBook.empty.add(session);
      b = b.addRound('s1', roundId: 'r1', messageId: 'm1', messageAt: DateTime.utc(2026));
      b = b.recordAttempt('s1', 'r1', _attempt('ex_1', 4));
      expect(GroupPracticeBook.fromJson(b.toJson()).byId('s1')!.toJson(), b.byId('s1')!.toJson());
      expect(GroupPracticeBook.fromJson({'v': 9}).sessions, isEmpty);

      final t = await TestTraining.create();
      addTearDown(t.controller.dispose);
      await t.controller.updateGroupPractice((_) => b);
      final reloaded = await t.controller.readGroupPractice();
      expect(reloaded.byId('s1')!.rounds.single.attempts.single.correct, 4);
      expect(reloaded.forConversation('group_tox_1'), hasLength(1));
      expect(reloaded.forConversation('group_tox_2'), isEmpty);
    });
  });

  testWidgets('participant: add a received exercise, copy it locally, nothing '
      'is sent; a deleted source becomes unavailable', (tester) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final chat = FakeChatService(selfPublicKey: 'F' * 64, clock: () => DateTime.utc(2026, 10, 4, 9));
    addTearDown(chat.dispose);
    final group = chat.addFakeGroup(const Group(id: 'tox_1', name: 'Net', kind: GroupKind.group));
    const conv = 'group_tox_1';
    final exercise = chat.receiveMessage(conv, 'KM KM', senderId: 'A' * 64, senderName: 'K1ABC');
    final t = await TestTraining.create(settings: kShortSettings);
    addTearDown(t.controller.dispose);
    final c = t.controller;
    await c.updateGroupPractice(
      (b) => b.add(
        GroupPracticeSession(
          id: 's1',
          conversationId: conv,
          title: group.name,
          role: GroupPracticeRole.participant,
          createdAt: DateTime.utc(2026, 10, 4),
        ),
      ),
    );
    final sentBefore = (await chat.loadHistory(conv)).where((m) => m.isMine).length;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ChatService>.value(value: chat),
          Provider<LearnPlaybackFactory>.value(value: FakeLearnPlaybackFactory()),
        ],
        child: l10nApp(home: GroupPracticeSessionPage(controller: c, sessionId: 's1')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('gp-add-round')));
    await tester.pumpAndSettle();
    // Picked by sender, not by the exercise text.
    expect(find.text('K1ABC'), findsOneWidget);
    expect(find.text('KM KM'), findsNothing);
    await tester.tap(find.byKey(Key('gp-pick-${exercise.id}')));
    await tester.runAsync(() => c.flush());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('gp-copy-0')));
    await tester.pumpAndSettle();
    expect(find.byType(ChatCopyScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'KM KM');
    final submit = find.byKey(const ValueKey('chat-practice-submit'));
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.runAsync(() => c.flush());
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    // The attempt is recorded once the copy page has closed.
    await tester.runAsync(() => c.flush());
    await tester.pumpAndSettle();

    final book = await c.readGroupPractice();
    final round = book.byId('s1')!.rounds.single;
    expect(round.state, GroupRoundState.done);
    expect(round.attempts.single.correct, round.attempts.single.total);
    // The shared exercise record carries the credit, once.
    expect(c.progress.history.where((h) => h.id == round.attempts.single.exerciseId), hasLength(1));
    expect(c.progress.history.last.source, ExerciseSource.chat);
    // Nothing went to the group; the draft is untouched.
    expect((await chat.loadHistory(conv)).where((m) => m.isMine).length, sentBefore);
    expect(chat.conversations.firstWhere((x) => x.id == conv).draft, isEmpty);

    // The source is cleared from history: reopening marks it unavailable.
    await chat.clearHistory(conv);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ChatService>.value(value: chat),
          Provider<LearnPlaybackFactory>.value(value: FakeLearnPlaybackFactory()),
        ],
        child: l10nApp(home: GroupPracticeSessionPage(controller: c, sessionId: 's1')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() => c.flush());
    await tester.pumpAndSettle();
    expect(find.text(en.groupPracticeSourceGone), findsOneWidget);
    expect(find.byKey(const Key('gp-copy-0')), findsNothing);
    // Shown, not stored: an empty read may be a history still loading.
    expect((await c.readGroupPractice()).byId('s1')!.rounds.single.state, GroupRoundState.done);
  });

  testWidgets('instructor: own exercise messages as a checklist, no copying', (tester) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final chat = FakeChatService(selfPublicKey: 'F' * 64, clock: () => DateTime.utc(2026, 10, 4, 9));
    addTearDown(chat.dispose);
    chat.addFakeGroup(const Group(id: 'tox_1', name: 'Net', kind: GroupKind.group));
    const conv = 'group_tox_1';
    final mine = await chat.sendText(conv, 'PARIS');
    chat.receiveMessage(conv, 'R R', senderId: 'A' * 64);
    final t = await TestTraining.create(settings: kShortSettings);
    addTearDown(t.controller.dispose);
    final c = t.controller;
    await c.updateGroupPractice(
      (b) => b.add(
        GroupPracticeSession(
          id: 's2',
          conversationId: conv,
          title: 'Net',
          role: GroupPracticeRole.instructor,
          createdAt: DateTime.utc(2026, 10, 4),
        ),
      ),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [Provider<ChatService>.value(value: chat)],
        child: l10nApp(home: GroupPracticeSessionPage(controller: c, sessionId: 's2')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('gp-add-round')));
    await tester.pumpAndSettle();
    // The instructor sees their own messages, by text; not others'.
    expect(find.byKey(Key('gp-pick-${mine.id}')), findsOneWidget);
    expect(find.text('R R'), findsNothing);
    await tester.tap(find.byKey(Key('gp-pick-${mine.id}')));
    await tester.runAsync(() => c.flush());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gp-copy-0')), findsNothing);
    await tester.tap(find.byKey(const Key('gp-done-0')));
    await tester.runAsync(() => c.flush());
    await tester.pumpAndSettle();
    expect(find.text(en.groupPracticeRoundsDone(1, 1)), findsWidgets);
    expect(c.progress.history, isEmpty, reason: 'a checklist adds no exercise');
  });

  testWidgets('without a chat session the rounds say so and retry when chat '
      'connects', (tester) async {
    final identity = FakeIdentityService.withProfile(
      identity: Identity(toxId: FakeIdentityService.toxIdForSeed(5), displayName: 'Me'),
      connectDelay: Duration.zero,
    );
    addTearDown(identity.dispose);
    await identity.open();
    final chat = FakeChatService(identity: identity);
    addTearDown(chat.dispose);
    final t = await TestTraining.create(settings: kShortSettings);
    addTearDown(t.controller.dispose);
    final c = t.controller;
    var book = GroupPracticeBook.empty.add(
      GroupPracticeSession(
        id: 's3',
        conversationId: 'group_tox_1',
        title: 'Net',
        role: GroupPracticeRole.participant,
        createdAt: DateTime.utc(2026, 10, 4),
      ),
    );
    book = book.addRound('s3', roundId: 'r1', messageId: 'm_x', messageAt: DateTime.utc(2026));
    await c.updateGroupPractice((_) => book);
    await tester.pumpWidget(
      MultiProvider(
        providers: [Provider<ChatService>.value(value: chat)],
        child: l10nApp(home: GroupPracticeSessionPage(controller: c, sessionId: 's3')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gp-retry')), findsOneWidget);
    expect(find.text(en.groupPracticeNotConnected), findsWidgets);
    await identity.connect();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gp-retry')), findsNothing);
  });
}

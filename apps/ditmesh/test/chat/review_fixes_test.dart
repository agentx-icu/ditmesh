import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/training_controller_host.dart';
import 'package:ditmesh/ui/chat/conversation_list.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/chat/search/message_bookmarks.dart';
import 'package:ditmesh/ui/chat/search/message_search_screen.dart';
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

String get _id => 'c2c_$kPeerKey';

/// 300 inbound rows, one minute apart; row 100 is the needle.
ChatHarness _seeded() {
  final h = ChatHarness();
  h.addAnn(withMessage: false);
  for (var i = 0; i < 300; i++) {
    h.service.receiveMessage(
      _id,
      i == 100 ? 'NEEDLE' : 'CQ $i',
      timestamp: DateTime(2026, 9, 30, 6).add(Duration(minutes: i)),
    );
  }
  return h;
}

Future<void> _jumpToNeedle(WidgetTester tester) async {
  await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatSearchMessages));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, 'needle');
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
  await tester.tap(find.text('NEEDLE'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a jumped window always offers the way back to the latest', (
    tester,
  ) async {
    final h = _seeded();
    await pumpChat(
      tester,
      (_) => ConversationScreen(target: _ann()),
      harness: h,
    );
    await _jumpToNeedle(tester);
    expect(find.text('NEEDLE'), findsOneWidget);
    expect(find.text(s.chatJumpToLatest), findsOneWidget);
    // Earlier history around the window loads (no failure).
    final earlier = find.byKey(const ValueKey('load-earlier'));
    if (earlier.evaluate().isNotEmpty) {
      await tester.tap(earlier);
      await tester.pumpAndSettle();
      expect(find.text(s.chatHistoryLoadFailed), findsNothing);
    }
    await tester.tap(find.text(s.chatJumpToLatest));
    await tester.pumpAndSettle();
    // The historical window is gone and the newest row is shown last.
    expect(find.text('NEEDLE'), findsNothing);
    expect(find.text('CQ 299'), findsOneWidget);
    expect(find.text(s.chatJumpToLatest), findsNothing);
  });

  testWidgets('arrivals while jumped are counted, not marked read', (
    tester,
  ) async {
    final h = _seeded();
    await pumpChat(
      tester,
      (_) => ConversationScreen(target: _ann()),
      harness: h,
    );
    await _jumpToNeedle(tester);
    h.service.receiveMessage(_id, 'NEW ONE');
    await tester.pumpAndSettle();
    expect(find.text(s.chatNewMessages(1)), findsOneWidget);
    // Scroll to the bottom of the historical window: not the live end.
    await tester.drag(
      find.byKey(const ValueKey('conversation-history')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(
      h.service.conversations.single.unreadCount,
      greaterThan(0),
      reason: 'the new message was never displayed',
    );
  });

  testWidgets('clearing a jumped conversation shows later arrivals', (
    tester,
  ) async {
    final h = _seeded();
    await pumpChat(
      tester,
      (_) => ConversationScreen(target: _ann()),
      harness: h,
    );
    await _jumpToNeedle(tester);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatClearHistory));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatClearHistory).last);
    await tester.pumpAndSettle();
    h.service.receiveMessage(_id, 'AFTER CLEAR');
    await tester.pumpAndSettle();
    expect(find.text('AFTER CLEAR'), findsOneWidget);
  });

  testWidgets('listen-only hides the received preview in the list', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final h = ChatHarness();
    h.settings.listenOnly = true;
    await pumpChat(tester, (h) {
      h.addAnn();
      return Scaffold(
        body: ConversationList(service: h.service, onOpen: (_) {}),
      );
    }, harness: h);
    expect(find.textContaining('CQ CQ DE ANN'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('CQ CQ DE ANN')), findsNothing);
    expect(find.text(s.chatListenOnlyPreview), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('practice needs an answer; unsupported text is confirmed', (
    tester,
  ) async {
    final t = await TestTraining.create(
      progress: TrainerProgress(currentLesson: 40),
    );
    late final TrainingControllerHost host;
    await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      h.service.receiveMessage(_id, 'CQ 你好');
      host = TrainingControllerHost(
        h.identity,
        factory: (_) async => t.controller,
      );
      return MultiProvider(
        providers: [
          Provider<TrainingControllerHost?>.value(value: host),
          Provider<LearnPlaybackFactory>.value(
            value: FakeLearnPlaybackFactory(),
          ),
        ],
        child: ConversationScreen(target: _ann()),
      );
    });
    addTearDown(host.dispose);
    // Practice: an empty copy cannot be submitted, so nothing is credited.
    await tester.tap(find.byTooltip(s.chatMessageLearnActions).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatPracticeMessage).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('chat-practice-confirm')));
    await tester.pumpAndSettle();
    final submit = tester.widget<ButtonStyleButton>(
      find.byKey(const ValueKey('chat-practice-submit')),
    );
    expect(submit.onPressed, isNull);
    expect(t.controller.progress.history, isEmpty);
  });

  testWidgets('a changed query never shows the old query results', (
    tester,
  ) async {
    final service = _GatedSearch();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: MessageSearchScreen(
          service: service,
          conversationId: 'c',
          peerKey: 'P',
          selfKey: 'ME',
          bookmarks: MessageBookmarks.memory(),
          hideText: false,
        ),
      ),
    );
    await tester.pump();
    expect(service.calls, hasLength(1));
    await tester.enterText(find.byType(TextField), 'new');
    await tester.pump();
    // The first scan is cancelled as soon as the query changes.
    expect(service.cancels.first!.isCancelled, isTrue);
    service.calls.first.$2.complete(
      MessageSearchPage(results: [_msg('old', 'OLD RESULT')]),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('OLD RESULT'), findsNothing);
    expect(service.calls.last.$1.text, 'new');
    service.calls.last.$2.complete(
      MessageSearchPage(results: [_msg('n', 'NEW RESULT')]),
    );
    await tester.pumpAndSettle();
    expect(find.text('NEW RESULT'), findsOneWidget);
  });

  group('MessageBookmarks', () {
    test('memory store toggles and drops missing references', () async {
      final b = MessageBookmarks.memory();
      await b.toggle('c', 'm1', DateTime(2026));
      await b.toggle('c', 'm2', DateTime(2026));
      await b.removeMissing('c', {'m1'});
      expect(b.contains('c', 'm1'), isFalse);
      expect(b.contains('c', 'm2'), isTrue);
    });

    test('retired stores ignore late writes', () async {
      final dir = await Directory.systemTemp.createTemp('ditmesh_bm_');
      addTearDown(() => dir.delete(recursive: true));
      final a = MessageBookmarks.forProfile(dir.path, 'A');
      await a.load();
      await a.toggle('c', 'm1', DateTime(2026));
      await MessageBookmarks.retireAll();
      await a.toggle('c', 'm2', DateTime(2026));
      final b = MessageBookmarks.forProfile(dir.path, 'A');
      expect(identical(a, b), isFalse);
      await b.load();
      expect(b.contains('c', 'm1'), isTrue);
      expect(b.contains('c', 'm2'), isFalse);
      await MessageBookmarks.retireAll();
    });
  });
}

/// Answers each search only when the test releases it.
final class _GatedSearch implements ChatService {
  final List<(MessageSearchQuery, Completer<MessageSearchPage>)> calls = [];
  final List<MessageSearchCancel?> cancels = [];

  @override
  Future<MessageSearchPage> searchMessages(
    String conversationId,
    MessageSearchQuery query, {
    MessageSearchCursor? cursor,
    int limit = 20,
    MessageSearchCancel? cancel,
  }) {
    final c = Completer<MessageSearchPage>();
    calls.add((query, c));
    cancels.add(cancel);
    return c.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ChatMessage _msg(String id, String text) => ChatMessage(
  id: id,
  conversationId: 'c',
  senderId: 'P',
  text: text,
  timestamp: DateTime(2026),
  status: MessageStatus.received,
  isMine: false,
);

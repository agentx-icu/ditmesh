import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/chat/search/message_search_screen.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'test_support.dart';

ConversationTarget _ann() => ConversationTarget(
  id: 'c2c_$kPeerKey',
  title: 'Ann',
  kind: ConversationKind.c2c,
);

String get _id => 'c2c_$kPeerKey';

/// 80 inbound rows, one minute apart; the needle is the oldest.
ChatHarness _seeded() {
  final h = ChatHarness();
  h.addAnn(withMessage: false);
  for (var i = 0; i < 80; i++) {
    h.service.receiveMessage(
      _id,
      i == 0 ? 'NEEDLE QTH PARIS' : 'CQ $i',
      timestamp: DateTime(2026, 9, 30, 8).add(Duration(minutes: i)),
    );
  }
  return h;
}

Future<void> _menu(WidgetTester tester, String messageText, String item) async {
  final bubble = find.ancestor(
    of: find.text(messageText),
    matching: find.byType(Material),
  );
  await tester.tap(
    find.descendant(of: bubble.first, matching: find.byIcon(Icons.more_vert)),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('search finds unloaded history and jumps there', (tester) async {
    final h = _seeded();
    await pumpChat(
      tester,
      (_) => ConversationScreen(target: _ann()),
      harness: h,
    );
    expect(find.text('NEEDLE QTH PARIS'), findsNothing, reason: 'not loaded');
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatSearchMessages));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'needle');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('NEEDLE QTH PARIS'), findsOneWidget);
    await tester.tap(find.text('NEEDLE QTH PARIS'));
    await tester.pumpAndSettle();
    expect(find.byType(MessageSearchScreen), findsNothing);
    expect(find.text('NEEDLE QTH PARIS'), findsOneWidget);
    // A live arrival while looking at old history offers the latest.
    h.service.receiveMessage(_id, 'NEW ONE');
    await tester.pumpAndSettle();
    expect(find.text('NEW ONE'), findsNothing);
  });

  testWidgets('equal timestamps page without loss or repeats', (tester) async {
    final h = ChatHarness();
    h.addAnn(withMessage: false);
    final at = DateTime(2026, 9, 30, 9);
    for (var i = 0; i < 45; i++) {
      h.service.receiveMessage(_id, 'SAME $i', timestamp: at);
    }
    final seen = <String>{};
    MessageSearchCursor? cursor;
    do {
      final page = await h.service.searchMessages(
        _id,
        const MessageSearchQuery(text: 'same'),
        cursor: cursor,
      );
      for (final m in page.results) {
        expect(seen.add(m.id), isTrue);
      }
      cursor = page.next;
    } while (cursor != null);
    expect(seen, hasLength(45));
    await h.dispose();
  });

  testWidgets('listen-only hides search result text until revealed', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final h = _seeded();
    h.settings.listenOnly = true;
    await pumpChat(
      tester,
      (_) => ConversationScreen(target: _ann()),
      harness: h,
    );
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatSearchMessages));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'needle');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.textContaining('NEEDLE'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('NEEDLE')), findsNothing);
    final search = find.byType(MessageSearchScreen);
    await tester.tap(
      find.descendant(of: search, matching: find.text(s.chatReveal)),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: search, matching: find.text('NEEDLE QTH PARIS')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('bookmarks show, filter, and vanish with cleared history', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.addAnn();
      return ConversationScreen(target: _ann());
    });
    await _menu(tester, 'CQ CQ DE ANN', s.chatAddBookmark);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatSearchMessages));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatSearchBookmarked));
    await tester.pumpAndSettle();
    expect(find.text('CQ CQ DE ANN'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatClearHistory));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatClearHistory).last);
    await tester.pumpAndSettle();
    h.service.receiveMessage(_id, 'CQ AGAIN');
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bookmark), findsNothing);
  });

  testWidgets('a queued send can be cancelled; a claimed one cannot', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return ConversationScreen(target: _ann());
    });
    final a = await h.service.sendText(_id, 'FIRST');
    final b = await h.service.sendText(_id, 'SECOND');
    expect(a.status, MessageStatus.pending);
    await tester.pumpWidget(h.wrap(const SizedBox()));
    await tester.pumpWidget(h.wrap(ConversationScreen(target: _ann())));
    await tester.pumpAndSettle();
    await _menu(tester, 'FIRST', s.chatCancelSend);
    expect(find.text(s.chatSendCancelled), findsOneWidget);
    final rows = await h.service.loadHistory(_id);
    expect(
      rows.firstWhere((m) => m.id == a.id).status,
      MessageStatus.cancelled,
    );
    expect(rows.where((m) => m.text == 'FIRST'), hasLength(1));

    h.service.claimMessage(b.id);
    await tester.pumpAndSettle();
    // Sending: no cancel offered any more; failed: retry keeps one row.
    h.service.failMessage(b.id);
    await tester.pumpAndSettle();
    await _menu(tester, 'SECOND', s.chatRetrySend);
    expect(find.text(s.chatRetryQueued), findsOneWidget);
    final after = await h.service.loadHistory(_id);
    expect(after.where((m) => m.text == 'SECOND'), hasLength(1));
    expect(after.firstWhere((m) => m.id == b.id).status, MessageStatus.pending);
  });

  testWidgets('the note to self offers no retry or cancel', (tester) async {
    final h = ChatHarness();
    final selfId = h.service.selfConversationId;
    if (selfId == null) {
      await h.dispose();
      return;
    }
    await pumpChat(
      tester,
      (_) => ConversationScreen(
        target: ConversationTarget.self(id: selfId, title: 'Me'),
      ),
      harness: h,
    );
    await h.service.sendText(selfId, 'NOTE');
    await tester.pumpWidget(h.wrap(const SizedBox()));
    await tester.pumpWidget(
      h.wrap(
        ConversationScreen(
          target: ConversationTarget.self(id: selfId, title: 'Me'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    expect(find.text(s.chatRetrySend), findsNothing);
    expect(find.text(s.chatCancelSend), findsNothing);
  });
}

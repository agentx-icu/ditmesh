import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/message_status_icon.dart';
import 'package:ditmesh/ui/chat/pending_messages_page.dart';
import 'package:ditmesh/ui/pages/chat_page.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'test_support.dart';

class _LateConversations implements ChatService {
  _LateConversations(this.delegate);
  final ChatService delegate;
  final changes = StreamController<List<Conversation>>.broadcast();
  bool visible = false;
  void expose() {
    visible = true;
    changes.add(conversations);
  }

  @override
  List<Conversation> get conversations => visible ? delegate.conversations : [];
  @override
  Stream<List<Conversation>> get conversationChanges => changes.stream;
  @override
  Stream<bool> get sessionChanges => const Stream.empty();
  @override
  bool get hasSession => true;
  @override
  Stream<ChatMessage> get messageEvents => delegate.messageEvents;
  @override
  bool get supportsSendControl => false;
  @override
  Future<MessageSearchPage> searchMessages(
    String conversationId,
    MessageSearchQuery query, {
    MessageSearchCursor? cursor,
    int limit = 50,
    MessageSearchCancel? cancel,
  }) => delegate.searchMessages(
    conversationId,
    query,
    cursor: cursor,
    limit: limit,
    cancel: cancel,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('delivery update between tap and sheet mount is retained', (
    tester,
  ) async {
    final h = ChatHarness()..addAnn(withMessage: false);
    final queued = await h.service.sendText('c2c_$kPeerKey', 'CQ');
    await pumpChat(
      tester,
      (_) => Scaffold(body: MessageStatusIcon(queued.status, message: queued)),
      harness: h,
    );
    await tester.tap(find.byIcon(Icons.schedule));
    h.service.setFriendOnline(kPeerKey, true);
    await tester.pumpAndSettle();
    expect(find.text(s.deliverySentDetail), findsOneWidget);
    expect(find.textContaining(s.deliveryPeerOffline), findsNothing);
  });

  ChatMessage message(MessageStatus status, String conversationId) =>
      ChatMessage(
        id: 'status-example',
        conversationId: conversationId,
        senderId: kSelfKey,
        text: 'CQ',
        timestamp: DateTime(2026, 10, 9),
        status: status,
        isMine: true,
      );

  testWidgets('pending history loads when conversations arrive after session', (
    tester,
  ) async {
    final h = ChatHarness()..addAnn(withMessage: false);
    final queued = await h.service.sendText('c2c_$kPeerKey', 'CQ');
    final late = _LateConversations(h.service);
    addTearDown(late.changes.close);
    await pumpChat(
      tester,
      (_) => PendingMessagesPage(service: late),
      harness: h,
    );
    expect(find.byKey(ValueKey('pending-row-${queued.id}')), findsNothing);
    late.expose();
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('pending-row-${queued.id}')), findsOneWidget);
  });

  testWidgets(
    'open pending detail follows peer presence without status event',
    (tester) async {
      final m = message(MessageStatus.pending, 'c2c_$kPeerKey');
      final h = await pumpChat(tester, (h) {
        h.addAnn(withMessage: false);
        return Scaffold(body: MessageStatusIcon(m.status, message: m));
      });
      await tester.tap(find.byIcon(Icons.schedule));
      await tester.pumpAndSettle();
      expect(find.textContaining(s.deliveryPeerOffline), findsOneWidget);
      h.service.setFriendOnline(kPeerKey, true);
      await tester.pumpAndSettle();
      expect(find.textContaining(s.deliveryPeerOffline), findsNothing);
      expect(find.text(s.messageStatusPendingDetail), findsOneWidget);
    },
  );

  testWidgets('self note details describe local storage', (tester) async {
    final m = message(MessageStatus.sent, 'c2c_$kSelfKey');
    await pumpChat(
      tester,
      (_) => Scaffold(body: MessageStatusIcon(m.status, message: m)),
    );
    expect(find.byTooltip(s.deliveryLocalTitle), findsOneWidget);
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();
    expect(find.text(s.deliveryLocalDetail), findsOneWidget);
    expect(find.text(s.deliverySentDetail), findsNothing);
  });

  testWidgets('group confirmation explicitly describes at least one receiver', (
    tester,
  ) async {
    final m = message(MessageStatus.delivered, 'group_tox_1');
    await pumpChat(
      tester,
      (_) => Scaffold(body: MessageStatusIcon(m.status, message: m)),
    );
    expect(find.byTooltip(s.deliveryGroupTitle), findsOneWidget);
    await tester.tap(find.byIcon(Icons.done_all));
    await tester.pumpAndSettle();
    expect(find.text(s.deliveryGroupDetail), findsOneWidget);
  });

  testWidgets('failed queued message retries under the same id', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return const ChatPage();
    });
    final failed = await h.service.sendText('c2c_$kPeerKey', 'CQ');
    h.service.failMessage(failed.id);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pending-messages-open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('pending-retry-${failed.id}')));
    await tester.pumpAndSettle();
    final rows = await h.service.loadHistory('c2c_$kPeerKey');
    expect(rows, hasLength(1));
    expect(rows.single.id, failed.id);
    expect(rows.single.status, MessageStatus.pending);
  });

  testWidgets('tapping a queued status opens accessible delivery details', (
    tester,
  ) async {
    await pumpChat(
      tester,
      (_) => const Scaffold(body: MessageStatusIcon(MessageStatus.pending)),
    );
    await tester.tap(find.byIcon(Icons.schedule));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('delivery-details')), findsOneWidget);
  });

  testWidgets(
    'pending list shows old queue rows and cancels without another bubble',
    (tester) async {
      final h = await pumpChat(tester, (h) {
        h.addAnn(withMessage: false);
        return const ChatPage();
      });
      final queued = await h.service.sendText('c2c_$kPeerKey', 'CQ');
      for (var i = 0; i < 55; i++) {
        h.service.receiveMessage('c2c_$kPeerKey', 'TEST $i');
      }
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pending-messages-open')));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('pending-row-${queued.id}')), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('pending-cancel-${queued.id}')));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('pending-row-${queued.id}')), findsNothing);
      final history = await h.service.loadAround('c2c_$kPeerKey', queued.id);
      expect(
        history.where((m) => m.id == queued.id).single.status,
        MessageStatus.cancelled,
      );
    },
  );

  testWidgets('pending list removes a delivered row on a live event', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return const ChatPage();
    });
    final queued = await h.service.sendText('c2c_$kPeerKey', 'CQ');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pending-messages-open')));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('pending-row-${queued.id}')), findsOneWidget);
    h.service.setFriendOnline(kPeerKey, true);
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('pending-row-${queued.id}')), findsNothing);
  });
}

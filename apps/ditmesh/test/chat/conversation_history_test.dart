import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/chat/conversation_timeline.dart';
import 'package:ditmesh/ui/chat/message_bubble.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import 'test_support.dart';

class _HistoryService implements ChatService {
  _HistoryService(this.delegate);
  final ChatService delegate;

  @override
  Set<String> get blockedPeers => delegate.blockedPeers;
  @override
  Stream<Set<String>> get blockedPeerChanges => delegate.blockedPeerChanges;
  @override
  Future<void> blockPeer(String publicKey) => delegate.blockPeer(publicKey);
  @override
  Future<void> unblockPeer(String publicKey) => delegate.unblockPeer(publicKey);
  final List<int> requests = [];
  Completer<void>? loadGate;
  Completer<void>? clearGate;
  Completer<void>? sendGate;
  bool failLoad = false;
  bool failClear = false;
  bool readAfterGate = false;
  bool createBeforeSendGate = false;
  int clears = 0;

  @override
  Future<List<ChatMessage>> loadHistory(
    String id, {
    int limit = 50,
    DateTime? before,
  }) async {
    requests.add(limit);
    final snapshot = readAfterGate
        ? null
        : await delegate.loadHistory(id, limit: limit, before: before);
    await loadGate?.future;
    if (failLoad) throw StateError('history unavailable');
    return snapshot ??
        await delegate.loadHistory(id, limit: limit, before: before);
  }

  @override
  Future<void> clearHistory(String id) async {
    clears++;
    if (failClear) throw StateError('storage unavailable');
    await delegate.clearHistory(id);
    await clearGate?.future;
  }

  @override
  List<Friend> get friends => delegate.friends;
  @override
  Stream<List<Friend>> get friendChanges => delegate.friendChanges;
  @override
  List<Group> get groups => delegate.groups;
  @override
  Stream<List<Group>> get groupChanges => delegate.groupChanges;
  @override
  List<Conversation> get conversations => delegate.conversations;
  @override
  Stream<ChatMessage> get messageEvents => delegate.messageEvents;
  @override
  int get maxMessageBytes => delegate.maxMessageBytes;
  @override
  Future<void> markRead(String id) => delegate.markRead(id);
  @override
  Future<void> setDraft(String id, String draft) =>
      delegate.setDraft(id, draft);
  @override
  Future<ChatMessage> sendText(String id, String text) async {
    final row = createBeforeSendGate ? await delegate.sendText(id, text) : null;
    await sendGate?.future;
    return row ?? await delegate.sendText(id, text);
  }

  @override
  bool get supportsSendControl => delegate.supportsSendControl;

  @override
  bool get hasSession => delegate.hasSession;

  @override
  Stream<bool> get sessionChanges => delegate.sessionChanges;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final id = 'c2c_$kPeerKey';
  ConversationTarget target() =>
      ConversationTarget(id: id, title: 'Ann', kind: ConversationKind.c2c);

  Future<(ChatHarness, _HistoryService)> setup(
    WidgetTester t, {
    int count = 80,
  }) async {
    final h = ChatHarness()..addAnn(withMessage: false);
    for (var i = 0; i < count; i++) {
      h.service.receiveMessage(id, 'HISTORY $i ${'CQ ' * (i % 4)}');
    }
    final service = _HistoryService(h.service);
    await pumpChat(
      t,
      (_) => Provider<ChatService>.value(
        value: service,
        child: ConversationScreen(target: target()),
      ),
      harness: h,
    );
    return (h, service);
  }

  ScrollPosition position(WidgetTester t) =>
      t.state<ScrollableState>(find.byType(Scrollable).first).position;

  Future<void> top(WidgetTester t) async {
    for (var i = 0; i < 6; i++) {
      position(t).jumpTo(position(t).minScrollExtent);
      await t.pumpAndSettle();
    }
  }

  Future<void> openClear(WidgetTester t) async {
    await t.tap(find.byType(PopupMenuButton<String>));
    await t.pump();
    await t.pump(const Duration(milliseconds: 350));
    await t.tap(find.text(s.chatClearHistory));
    await t.pump();
    await t.pump(const Duration(milliseconds: 350));
  }

  testWidgets(
    'unloaded own status updates stay historical and never duplicate',
    (t) async {
      final h = ChatHarness()..addAnn(withMessage: false);
      final oldest = await h.service.sendText(id, 'OLDEST PENDING');
      for (var i = 0; i < 80; i++) {
        h.service.receiveMessage(id, 'HISTORY $i');
      }
      await pumpChat(
        t,
        (_) => ConversationScreen(target: target()),
        harness: h,
      );
      h.service.setFriendOnline(kPeerKey, true);
      await t.pumpAndSettle();
      expect(find.text('OLDEST PENDING'), findsNothing);
      await top(t);
      final view = t.widget<ConversationTimeline>(
        find.byType(ConversationTimeline),
      );
      final rows = [...view.older, ...view.messages];
      expect(rows.where((m) => m.id == oldest.id), hasLength(1));
      expect(
        rows.singleWhere((m) => m.id == oldest.id).status,
        MessageStatus.sent,
      );
      expect(view.messages.any((m) => m.id == oldest.id), isFalse);
    },
  );

  testWidgets(
    'live arrivals during a late history read cannot evict loaded records',
    (t) async {
      final (h, service) = await setup(t, count: 200);
      position(t).jumpTo(position(t).minScrollExtent);
      await t.pumpAndSettle();
      final first = t.widget<ConversationTimeline>(
        find.byType(ConversationTimeline),
      );
      final before = first.older.map((m) => m.id).toSet();
      expect(before, isNotEmpty);
      service
        ..readAfterGate = true
        ..loadGate = Completer<void>();
      position(t).jumpTo(position(t).minScrollExtent);
      await t.pump();
      final anchor = find
          .byType(MessageBubble)
          .evaluate()
          .firstWhere((e) {
            final y = t.getTopLeft(find.byKey(e.widget.key!)).dy;
            return y >= 60 && y < 500;
          })
          .widget
          .key!;
      final offset = t.getTopLeft(find.byKey(anchor));
      for (var i = 0; i < 60; i++) {
        h.service.receiveMessage(id, 'LIVE $i');
      }
      await t.pump();
      service.loadGate!.complete();
      await t.pumpAndSettle();
      final view = t.widget<ConversationTimeline>(
        find.byType(ConversationTimeline),
      );
      final ids = [...view.older, ...view.messages].map((m) => m.id).toList();
      expect(ids.toSet().containsAll(before), isTrue);
      expect(ids.toSet(), hasLength(ids.length));
      expect(t.getTopLeft(find.byKey(anchor)), offset);
    },
  );

  testWidgets(
    'a displaced origin expands the window without moving the reader',
    (t) async {
      final (h, service) = await setup(t, count: 200);
      position(t).jumpTo(position(t).minScrollExtent);
      await t.pumpAndSettle();
      service
        ..readAfterGate = true
        ..loadGate = Completer<void>();
      position(t).jumpTo(position(t).minScrollExtent);
      await t.pump();
      final anchor = find
          .byType(MessageBubble)
          .evaluate()
          .firstWhere((e) {
            final y = t.getTopLeft(find.byKey(e.widget.key!)).dy;
            return y >= 60 && y < 500;
          })
          .widget
          .key!;
      final offset = t.getTopLeft(find.byKey(anchor));
      for (var i = 0; i < 200; i++) {
        h.service.receiveMessage(id, 'BURST $i');
      }
      await t.pump();
      service.loadGate!.complete();
      await t.pumpAndSettle();
      expect(service.requests.last, greaterThan(150));
      expect(t.getTopLeft(find.byKey(anchor)), offset);
      expect(find.byKey(const ValueKey('load-earlier')), findsNothing);
    },
  );

  testWidgets('a send from an older route appears once in the newer route', (
    t,
  ) async {
    final (h, service) = await setup(t, count: 3);
    service.sendGate = Completer<void>();
    await keyIn(t, 'MY NEW SEND');
    await t.pump();
    await t.tap(find.byTooltip(s.chatSend));
    final nav = t.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => Provider<ChatService>.value(
            value: service,
            child: ConversationScreen(target: target()),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await keyIn(t, 'NEWER DRAFT');
    await t.pump(const Duration(milliseconds: 450));
    service.sendGate!.complete();
    await t.pumpAndSettle();
    expect(find.text('MY NEW SEND'), findsOneWidget);
    expect(
      t.widget<TextField>(find.byType(TextField)).controller!.text,
      'NEWER DRAFT',
    );
    nav.pop();
    await t.pumpAndSettle();
    expect(find.text('MY NEW SEND'), findsOneWidget);
    expect(
      h.service.conversations.singleWhere((c) => c.id == id).draft,
      'NEWER DRAFT',
    );
  });

  testWidgets(
    'a cleared outgoing row cannot return when its send future finishes',
    (t) async {
      final (h, service) = await setup(t, count: 3);
      service
        ..createBeforeSendGate = true
        ..sendGate = Completer<void>();
      await keyIn(t, 'CLEARED SEND');
      await t.pump();
      await t.tap(find.byTooltip(s.chatSend));
      await t.pump();
      await openClear(t);
      await t.tap(find.widgetWithText(FilledButton, s.chatClearHistory));
      await t.pump();
      await t.pump(const Duration(milliseconds: 350));
      service.sendGate!.complete();
      await t.pumpAndSettle();
      expect(await h.service.loadHistory(id), isEmpty);
      expect(find.text(s.chatNoMessages), findsOneWidget);
      expect(find.text('CLEARED SEND'), findsNothing);
    },
  );

  testWidgets(
    'clear completion after closing still rejects a deleted send in a new route',
    (t) async {
      final (h, service) = await setup(t, count: 3);
      service
        ..createBeforeSendGate = true
        ..sendGate = Completer<void>();
      await keyIn(t, 'DELETED SEND');
      await t.pump();
      await t.tap(find.byTooltip(s.chatSend));
      await t.pump();
      service.clearGate = Completer<void>();
      await openClear(t);
      await t.tap(find.widgetWithText(FilledButton, s.chatClearHistory));
      await t.pump();
      await t.pumpWidget(h.wrap(const SizedBox()));
      await t.pumpWidget(
        h.wrap(
          Provider<ChatService>.value(
            value: service,
            child: ConversationScreen(target: target()),
          ),
        ),
      );
      await t.pumpAndSettle();
      service.clearGate!.complete();
      await t.pump();
      service.sendGate!.complete();
      await t.pumpAndSettle();
      expect(await h.service.loadHistory(id), isEmpty);
      expect(find.text(s.chatNoMessages), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('loading earlier records preserves a visible bubble position', (
    t,
  ) async {
    final (_, service) = await setup(t);
    service.loadGate = Completer<void>();
    position(t).jumpTo(position(t).minScrollExtent);
    await t.pump();
    final anchor = find
        .byType(MessageBubble)
        .evaluate()
        .firstWhere((e) {
          final y = t.getTopLeft(find.byKey(e.widget.key!)).dy;
          return y >= 60 && y < 500;
        })
        .widget
        .key!;
    final before = t.getTopLeft(find.byKey(anchor));
    expect(service.requests.length, 2);
    service.loadGate!.complete();
    await t.pumpAndSettle();
    expect(t.getTopLeft(find.byKey(anchor)), before);
  });

  testWidgets('initial history merges arrivals and newer delivery status', (
    t,
  ) async {
    final h = ChatHarness()..addAnn(withMessage: false);
    await h.service.sendText(id, 'PENDING');
    final service = _HistoryService(h.service)..loadGate = Completer<void>();
    addTearDown(h.dispose);
    await t.pumpWidget(
      h.wrap(
        Provider<ChatService>.value(
          value: service,
          child: ConversationScreen(target: target()),
        ),
      ),
    );
    await t.pump();
    h.service.setFriendOnline(kPeerKey, true);
    h.service.receiveMessage(id, 'DURING LOAD');
    await t.pump();
    service.loadGate!.complete();
    await t.pumpAndSettle();
    expect(find.text('DURING LOAD'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsNothing);
  });

  testWidgets('finishing history after closing the screen is safe', (t) async {
    final h = ChatHarness()..addAnn();
    final service = _HistoryService(h.service)..loadGate = Completer<void>();
    addTearDown(h.dispose);
    await t.pumpWidget(
      h.wrap(
        Provider<ChatService>.value(
          value: service,
          child: ConversationScreen(target: target()),
        ),
      ),
    );
    await t.pump();
    await t.pumpWidget(h.wrap(const SizedBox()));
    service.loadGate!.complete();
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets('a failed clear during initial load still restores history', (
    t,
  ) async {
    final h = ChatHarness()..addAnn();
    final service = _HistoryService(h.service)
      ..loadGate = Completer<void>()
      ..failClear = true;
    addTearDown(h.dispose);
    await t.pumpWidget(
      h.wrap(
        Provider<ChatService>.value(
          value: service,
          child: ConversationScreen(target: target()),
        ),
      ),
    );
    await t.pump();
    await openClear(t);
    await t.tap(find.widgetWithText(FilledButton, s.chatClearHistory));
    await t.pump();
    service.loadGate!.complete();
    await t.pumpAndSettle();
    expect(find.text('CQ CQ DE ANN'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('older history is reachable even with tied timestamps', (
    t,
  ) async {
    final (_, service) = await setup(t, count: 175);
    await top(t);
    // Clicking the entry also works when automatic loading is not triggered.
    if (find.byKey(const ValueKey('load-earlier')).evaluate().isNotEmpty) {
      await t.tap(find.byKey(const ValueKey('load-earlier')));
      await t.pumpAndSettle();
    }
    await top(t);
    expect(service.requests.any((limit) => limit >= 200), isTrue);
    expect(find.text('HISTORY 0 '), findsOneWidget);
  });

  testWidgets(
    'incoming messages preserve a reader anchor until entry is tapped',
    (t) async {
      final (h, _) = await setup(t);
      await t.drag(find.byType(Scrollable).first, const Offset(0, 900));
      await t.pumpAndSettle();
      final anchor = find
          .byType(MessageBubble)
          .evaluate()
          .firstWhere((e) {
            final y = t.getTopLeft(find.byKey(e.widget.key!)).dy;
            return y >= 60 && y < 500;
          })
          .widget
          .key!;
      final before = t.getTopLeft(find.byKey(anchor));
      h.service.receiveMessage(id, 'NEW INBOUND');
      await t.pumpAndSettle();
      expect(t.getTopLeft(find.byKey(anchor)), before);
      expect(find.byKey(const ValueKey('new-messages')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('new-messages')));
      await t.pumpAndSettle();
      expect(find.text('NEW INBOUND'), findsOneWidget);
      expect(find.byKey(const ValueKey('new-messages')), findsNothing);
    },
  );

  testWidgets('messages follow the bottom and explicit sends return to it', (
    t,
  ) async {
    final (h, _) = await setup(t);
    h.service.receiveMessage(id, 'AT BOTTOM');
    await t.pumpAndSettle();
    expect(find.text('AT BOTTOM'), findsOneWidget);
    await t.drag(find.byType(Scrollable).first, const Offset(0, 900));
    await t.pumpAndSettle();
    await keyIn(t, 'MY SEND');
    await t.pump();
    await t.tap(find.byTooltip(s.chatSend));
    await t.pumpAndSettle();
    expect(find.text('MY SEND'), findsOneWidget);
    expect(position(t).extentAfter, lessThan(1));
  });

  testWidgets('clear requires confirmation and cancel keeps all history', (
    t,
  ) async {
    final (_, service) = await setup(t, count: 3);
    await openClear(t);
    expect(service.clears, 0);
    expect(find.byType(AlertDialog), findsOneWidget);
    await t.tap(find.text(s.actionCancel));
    await t.pumpAndSettle();
    expect(service.clears, 0);
    expect(find.byType(MessageBubble), findsNWidgets(3));
    await openClear(t);
    await t.tap(find.widgetWithText(FilledButton, s.chatClearHistory));
    await t.pumpAndSettle();
    expect(service.clears, 1);
    expect(find.text(s.chatNoMessages), findsOneWidget);
  });

  testWidgets('failed clear preserves history and reports an error', (t) async {
    final (_, service) = await setup(t, count: 3);
    service.failClear = true;
    await openClear(t);
    await t.tap(find.widgetWithText(FilledButton, s.chatClearHistory));
    await t.pumpAndSettle();
    expect(find.byType(MessageBubble), findsNWidgets(3));
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('group history uses the same explicit clear confirmation', (
    t,
  ) async {
    final h = ChatHarness();
    final group = await h.service.createGroup('CQ GROUP');
    h.service.receiveMessage('group_${group.id}', 'GROUP RECORD');
    final service = _HistoryService(h.service);
    await pumpChat(
      t,
      (_) => Provider<ChatService>.value(
        value: service,
        child: ConversationScreen(target: ConversationTarget.fromGroup(group)),
      ),
      harness: h,
    );
    await openClear(t);
    expect(service.clears, 0);
    await t.tap(find.widgetWithText(FilledButton, s.chatClearHistory));
    await t.pumpAndSettle();
    expect(service.clears, 1);
    expect(find.text(s.chatNoMessages), findsOneWidget);
  });

  testWidgets('failed older loads leave records and can be retried', (t) async {
    final (_, service) = await setup(t);
    service.failLoad = true;
    await top(t);
    expect(find.byType(MessageBubble), findsWidgets);
    expect(find.byKey(const ValueKey('load-earlier')), findsOneWidget);
    service.failLoad = false;
    await t.tap(find.byKey(const ValueKey('load-earlier')));
    await t.pumpAndSettle();
    await top(t);
    expect(find.text('HISTORY 0 '), findsOneWidget);
  });

  testWidgets(
    'clear rejects pending history and preserves post-clear arrivals',
    (t) async {
      final (h, service) = await setup(t);
      service.loadGate = Completer<void>();
      position(t).jumpTo(position(t).minScrollExtent);
      await t.pump();
      await openClear(t);
      service.clearGate = Completer<void>();
      await t.tap(find.widgetWithText(FilledButton, s.chatClearHistory));
      await t.pumpAndSettle();
      h.service.receiveMessage(id, 'AFTER CLEAR');
      await t.pump();
      service.clearGate!.complete();
      service.loadGate!.complete();
      await t.pumpAndSettle();
      expect(find.text('AFTER CLEAR'), findsOneWidget);
      expect(find.textContaining('HISTORY'), findsNothing);
    },
  );

  testWidgets('a reload after paging still offers earlier history (M6)', (
    t,
  ) async {
    const String gid = 'group_tox_1';
    final String member = 'C' * 64;
    final String blocked = 'D' * 64;
    final h = ChatHarness();
    h.service.addFakeGroup(
      const Group(id: 'tox_1', name: 'Net', kind: GroupKind.group),
    );
    for (var i = 0; i < 120; i++) {
      h.service.receiveMessage(gid, 'NET $i', senderId: member);
    }
    final service = _HistoryService(h.service);
    await pumpChat(
      t,
      (_) => Provider<ChatService>.value(
        value: service,
        child: ConversationScreen(
          target: ConversationTarget(
            id: gid,
            title: 'Net',
            kind: ConversationKind.group,
          ),
        ),
      ),
      harness: h,
    );
    expect(service.requests.toSet(), {50}, reason: 'latest page only');
    service.requests.clear();
    position(t).jumpTo(position(t).minScrollExtent);
    await t.pumpAndSettle();
    expect(service.requests, [100]);
    // An unblock reloads the latest page (the same path as jumping back
    // from a search result or the session-start retry).
    await service.blockPeer(blocked);
    await t.pumpAndSettle();
    await service.unblockPeer(blocked);
    await t.pumpAndSettle();
    expect(service.requests, [100, 50]);
    position(t).jumpTo(position(t).minScrollExtent);
    await t.pumpAndSettle();
    expect(service.requests, [
      100,
      50,
      100,
    ], reason: '"load earlier" survives the reload');
  });
}

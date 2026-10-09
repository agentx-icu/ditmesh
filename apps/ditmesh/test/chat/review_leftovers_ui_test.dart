import 'dart:async';

import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/chat/conversation_tile.dart';
import 'package:ditmesh/ui/chat/search/message_bookmarks.dart';
import 'package:ditmesh/ui/chat/search/message_search_screen.dart';
import 'package:ditmesh/ui/groups/group_join_feedback.dart';
import 'package:ditmesh/ui/pages/groups_page.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'test_support.dart';

/// Low findings of the 2026-10-08 chat review in the conversation UI:
/// search jumps and their page loads (L1 / L2), the search date filter
/// (L3), the conversation menu's accessible name (L4), and draft save
/// failures (L5).

/// Records the rejoins a retry makes.
final class _Rejoins implements ChatService {
  final List<(String, String?)> calls = [];
  @override
  Future<void> rejoinGroup(String groupId, {String? password}) async =>
      calls.add((groupId, password));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// [FakeChatService] behind gates the test opens.
class _Gated implements ChatService {
  _Gated(this.d);
  final FakeChatService d;

  Completer<void>? historyGate;
  bool failHistory = false;

  /// Each loadAround call waits on the next queued gate, if any.
  final List<Completer<void>> aroundGates = [];
  bool emptyAround = false;

  /// Later-rows reads (`after > 0`) throw while set.
  bool failNewer = false;
  int newerCalls = 0;

  bool failDraft = false;
  int draftCalls = 0;

  @override
  Future<List<ChatMessage>> loadHistory(
    String id, {
    int limit = 50,
    DateTime? before,
  }) async {
    final rows = await d.loadHistory(id, limit: limit, before: before);
    await historyGate?.future;
    if (failHistory) throw StateError('history unavailable');
    return rows;
  }

  @override
  Future<List<ChatMessage>> loadAround(
    String id,
    String messageId, {
    int before = 25,
    int after = 25,
  }) async {
    if (after > 0 && before == 0) {
      newerCalls++;
      if (failNewer) throw StateError('later rows unavailable');
    }
    final rows = await d.loadAround(
      id,
      messageId,
      before: before,
      after: after,
    );
    if (aroundGates.isNotEmpty) await aroundGates.removeAt(0).future;
    return emptyAround && after > 0 && before > 0 ? const [] : rows;
  }

  @override
  Future<void> setDraft(String id, String draft) async {
    draftCalls++;
    if (failDraft) throw StateError('disk full');
    return d.setDraft(id, draft);
  }

  @override
  Future<MessageSearchPage> searchMessages(
    String conversationId,
    MessageSearchQuery query, {
    MessageSearchCursor? cursor,
    int limit = 20,
    MessageSearchCancel? cancel,
  }) => d.searchMessages(
    conversationId,
    query,
    cursor: cursor,
    limit: limit,
    cancel: cancel,
  );

  @override
  Set<String> get blockedPeers => d.blockedPeers;
  @override
  Stream<Set<String>> get blockedPeerChanges => d.blockedPeerChanges;
  @override
  List<Friend> get friends => d.friends;
  @override
  Stream<List<Friend>> get friendChanges => d.friendChanges;
  @override
  List<Group> get groups => d.groups;
  @override
  Stream<List<Group>> get groupChanges => d.groupChanges;
  @override
  List<Conversation> get conversations => d.conversations;
  @override
  Stream<List<Conversation>> get conversationChanges => d.conversationChanges;
  @override
  Stream<ChatMessage> get messageEvents => d.messageEvents;
  @override
  int get maxMessageBytes => d.maxMessageBytes;
  @override
  Future<void> markRead(String id) => d.markRead(id);
  @override
  Future<ChatMessage> sendText(String id, String text) => d.sendText(id, text);
  @override
  bool get supportsSendControl => d.supportsSendControl;
  @override
  bool get hasSession => d.hasSession;
  @override
  Stream<bool> get sessionChanges => d.sessionChanges;
  @override
  String? get selfConversationId => d.selfConversationId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String get _id => 'c2c_$kPeerKey';

ConversationTarget _ann() =>
    ConversationTarget(id: _id, title: 'Ann', kind: ConversationKind.c2c);

/// 80 inbound rows a minute apart; NEEDLE A is the oldest, NEEDLE B the
/// 11th.
ChatHarness _seeded() {
  final h = ChatHarness()..addAnn(withMessage: false);
  for (var i = 0; i < 80; i++) {
    h.service.receiveMessage(
      _id,
      switch (i) {
        0 => 'NEEDLE A',
        10 => 'NEEDLE B',
        _ => 'CQ $i',
      },
      timestamp: DateTime(2026, 9, 30, 8).add(Duration(minutes: i)),
    );
  }
  return h;
}

Future<_Gated> _pump(
  WidgetTester t,
  ChatHarness h, {
  void Function(_Gated g)? before,
  Size size = kPhone,
}) async {
  final g = _Gated(h.service);
  before?.call(g);
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  addTearDown(h.dispose);
  await t.pumpWidget(
    h.wrap(
      Provider<ChatService>.value(
        value: g,
        child: ConversationScreen(target: _ann()),
      ),
    ),
  );
  await t.pump();
  return g;
}

/// Opens search from the overflow menu and picks the result [text].
Future<void> _jumpTo(WidgetTester t, String text) async {
  await t.tap(find.byType(PopupMenuButton<String>));
  await t.pump();
  await t.pump(const Duration(milliseconds: 350));
  await t.tap(find.text(s.chatSearchMessages));
  await t.pump();
  await t.pump(const Duration(milliseconds: 350));
  await t.enterText(find.byType(TextField).first, 'needle');
  await t.pump(const Duration(milliseconds: 400));
  await t.pump(const Duration(milliseconds: 50));
  await t.tap(
    find.descendant(
      of: find.byType(MessageSearchScreen),
      matching: find.text(text),
    ),
  );
  await t.pump();
  await t.pump(const Duration(milliseconds: 350));
}

void main() {
  tearDown(MessageBookmarks.retireAll);

  group('L1 search jumps', () {
    testWidgets('a jump that finds nothing does not strand the first load', (
      t,
    ) async {
      final h = _seeded();
      final gate = Completer<void>();
      final g = await _pump(
        t,
        h,
        before: (g) => g
          ..historyGate = gate
          ..emptyAround = true,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await _jumpTo(t, 'NEEDLE A');
      expect(find.text(s.chatMessageGone), findsOneWidget);
      gate.complete();
      g.historyGate = null;
      await t.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('CQ 79'), findsOneWidget);
    });

    testWidgets('of two overlapping jumps only the later one lands', (
      t,
    ) async {
      final h = _seeded();
      final g = await _pump(t, h);
      await t.pumpAndSettle();
      final first = Completer<void>();
      final second = Completer<void>();
      g.aroundGates.addAll([first, second]);
      await _jumpTo(t, 'NEEDLE A');
      await _jumpTo(t, 'NEEDLE B');
      second.complete();
      await t.pumpAndSettle();
      expect(find.text('NEEDLE B'), findsOneWidget);
      first.complete();
      await t.pumpAndSettle();
      expect(find.text('NEEDLE B'), findsOneWidget);
      expect(find.text('NEEDLE A'), findsNothing, reason: 'stale jump dropped');
    });

    testWidgets('a jump replaces a first load that failed meanwhile', (
      t,
    ) async {
      final h = _seeded();
      final gate = Completer<void>();
      final around = Completer<void>();
      final g = await _pump(
        t,
        h,
        before: (g) => g
          ..historyGate = gate
          ..failHistory = true
          ..aroundGates.add(around),
      );
      await _jumpTo(t, 'NEEDLE B');
      gate.complete();
      await t.pump();
      around.complete();
      g.failHistory = false;
      await t.pumpAndSettle();
      expect(find.text('NEEDLE B'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  testWidgets('L1 a stale later-rows read does not free the new one', (
    t,
  ) async {
    final h = _seeded();
    final g = await _pump(t, h);
    await t.pumpAndSettle();
    Future<void> toEnd() async {
      final ScrollPosition position = t
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      position.jumpTo(position.maxScrollExtent - 1);
      await t.pump();
      position.jumpTo(position.maxScrollExtent);
      await t.pump();
    }

    await _jumpTo(t, 'NEEDLE A');
    await t.pumpAndSettle();
    final staleNewer = Completer<void>();
    g.aroundGates.add(staleNewer);
    await toEnd();
    expect(g.newerCalls, 1);
    await _jumpTo(t, 'NEEDLE B');
    await t.pumpAndSettle();
    final liveNewer = Completer<void>();
    g.aroundGates.add(liveNewer);
    await toEnd();
    expect(g.newerCalls, 2, reason: 'the new window reads its own rows');
    staleNewer.complete();
    await t.pump();
    await toEnd();
    await toEnd();
    expect(g.newerCalls, 2, reason: 'one read in flight per window');
    liveNewer.complete();
    await t.pumpAndSettle();
  });

  testWidgets('L2 a failing later-rows read is reported once per streak', (
    t,
  ) async {
    final h = _seeded();
    final g = await _pump(t, h);
    await t.pumpAndSettle();
    await _jumpTo(t, 'NEEDLE A');
    await t.pumpAndSettle();
    g.failNewer = true;
    final ScrollPosition position = t
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    Future<void> toEnd() async {
      position.jumpTo(position.maxScrollExtent - 1);
      await t.pump();
      position.jumpTo(position.maxScrollExtent);
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
    }

    await toEnd();
    expect(g.newerCalls, greaterThanOrEqualTo(1));
    expect(find.text(s.errorUnknown), findsOneWidget);
    ScaffoldMessenger.of(
      t.element(find.byType(ConversationScreen)),
    ).removeCurrentSnackBar();
    await t.pump();
    final calls = g.newerCalls;
    await toEnd();
    expect(g.newerCalls, greaterThan(calls), reason: 'scrolling retries');
    expect(find.text(s.errorUnknown), findsNothing, reason: 'same streak');
  });

  group('L3 search date range', () {
    Future<void> openSearch(WidgetTester t, ChatHarness h) async {
      // Wide enough for the full-screen range picker's header.
      final g = await _pump(t, h, size: kDesktop);
      await t.pumpAndSettle();
      expect(g, isNotNull);
      await t.tap(find.byType(PopupMenuButton<String>));
      await t.pumpAndSettle();
      await t.tap(find.text(s.chatSearchMessages));
      await t.pumpAndSettle();
    }

    Future<void> pickRange(WidgetTester t) async {
      await t.ensureVisible(find.text(s.chatSearchAnyDate));
      await t.pumpAndSettle();
      await t.tap(find.text(s.chatSearchAnyDate));
      await t.pumpAndSettle();
    }

    testWidgets('cancelling the picker keeps the range; delete clears it', (
      t,
    ) async {
      await openSearch(t, _seeded());
      final state = t.state(find.byType(MessageSearchScreen));
      await pickRange(t);
      // Choose a range in the picker's input mode-agnostic way: save the
      // initial (today) selection after tapping a day twice.
      final day = find.text('${DateTime.now().day}').last;
      await t.tap(day);
      await t.pump();
      await t.tap(day);
      await t.pumpAndSettle();
      await t.tap(find.byType(TextButton).last); // Save
      await t.pumpAndSettle();
      expect(find.text(s.chatSearchAnyDate), findsNothing);
      expect(find.byType(InputChip), findsOneWidget);

      await t.ensureVisible(find.byType(InputChip));
      await t.pumpAndSettle();
      await t.tap(find.byType(InputChip));
      await t.pumpAndSettle();
      await t.tap(find.byIcon(Icons.close).first); // cancel the picker
      await t.pumpAndSettle();
      expect(identical(t.state(find.byType(MessageSearchScreen)), state), isTrue);
      expect(find.byType(InputChip), findsOneWidget, reason: 'range kept');

      await t.ensureVisible(find.byTooltip(s.chatSearchClearDates));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip(s.chatSearchClearDates));
      await t.pumpAndSettle();
      expect(find.text(s.chatSearchAnyDate), findsOneWidget);
      expect(find.byType(InputChip), findsNothing);
    });
  });

  testWidgets('L4 the conversation menu button has an accessible name', (
    t,
  ) async {
    final h = ChatHarness()..addAnn();
    final conversation = h.service.conversations.firstWhere((c) => c.id == _id);
    await pumpChat(
      t,
      (_) => Scaffold(
        body: ConversationTile(
          conversation: conversation,
          selected: false,
          onTap: () {},
          onAction: (_) {},
        ),
      ),
      harness: h,
    );
    expect(find.byTooltip(s.chatConversationActions('Ann')), findsOneWidget);
    expect(
      t
          .widget<PopupMenuButton<ConversationAction>>(
            find.byType(PopupMenuButton<ConversationAction>),
          )
          .tooltip,
      s.chatConversationActions('Ann'),
    );
  });

  testWidgets('L5 a failed draft save is reported once per streak', (t) async {
    final h = _seeded();
    final g = await _pump(t, h, before: (g) => g.failDraft = true);
    await t.pumpAndSettle();
    await keyIn(t, 'CQ');
    await t.pump(const Duration(seconds: 2));
    await t.pump();
    expect(g.draftCalls, greaterThanOrEqualTo(1));
    expect(find.text(s.chatDraftSaveFailed), findsOneWidget);
    ScaffoldMessenger.of(
      t.element(find.byType(ConversationScreen)),
    ).removeCurrentSnackBar();
    await t.pump();
    await keyIn(t, 'CQ CQ');
    await t.pump(const Duration(seconds: 2));
    await t.pump();
    expect(find.text(s.chatDraftSaveFailed), findsNothing, reason: 'same streak');
    // A save that works ends the streak; the next failure is reported.
    g.failDraft = false;
    await keyIn(t, 'CQ CQ CQ');
    await t.pump(const Duration(seconds: 2));
    await t.pump();
    g.failDraft = true;
    await keyIn(t, 'CQ CQ CQ DE');
    await t.pump(const Duration(seconds: 2));
    await t.pump();
    expect(find.text(s.chatDraftSaveFailed), findsOneWidget);
  });

  group('item 2 a held group is given a password only when it asked', () {
    GroupJoinRefusal held(GroupJoinRefusalReason reason) => GroupJoinRefusal(
      groupId: 'tox_1',
      groupName: 'Held',
      reason: reason,
      established: true,
    );

    test('retry targets and prompts by reason', () async {
      final service = _Rejoins();
      for (final reason in GroupJoinRefusalReason.values) {
        final r = held(reason);
        expect(
          groupJoinRetryAsksPassword(r),
          reason == GroupJoinRefusalReason.invalidPassword,
        );
        await groupJoinRetry(service, r)!(null);
      }
      expect(service.calls, everyElement(('tox_1', null)));
      expect(
        groupJoinRefusalMessage(s, held(GroupJoinRefusalReason.unknown)),
        s.chatGroupReconnectFailed('Held'),
      );
      expect(
        groupJoinRefusalMessage(s, held(GroupJoinRefusalReason.groupFull)),
        s.chatGroupJoinRefusedFull('Held'),
      );
      expect(
        groupJoinRefusalMessage(
          s,
          held(GroupJoinRefusalReason.invalidPassword),
        ),
        s.chatGroupReconnectRefused('Held'),
      );
    });

    testWidgets('an unknown refusal retries at once, without a prompt', (
      t,
    ) async {
      final h = await pumpChat(t, (h) {
        h.service.addFakeGroup(
          const Group(id: 'tox_1', name: 'Held', kind: GroupKind.group),
        );
        return const GroupsPage();
      });
      // A wrong (non-empty) password would be refused again.
      h.service.requireGroupPassword('tox_1', '');
      h.service.refuseGroupJoin(held(GroupJoinRefusalReason.unknown));
      await t.pumpAndSettle();
      expect(find.text(s.chatGroupReconnectFailed('Held')), findsOneWidget);
      await t.tap(find.text(s.actionRetry));
      await t.pumpAndSettle();
      expect(find.text(s.chatGroupPasswordTitle('Held')), findsNothing);
      expect(find.text(s.chatGroupReconnectRefused('Held')), findsNothing);
      expect(find.text(s.chatGroupReconnectFailed('Held')), findsNothing);
      expect(h.service.groups.map((g) => g.id), ['tox_1']);
    });
  });
}

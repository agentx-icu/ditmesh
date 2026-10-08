import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/contacts/tox_id.dart';
import 'package:ditmesh/ui/groups/create_group_sheet.dart';
import 'package:ditmesh/ui/groups/group_invites_inbox.dart';
import 'package:ditmesh/ui/groups/group_join_feedback.dart';
import 'package:ditmesh/ui/pages/groups_page.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'test_support.dart';

/// A [ChatService] whose createGroup is held until the test releases it.
final class _HeldCreate implements ChatService {
  int calls = 0;
  Completer<Group> pending = Completer<Group>();

  @override
  Future<Group> createGroup(String name, {GroupKind kind = GroupKind.group}) {
    calls++;
    return pending.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ConversationTarget _ann() => ConversationTarget(
  id: 'c2c_$kPeerKey',
  title: 'Ann',
  kind: ConversationKind.c2c,
);

/// Keys [pattern] on the straight key by touch, then lets the character
/// gap pass so the decoder commits it.
Future<void> _keyPattern(
  WidgetTester tester,
  ChatHarness h,
  String pattern,
) async {
  for (final String e in pattern.split('')) {
    final gesture = await tester.press(find.byType(StraightKeyButton));
    await tester.pump();
    h.clock.advance(Duration(milliseconds: e == '.' ? 60 : 180));
    await gesture.up();
    await tester.pump();
    h.clock.advance(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 40));
  }
  // Past the character gap, short of the word gap.
  h.clock.advance(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 80));
}

String _draft(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

/// A harness whose fake follows a real (fake) identity session, so a test
/// can end the session and start the next one.
Future<(ChatHarness, FakeIdentityService)> _sessionHarness(
  WidgetTester tester,
  Widget Function(ChatHarness h) build,
) async {
  final FakeIdentityService identity = FakeIdentityService.withProfile(
    identity: Identity(toxId: kSelfToxId, displayName: 'Me'),
    connectDelay: Duration.zero,
  );
  await tester.runAsync(() async {
    await identity.open();
    await identity.connect();
  });
  addTearDown(identity.dispose);
  final ChatHarness h = ChatHarness(
    service: FakeChatService(selfPublicKey: kSelfKey, identity: identity),
  );
  await pumpChat(tester, build, harness: h);
  return (h, identity);
}

/// Ends the session and opens the next one.
Future<void> _newSession(WidgetTester tester, FakeIdentityService id) async {
  await tester.runAsync(() async {
    await id.disconnect();
    await id.connect();
  });
  await tester.pumpAndSettle();
}

Future<void> _enterPassword(WidgetTester tester, String password) async {
  await tester.enterText(
    find.byKey(const ValueKey<String>('group_password_field')),
    password,
  );
  await tester.tap(find.widgetWithText(FilledButton, s.chatJoin));
  await tester.pumpAndSettle();
}

void main() {
  group('M1 send to a removed friend', () {
    testWidgets('shows the localized error and keeps the draft', (
      tester,
    ) async {
      final h = await pumpChat(tester, (h) {
        h.addAnn(withMessage: false);
        return ConversationScreen(target: _ann());
      });
      await h.service.removeFriend(kPeerKey);
      await tester.pump();
      await keyIn(tester, 'CQ');
      await tester.tap(find.byTooltip(s.chatSend));
      await tester.pumpAndSettle();
      expect(find.text(s.errorNotFriend), findsOneWidget);
      expect(_draft(tester), 'CQ');
      expect(await h.service.loadHistory('c2c_$kPeerKey'), isEmpty);
    });
  });

  group('M2 asynchronous join refusals', () {
    final String chatId = 'D' * 64;

    testWidgets('a wrong password reported after the join returned, and '
        'Retry with the password joins', (tester) async {
      final h = await pumpChat(tester, (_) => const GroupsPage());
      h.service.requireGroupPassword(chatId, 'pw');
      // The join call returns at once; the group refuses afterwards (the
      // join sheet has long closed by then).
      await h.service.joinGroup(chatId);
      await tester.pumpAndSettle();
      final String label = shortKey(chatId, length: 12);
      expect(find.text(s.chatGroupJoinRefusedPassword(label)), findsOneWidget);
      expect(h.service.groups, isEmpty);

      await tester.tap(find.text(s.actionRetry));
      await tester.pumpAndSettle();
      expect(find.text(s.chatGroupPasswordTitle(label)), findsOneWidget);
      await _enterPassword(tester, 'pw');
      expect(h.service.groups.single.chatId, chatId);
    });

    testWidgets('a full group is reported with its name', (tester) async {
      final h = await pumpChat(tester, (_) => const GroupsPage());
      h.service.refuseGroupJoin(
        GroupJoinRefusal(
          groupId: 'tox_3',
          chatId: chatId,
          groupName: 'DX',
          reason: GroupJoinRefusalReason.groupFull,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(s.chatGroupJoinRefusedFull('DX')), findsOneWidget);
    });

    testWidgets('a held group refusing to reconnect is reported over an open '
        'conversation; Retry rejoins it by its id', (tester) async {
      final h = await pumpChat(tester, (h) {
        h.service.addFakeGroup(
          const Group(id: 'tox_1', name: 'Held', kind: GroupKind.group),
        );
        return const GroupsPage();
      });
      h.service.requireGroupPassword('tox_1', 'pw');
      await tester.tap(find.text('Held'));
      await tester.pumpAndSettle();
      expect(find.byType(ConversationScreen), findsOneWidget);
      h.service.refuseGroupJoin(
        const GroupJoinRefusal(
          groupId: 'tox_1',
          groupName: 'Held',
          reason: GroupJoinRefusalReason.invalidPassword,
          established: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(s.chatGroupReconnectRefused('Held')), findsOneWidget);
      // A wrong password reaches rejoinGroup and is refused again.
      await tester.tap(find.text(s.actionRetry));
      await tester.pumpAndSettle();
      await _enterPassword(tester, 'wrong');
      expect(find.text(s.chatGroupReconnectRefused('Held')), findsOneWidget);
      expect(h.service.groups.map((g) => g.id), ['tox_1']);
    });
  });

  group('M3 password-protected invites', () {
    testWidgets('a refused accept asks for the password on the next accept', (
      tester,
    ) async {
      late GroupInvite invite;
      final h = await pumpChat(tester, (h) {
        invite = h.service.receiveGroupInvite(
          fromPublicKey: kPeerKey,
          groupName: 'Private',
        );
        h.service.requireGroupPassword(invite.inviteId, 'pw');
        return const GroupsPage();
      });
      await tester.tap(find.byTooltip(s.chatAccept));
      await tester.pumpAndSettle();
      expect(find.text(s.chatGroupJoinRefusedPassword('Private')), findsOne);
      expect(h.service.groupInvites.map((i) => i.inviteId), [invite.inviteId]);

      await tester.tap(find.byTooltip(s.chatAccept));
      await tester.pumpAndSettle();
      expect(find.text(s.chatGroupPasswordTitle('Private')), findsOneWidget);
      // A wrong password is refused again, and the prompt comes back.
      await _enterPassword(tester, 'nope');
      await tester.tap(find.byTooltip(s.chatAccept));
      await tester.pumpAndSettle();
      await _enterPassword(tester, 'pw');
      expect(h.service.groups.single.name, 'Private');
      expect(h.service.groupInvites, isEmpty);
    });

    testWidgets('"Accept with password" passes the password; cancelling the '
        'prompt answers nothing', (tester) async {
      late GroupInvite invite;
      final h = await pumpChat(tester, (h) {
        invite = h.service.receiveGroupInvite(
          fromPublicKey: kPeerKey,
          groupName: 'Private',
        );
        h.service.requireGroupPassword(invite.inviteId, 'pw');
        return const GroupsPage();
      });
      Future<void> openPasswordAccept() async {
        await tester.tap(
          find.byKey(ValueKey<String>('invite_menu_${invite.inviteId}')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(s.chatAcceptWithPassword));
        await tester.pumpAndSettle();
      }

      await openPasswordAccept();
      await tester.tap(find.text(s.actionCancel));
      await tester.pumpAndSettle();
      expect(h.service.groupInvites, hasLength(1));
      expect(h.service.groups, isEmpty);

      await openPasswordAccept();
      await _enterPassword(tester, 'pw');
      expect(h.service.groups.single.name, 'Private');
    });

    testWidgets('a conference invite offers no password action', (
      tester,
    ) async {
      late GroupInvite invite;
      await pumpChat(tester, (h) {
        invite = h.service.receiveGroupInvite(
          fromPublicKey: kPeerKey,
          groupName: 'Old',
          kind: GroupKind.conference,
        );
        return const GroupsPage();
      });
      await tester.tap(
        find.byKey(ValueKey<String>('invite_menu_${invite.inviteId}')),
      );
      await tester.pumpAndSettle();
      expect(find.text(s.chatReject), findsOneWidget);
      expect(find.text(s.chatAcceptWithPassword), findsNothing);
    });
  });

  group('M5 create group while pending', () {
    testWidgets('Enter and Create during a pending creation start one '
        'creation; a failure can be retried', (tester) async {
      final held = _HeldCreate();
      await pumpChat(
        tester,
        (_) => Scaffold(body: CreateGroupForm(service: held)),
      );
      await tester.enterText(find.byType(TextFormField), 'Net');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.tap(find.text(s.chatCreate));
      await tester.pump();
      expect(held.calls, 1);
      final TextField field = tester.widget<TextField>(find.byType(TextField));
      expect(field.readOnly, isTrue);

      held.pending.completeError(
        const ChatException('create_group_failed', 'refused'),
      );
      await tester.pumpAndSettle();
      held.pending = Completer<Group>();
      await tester.tap(find.text(s.chatCreate));
      await tester.pump();
      expect(held.calls, 2);
      held.pending.complete(
        const Group(id: 'tox_1', name: 'Net', kind: GroupKind.group),
      );
      await tester.pumpAndSettle();
    });
  });

  group('M7 delete-last', () {
    testWidgets('a keyed prosign is deleted as one token', (tester) async {
      final h = await pumpChat(tester, (h) {
        h.addAnn(withMessage: false);
        return ConversationScreen(target: _ann());
      });
      await _keyPattern(tester, h, '.');
      await _keyPattern(tester, h, '...-.-');
      expect(_draft(tester), 'E<SK>');
      await tester.tap(find.byTooltip(s.chatDeleteLast));
      await tester.pump();
      expect(_draft(tester), 'E');
    });

    testWidgets('an unread pattern restored from the draft goes whole', (
      tester,
    ) async {
      await pumpChat(tester, (h) {
        h.addAnn(withMessage: false);
        unawaited(h.service.setDraft('c2c_$kPeerKey', 'CQ <..--.>'));
        return ConversationScreen(target: _ann());
      });
      expect(_draft(tester), 'CQ <..--.>');
      await tester.tap(find.byTooltip(s.chatDeleteLast));
      await tester.pump();
      expect(_draft(tester), 'CQ ');
    });
  });

  group('stale session guards (review round 1)', () {
    testWidgets('a Retry from an earlier session does nothing', (tester) async {
      final (h, identity) = await _sessionHarness(
        tester,
        (_) => const GroupsPage(),
      );
      h.service.refuseGroupJoin(
        GroupJoinRefusal(
          groupId: 'tox_1',
          chatId: 'D' * 64,
          groupName: 'DX',
          reason: GroupJoinRefusalReason.invalidPassword,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(s.chatGroupJoinRefusedPassword('DX')), findsOneWidget);
      await _newSession(tester, identity);
      await tester.tap(find.text(s.actionRetry));
      await tester.pumpAndSettle();
      expect(find.text(s.chatGroupPasswordTitle('DX')), findsNothing);
      expect(h.service.groups, isEmpty);
    });

    testWidgets('a password prompt that outlived its session accepts nothing', (
      tester,
    ) async {
      late GroupInvite invite;
      final (h, identity) = await _sessionHarness(tester, (h) {
        invite = h.service.receiveGroupInvite(
          fromPublicKey: kPeerKey,
          groupName: 'Private',
        );
        return const GroupsPage();
      });
      await tester.tap(
        find.byKey(ValueKey<String>('invite_menu_${invite.inviteId}')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(s.chatAcceptWithPassword));
      await tester.pumpAndSettle();
      await _newSession(tester, identity);
      await _enterPassword(tester, 'pw');
      expect(h.service.groups, isEmpty);
      expect(h.service.groupInvites.map((i) => i.inviteId), [invite.inviteId]);
      // The invite can be answered in the new session.
      await tester.tap(find.byTooltip(s.chatAccept));
      await tester.pumpAndSettle();
      expect(h.service.groups.single.name, 'Private');
    });
  });

  group('service replacement (review round 2)', () {
    /// Hosts [build] with the service in [current]; flipping it rebuilds
    /// the same widget with the replacement service.
    Widget host(
      ValueNotifier<ChatService> current,
      Widget Function(ChatService service) build,
    ) => ValueListenableBuilder<ChatService>(
      valueListenable: current,
      builder: (_, service, _) => build(service),
    );

    testWidgets('a Retry from the replaced service does nothing', (
      tester,
    ) async {
      final FakeChatService a = FakeChatService(selfPublicKey: kSelfKey);
      final FakeChatService b = FakeChatService(selfPublicKey: kSelfKey);
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      final ValueNotifier<ChatService> current = ValueNotifier(a);
      addTearDown(current.dispose);
      await pumpChat(
        tester,
        (_) => host(
          current,
          (service) => GroupJoinFeedback(
            service: service,
            child: const Scaffold(body: SizedBox.shrink()),
          ),
        ),
      );
      a.refuseGroupJoin(
        GroupJoinRefusal(
          groupId: 'tox_1',
          chatId: 'D' * 64,
          groupName: 'DX',
          reason: GroupJoinRefusalReason.invalidPassword,
        ),
      );
      await tester.pumpAndSettle();
      current.value = b;
      await tester.pumpAndSettle();
      await tester.tap(find.text(s.actionRetry));
      await tester.pumpAndSettle();
      expect(find.text(s.chatGroupPasswordTitle('DX')), findsNothing);
      expect(a.groups, isEmpty);
      expect(b.groups, isEmpty);
    });

    testWidgets('a password prompt of the replaced service accepts nothing', (
      tester,
    ) async {
      final FakeChatService a = FakeChatService(selfPublicKey: kSelfKey);
      final FakeChatService b = FakeChatService(selfPublicKey: kSelfKey);
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      final GroupInvite invite = a.receiveGroupInvite(
        fromPublicKey: kPeerKey,
        groupName: 'Private',
      );
      final ValueNotifier<ChatService> current = ValueNotifier(a);
      addTearDown(current.dispose);
      await pumpChat(
        tester,
        (_) => host(
          current,
          (service) => Scaffold(
            body: ListView(children: [GroupInvitesInbox(service: service)]),
          ),
        ),
      );
      await tester.tap(
        find.byKey(ValueKey<String>('invite_menu_${invite.inviteId}')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(s.chatAcceptWithPassword));
      await tester.pumpAndSettle();
      current.value = b;
      await tester.pump();
      await _enterPassword(tester, 'pw');
      expect(a.groups, isEmpty);
      expect(a.groupInvites, hasLength(1));
      expect(b.groups, isEmpty);
    });
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/contacts/friend_request_inbox.dart';
import 'package:ditmesh/ui/groups/group_members_sheet.dart';
import 'package:ditmesh/ui/moderation/blocked_people_page.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../chat/test_support.dart';

const String _member =
    '3333333333333333333333333333333333333333333333333333333333333333';

ConversationTarget _ann() => ConversationTarget(
  id: 'c2c_$kPeerKey',
  title: 'Ann',
  kind: ConversationKind.c2c,
);

/// A home page that pushes [target]'s conversation, so a test can see the
/// route close.
Widget _launcher(ConversationTarget target) => Builder(
  builder: (context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ConversationScreen(target: target),
          ),
        ),
        child: const Text('open'),
      ),
    ),
  ),
);

Future<void> _openMenu(WidgetTester tester, String label) async {
  await tester.tap(find.byType(PopupMenuButton<String>).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('block from the conversation menu confirms, blocks and closes '
      'the conversation', (tester) async {
    final h = ChatHarness()..addAnn();
    await pumpChat(tester, (_) => _launcher(_ann()), harness: h);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(ConversationScreen), findsOneWidget);

    await _openMenu(tester, s.moderationBlock);
    expect(find.text(s.moderationBlockTitle('Ann')), findsOneWidget);
    expect(find.text(s.moderationBlockFriendBody), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, s.moderationBlock));
    await tester.pumpAndSettle();

    expect(h.service.blockedPeers, {kPeerKey});
    expect(h.service.friends, isEmpty);
    expect(find.byType(ConversationScreen), findsNothing, reason: 'closed');
    expect(find.text(s.moderationBlocked), findsOneWidget);
  });

  testWidgets('blocking a group member hides their rows in the open group', (
    tester,
  ) async {
    final h = ChatHarness();
    final group = h.service.addFakeGroup(
      const Group(id: 'tox_1', name: 'DX net', kind: GroupKind.group),
      members: [
        GroupMember(publicKey: kSelfKey, displayName: 'Me', isSelf: true),
        const GroupMember(publicKey: _member, displayName: 'Spammer'),
      ],
    );
    h.service.receiveMessage('group_tox_1', 'GM', senderId: kPeerKey);
    h.service.receiveMessage('group_tox_1', 'SPAM SPAM', senderId: _member);
    const target = ConversationTarget(
      id: 'group_tox_1',
      title: 'DX net',
      kind: ConversationKind.group,
    );
    await pumpChat(
      tester,
      (_) => const ConversationScreen(target: target),
      harness: h,
    );
    expect(find.text('SPAM SPAM'), findsOneWidget);

    await showGroupMembersSheetForTest(tester, h, group);
    await tester.tap(find.byKey(const ValueKey('member-menu-$_member')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.moderationBlock).last);
    await tester.pumpAndSettle();
    expect(find.text(s.moderationBlockMemberBody), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, s.moderationBlock));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(ConversationScreen))).pop();
    await tester.pumpAndSettle();

    expect(h.service.blockedPeers, {_member});
    expect(find.text('SPAM SPAM'), findsNothing);
    expect(find.text('GM'), findsOneWidget);

    // The sheet now offers Unblock for that member; unblocking brings the
    // rows back in the open conversation.
    await showGroupMembersSheetForTest(tester, h, group);
    await tester.tap(find.byKey(const ValueKey('member-menu-$_member')));
    await tester.pumpAndSettle();
    expect(find.text(s.moderationBlock), findsNothing);
    await tester.tap(find.text(s.moderationUnblock));
    await tester.pumpAndSettle();
    expect(h.service.blockedPeers, isEmpty);
    // Close the members sheet.
    Navigator.of(tester.element(find.byType(ConversationScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.text('SPAM SPAM'), findsOneWidget, reason: 'restored');
  });

  testWidgets('a friend request can be blocked from the inbox', (tester) async {
    final h = ChatHarness();
    h.service.receiveFriendRequest(kPeerKey);
    await pumpChat(
      tester,
      (h) => Scaffold(body: FriendRequestInbox(service: h.service)),
      harness: h,
    );
    await tester.tap(find.byKey(ValueKey<String>('req_block_$kPeerKey')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, s.moderationBlock));
    await tester.pumpAndSettle();
    expect(h.service.blockedPeers, {kPeerKey});
    expect(h.service.friendRequests, isEmpty);
  });

  testWidgets('blocked people can be unblocked', (tester) async {
    final h = ChatHarness();
    await h.service.blockPeer(kPeerKey);
    await pumpChat(tester, (_) => const BlockedPeoplePage(), harness: h);
    expect(find.text(s.moderationBlockedNote), findsOneWidget);
    expect(find.byKey(ValueKey<String>('blocked_$kPeerKey')), findsOneWidget);
    await tester.tap(find.text(s.moderationUnblock));
    await tester.pumpAndSettle();
    expect(h.service.blockedPeers, isEmpty);
    expect(find.text(s.moderationBlockedEmpty), findsOneWidget);
  });
}

/// Opens the members sheet over the open conversation, the way its menu
/// does.
Future<void> showGroupMembersSheetForTest(
  WidgetTester tester,
  ChatHarness h,
  Group group,
) async {
  final BuildContext context = tester.element(find.byType(ConversationScreen));
  unawaited(showGroupMembersSheet(context, service: h.service, group: group));
  await tester.pumpAndSettle();
}

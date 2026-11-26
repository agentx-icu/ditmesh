import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh/ui/contacts/friend_request_inbox.dart';
import 'package:ditmesh/ui/contacts/contacts_page.dart';
import 'package:ditmesh/ui/groups/group_invites_inbox.dart';

import 'test_support.dart';

IconButton _button(WidgetTester tester, String tooltip) =>
    tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip(tooltip),
        matching: find.byType(IconButton),
      ),
    );

void main() {
  testWidgets('a friend request cannot be answered twice while in flight', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.service.receiveFriendRequest('D' * 64);
      return Scaffold(body: FriendRequestInbox(service: h.service));
    });
    final Completer<void> hold = Completer<void>();
    h.service.holdAnswers = hold;
    final accept = find.widgetWithText(FilledButton, s.chatAccept);
    final reject = find.widgetWithText(OutlinedButton, s.chatReject);
    await tester.tap(accept);
    await tester.pump();
    // Both answers are off until the first one settles.
    expect(tester.widget<FilledButton>(accept).onPressed, isNull);
    expect(tester.widget<OutlinedButton>(reject).onPressed, isNull);
    hold.complete();
    await tester.pumpAndSettle();
    expect(h.service.friendRequests, isEmpty);
    expect(h.service.friends.map((f) => f.publicKey), contains('D' * 64));
  });

  testWidgets(
    'rejecting a request explains follow-up filtering before changing anything',
    (tester) async {
      final h = await pumpChat(tester, (h) {
        h.service.receiveFriendRequest('D' * 64);
        return Scaffold(body: FriendRequestInbox(service: h.service));
      });
      await tester.tap(find.widgetWithText(OutlinedButton, s.chatReject));
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(
          of: dialog,
          matching: find.textContaining('future requests'),
        ),
        findsOneWidget,
      );
      expect(h.service.friendRequests, hasLength(1));
    },
  );

  testWidgets(
    'rejected senders are visible and the request filter can be undone',
    (tester) async {
      final key = 'D' * 64;
      final h = await pumpChat(tester, (h) {
        h.service.receiveFriendRequest(key);
        return ContactsPage(
          service: h.service,
          identity: null,
          onOpenConversation: (_) {},
        );
      });
      await tester.tap(find.widgetWithText(OutlinedButton, s.chatReject));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(s.chatReject),
        ),
      );
      await tester.pumpAndSettle();
      h.service.receiveFriendRequest(key, message: 'A fresh request');
      await tester.pumpAndSettle();
      expect(find.text('A fresh request'), findsNothing);

      final rejected = find.text(s.chatRejectedRequests);
      await tester.ensureVisible(rejected);
      await tester.tap(rejected);
      await tester.pumpAndSettle();
      await tester.tap(find.text(s.chatAllowFutureRequests));
      await tester.pumpAndSettle();
      expect(find.text(s.chatRejectedRequestsEmpty), findsOneWidget);
      await tester.pageBack();
      h.service.receiveFriendRequest(key, message: 'A fresh request');
      await tester.pumpAndSettle();
      expect(find.text('A fresh request'), findsOneWidget);
    },
  );

  testWidgets('a group invite cannot be answered twice while in flight', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.service.receiveGroupInvite(fromPublicKey: kPeerKey, groupName: 'Net');
      return Scaffold(body: GroupInvitesInbox(service: h.service));
    });
    final Completer<void> hold = Completer<void>();
    h.service.holdAnswers = hold;
    final String id = h.service.groupInvites.single.inviteId;
    await tester.tap(find.byKey(ValueKey<String>('invite_menu_$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatReject));
    await tester.pump();
    expect(_button(tester, s.chatAccept).onPressed, isNull);
    final PopupMenuButton<String> menu = tester.widget(
      find.byKey(ValueKey<String>('invite_menu_$id')),
    );
    expect(menu.enabled, isFalse);
    hold.complete();
    await tester.pumpAndSettle();
    expect(h.service.groupInvites, isEmpty);
    expect(h.service.groups, isEmpty);
  });

  testWidgets('a failed invite stays visible with an explicit working retry', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.service.receiveGroupInvite(fromPublicKey: kPeerKey, groupName: 'Net');
      return Scaffold(body: GroupInvitesInbox(service: h.service));
    });
    final hold = Completer<void>();
    h.service.holdAnswers = hold;
    await tester.tap(find.byTooltip(s.chatAccept));
    await tester.pump();
    hold.completeError(const ChatException('not_connected', 'offline'));
    await tester.pumpAndSettle();
    expect(find.text('Net'), findsOneWidget);
    expect(find.text('Could not accept the invitation'), findsOneWidget);
    expect(find.text(s.groupInviteReconnectHint), findsOneWidget);
    expect(h.service.groupInvites, hasLength(1));

    h.service.holdAnswers = null;
    await tester.tap(find.text('Retry acceptance'));
    await tester.pumpAndSettle();
    expect(h.service.groupInvites, isEmpty);
    expect(h.service.groups.single.name, 'Net');
  });
}

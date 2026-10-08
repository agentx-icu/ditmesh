import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/contacts/friend_request_inbox.dart';
import 'package:ditmesh/ui/groups/group_invites_inbox.dart';

import 'test_support.dart';

IconButton _button(WidgetTester tester, String tooltip) =>
    tester.widget<IconButton>(
      find.ancestor(of: find.byTooltip(tooltip), matching: find.byType(IconButton)),
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
    await tester.tap(find.byTooltip(s.chatAccept));
    await tester.pump();
    // Both answers are off until the first one settles.
    expect(_button(tester, s.chatAccept).onPressed, isNull);
    expect(_button(tester, s.chatReject).onPressed, isNull);
    hold.complete();
    await tester.pumpAndSettle();
    expect(h.service.friendRequests, isEmpty);
    expect(h.service.friends.map((f) => f.publicKey), contains('D' * 64));
  });

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
}

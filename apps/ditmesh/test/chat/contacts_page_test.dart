import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/contacts/contacts_page.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'test_support.dart';

void main() {
  late List<ConversationTarget> opened;

  setUp(() => opened = []);

  Future<ChatHarness> pumpContacts(
    WidgetTester tester, {
    void Function(ChatHarness h)? seed,
  }) => pumpChat(tester, (h) {
    seed?.call(h);
    return ContactsPage(
      service: h.service,
      identity: h.identity,
      onOpenConversation: opened.add,
      canScan: false,
    );
  });

  Friend friend(String key, String name, {bool online = false}) =>
      Friend(publicKey: key * 64, displayName: name, online: online);

  testWidgets('no friends yet: an empty state, not a blank list', (
    tester,
  ) async {
    await pumpContacts(tester);
    expect(find.text(s.chatFriendsCount(0)), findsOneWidget);
    expect(find.text(s.chatNoFriends), findsOneWidget);
  });

  testWidgets('online friends first, then by name without regard to case', (
    tester,
  ) async {
    await pumpContacts(
      tester,
      seed: (h) {
        h.service.addFakeFriend(friend('1', 'zed'));
        h.service.addFakeFriend(friend('2', 'Bob', online: true));
        h.service.addFakeFriend(friend('3', 'amy'));
        h.service.addFakeFriend(friend('4', 'Yan', online: true));
      },
    );
    expect(find.text(s.chatFriendsCount(4)), findsOneWidget);
    double y(String name) => tester.getTopLeft(find.text(name)).dy;
    expect(y('Bob'), lessThan(y('Yan')));
    expect(y('Yan'), lessThan(y('amy')));
    expect(y('amy'), lessThan(y('zed')));
    expect(find.text(s.connectionOnline), findsNWidgets(2));
    expect(find.text(s.connectionOffline), findsNWidgets(2));
  });

  testWidgets('a status message replaces the online label', (tester) async {
    await pumpContacts(
      tester,
      seed: (h) => h.service.addFakeFriend(
        Friend(
          publicKey: 'A' * 64,
          displayName: 'Ann',
          online: true,
          statusMessage: 'QRV 7.030',
        ),
      ),
    );
    expect(find.text('QRV 7.030'), findsOneWidget);
    expect(find.text(s.connectionOnline), findsNothing);
  });

  testWidgets('tapping a friend opens the conversation', (tester) async {
    await pumpContacts(tester, seed: (h) => h.addAnn(withMessage: false));
    await tester.tap(find.byKey(ValueKey<String>('friend_$kPeerKey')));
    await tester.pumpAndSettle();
    expect(opened, hasLength(1));
    expect(opened.single.title, 'Ann');
  });

  Future<void> openRemove(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byKey(ValueKey<String>('friend_$kPeerKey')),
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatRemoveFriend));
    await tester.pumpAndSettle();
    expect(find.text(s.chatRemoveFriendTitle), findsOneWidget);
  }

  testWidgets('removing a friend asks first; cancel keeps them', (
    tester,
  ) async {
    final h = await pumpContacts(
      tester,
      seed: (h) => h.addAnn(withMessage: false),
    );
    await openRemove(tester);
    await tester.tap(find.text(s.actionCancel));
    await tester.pumpAndSettle();
    expect(h.service.friends, hasLength(1));
    expect(find.text('Ann'), findsOneWidget);

    await openRemove(tester);
    await tester.tap(find.text(s.chatRemove));
    await tester.pumpAndSettle();
    expect(h.service.friends, isEmpty);
    expect(find.text('Ann'), findsNothing);
    expect(find.text(s.chatNoFriends), findsOneWidget);
  });

  testWidgets('a failed removal is reported, not thrown', (tester) async {
    final h = await pumpContacts(
      tester,
      seed: (h) => h.addAnn(withMessage: false),
    );
    await openRemove(tester);
    // Removed meanwhile (e.g. blocked from the conversation on desktop):
    // the transport no longer knows the friend.
    await h.service.removeFriend(kPeerKey);
    await tester.tap(find.text(s.chatRemove));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a sent request from the add sheet is confirmed', (tester) async {
    final h = await pumpContacts(tester);
    await tester.tap(find.byTooltip(s.chatAddFriend));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, kPeerToxId);
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatSendRequest));
    await tester.pumpAndSettle();
    expect(find.text(s.chatRequestSent), findsOneWidget);
    expect(h.service.friends.map((f) => f.publicKey), [
      kPeerToxId.substring(0, 64),
    ]);
  });

  testWidgets('closing the add sheet sends nothing and says nothing', (
    tester,
  ) async {
    final h = await pumpContacts(tester);
    await tester.tap(find.byTooltip(s.chatAddFriend));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5)); // the barrier
    await tester.pumpAndSettle();
    expect(find.text(s.chatRequestSent), findsNothing);
    expect(h.service.friends, isEmpty);
  });
}

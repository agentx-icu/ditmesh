import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/conversation_list.dart';
import 'package:ditmesh/ui/chat/conversation_tile.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'test_support.dart';

void main() {
  testWidgets('renders title, text + Morse preview, unread badge', (
    tester,
  ) async {
    await pumpChat(tester, (h) {
      h.addAnn();
      return Scaffold(
        body: ConversationList(service: h.service, onOpen: (_) {}),
      );
    });
    expect(find.text('Ann'), findsOneWidget);
    expect(find.text('CQ CQ DE ANN'), findsOneWidget);
    // Pattern for "CQ CQ DE ANN": words separated by " / ".
    expect(
      find.textContaining('-.-. --.- / -.-. --.- / -.. . / .- -. -.'),
      findsOneWidget,
    );
    expect(find.text('1'), findsOneWidget); // unread badge
  });

  testWidgets('pin via overflow menu moves the row first and marks it', (
    tester,
  ) async {
    final ChatHarness h = await pumpChat(tester, (h) {
      h.addAnn();
      h.service.addFakeFriend(
        Friend(publicKey: 'C' * 64, displayName: 'Bob', online: true),
      );
      h.service.receiveMessage(
        'c2c_${'C' * 64}',
        'HELLO',
        timestamp: DateTime(2026, 9, 30, 13),
      );
      return Scaffold(
        body: ConversationList(service: h.service, onOpen: (_) {}),
      );
    });
    // Bob's message is newer, so Bob is first.
    List<ConversationTile> tiles() => tester
        .widgetList<ConversationTile>(find.byType(ConversationTile))
        .toList();
    expect(tiles().first.conversation.title, 'Bob');

    // Open Ann's overflow menu and pin.
    final Finder annMenu = find.descendant(
      of: find.byKey(ValueKey<String>('c2c_$kPeerKey')),
      matching: find.byType(PopupMenuButton<ConversationAction>),
    );
    await tester.tap(annMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatPin));
    await tester.pumpAndSettle();

    expect(
      h.service.conversations.firstWhere((c) => c.title == 'Ann').pinned,
      isTrue,
    );
    expect(tiles().first.conversation.title, 'Ann');
    expect(find.byIcon(Icons.push_pin), findsOneWidget);
  });

  testWidgets('search filters by title and last message', (tester) async {
    await pumpChat(tester, (h) {
      h.addAnn();
      h.service.addFakeFriend(Friend(publicKey: 'C' * 64, displayName: 'Bob'));
      h.service.receiveMessage('c2c_${'C' * 64}', 'HELLO');
      return Scaffold(
        body: ConversationList(service: h.service, onOpen: (_) {}),
      );
    });
    expect(find.byType(ConversationTile), findsNWidgets(2));
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pumpAndSettle();
    expect(find.byType(ConversationTile), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text(s.chatNoSearchResults), findsOneWidget);
  });

  testWidgets('empty list falls back to the localized prompt', (tester) async {
    await pumpChat(
      tester,
      (h) => Scaffold(
        body: ConversationList(service: h.service, onOpen: (_) {}),
      ),
    );
    expect(find.text(s.chatNoConversations), findsOneWidget);
  });

  testWidgets('swipe right pins on touch platforms; tap opens', (tester) async {
    Conversation? opened;
    final ChatHarness h = await pumpChat(tester, (h) {
      h.addAnn();
      return Scaffold(
        body: ConversationList(
          service: h.service,
          swipeEnabled: true,
          onOpen: (c) => opened = c,
        ),
      );
    });
    await tester.drag(find.text('Ann'), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(h.service.conversations.single.pinned, isTrue);
    await tester.tap(find.text('Ann'));
    expect(opened?.title, 'Ann');
  });
}

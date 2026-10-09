import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/app_preferences.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/message_input.dart';
import 'package:ditmesh/ui/contacts/contacts_page.dart';
import 'package:ditmesh/ui/pages/chat_page.dart';
import 'package:provider/provider.dart';

import 'test_support.dart';

void main() {
  testWidgets('restored banner and guide scroll and open at 3x text', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('ditmesh_guide_headers_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final item = RestoredPendingItem(
      id: 'restored',
      conversationId: 'c2c_$kPeerKey',
      text: 'CQ',
      queuedAt: DateTime(2026, 10, 9),
    );
    final file = File('${dir.path}/$restoredPendingDoc');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
      jsonEncode({
        'items': [item.toJson()],
      }),
    );
    final identity = StubIdentityService(dataDirectoryPath: dir.path);
    Widget page() => Provider<IdentityService>.value(
      value: identity,
      child: const ChatPage(),
    );
    final h = await pumpChat(tester, (_) => page(), size: const Size(320, 568));
    await tester.pumpWidget(
      h.wrap(page(), textScaler: const TextScaler.linear(3)),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('restored-pending-banner')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    final start = find.byKey(const ValueKey('first-chat-guide-start'));
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pumpAndSettle();
    final friend = find.byKey(const ValueKey('first-chat-guide-friend'));
    await tester.ensureVisible(friend);
    await tester.pumpAndSettle();
    await tester.tap(friend);
    await tester.pumpAndSettle();
    expect(find.byType(ContactsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'first chat opens real self conversation without inserting text',
    (tester) async {
      final h = await pumpChat(
        tester,
        (_) => const ChatPage(),
        harness: ChatHarness(
          service: FakeChatService(identity: StubIdentityService()),
        ),
      );
      expect(
        find.byKey(const ValueKey('first-chat-guide-card')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('first-chat-guide-start')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('first-chat-guide-self')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ConversationScreen>(find.byType(ConversationScreen))
            .target
            .isSelf,
        isTrue,
      );
      final draft = find.descendant(
        of: find.byType(MessageInput),
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(draft).readOnly, isTrue);
      expect(tester.widget<TextField>(draft).controller!.text, isEmpty);
      expect(
        await h.service.loadHistory(h.service.selfConversationId!),
        isEmpty,
      );
    },
  );

  test('dismissal is durable and scoped to the full identity key', () async {
    final store = InMemoryKeyValueStore();
    final firstIdentity = FakeIdentityService.withProfile(
      identity: Identity(toxId: kSelfToxId, displayName: 'Me'),
    );
    await firstIdentity.open();
    final first = AppPreferences(
      store,
      backendLabel: 'test',
      identity: firstIdentity,
    );
    first.firstChat.dismiss();
    await first.flush();
    first.dispose();
    final restarted = AppPreferences(
      store,
      backendLabel: 'test',
      identity: firstIdentity,
    );
    expect(restarted.firstChat.dismissed, isTrue);
    restarted.dispose();
    final secondIdentity = FakeIdentityService.withProfile(
      identity: Identity(toxId: '${'B' * 64}${'0' * 12}', displayName: 'Other'),
    );
    await secondIdentity.open();
    final second = AppPreferences(
      store,
      backendLabel: 'test',
      identity: secondIdentity,
    );
    expect(second.firstChat.dismissed, isFalse);
    second.dispose();
    await firstIdentity.dispose();
    await secondIdentity.dispose();
  });

  testWidgets('dismissed guide stays dismissed and help can reopen it', (
    tester,
  ) async {
    final h = await pumpChat(tester, (_) => const ChatPage());
    await tester.tap(find.byKey(const ValueKey('first-chat-guide-dismiss')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('first-chat-guide-card')), findsNothing);
    await tester.pumpWidget(h.wrap(const SizedBox()));
    await tester.pumpWidget(h.wrap(const ChatPage()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('first-chat-guide-card')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('first-chat-guide-help')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('first-chat-guide-self')), findsOneWidget);
  });

  testWidgets('guide reaches existing friend and QR flow', (tester) async {
    await pumpChat(tester, (_) => const ChatPage());
    await tester.tap(find.byKey(const ValueKey('first-chat-guide-start')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('first-chat-guide-friend')),
    );
    await tester.tap(find.byKey(const ValueKey('first-chat-guide-friend')));
    await tester.pumpAndSettle();
    expect(find.byType(ContactsPage), findsOneWidget);
  });

  testWidgets('existing friendships suppress first-run card', (tester) async {
    await pumpChat(tester, (h) {
      h.addAnn();
      return const ChatPage();
    });
    expect(find.byKey(const ValueKey('first-chat-guide-card')), findsNothing);
    expect(find.byKey(const ValueKey('first-chat-guide-help')), findsOneWidget);
  });

  testWidgets('guide fits short phone with large text', (tester) async {
    final h = await pumpChat(
      tester,
      (_) => const ChatPage(),
      size: const Size(640, 360),
    );
    await tester.pumpWidget(
      h.wrap(const ChatPage(), textScaler: const TextScaler.linear(1.6)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('first-chat-guide-help')));
    await tester.pumpAndSettle();
    expect(
      MediaQuery.textScalerOf(
        tester.element(find.byKey(const ValueKey('first-chat-guide-self'))),
      ).scale(10),
      16,
    );
    expect(tester.takeException(), isNull);
  });
}

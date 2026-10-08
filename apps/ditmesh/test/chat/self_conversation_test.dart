import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/conversation_list.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/chat/conversation_tile.dart';
import 'package:ditmesh/ui/chat/message_bubble.dart';
import 'package:ditmesh/ui/chat/self_badge.dart';
import 'package:ditmesh/ui/contacts/contacts_page.dart';
import 'package:ditmesh/ui/pages/chat_page.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'test_support.dart';

/// The default "me" contact: the note-to-self conversation. Every scenario
/// runs at phone and desktop width (mobile parity).
final StubIdentityService _zoe = StubIdentityService(
  identity: Identity(toxId: kSelfToxId, displayName: 'Zoe'),
);

ChatHarness _harness() => ChatHarness(
  service: FakeChatService(
    identity: _zoe,
    clock: () => DateTime(2026, 10, 1, 9),
  ),
);

final Finder _selfTile = find.byKey(const ValueKey<String>('contacts_self'));

final String _selfId = 'c2c_$kSelfKey';
final Finder _selfRow = find.byKey(ValueKey<String>(_selfId));
final Finder _annRow = find.byKey(ValueKey<String>('c2c_$kPeerKey'));

Finder _overflowOf(Finder row) => find.descendant(
  of: row,
  matching: find.byType(PopupMenuButton<ConversationAction>),
);

/// The conversation list with "me" (holding a note) and Ann; swipe forced on
/// so the touch gestures are exercised at every width.
Future<ChatHarness> _pumpList(WidgetTester tester, Size size) async {
  final ChatHarness h = await pumpChat(
    tester,
    (h) {
      h.addAnn();
      return Scaffold(
        body: ConversationList(
          service: h.service,
          swipeEnabled: true,
          onOpen: (_) {},
        ),
      );
    },
    size: size,
    harness: _harness(),
  );
  await h.service.sendText(_selfId, 'KEEP ME');
  await tester.pumpAndSettle();
  return h;
}

Future<void> _dismissMenu(WidgetTester tester) async {
  await tester.tapAt(const Offset(2, 2));
  await tester.pumpAndSettle();
}

Future<void> _send(WidgetTester tester, String text) async {
  await keyIn(tester, text);
  await tester.pump();
  await tester.tap(find.byTooltip(s.chatSend));
  await tester.pumpAndSettle();
}

void main() {
  for (final (String label, Size size) in <(String, Size)>[
    ('phone', kPhone),
    ('desktop', kDesktop),
  ]) {
    group('at $label width', () {
      testWidgets('Contacts lists "me" first, with the own name', (
        tester,
      ) async {
        ConversationTarget? opened;
        await pumpChat(
          tester,
          (h) {
            h.addAnn(withMessage: false);
            return ContactsPage(
              service: h.service,
              identity: _zoe,
              onOpenConversation: (t) => opened = t,
              canScan: false,
            );
          },
          size: size,
          harness: _harness(),
        );
        expect(_selfTile, findsOneWidget);
        expect(
          find.descendant(of: _selfTile, matching: find.text('Zoe')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: _selfTile, matching: find.byType(SelfBadge)),
          findsOneWidget,
        );
        expect(find.text(s.chatSelfContactSubtitle), findsOneWidget);
        // Above the friends; not a friend (no remove menu, not counted).
        expect(
          tester.getTopLeft(_selfTile).dy,
          lessThan(tester.getTopLeft(find.text('Ann')).dy),
        );
        expect(
          find.descendant(
            of: _selfTile,
            matching: find.byType(PopupMenuButton<String>),
          ),
          findsNothing,
        );
        expect(find.text(s.chatFriendsCount(1)), findsOneWidget);

        await tester.tap(_selfTile);
        expect(opened?.id, 'c2c_$kSelfKey');
        expect(opened?.isSelf, isTrue);
        expect(opened?.title, 'Zoe');
      });

      testWidgets('notes to self are delivered at once and stay local', (
        tester,
      ) async {
        final ChatHarness h = await pumpChat(
          tester,
          (h) => ConversationScreen(
            target: ConversationTarget.self(id: 'c2c_$kSelfKey', title: 'Zoe'),
          ),
          size: size,
          harness: _harness(),
        );
        expect(find.text(s.chatSelfLocalOnly), findsOneWidget);
        expect(find.text(s.connectionOffline), findsNothing);
        expect(find.text(s.connectionOnline), findsNothing);

        await _send(tester, 'CQ TEST');
        expect(find.byType(MessageBubble), findsOneWidget);
        expect(find.byIcon(Icons.schedule), findsNothing, reason: 'no queue');
        final Conversation self = h.service.conversations.singleWhere(
          (c) => c.isSelf,
        );
        expect(self.lastMessage?.text, 'CQ TEST');
        expect(self.lastMessage?.status, MessageStatus.sent);
      });

      testWidgets('the conversation list shows it with the "me" badge', (
        tester,
      ) async {
        await pumpChat(
          tester,
          (h) => const ChatPage(),
          size: size,
          harness: _harness(),
        );
        expect(find.text('Zoe'), findsOneWidget);
        expect(find.byType(SelfBadge), findsOneWidget);
        expect(find.byType(SelfAvatar), findsOneWidget);
        expect(find.text(ChatPage.description(s)), findsNothing);
      });

      testWidgets('"me" has no Delete in its menu; a friend still has', (
        tester,
      ) async {
        await _pumpList(tester, size);

        await tester.tap(_overflowOf(_selfRow));
        await tester.pumpAndSettle();
        expect(find.text(s.chatPin), findsOneWidget);
        expect(find.text(s.chatDelete), findsNothing);
        await _dismissMenu(tester);

        // Long press (and right-click) open the same item list.
        await tester.longPress(
          find.descendant(of: _selfRow, matching: find.byType(ListTile)),
        );
        await tester.pumpAndSettle();
        expect(find.text(s.chatPin), findsOneWidget);
        expect(find.text(s.chatDelete), findsNothing);
        await _dismissMenu(tester);

        await tester.tap(_overflowOf(_annRow));
        await tester.pumpAndSettle();
        expect(find.text(s.chatDelete), findsOneWidget);
        await _dismissMenu(tester);
      });

      testWidgets('"me" does not swipe to delete; it still swipes to pin', (
        tester,
      ) async {
        final ChatHarness h = await _pumpList(tester, size);

        // Swipes travel 70% of the width (past the dismiss threshold).
        final double travel = size.width * 0.7;
        final TestGesture gesture = await tester.startGesture(
          tester.getTopRight(_selfRow) + const Offset(-20, 20),
        );
        await gesture.moveBy(Offset(-travel, 0));
        await tester.pump();
        expect(
          find.byIcon(Icons.delete_outline),
          findsNothing,
          reason: 'no delete background is offered',
        );
        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.text(s.chatDeleteConversationTitle), findsNothing);
        expect(_selfRow, findsOneWidget);
        expect((await h.service.loadHistory(_selfId)).single.text, 'KEEP ME');

        await tester.dragFrom(
          tester.getTopLeft(_selfRow) + const Offset(20, 20),
          Offset(travel, 0),
        );
        await tester.pumpAndSettle();
        final Conversation self = h.service.conversations.singleWhere(
          (c) => c.isSelf,
        );
        expect(self.pinned, isTrue);
        expect(self.lastMessage?.text, 'KEEP ME');

        // A friend's row still offers delete on the same swipe.
        await tester.dragFrom(
          tester.getTopRight(_annRow) + const Offset(-20, 20),
          Offset(-travel, 0),
        );
        await tester.pumpAndSettle();
        expect(find.text(s.chatDeleteConversationTitle), findsOneWidget);
        await tester.tap(find.text(s.actionCancel));
        await tester.pumpAndSettle();
      });
    });
  }

  testWidgets('no identity, no "me" contact', (tester) async {
    await pumpChat(
      tester,
      (h) => ContactsPage(
        service: h.service, // the default harness fake has no identity
        identity: null,
        onOpenConversation: (_) {},
        canScan: false,
      ),
    );
    expect(_selfTile, findsNothing);
  });

  testWidgets('a nameless profile falls back to "Me"', (tester) async {
    final StubIdentityService nameless = StubIdentityService(
      identity: Identity(toxId: kSelfToxId, displayName: ''),
    );
    await pumpChat(
      tester,
      (h) => ContactsPage(
        service: h.service,
        identity: nameless,
        onOpenConversation: (_) {},
        canScan: false,
      ),
      harness: ChatHarness(service: FakeChatService(identity: nameless)),
    );
    expect(
      find.descendant(of: _selfTile, matching: find.text(s.chatSelfMe)),
      findsNWidgets(2), // the title fallback and the badge
    );
  });
}

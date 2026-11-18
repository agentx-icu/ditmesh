import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/chat_layout.dart';
import 'package:ditmesh/ui/chat/conversation_list.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_tile.dart';
import 'package:ditmesh/ui/chat/message_input.dart';
import 'package:ditmesh/ui/chat/search/message_search_screen.dart';
import 'package:ditmesh/ui/pages/chat_page.dart';
import 'package:ditmesh/ui/pages/groups_page.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'test_support.dart';

void main() {
  test('master-detail breakpoint is 900 logical pixels', () {
    expect(isMasterDetailWidth(899), isFalse);
    expect(isMasterDetailWidth(900), isTrue);
    expect(isMasterDetailWidth(kMasterDetailMinWidth), isTrue);
  });

  testWidgets('1280 px: list and conversation side by side', (tester) async {
    await pumpChat(tester, (h) {
      h.addAnn();
      return const ChatPage();
    }, size: kDesktop);
    expect(find.byType(MasterDetail), findsOneWidget);
    expect(find.text(s.chatSelectConversation), findsOneWidget);
    expect(find.byType(ConversationScreen), findsNothing);

    await tester.tap(find.text('Ann').first);
    await tester.pumpAndSettle();

    // Both panes are on screen and no route was pushed.
    expect(find.byType(ConversationList), findsOneWidget);
    expect(find.byType(ConversationScreen), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    expect(find.text(s.chatSelectConversation), findsNothing);
    // The list keeps the open row highlighted.
    final ListTile tile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Ann').first,
        matching: find.byType(ListTile),
      ),
    );
    expect(tile.selected, isTrue);
  });

  testWidgets('390 px: tapping pushes the conversation as a route', (
    tester,
  ) async {
    await pumpChat(tester, (h) {
      h.addAnn();
      return const ChatPage();
    }, size: kPhone);
    expect(find.byType(MasterDetail), findsNothing);
    await tester.tap(find.text('Ann'));
    await tester.pumpAndSettle();
    expect(find.byType(ConversationScreen), findsOneWidget);
    expect(find.byType(ConversationList), findsNothing);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(ConversationList), findsOneWidget);
  });

  for (final bool shrink in [false, true]) {
    testWidgets('deleting the selected conversation discards its pending draft'
        '${shrink ? ' after collapsing the panes' : ''}', (tester) async {
      final ChatHarness h = await pumpChat(tester, (h) {
        h.addAnn();
        return const ChatPage();
      }, size: kDesktop);
      final id = 'c2c_$kPeerKey';
      await tester.tap(find.text('Ann').first);
      await tester.pumpAndSettle();
      final Finder draft = find.descendant(
        of: find.byType(MessageInput),
        matching: find.byType(TextField),
      );
      final controller = tester.widget<TextField>(draft).controller!;
      controller.text = 'PERSISTED DRAFT';
      await tester.pump(const Duration(milliseconds: 400));
      expect(h.service.conversations.single.draft, 'PERSISTED DRAFT');

      await tester.tap(find.byType(PopupMenuButton<ConversationAction>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(s.chatDelete));
      await tester.pumpAndSettle();
      if (shrink) {
        tester.view.physicalSize = const Size(820, 1180);
        await tester.pumpAndSettle();
      }
      controller.text = 'PENDING DRAFT';
      await tester.tap(find.widgetWithText(FilledButton, s.chatDelete));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(ConversationScreen), findsNothing);
      expect(h.service.conversations, isEmpty);

      h.service.receiveMessage(id, 'NEW MSG');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ann').first);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(draft).controller!.text, isEmpty);
      expect(h.service.conversations.single.draft, isEmpty);
    });
  }

  testWidgets('contacts opens from the app bar and starts a chat inline', (
    tester,
  ) async {
    await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      h.service.receiveFriendRequest('D' * 64);
      return const ChatPage();
    }, size: kDesktop);
    // A friend has a row before any message, like the Tox backend lists it.
    expect(find.text('Ann'), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // requests badge
    await tester.tap(find.byKey(const ValueKey('chat-contacts-open')));
    await tester.pumpAndSettle();
    expect(find.text(s.chatFriendRequestsCount(1)), findsOneWidget);
    await tester.tap(find.text('Ann').last);
    await tester.pumpAndSettle();
    // Back on the chat page, Ann is open in the detail pane.
    expect(find.byType(ConversationScreen), findsOneWidget);
    expect(find.byType(MasterDetail), findsOneWidget);
  });

  testWidgets('groups page uses the same two-pane rule', (tester) async {
    await pumpChat(tester, (h) {
      h.service.addFakeGroup(
        const Group(id: 'tox_1', name: 'Net', kind: GroupKind.group),
      );
      return const GroupsPage();
    }, size: kDesktop);
    expect(find.byType(MasterDetail), findsOneWidget);
    await tester.tap(find.text('Net').first);
    await tester.pumpAndSettle();
    expect(find.byType(ConversationScreen), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  group('iPad rotation landscape -> portrait (two panes -> one)', () {
    const Size landscape = Size(1180, 820); // iPad Air
    const Size portrait = Size(820, 1180);

    Future<void> rotate(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
    }

    testWidgets('the open conversation stays open, draft included', (
      tester,
    ) async {
      final ChatHarness h = await pumpChat(tester, (h) {
        h.addAnn();
        return const ChatPage();
      }, size: landscape);
      await tester.tap(find.text('Ann').first);
      await tester.pumpAndSettle();
      // The composer's field (the list has a search field too). Keyed, not
      // typed: fill it the way decoded keying does.
      final Finder draft = find.descendant(
        of: find.byType(MessageInput),
        matching: find.byType(TextField),
      );
      tester.widget<TextField>(draft).controller!.text = 'CQ DE';
      await tester.pump();

      await rotate(tester, portrait);
      expect(find.byType(MasterDetail), findsNothing);
      expect(find.byType(ConversationScreen), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(tester.widget<TextField>(draft).controller?.text, 'CQ DE');
      await tester.pump(const Duration(seconds: 1));
      expect(
        h.service.conversations
            .firstWhere((c) => c.id.startsWith('c2c_'))
            .draft,
        'CQ DE',
      );

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(ConversationList), findsOneWidget);
      expect(find.byType(ConversationScreen), findsNothing);
    });

    testWidgets('the groups page keeps the open group too', (tester) async {
      await pumpChat(tester, (h) {
        h.service.addFakeGroup(
          const Group(id: 'tox_1', name: 'Net', kind: GroupKind.group),
        );
        return const GroupsPage();
      }, size: landscape);
      await tester.tap(find.text('Net').first);
      await tester.pumpAndSettle();
      await rotate(tester, portrait);
      expect(find.byType(ConversationScreen), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });

    for (final bool groups in <bool>[false, true]) {
      testWidgets(
        'a search result opens in the ${groups ? 'group' : 'chat'} route '
        'after collapsing the pane',
        (tester) async {
          final String id = groups ? 'group_tox_1' : 'c2c_$kPeerKey';
          await pumpChat(tester, (h) {
            if (groups) {
              h.service.addFakeGroup(
                const Group(id: 'tox_1', name: 'Net', kind: GroupKind.group),
              );
            } else {
              h.addAnn(withMessage: false);
            }
            final start = DateTime(2026, 9, 30);
            h.service.receiveMessage(id, 'NEEDLE QTH PARIS', timestamp: start);
            for (int i = 1; i <= 60; i++) {
              h.service.receiveMessage(
                id,
                'NEWER QSO $i',
                timestamp: start.add(Duration(minutes: i)),
              );
            }
            return groups ? const GroupsPage() : const ChatPage();
          }, size: landscape);
          await tester.tap(find.text(groups ? 'Net' : 'Ann').first);
          await tester.pumpAndSettle();
          expect(find.text('NEEDLE QTH PARIS'), findsNothing);

          await tester.tap(
            find.descendant(
              of: find.byType(ConversationScreen),
              matching: find.byType(PopupMenuButton<String>),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(s.chatSearchMessages));
          await tester.pumpAndSettle();
          final search = find.byType(MessageSearchScreen);
          await tester.enterText(
            find.descendant(of: search, matching: find.byType(TextField)),
            'needle',
          );
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pumpAndSettle();

          await rotate(tester, portrait);
          await tester.tap(find.text('NEEDLE QTH PARIS'));
          await tester.pumpAndSettle();
          expect(search, findsNothing);
          expect(find.byType(ConversationScreen), findsOneWidget);
          expect(find.byType(BackButton), findsOneWidget);
          expect(find.text('NEEDLE QTH PARIS'), findsOneWidget);
        },
      );

      testWidgets(
        'a dialog over the ${groups ? 'group' : 'chat'} pane survives the '
        'collapse; the route reopens once it closes',
        (tester) async {
          final ChatHarness h = await pumpChat(tester, (h) {
            if (groups) {
              h.service.addFakeGroup(
                const Group(id: 'tox_1', name: 'Net', kind: GroupKind.group),
              );
              h.service.receiveMessage('group_tox_1', 'QST DE NET');
              return const GroupsPage();
            }
            h.addAnn();
            return const ChatPage();
          }, size: landscape);
          await tester.tap(find.text(groups ? 'Net' : 'Ann').first);
          await tester.pumpAndSettle();
          final String id = groups ? 'group_tox_1' : 'c2c_$kPeerKey';
          expect(await h.service.loadHistory(id), isNotEmpty);
          final Finder draft = find.descendant(
            of: find.byType(MessageInput),
            matching: find.byType(TextField),
          );
          tester.widget<TextField>(draft).controller!.text = 'KEEP THIS DRAFT';
          await tester.tap(
            find.descendant(
              of: find.byType(ConversationScreen),
              matching: find.byType(PopupMenuButton<String>),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(s.chatClearHistory));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsOneWidget);

          await rotate(tester, portrait);
          // Nothing was pushed above the dialog, and its owner is alive.
          expect(find.byType(AlertDialog), findsOneWidget);
          expect(find.byType(BackButton), findsNothing);
          await tester.tap(
            find.widgetWithText(FilledButton, s.chatClearHistory),
          );
          await tester.pumpAndSettle();
          expect(await h.service.loadHistory(id), isEmpty);

          expect(find.byType(ConversationScreen), findsOneWidget);
          expect(find.byType(BackButton), findsOneWidget);
          expect(
            tester.widget<TextField>(draft).controller!.text,
            'KEEP THIS DRAFT',
          );
        },
      );
    }

    testWidgets('a hidden tab reopens the conversation once it is shown', (
      tester,
    ) async {
      final ValueNotifier<bool> shown = ValueNotifier<bool>(true);
      addTearDown(shown.dispose);
      await pumpChat(tester, (h) {
        h.addAnn();
        return ValueListenableBuilder<bool>(
          valueListenable: shown,
          builder: (_, enabled, child) =>
              TickerMode(enabled: enabled, child: child!),
          child: const ChatPage(),
        );
      }, size: landscape);
      await tester.tap(find.text('Ann').first);
      await tester.pumpAndSettle();

      shown.value = false;
      await rotate(tester, portrait);
      expect(find.byType(BackButton), findsNothing);

      shown.value = true;
      await tester.pumpAndSettle();
      expect(find.byType(ConversationScreen), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });
  });

  testWidgets('without providers the pages fall back to the placeholder', (
    tester,
  ) async {
    const MaterialApp Function(Widget) app = _localizedApp;
    await tester.pumpWidget(app(const ChatPage()));
    expect(find.text(ChatPage.description(s)), findsOneWidget);
    await tester.pumpWidget(app(const GroupsPage()));
    expect(find.text(GroupsPage.description(s)), findsOneWidget);
  });
}

MaterialApp _localizedApp(Widget home) => MaterialApp(
  localizationsDelegates: S.localizationsDelegates,
  supportedLocales: S.supportedLocales,
  locale: const Locale('en'),
  home: home,
);

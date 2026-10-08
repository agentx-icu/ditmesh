import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/chat_layout.dart';
import 'package:ditmesh/ui/chat/conversation_list.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/message_input.dart';
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
    await tester.tap(find.byTooltip(s.chatContacts));
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

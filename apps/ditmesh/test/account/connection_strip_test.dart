import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/account/connection_chip.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/self_badge.dart';
import 'package:ditmesh/ui/contacts/contacts_page.dart';
import 'package:ditmesh/ui/pages/chat_page.dart';
import 'package:ditmesh/ui/shell/app_shell.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'test_app.dart';

final S en = lookupS(const Locale('en'));

/// While the node is not online, the connection chip used to float over the
/// shell's top-right corner — exactly where every page's app-bar action
/// lives — and swallowed taps meant for it (the Chat page's Contacts button
/// could not be opened while "Connecting…", or at all while offline). The
/// chip now sits in its own strip above the shell.
void main() {
  for (final (String label, Size size) in <(String, Size)>[
    ('phone', kPhoneSize),
    ('desktop', kDesktopSize),
  ]) {
    testWidgets('$label: Contacts opens while still connecting', (
      tester,
    ) async {
      final identity = seededIdentityService(
        connectDelay: const Duration(seconds: 30),
      );
      await pumpApp(tester, identity: identity, size: size);
      expect(identity.connectionStatus, ConnectionStatus.connecting);
      expect(find.text(en.connectionConnecting), findsOneWidget);

      expect(find.byType(ChatPage), findsOneWidget);

      final Finder contacts = find.byTooltip(en.chatContacts);
      expect(
        contacts.hitTestable(),
        findsOneWidget,
        reason: 'nothing may cover the app-bar action',
      );
      await tester.tap(contacts);
      await settle(tester);
      expect(find.byType(ContactsPage), findsOneWidget);

      await tester.pump(const Duration(seconds: 31));
      await settle(tester);
    });
  }

  testWidgets('desktop: the detail pane menu is reachable while connecting', (
    tester,
  ) async {
    final identity = seededIdentityService(
      connectDelay: const Duration(seconds: 30),
    );
    await pumpApp(tester, identity: identity, size: kDesktopSize);
    // The note-to-self row is always there; it opens in the detail pane.
    await tester.tap(find.byType(SelfAvatar));
    await settle(tester);
    expect(find.byType(ConversationScreen), findsOneWidget);
    final Finder menu = find.descendant(
      of: find.byType(ConversationScreen),
      matching: find.byType(PopupMenuButton<String>),
    );
    expect(menu.hitTestable(), findsOneWidget);
    await tester.tap(menu);
    await settle(tester);
    expect(find.text(en.chatClearHistory), findsOneWidget);
    await tester.pump(const Duration(seconds: 31));
    await settle(tester);
  });

  testWidgets('the shell keeps its state when the node comes online', (
    tester,
  ) async {
    final identity = seededIdentityService(
      connectDelay: const Duration(seconds: 2),
    );
    await pumpApp(tester, identity: identity);
    final Finder groupsTab = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.groups_outlined),
    );
    await tester.tap(groupsTab);
    await settle(tester);
    final State shellState = tester.state(find.byType(AppShell));
    expect(find.byType(ConnectionChip), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
    expect(identity.connectionStatus, ConnectionStatus.online);
    expect(find.byType(ConnectionChip), findsNothing);
    expect(
      identical(tester.state(find.byType(AppShell)), shellState),
      isTrue,
      reason: 'the shell must not be remounted',
    );
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    // Online: the shell gets the full top inset back (no strip).
    expect(tester.getTopLeft(find.byType(AppShell)).dy, 0);
  });

  testWidgets(
    'a notched phone: the strip takes the top inset, then returns it',
    (tester) async {
      const double inset = 47; // status bar / notch, logical px at DPR 1
      tester.view.padding = const FakeViewPadding(top: inset);
      tester.view.viewPadding = const FakeViewPadding(top: inset);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      final identity = seededIdentityService(
        connectDelay: const Duration(seconds: 2),
      );
      await pumpApp(tester, identity: identity);
      MediaQueryData shellMedia() =>
          MediaQuery.of(tester.element(find.byType(AppShell)));

      // Connecting: the chip sits below the status bar, and the shell below the
      // strip sees no top inset (its app bar is not padded a second time).
      expect(
        tester.getTopLeft(find.byType(ConnectionChip)).dy,
        greaterThanOrEqualTo(inset),
      );
      expect(shellMedia().padding.top, 0);
      expect(shellMedia().viewPadding.top, 0);
      final double appBarTop = tester.getTopLeft(find.byType(AppBar).first).dy;
      expect(appBarTop, greaterThan(inset));
      expect(
        tester.getSize(find.byType(AppBar).first).height,
        kToolbarHeight,
        reason:
            'no status-bar padding inside the app bar while the strip shows',
      );

      // Online: no strip; the shell owns the inset again.
      await tester.pump(const Duration(seconds: 3));
      await settle(tester);
      expect(find.byType(ConnectionChip), findsNothing);
      expect(shellMedia().padding.top, inset);
      expect(shellMedia().viewPadding.top, inset);
      expect(tester.getTopLeft(find.byType(AppShell)).dy, 0);
      expect(
        tester.getSize(find.byType(AppBar).first).height,
        kToolbarHeight + inset,
      );
    },
  );

  testWidgets('the chip strip does not overlap the shell', (tester) async {
    final identity = seededIdentityService(
      connectDelay: const Duration(seconds: 30),
    );
    await pumpApp(tester, identity: identity);
    final Rect chip = tester.getRect(find.byType(ConnectionChip));
    final Rect appBar = tester.getRect(find.byType(AppBar).first);
    expect(chip.overlaps(appBar), isFalse);
    await tester.pump(const Duration(seconds: 31));
    await settle(tester);
  });
}

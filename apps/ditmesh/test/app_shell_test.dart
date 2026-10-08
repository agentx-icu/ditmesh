import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/app_services.dart';
import 'package:ditmesh/di/fake_backend_factory.dart';
import 'package:ditmesh/i18n/locale_controller.dart';
import 'package:ditmesh/i18n/locale_resolution.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/main.dart';
import 'package:ditmesh/notifications/notification_payload.dart';
import 'package:ditmesh/notifications/testing/fake_badge_api.dart';
import 'package:ditmesh/notifications/testing/fake_local_notifications_api.dart';
import 'package:ditmesh/ui/account/backup_file_gateway.dart';
import 'package:ditmesh/ui/account/identity_card.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_list.dart';
import 'package:ditmesh/ui/contacts/contacts_page.dart';
import 'package:ditmesh/ui/learn/drill_session_guard.dart';
import 'package:ditmesh/ui/pages/chat_page.dart';
import 'package:ditmesh/ui/pages/groups_page.dart';
import 'package:ditmesh/ui/pages/me_page.dart';
import 'package:ditmesh/ui/pages/reference_page.dart';
import 'package:ditmesh/ui/reference/reference_screen.dart';
import 'package:ditmesh/ui/responsive.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:provider/provider.dart';

import 'account/test_app.dart';

/// The harness renders in English (no override, default test locale).
final S en = lookupS(const Locale('en'));

final List<String> _labels = [
  ChatPage.title(en),
  GroupsPage.title(en),
  ReferencePage.title(en),
  MePage.title(en),
];

/// One widget that only the selected destination's page renders. The
/// placeholder pages show their description; Chat shows its conversation list
/// (never empty once an identity exists: the note to self is always there);
/// the Me page shows the identity card.
final Map<String, Finder> _pageMarkers = {
  ChatPage.title(en): find.byType(ConversationList),
  GroupsPage.title(en): find.text(GroupsPage.description(en)),
  ReferencePage.title(en): find.byType(ReferenceScreen),
  MePage.title(en): find.byType(IdentityCard),
};

/// The shell renders only behind the startup gate, so every test boots the
/// app with a ready (plain, already-created) fake identity.
Future<void> _pumpAt(
  WidgetTester tester,
  Size logicalSize, {
  String? localeTag,
  FakeLocalNotificationsApi? notifications,
}) async {
  tester.view.physicalSize = logicalSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final identity = FakeIdentityService.withProfile(
    identity: Identity(
      toxId: FakeIdentityService.toxIdForSeed(1),
      displayName: 'Shell Tester',
    ),
    connectDelay: Duration.zero,
    dataDirectoryPath: freshDataDirectory(),
  );
  await tester.pumpWidget(
    DitmeshApp(
      backend: FakeBackendFactory(identityService: identity),
      backupFiles: FakeBackupFileGateway(),
      notifications: notifications == null
          ? null
          : NotificationApis(
              notifications: notifications,
              badge: FakeBadgeApi(),
            ),
      localeStore: acceptedTermsStore({
        LocaleController.storageKey: ?localeTag,
      }),
    ),
  );
  await settle(tester);
}

/// Only the selected destination's page is visible in the IndexedStack, so
/// its marker appearing exactly once is the switch signal.
void _expectSelected(String label) {
  expect(_pageMarkers[label]!, findsOneWidget);
  for (final other in _labels.where((l) => l != label)) {
    expect(_pageMarkers[other]!, findsNothing);
  }
}

void main() {
  for (final tag in ['zh_Hant', 'ja', 'ko', 'de', 'fr', 'es', 'pt', 'ru']) {
    for (final size in [const Size(390, 844), kDesktopSize]) {
      testWidgets('$tag renders all destinations at $size', (tester) async {
        await _pumpAt(tester, size, localeTag: tag);
        final s = lookupS(parseLocaleTag(tag)!);
        final navigation = find.byType(
          size.width < 600 ? NavigationBar : NavigationRail,
        );
        final markers = {
          s.navChat: find.byType(ConversationList),
          s.navGroups: find.text(s.navGroupsDescription),
          s.navReference: find.byType(ReferenceScreen),
          s.navMe: find.byType(IdentityCard),
        };
        for (final entry in markers.entries) {
          final label = find.descendant(
            of: navigation,
            matching: find.text(entry.key),
          );
          expect(label, findsOneWidget);
          await tester.tap(label);
          await settle(tester);
          expect(entry.value, findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      });
    }
  }

  group('AppShell at phone width', () {
    testWidgets('renders a bottom NavigationBar with four destinations', (
      tester,
    ) async {
      await _pumpAt(tester, kPhoneSize);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      for (final label in _labels) {
        expect(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
          findsOneWidget,
        );
      }
      _expectSelected(ChatPage.title(en));
      expect(find.byIcon(Icons.school_outlined), findsNothing);
    });

    testWidgets('tapping a destination switches the page', (tester) async {
      await _pumpAt(tester, kPhoneSize);
      for (final label in _labels.skip(1)) {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
        );
        await settle(tester);
        _expectSelected(label);
      }
    });
  });

  group('AppShell at desktop width', () {
    testWidgets('renders a NavigationRail with four destinations', (
      tester,
    ) async {
      await _pumpAt(tester, kDesktopSize);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      for (final label in _labels) {
        expect(
          find.descendant(
            of: find.byType(NavigationRail),
            matching: find.text(label),
          ),
          findsOneWidget,
        );
      }
      _expectSelected(ChatPage.title(en));
      expect(find.byIcon(Icons.school_outlined), findsNothing);
    });

    testWidgets('tapping a rail destination switches the page', (tester) async {
      await _pumpAt(tester, kDesktopSize);
      for (final label in _labels.skip(1)) {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationRail),
            matching: find.text(label),
          ),
        );
        await settle(tester);
        _expectSelected(label);
      }
    });
  });

  group('notification taps', () {
    /// Every ConversationScreen in the navigator, covered routes included.
    final Finder screens = find.byType(ConversationScreen, skipOffstage: false);

    Future<(FakeLocalNotificationsApi, String)> openChat(
      WidgetTester tester,
    ) async {
      final api = FakeLocalNotificationsApi();
      await _pumpAt(tester, kPhoneSize, notifications: api);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(ChatPage.title(en)),
        ),
      );
      await settle(tester);
      final chat = tester
          .element(find.byType(ConversationList))
          .read<ChatService>();
      return (api, chat.conversations.first.id);
    }

    testWidgets('tapping the open conversation does not stack a duplicate', (
      tester,
    ) async {
      final (api, id) = await openChat(tester);
      api.tapTarget(OpenConversationTarget(id));
      await settle(tester);
      expect(screens, findsOneWidget);

      // Reading it already: a second tap (or a cold-start replay) is a no-op.
      api.tapTarget(OpenConversationTarget(id));
      await settle(tester);
      expect(screens, findsOneWidget);
    });

    testWidgets('a group invite tap leaves the chat for the Groups tab', (
      tester,
    ) async {
      final (api, id) = await openChat(tester);
      api.tapTarget(OpenConversationTarget(id));
      await settle(tester);
      expect(screens, findsOneWidget);

      api.tapTarget(const GroupInviteTarget('invite-1'));
      await settle(tester);
      expect(screens, findsNothing);
      _expectSelected(GroupsPage.title(en));

      // A friend request opens contacts above the Chat tab.
      api.tapTarget(FriendRequestTarget('A' * 64));
      await settle(tester);
      expect(find.byType(ContactsPage), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      _expectSelected(ChatPage.title(en));
    });

    testWidgets('two quick taps for one conversation open it once', (
      tester,
    ) async {
      final (api, id) = await openChat(tester);
      // No frame between them: the first screen has not built yet.
      api.tapTarget(OpenConversationTarget(id));
      api.tapTarget(OpenConversationTarget(id));
      await settle(tester);
      expect(screens, findsOneWidget);

      // The reservation is released when the route pops.
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(screens, findsNothing);
      api.tapTarget(OpenConversationTarget(id));
      await settle(tester);
      expect(screens, findsOneWidget);
    });

    testWidgets('A, B, A before the first frame opens only A', (tester) async {
      final (api, a) = await openChat(tester);
      final chat =
          tester.element(find.byType(ConversationList)).read<ChatService>()
              as FakeChatService;
      final String bob = 'B' * 64;
      chat.addFakeFriend(Friend(publicKey: bob, displayName: 'Bob'));
      chat.receiveMessage('c2c_$bob', 'CQ DE BOB');
      await settle(tester);

      api.tapTarget(OpenConversationTarget(a));
      api.tapTarget(OpenConversationTarget('c2c_$bob'));
      api.tapTarget(OpenConversationTarget(a));
      await settle(tester);
      // Only the latest tap is routed: the earlier two were superseded.
      expect(screens, findsOneWidget);
      expect(tester.widget<ConversationScreen>(screens).target.id, a);
    });

    testWidgets('an invite tap right after a conversation tap', (tester) async {
      final (api, id) = await openChat(tester);
      // No frame between: the conversation route is pushed, not built.
      api.tapTarget(OpenConversationTarget(id));
      api.tapTarget(const GroupInviteTarget('invite-1'));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(screens, findsNothing);
      _expectSelected(GroupsPage.title(en));
    });

    testWidgets('a friend-request tap does not discard a guarded drill', (
      tester,
    ) async {
      final api = FakeLocalNotificationsApi();
      await _pumpAt(tester, kPhoneSize, notifications: api);
      final navigator = Navigator.of(
        tester.element(find.byType(NavigationBar)),
      );
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const DrillLeaveGuard(
              guard: true,
              child: Scaffold(body: Text('drill in progress')),
            ),
          ),
        ),
      );
      await settle(tester);

      api.tapTarget(FriendRequestTarget('A' * 64));
      await settle(tester);
      // Contacts open above the drill; nothing was popped, so the guard is
      // never bypassed (and not even asked).
      expect(find.byType(ContactsPage), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        find.text('drill in progress', skipOffstage: false),
        findsOneWidget,
      );

      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.text('drill in progress'), findsOneWidget);
    });
  });

  test('breakpoint is exactly 600 logical pixels', () {
    expect(layoutClassForWidth(599), LayoutClass.compact);
    expect(layoutClassForWidth(600), LayoutClass.expanded);
    expect(layoutClassForWidth(kCompactMaxWidth), LayoutClass.expanded);
  });
}

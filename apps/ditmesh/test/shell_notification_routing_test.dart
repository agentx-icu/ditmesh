import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/app_services.dart';
import 'package:ditmesh/di/fake_backend_factory.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/main.dart';
import 'package:ditmesh/notifications/notifications.dart';
import 'package:ditmesh/notifications/testing/fake_badge_api.dart';
import 'package:ditmesh/notifications/testing/fake_local_notifications_api.dart';
import 'package:ditmesh/ui/account/backup_file_gateway.dart';
import 'package:ditmesh/ui/account/unlock_page.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/contacts/contacts_page.dart';
import 'package:ditmesh/ui/groups/group_invites_page.dart';
import 'package:ditmesh/ui/moderation/terms_gate_page.dart';
import 'package:ditmesh/ui/pages/groups_page.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:provider/provider.dart';

import 'account/test_app.dart';

final String _peer = 'B' * 64;
final String _peerConv = 'c2c_$_peer';

/// The real app (fake backend) with recording notification fakes, at phone
/// width so a conversation opens as a route.
Future<FakeLocalNotificationsApi> _pump(
  WidgetTester tester, {
  String? launchPayload,
  String? password,
  bool termsAccepted = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final FakeLocalNotificationsApi api = FakeLocalNotificationsApi(
    launchPayload: launchPayload,
  );
  final identity = FakeIdentityService.withProfile(
    identity: Identity(
      toxId: FakeIdentityService.toxIdForSeed(1),
      displayName: 'Router Tester',
    ),
    password: password,
    connectDelay: Duration.zero,
    dataDirectoryPath: freshDataDirectory(),
  );
  await tester.pumpWidget(
    DitmeshApp(
      backend: FakeBackendFactory(identityService: identity),
      backupFiles: FakeBackupFileGateway(),
      notifications: NotificationApis(
        notifications: api,
        badge: FakeBadgeApi(),
      ),
      localeStore: termsAccepted ? acceptedTermsStore() : null,
    ),
  );
  await settle(tester);
  return api;
}

/// Types [password] on the unlock page and submits it.
Future<void> _unlock(WidgetTester tester, String password) async {
  final Finder page = find.byType(UnlockPage);
  expect(page, findsOneWidget);
  await tester.enterText(
    find.descendant(of: page, matching: find.byType(TextField)),
    password,
  );
  await tester.pump();
  await tester.tap(
    find.descendant(of: page, matching: find.byType(FilledButton)),
  );
  await settle(tester);
}

void main() {
  testWidgets('a cold-start tap opens its conversation once the shell is up', (
    tester,
  ) async {
    await _pump(
      tester,
      launchPayload: OpenConversationTarget(_peerConv).encode(),
    );
    expect(find.byType(ConversationScreen), findsOneWidget);
    // An unknown peer is titled with its short key, not the raw id.
    expect(find.textContaining(_peerConv), findsNothing);
  });

  testWidgets('a cold-start tap survives the unlock page of a '
      'password-locked identity', (tester) async {
    await _pump(
      tester,
      launchPayload: OpenConversationTarget(_peerConv).encode(),
      password: 'hunter2',
    );
    expect(find.byType(ConversationScreen), findsNothing);
    await _unlock(tester, 'hunter2');
    expect(find.byType(ConversationScreen), findsOneWidget);
  });

  testWidgets('a tap while the unlock page shows is routed after unlock', (
    tester,
  ) async {
    final api = await _pump(tester, password: 'hunter2');
    api.tapTarget(OpenConversationTarget(_peerConv));
    await settle(tester);
    expect(find.byType(ConversationScreen), findsNothing);
    await _unlock(tester, 'hunter2');
    expect(find.byType(ConversationScreen), findsOneWidget);
  });

  testWidgets('a cold-start tap survives unlock and the terms gate', (
    tester,
  ) async {
    await _pump(
      tester,
      launchPayload: OpenConversationTarget(_peerConv).encode(),
      password: 'hunter2',
      termsAccepted: false,
    );
    await _unlock(tester, 'hunter2');
    expect(find.byType(TermsGatePage), findsOneWidget);
    expect(find.byType(ConversationScreen), findsNothing);
    final Finder agree = find.byKey(
      const ValueKey('terms-agree'),
      skipOffstage: false,
    );
    await tester.ensureVisible(agree);
    await tester.pumpAndSettle();
    await tester.tap(agree);
    await settle(tester);
    expect(find.byType(ConversationScreen), findsOneWidget);
  });

  testWidgets('tapping the same conversation again does not stack it', (
    tester,
  ) async {
    final api = await _pump(tester);
    api.tapTarget(OpenConversationTarget(_peerConv));
    await settle(tester);
    api.tapTarget(OpenConversationTarget(_peerConv));
    await settle(tester);
    expect(find.byType(ConversationScreen, skipOffstage: false), findsOneWidget);
  });

  testWidgets('a friend-request tap opens contacts', (tester) async {
    final api = await _pump(tester);
    api.tapTarget(FriendRequestTarget(_peer));
    await settle(tester);
    expect(find.byType(ContactsPage), findsOneWidget);
  });

  testWidgets('a group-invite tap shows the groups page', (tester) async {
    final api = await _pump(tester);
    api.tapTarget(OpenConversationTarget(_peerConv));
    await settle(tester);
    api.tapTarget(const GroupInviteTarget('invite-1'));
    await settle(tester);
    expect(find.byType(ConversationScreen), findsNothing);
    expect(find.byType(GroupsPage), findsOneWidget);
  });

  testWidgets('an invite tap under another flow opens the invites on top', (
    tester,
  ) async {
    final api = await _pump(tester);
    final BuildContext shell = tester.element(
      find.byType(GroupsPage, skipOffstage: false),
    );
    final FakeChatService chat =
        Provider.of<ChatService>(shell, listen: false) as FakeChatService;
    final GroupInvite invite = chat.receiveGroupInvite(
      fromPublicKey: _peer,
      groupName: 'Net',
    );
    // Something unrelated covers the shell (an account / settings page).
    unawaited(
      Navigator.of(shell).push(
        MaterialPageRoute<void>(builder: (_) => const Scaffold()),
      ),
    );
    await settle(tester);
    api.tapTarget(GroupInviteTarget(invite.inviteId));
    await settle(tester);
    expect(find.byType(GroupInvitesPage), findsOneWidget);
    expect(find.text('Net'), findsOneWidget);
  });

  testWidgets('a group join refusal is reported while another tab is shown', (
    tester,
  ) async {
    await _pump(tester);
    final BuildContext shell = tester.element(
      find.byType(GroupsPage, skipOffstage: false),
    );
    final FakeChatService chat =
        Provider.of<ChatService>(shell, listen: false) as FakeChatService;
    final S s = S.of(shell);
    expect(find.byType(GroupsPage), findsNothing, reason: 'chat tab shown');
    chat.refuseGroupJoin(
      const GroupJoinRefusal(
        groupId: 'tox_4',
        groupName: 'DX',
        reason: GroupJoinRefusalReason.invalidPassword,
      ),
    );
    await settle(tester);
    expect(find.text(s.chatGroupJoinRefusedPassword('DX')), findsOneWidget);
  });
}

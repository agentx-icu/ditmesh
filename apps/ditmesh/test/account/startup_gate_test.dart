import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/i18n/chat_error_messages.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/startup/startup_screens.dart';
import 'package:ditmesh/ui/account/connection_chip.dart';
import 'package:ditmesh/ui/account/unlock_page.dart';
import 'package:ditmesh/ui/account/welcome_page.dart';
import 'package:ditmesh/ui/shell/app_shell.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'test_app.dart';

/// The harness renders in English (no override, default test locale).
final S en = lookupS(const Locale('en'));

void main() {
  testWidgets('IdentityState.none routes to the welcome page', (tester) async {
    await pumpApp(tester, identity: freshIdentityService());
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    expect(find.text(en.accountCreateIdentity), findsOneWidget);
    expect(find.text(en.accountRestoreFromBackup), findsOneWidget);
  });

  testWidgets('IdentityState.locked routes to the unlock page', (tester) async {
    await pumpApp(tester, identity: seededIdentityService(password: 'pw'));
    expect(find.byType(UnlockPage), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets('IdentityState.ready opens, shows the shell and connects', (
    tester,
  ) async {
    final identity = seededIdentityService();
    await pumpApp(tester, identity: identity);
    expect(find.byType(AppShell), findsOneWidget);
    expect(identity.current, isNotNull);
    expect(identity.connectionStatus, ConnectionStatus.online);
    // Online → the overlay chip is hidden; the shell is unobstructed.
    expect(find.text(en.connectionConnecting), findsNothing);
    expect(find.text(en.connectionOffline), findsNothing);
  });

  testWidgets('connection does not block the shell; chip shows meanwhile', (
    tester,
  ) async {
    final identity = seededIdentityService(
      connectDelay: const Duration(seconds: 2),
    );
    await pumpApp(tester, identity: identity);
    expect(find.byType(AppShell), findsOneWidget);
    expect(identity.connectionStatus, ConnectionStatus.connecting);
    expect(find.byType(ConnectionChip), findsWidgets);
    expect(find.text(en.connectionConnecting), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
    expect(identity.connectionStatus, ConnectionStatus.online);
    expect(find.text(en.connectionConnecting), findsNothing);
  });

  testWidgets('inspect failure shows the retry screen; retry recovers', (
    tester,
  ) async {
    final identity = seededIdentityService()
      ..inspectError = StateError('disk unreadable');
    await pumpApp(tester, identity: identity);
    expect(find.byType(StartupErrorPage), findsOneWidget);
    // Non-ChatException: generic message plus the raw detail for bug reports.
    expect(find.textContaining(en.errorUnknown), findsOneWidget);
    expect(find.textContaining('disk unreadable'), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);

    await tester.tap(find.text(en.actionRetry));
    await settle(tester);
    expect(find.byType(AppShell), findsOneWidget);
  });

  test('describeChatError maps ChatException codes, not their messages', () {
    expect(
      describeChatError(en, const ChatException('wrong_password', 'raw')),
      en.errorWrongPassword,
    );
    expect(describeChatError(en, StateError('x')), en.errorUnknown);
  });

  testWidgets('deleting the identity returns to onboarding', (tester) async {
    final identity = seededIdentityService();
    await pumpApp(tester, identity: identity);
    expect(find.byType(AppShell), findsOneWidget);
    await identity.deleteIdentity();
    await settle(tester);
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}

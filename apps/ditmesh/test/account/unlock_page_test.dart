import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/account/restore_backup_page.dart';
import 'package:ditmesh/ui/account/unlock_page.dart';
import 'package:ditmesh/ui/shell/app_shell.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'test_app.dart';

/// The harness renders in English (no override, default test locale).
final S en = lookupS(const Locale('en'));

void main() {
  testWidgets('wrong password shows an error and stays locked', (tester) async {
    final identity = seededIdentityService(password: 'secret');
    await pumpApp(tester, identity: identity);
    expect(find.byType(UnlockPage), findsOneWidget);
    expect(buttonEnabled(tester, en.accountUnlockButton), isFalse);

    await tester.enterText(find.byType(TextField), 'nope');
    await settle(tester);
    expect(buttonEnabled(tester, en.accountUnlockButton), isTrue);
    await tester.tap(find.text(en.accountUnlockButton));
    await settle(tester);

    expect(find.text(en.errorWrongPassword), findsOneWidget);
    expect(find.byType(UnlockPage), findsOneWidget);
    expect(identity.current, isNull);
    expect(await identity.inspect(), IdentityState.locked);
  });

  testWidgets('correct password unlocks into the shell', (tester) async {
    final identity = seededIdentityService(password: 'secret');
    await pumpApp(tester, identity: identity);
    await tester.enterText(find.byType(TextField), 'secret');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(find.byType(AppShell), findsOneWidget);
    expect(identity.current?.displayName, 'Ann');
    expect(identity.connectionStatus, ConnectionStatus.online);
  });

  testWidgets('show/hide toggles obscuring', (tester) async {
    await pumpApp(tester, identity: seededIdentityService(password: 'x'));
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, true);
    await tester.tap(find.byTooltip(en.accountShowPassword));
    await settle(tester);
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, false);
  });

  testWidgets('"restore from backup instead" opens the restore page', (
    tester,
  ) async {
    await pumpApp(tester, identity: seededIdentityService(password: 'x'));
    await tester.tap(find.text(en.accountUnlockRestoreInstead));
    await settle(tester);
    expect(find.byType(RestoreBackupPage), findsOneWidget);
  });
}

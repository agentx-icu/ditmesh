import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/account/backup_file_gateway.dart';
import 'package:ditmesh/ui/account/backup_wizard_page.dart';
import 'package:ditmesh/ui/account/create_identity_page.dart';
import 'package:ditmesh/ui/account/restore_backup_page.dart';
import 'package:ditmesh/ui/account/tox_id_qr_dialog.dart';
import 'package:ditmesh/ui/account/welcome_page.dart';
import 'package:ditmesh/ui/shell/app_shell.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';

import 'test_app.dart';

/// The harness renders in English (no override, default test locale).
final S en = lookupS(const Locale('en'));

Future<void> _openCreatePage(WidgetTester tester) async {
  await tapVisible(tester, find.text(en.accountCreateIdentity));
  expect(find.byType(CreateIdentityPage), findsOneWidget);
}

Future<void> _createNamed(WidgetTester tester, String name) async {
  await tester.enterText(
    find.widgetWithText(TextField, en.accountDisplayName),
    name,
  );
  await tapVisible(tester, find.text(en.accountCreateButton));
}

void main() {
  late FakeIdentityService identity;
  late FakeBackupFileGateway files;

  setUp(() {
    identity = freshIdentityService();
    files = FakeBackupFileGateway();
  });

  testWidgets('create → backup wizard; continue needs the checkbox', (
    tester,
  ) async {
    await pumpApp(tester, identity: identity, backupFiles: files);
    await _openCreatePage(tester);
    await _createNamed(tester, 'Ann');

    expect(identity.current?.displayName, 'Ann');
    expect(identity.current?.hasPassword, isFalse);
    // The complete backup is sealed with a passphrase whatever the
    // identity password (F10).
    expect(find.text(en.backupXWizardInside), findsOneWidget);
    expect(find.text(en.accountBackupWhatIsInsidePlain), findsNothing);
    expect(find.byType(BackupWizardPage), findsOneWidget);
    expect(find.byType(CreateIdentityPage), findsNothing);
    expect(find.byType(AppShell), findsNothing);
    // Mandatory: no back arrow.
    expect(find.byType(BackButton), findsNothing);
    expect(buttonEnabled(tester, en.accountBackupContinue), isFalse);

    // Saving works but is not enough on its own.
    // Label is "Save" on desktop and "Share" on mobile; find by key.
    await tapVisible(tester, find.byKey(BackupWizardPage.saveButtonKey));
    await completeEncryptedBackup(tester);
    expect(files.saved, hasLength(1));
    expect(isEncryptedBackup(files.saved.single), isTrue);
    expect(files.savedNames.single, startsWith('ditmesh-Ann-'));
    expect(files.savedNames.single, endsWith('.mcqbackup'));
    expect(buttonEnabled(tester, en.accountBackupContinue), isFalse);

    await tapVisible(tester, find.byType(Checkbox));
    expect(buttonEnabled(tester, en.accountBackupContinue), isTrue);

    await tapVisible(tester, find.text(en.accountBackupContinue));
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(BackupWizardPage), findsNothing);
  });

  testWidgets('wizard shows the Tox ID QR dialog', (tester) async {
    await pumpApp(tester, identity: identity, backupFiles: files);
    await _openCreatePage(tester);
    await _createNamed(tester, 'Ann');
    await tapVisible(tester, find.text(en.accountShowQr));
    expect(find.byType(ToxIdQrDialog), findsOneWidget);
    expect(find.text(en.actionClose), findsOneWidget);
  });

  testWidgets('empty name is rejected before creating anything', (
    tester,
  ) async {
    await pumpApp(tester, identity: identity, backupFiles: files);
    await _openCreatePage(tester);
    await tapVisible(tester, find.text(en.accountCreateButton));
    expect(find.text(en.accountDisplayNameRequired), findsOneWidget);
    expect(identity.hasStoredProfile, isFalse);
    expect(find.byType(CreateIdentityPage), findsOneWidget);
  });

  testWidgets('password must be confirmed; then identity is encrypted', (
    tester,
  ) async {
    await pumpApp(tester, identity: identity, backupFiles: files);
    await _openCreatePage(tester);
    await tester.enterText(
      find.widgetWithText(TextField, en.accountDisplayName),
      'Ann',
    );
    await tester.enterText(
      find.widgetWithText(TextField, en.accountPasswordOptional),
      'correct horse',
    );
    await settle(tester);
    expect(find.text(en.accountStrengthStrong), findsNothing);
    expect(find.text(en.accountStrengthFair), findsOneWidget);
    expect(find.text(en.accountConfirmPassword), findsOneWidget);

    await tapVisible(tester, find.text(en.accountCreateButton));
    expect(find.text(en.accountPasswordsDoNotMatch), findsOneWidget);
    expect(identity.hasStoredProfile, isFalse);

    await tester.enterText(
      find.widgetWithText(TextField, en.accountConfirmPassword),
      'correct horse',
    );
    await tapVisible(tester, find.text(en.accountCreateButton));
    expect(identity.current?.hasPassword, isTrue);
    expect(identity.storedPassword, 'correct horse');
    expect(find.byType(BackupWizardPage), findsOneWidget);
    expect(find.text(en.backupXWizardInside), findsOneWidget);
  });

  testWidgets('restore from backup skips the wizard and opens the shell', (
    tester,
  ) async {
    final source = FakeIdentityService.withProfile(
      identity: testIdentity(),
      connectDelay: Duration.zero,
    );
    addTearDown(source.dispose);
    await source.open();
    await source.changePassword(newPassword: 'pw');
    files.pickResult = await source.exportBackup();

    await pumpApp(tester, identity: identity, backupFiles: files);
    await tapVisible(tester, find.text(en.accountRestoreFromBackup));
    expect(find.byType(RestoreBackupPage), findsOneWidget);

    // No file yet.
    await tapVisible(tester, find.text(en.accountRestoreButton));
    expect(find.text(en.accountRestoreNoFile), findsOneWidget);

    await tapVisible(tester, find.text(en.accountRestoreChooseFile));
    expect(
      find.text(en.accountRestoreFileChosenSize(files.pickResult!.length)),
      findsOne,
    );

    // Wrong password is reported inline.
    await tapVisible(tester, find.text(en.accountRestoreButton));
    expect(find.text(en.errorWrongPassword), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, en.accountPasswordOptional),
      'pw',
    );
    await tapVisible(tester, find.text(en.accountRestoreButton));
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(BackupWizardPage), findsNothing);
    expect(identity.current?.toxId, testIdentity().toxId);
  });

  testWidgets('welcome page explains the no-server model', (tester) async {
    await pumpApp(tester, identity: identity, backupFiles: files);
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.text(en.accountWelcomePointNoServer), findsOneWidget);
    expect(find.text(en.accountWelcomePointBackup), findsOneWidget);
  });

  testWidgets('a file too large to be a backup says so at pick time', (
    tester,
  ) async {
    files.pickError = const ChatException('invalid_backup', 'too large');
    await pumpApp(tester, identity: identity, backupFiles: files);
    await tapVisible(tester, find.text(en.accountRestoreFromBackup));
    await tapVisible(tester, find.text(en.accountRestoreChooseFile));
    expect(find.text(en.accountRestoreInvalidFile), findsOneWidget);
  });
}

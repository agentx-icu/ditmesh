import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/account/backup_file_gateway.dart';
import 'package:ditmesh/ui/account/change_password_page.dart';
import 'package:ditmesh/ui/account/delete_identity_dialog.dart';
import 'package:ditmesh/ui/account/edit_profile_page.dart';
import 'package:ditmesh/ui/account/identity_card.dart';
import 'package:ditmesh/ui/account/welcome_page.dart';
import 'package:ditmesh/ui/learn/settings/training_settings_screen.dart';
import 'package:ditmesh/ui/pages/me_page.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';

import 'test_app.dart';

/// The harness renders in English (no override, default test locale).
final S en = lookupS(const Locale('en'));

Future<void> _openMe(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(MePage.title(en)),
    ),
  );
  await settle(tester);
  expect(find.byType(IdentityCard), findsOneWidget);
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await settle(tester);
}

void main() {
  late FakeIdentityService identity;
  late FakeBackupFileGateway files;

  setUp(() {
    identity = seededIdentityService();
    files = FakeBackupFileGateway();
  });

  testWidgets('identity card shows name, status and copies the Tox ID', (
    tester,
  ) async {
    final clipboard = ClipboardSpy(tester);
    await pumpApp(tester, identity: identity, backupFiles: files);
    await _openMe(tester);

    expect(find.text('Ann'), findsOneWidget);
    expect(find.text('QRV on 40m'), findsOneWidget);
    expect(find.text(en.connectionOnline), findsOneWidget);

    await tester.tap(find.byTooltip(en.actionCopy));
    await settle(tester);
    expect(clipboard.copied, [identity.current!.toxId]);
    expect(find.text(en.accountCopied), findsOneWidget);
  });

  testWidgets('export backup saves through the gateway', (tester) async {
    await pumpApp(tester, identity: identity, backupFiles: files);
    await _openMe(tester);
    await _scrollTo(tester, find.text(en.accountExportBackup));
    await tester.tap(find.text(en.accountExportBackup));
    await settle(tester);
    // Too short, then mismatched: nothing is written.
    Finder field(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(TextField),
    );
    await tester.enterText(field('backup-x-passphrase'), 'short');
    await tapVisible(tester, find.byKey(const ValueKey('backup-x-export')));
    expect(find.text(en.backupXPassphraseTooShort), findsOneWidget);
    await tester.enterText(field('backup-x-passphrase'), 'correct horse');
    await tester.enterText(field('backup-x-confirm'), 'correct hose');
    await tapVisible(tester, find.byKey(const ValueKey('backup-x-export')));
    expect(find.text(en.backupXPassphraseMismatch), findsOneWidget);
    expect(files.saved, isEmpty);
    await completeEncryptedBackup(tester);
    expect(files.saved, hasLength(1));
    expect(isEncryptedBackup(files.saved.single), isTrue);
    expect(find.text(en.accountBackupSaved), findsOneWidget);
  });

  testWidgets('export backup anchors the iPad share popover to the tile', (
    tester,
  ) async {
    await pumpApp(
      tester,
      identity: identity,
      backupFiles: files,
      size: const Size(1024, 1366), // iPad portrait: the rail, not the bar
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text(MePage.title(en)),
      ),
    );
    await settle(tester);
    final tile = find.ancestor(
      of: find.text(en.accountExportBackup),
      matching: find.byType(ListTile),
    );
    await _scrollTo(tester, tile);
    await tester.tap(tile);
    await settle(tester);
    // The encrypted backup page's create button anchors the popover.
    Finder field(String key) => find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(TextField),
    );
    await tester.enterText(field('backup-x-passphrase'), 'correct horse');
    await tester.enterText(field('backup-x-confirm'), 'correct horse');
    final button = find.byKey(const ValueKey('backup-x-export'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    final buttonRect = tester.getRect(button);
    await tester.tap(button);
    await settle(tester);
    expect(files.saved, hasLength(1));
    expect(files.shareOrigins.single, buttonRect);
  });

  testWidgets('edit profile updates the card', (tester) async {
    await pumpApp(tester, identity: identity, backupFiles: files);
    await _openMe(tester);
    await tester.tap(find.text(en.accountEditProfile));
    await settle(tester);
    expect(find.byType(EditProfilePage), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, en.accountDisplayName),
      'Bob',
    );
    await tester.tap(find.text(en.actionSave));
    await settle(tester);
    expect(find.byType(EditProfilePage), findsNothing);
    expect(identity.current?.displayName, 'Bob');
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('set password then the tile reads "Change password"', (
    tester,
  ) async {
    await pumpApp(tester, identity: identity, backupFiles: files);
    await _openMe(tester);
    await tester.tap(find.text(en.accountSetPassword));
    await settle(tester);
    expect(find.byType(ChangePasswordPage), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, en.accountNewPassword),
      'longer password 1',
    );
    await tester.enterText(
      find.widgetWithText(TextField, en.accountConfirmPassword),
      'longer password 1',
    );
    await tester.tap(find.text(en.actionSave));
    await settle(tester);
    expect(identity.storedPassword, 'longer password 1');
    expect(find.text(en.accountChangePassword), findsOneWidget);
  });

  testWidgets('training defaults tile navigates to /settings/training', (
    tester,
  ) async {
    await pumpApp(tester, identity: identity, backupFiles: files);
    await _openMe(tester);
    await _scrollTo(tester, find.text(en.accountTrainingDefaults));
    await tester.tap(find.text(en.accountTrainingDefaults));
    await settle(tester);
    // The route resolves the identity's shared TrainingController through
    // TrainingControllerHost and lands on the real settings screen.
    expect(find.byType(TrainingSettingsScreen), findsOneWidget);
    expect(find.text(en.learnEffectiveSpeed), findsOneWidget);
  });

  testWidgets('delete requires typing DELETE; cancel keeps the identity', (
    tester,
  ) async {
    await pumpApp(tester, identity: identity, backupFiles: files);
    await _openMe(tester);
    await _scrollTo(tester, find.text(en.accountDeleteIdentity));
    await tester.tap(find.text(en.accountDeleteIdentity));
    await settle(tester);
    expect(find.byType(DeleteIdentityDialog), findsOneWidget);
    expect(buttonEnabled(tester, en.accountDeleteButton), isFalse);

    await tester.enterText(
      find.descendant(
        of: find.byType(DeleteIdentityDialog),
        matching: find.byType(TextField),
      ),
      'delete',
    );
    await settle(tester);
    expect(buttonEnabled(tester, en.accountDeleteButton), isFalse);

    await tester.tap(find.text(en.actionCancel));
    await settle(tester);
    expect(find.byType(DeleteIdentityDialog), findsNothing);
    expect(identity.hasStoredProfile, isTrue);
  });

  testWidgets('typed confirmation deletes and returns to onboarding', (
    tester,
  ) async {
    await pumpApp(tester, identity: identity, backupFiles: files);
    await _openMe(tester);
    await _scrollTo(tester, find.text(en.accountDeleteIdentity));
    await tester.tap(find.text(en.accountDeleteIdentity));
    await settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(DeleteIdentityDialog),
        matching: find.byType(TextField),
      ),
      en.accountDeleteConfirmWord,
    );
    await settle(tester);
    expect(buttonEnabled(tester, en.accountDeleteButton), isTrue);
    await tester.tap(find.text(en.accountDeleteButton));
    await settle(tester);

    expect(identity.hasStoredProfile, isFalse);
    expect(identity.current, isNull);
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.byType(IdentityCard), findsNothing);
  });
}

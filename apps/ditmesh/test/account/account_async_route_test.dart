import 'dart:async';
import 'dart:typed_data';

import 'package:ditmesh/di/app_preferences.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/i18n/locale_controller.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/startup/startup_controller.dart';
import 'package:ditmesh/ui/account/backup_file_gateway.dart';
import 'package:ditmesh/ui/account/change_password_page.dart';
import 'package:ditmesh/ui/account/create_identity_page.dart';
import 'package:ditmesh/ui/account/edit_profile_page.dart';
import 'package:ditmesh/ui/account/encrypted_backup_page.dart';
import 'package:ditmesh/ui/account/restore_backup_page.dart';
import 'package:ditmesh/ui/account/restore_report_page.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'test_app.dart';

final s = lookupS(const Locale('en'));

final class _DelayedPick implements BackupFileGateway {
  _DelayedPick(this.first);

  final Uint8List first;
  final next = Completer<Uint8List?>();
  int _picks = 0;

  @override
  Future<PickedBackup?> pickBackup() async {
    final bytes = _picks++ == 0 ? first : await next.future;
    return bytes == null ? null : (bytes: bytes, name: null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _DelayedIdentity
    implements IdentityService, EncryptedBackupService {
  final gate = Completer<void>();
  int mutations = 0;
  String? restoredPassphrase;

  @override
  Identity? current;

  @override
  Stream<Identity?> get identityChanges => const Stream.empty();

  @override
  Future<void> connect() async {}

  Future<Identity> _write() async {
    mutations++;
    await gate.future;
    return current = testIdentity();
  }

  @override
  Future<Identity> create({required String displayName, String? password}) =>
      _write();

  @override
  Future<Identity> updateProfile({
    String? displayName,
    String? statusMessage,
  }) => _write();

  @override
  Future<void> changePassword({
    String? oldPassword,
    String? newPassword,
  }) async {
    await _write();
  }

  @override
  Future<Identity> importBackup(Uint8List bytes, {String? password}) =>
      _write();

  @override
  Future<BackupInventory> backupInventory() async => const BackupInventory(
    sizes: {},
    pendingMessages: 0,
    queuedInvites: 0,
    profileHasPassword: false,
  );

  @override
  Future<Uint8List> exportEncryptedBackup(
    EncryptedBackupRequest request,
  ) async {
    mutations++;
    await gate.future;
    return Uint8List.fromList([1]);
  }

  @override
  Future<BackupPreview> previewEncryptedBackup(
    Uint8List bytes,
    String passphrase,
  ) async => BackupPreview(
    toxId: testIdentity().toxId,
    displayName: 'Ann',
    createdAt: DateTime.utc(2026),
    sizes: const {},
    pendingMessages: 0,
    pendingIncluded: false,
    queuedInvites: 0,
    profileNeedsPassword: false,
  );

  @override
  void forgetPreview() {}

  @override
  Future<RestoreReport> restoreEncryptedBackup(
    Uint8List bytes,
    String passphrase, {
    String? identityPassword,
  }) async {
    restoredPassphrase = passphrase;
    await _write();
    return const RestoreReport(
      restored: {},
      notIncluded: {},
      pendingForReview: 0,
      pendingNotResumed: 0,
      queuedInvitesNotResumed: 0,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<NavigatorState> _open(
  WidgetTester tester,
  Widget page,
  _DelayedIdentity identity, {
  Uint8List? backup,
  BackupFileGateway? files,
}) async {
  final store = InMemoryKeyValueStore();
  final startup = StartupController(identity);
  final prefs = AppPreferences(store, backendLabel: 'test', identity: identity);
  final locale = LocaleController(store);
  addTearDown(startup.dispose);
  addTearDown(prefs.dispose);
  addTearDown(locale.dispose);
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<IdentityService>.value(value: identity),
        ChangeNotifierProvider<StartupController>.value(value: startup),
        Provider<AppPreferences>.value(value: prefs),
        ChangeNotifierProvider<LocaleController>.value(value: locale),
        Provider<BackupFileGateway>.value(
          value: files ?? FakeBackupFileGateway(pickResult: backup),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigator,
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(body: Text('root')),
      ),
    ),
  );
  final nav = navigator.currentState!;
  unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => page)));
  await tester.pumpAndSettle();
  return nav;
}

Future<void> _tap(WidgetTester tester, Finder button) async {
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _openNewerPage(WidgetTester tester, NavigatorState nav) async {
  unawaited(
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('newer page')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('reading a new backup disables an old preview for restoration', (
    tester,
  ) async {
    final identity = _DelayedIdentity();
    final first = Uint8List.fromList('MCQEA'.codeUnits);
    final second = Uint8List.fromList('MCQEBC'.codeUnits);
    final gateway = _DelayedPick(first);
    await _open(tester, const RestoreBackupPage(), identity, files: gateway);
    final choose = find.text(s.accountRestoreChooseFile);
    final restore = find.byKey(const ValueKey('restore-button'));
    final open = find.byKey(const ValueKey('restore-x-open'));
    await _tap(tester, choose);
    await _tap(tester, open);
    expect(tester.widget<FilledButton>(restore).onPressed, isNotNull);
    await _tap(tester, choose);
    final restoreWhileReading = tester.widget<FilledButton>(restore).onPressed;
    gateway.next.complete(second);
    await tester.pumpAndSettle();

    expect(restoreWhileReading, isNull);
    expect(find.text(s.accountRestoreFileChosenSize(second.length)), findsOne);
    expect(find.byType(BackupPreviewCard), findsNothing);
    expect(tester.widget<FilledButton>(restore).onPressed, isNull);
    expect(identity.mutations, 0);
  });

  testWidgets('confirmation uses the passphrase captured when it opened', (
    tester,
  ) async {
    final identity = _DelayedIdentity();
    await _open(
      tester,
      const RestoreBackupPage(),
      identity,
      backup: Uint8List.fromList('MCQE'.codeUnits),
    );
    await _tap(tester, find.text(s.accountRestoreChooseFile));
    final field = find.widgetWithText(TextField, s.backupXPassphrase);
    await tester.enterText(field, 'chosen passphrase');
    final input = tester.widget<TextField>(field).controller!;
    await _tap(tester, find.byKey(const ValueKey('restore-x-open')));
    await _tap(tester, find.byKey(const ValueKey('restore-button')));
    input.text = 'late text change';
    await _tap(tester, find.byKey(const ValueKey('restore-x-confirm')));
    final used = identity.restoredPassphrase;
    identity.gate.complete();
    await tester.pumpAndSettle();
    expect(used, 'chosen passphrase');
  });

  testWidgets('a completed creation preserves the page opened after leaving', (
    tester,
  ) async {
    final identity = _DelayedIdentity();
    final nav = await _open(tester, const CreateIdentityPage(), identity);
    await tester.enterText(
      find.widgetWithText(TextField, s.accountDisplayName),
      'Ann',
    );
    await _tap(tester, find.text(s.accountCreateButton));
    expect(identity.mutations, 1);
    nav.pop();
    await tester.pumpAndSettle();
    await _openNewerPage(tester, nav);

    identity.gate.complete();
    await tester.pumpAndSettle();
    expect(identity.current?.displayName, 'Ann');
    expect(find.text('newer page'), findsOneWidget);
  });

  testWidgets('profile save removes only the page that started the save', (
    tester,
  ) async {
    final identity = _DelayedIdentity();
    final nav = await _open(
      tester,
      EditProfilePage(identity: testIdentity()),
      identity,
    );
    await _tap(tester, find.text(s.actionSave));
    expect(identity.mutations, 1);
    await _openNewerPage(tester, nav);

    identity.gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('newer page'), findsOneWidget);
    nav.pop();
    await tester.pumpAndSettle();
    expect(find.text('root'), findsOneWidget);
  });

  testWidgets('keyboard submit cannot duplicate an ongoing password change', (
    tester,
  ) async {
    final identity = _DelayedIdentity();
    await _open(tester, const ChangePasswordPage(hasPassword: false), identity);
    await tester.enterText(
      find.widgetWithText(TextField, s.accountNewPassword),
      'replacement',
    );
    final confirm = find.widgetWithText(TextField, s.accountConfirmPassword);
    await tester.enterText(confirm, 'replacement');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.showKeyboard(confirm);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    final attempts = identity.mutations;
    identity.gate.complete();
    await tester.pumpAndSettle();
    expect(attempts, 1);
  });

  testWidgets('an export completed after leaving does not open a save dialog', (
    tester,
  ) async {
    final identity = _DelayedIdentity()..current = testIdentity();
    final files = FakeBackupFileGateway();
    final nav = await _open(
      tester,
      const EncryptedBackupPage(),
      identity,
      files: files,
    );
    for (final label in [s.backupXPassphrase, s.backupXPassphraseConfirm]) {
      final field = find.widgetWithText(TextField, label);
      await tester.ensureVisible(field);
      await tester.enterText(field, 'a longer passphrase');
    }
    final button = find.byKey(EncryptedBackupPage.exportKey);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(identity.mutations, 1);
    nav.pop();
    await tester.pumpAndSettle();
    await _openNewerPage(tester, nav);

    identity.gate.complete();
    await tester.pumpAndSettle();
    expect(files.saved, isEmpty);
    expect(find.text('newer page'), findsOneWidget);
  });

  for (final encrypted in [false, true]) {
    testWidgets('restore preserves the newer route (encrypted: $encrypted)', (
      tester,
    ) async {
      final identity = _DelayedIdentity();
      final nav = await _open(
        tester,
        const RestoreBackupPage(),
        identity,
        backup: Uint8List.fromList(encrypted ? 'MCQE'.codeUnits : [1]),
      );
      await _tap(tester, find.text(s.accountRestoreChooseFile));
      if (encrypted) {
        await _tap(tester, find.byKey(const ValueKey('restore-x-open')));
      }
      await _tap(tester, find.byKey(const ValueKey('restore-button')));
      if (encrypted) {
        await _tap(tester, find.byKey(const ValueKey('restore-x-confirm')));
      }
      expect(identity.mutations, 1);
      nav.pop();
      await tester.pumpAndSettle();
      await _openNewerPage(tester, nav);

      identity.gate.complete();
      await tester.pumpAndSettle();
      expect(identity.current?.displayName, 'Ann');
      expect(find.byType(RestoreReportPage), findsNothing);
      expect(find.text('newer page'), findsOneWidget);
    });
  }
}

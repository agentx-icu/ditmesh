import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/account/backup_file_gateway.dart';
import 'package:ditmesh/ui/account/backup_wizard_page.dart';
import 'package:ditmesh/ui/account/restore_backup_page.dart';
import 'package:ditmesh/ui/account/restore_report_page.dart';
import 'package:ditmesh/ui/chat/restored_pending.dart';
import 'package:ditmesh/ui/shell/app_shell.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:path/path.dart' as p;

import 'test_app.dart';

final S en = lookupS(const Locale('en'));

Finder _field(String key) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(TextField));

/// F10 restore UI: passphrase → validated preview → identity password when
/// needed → explicit confirmation → report. Nothing changes before the
/// confirmation.
void main() {
  late FakeIdentityService identity;
  late FakeBackupFileGateway files;

  setUp(() {
    identity = freshIdentityService();
    files = FakeBackupFileGateway();
  });

  Future<Uint8List> backupOf({String? password, int pending = 0, bool withPending = false}) async {
    final source = FakeIdentityService.withProfile(
      identity: testIdentity(hasPassword: password != null),
      password: password,
      connectDelay: Duration.zero,
    );
    addTearDown(source.dispose);
    if (password == null) {
      await source.open();
    } else {
      await source.unlock(password);
    }
    source.fakePendingMessages = pending;
    return source.exportEncryptedBackup(
      EncryptedBackupRequest(
        passphrase: 'correct horse',
        categories: {
          BackupCategory.training,
          BackupCategory.preferences,
          if (withPending) BackupCategory.pendingMessages,
        },
        preferences: Uint8List.fromList(
          utf8.encode('{"chat.playback":{"wpm":23}}'),
        ),
      ),
    );
  }

  Future<void> openRestore(WidgetTester tester) async {
    await pumpApp(tester, identity: identity, backupFiles: files);
    await tapVisible(tester, find.text(en.accountRestoreFromBackup));
    expect(find.byType(RestoreBackupPage), findsOneWidget);
    await tapVisible(tester, find.text(en.accountRestoreChooseFile));
  }

  testWidgets('wrong passphrase, preview, confirm, report', (tester) async {
    files.pickResult = await backupOf(pending: 2);
    await openRestore(tester);
    // Restore stays disabled until the backup has been opened.
    final restore = find.byKey(const ValueKey('restore-button'));
    expect(tester.widget<FilledButton>(restore).onPressed, isNull);

    await tester.enterText(_field('restore-x-passphrase'), 'wrong one');
    await tapVisible(tester, find.byKey(const ValueKey('restore-x-open')));
    expect(find.text(en.restoreXWrongPassphrase), findsOneWidget);
    expect(identity.current, isNull);

    await tester.enterText(_field('restore-x-passphrase'), 'correct horse');
    await tapVisible(tester, find.byKey(const ValueKey('restore-x-open')));
    expect(find.byType(BackupPreviewCard), findsOneWidget);
    expect(find.text(en.restoreXPendingExcluded(2)), findsOneWidget);
    expect(identity.current, isNull, reason: 'preview changes nothing');

    // Cancelling the confirmation keeps everything as it was.
    await tapVisible(tester, restore);
    expect(find.text(en.restoreXConfirmTitle), findsOneWidget);
    await tapVisible(tester, find.text(en.actionCancel));
    expect(identity.current, isNull);

    await tapVisible(tester, restore);
    await tapVisible(tester, find.byKey(const ValueKey('restore-x-confirm')));
    expect(find.byType(RestoreReportPage), findsOneWidget);
    expect(identity.current?.toxId, testIdentity().toxId);
    expect(find.text(en.restoreXReportPendingNotResumed(2)), findsOneWidget);
    expect(find.text(en.restoreXReportStopOld), findsOneWidget);

    await tapVisible(tester, find.byKey(const ValueKey('restore-x-done')));
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(BackupWizardPage), findsNothing);
  });

  testWidgets('an encrypted profile asks for the identity password too', (
    tester,
  ) async {
    files.pickResult = await backupOf(password: 'id-pass');
    await openRestore(tester);
    await tester.enterText(_field('restore-x-passphrase'), 'correct horse');
    await tapVisible(tester, find.byKey(const ValueKey('restore-x-open')));
    expect(find.text(en.restoreXIdentityPasswordNote), findsOneWidget);

    final restore = find.byKey(const ValueKey('restore-button'));
    await tapVisible(tester, restore);
    await tapVisible(tester, find.byKey(const ValueKey('restore-x-confirm')));
    expect(find.text(en.errorWrongPassword), findsOneWidget);
    expect(identity.current, isNull);

    await tester.enterText(_field('restore-x-identity-password'), 'id-pass');
    await tapVisible(tester, restore);
    await tapVisible(tester, find.byKey(const ValueKey('restore-x-confirm')));
    expect(find.byType(RestoreReportPage), findsOneWidget);
    expect(identity.current?.hasPassword, isTrue);
  });

  test('restored unsent messages are listed and dismissed, never sent', () {
    final dir = Directory.systemTemp.createTempSync('restored_pending_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, restoredPendingDoc))
      ..createSync(recursive: true)
      ..writeAsStringSync(
        jsonEncode({
          'items': [
            RestoredPendingItem(
              id: 'b',
              conversationId: 'c2c_${'A' * 64}',
              text: 'QRL?',
              queuedAt: DateTime.utc(2026, 10, 4, 9),
            ).toJson(),
            RestoredPendingItem(
              id: 'a',
              conversationId: 'c2c_${'A' * 64}',
              text: 'CQ',
              queuedAt: DateTime.utc(2026, 10, 4, 8),
            ).toJson(),
            {'id': 'broken'},
          ],
        }),
      );
    final store = RestoredPendingStore(file);
    expect(store.read().map((i) => i.text), ['CQ', 'QRL?']);
    store.dismiss('a');
    expect(store.read().single.id, 'b');
    store.dismiss();
    expect(file.existsSync(), isFalse);
    expect(store.read(), isEmpty);
  });
}

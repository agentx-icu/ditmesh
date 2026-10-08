import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/account/backup_file_gateway.dart';
import 'package:ditmesh/ui/pages/me_page.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';

import 'test_app.dart';

final S en = lookupS(const Locale('en'));

Future<void> _openExport(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(MePage.title(en)),
    ),
  );
  await settle(tester);
  await tester.ensureVisible(find.text(en.accountExportBackup));
  await settle(tester);
  await tester.tap(find.text(en.accountExportBackup));
  await settle(tester);
}

CheckboxListTile _tile(WidgetTester tester, BackupCategory c) =>
    tester.widget<CheckboxListTile>(find.byKey(ValueKey('backup-x-${c.name}')));

/// Recordings are opt-in on the encrypted backup page (functional spec
/// §11.3, F10): off by default, offered when there are some, refused when
/// they exceed the limit.
void main() {
  late FakeIdentityService identity;
  late FakeBackupFileGateway files;

  setUp(() {
    identity = seededIdentityService();
    files = FakeBackupFileGateway();
  });

  Future<BackupPreview> previewOfSaved() => identity.previewEncryptedBackup(
    files.saved.single,
    'correct horse',
  );

  testWidgets('no recordings: the category cannot be chosen', (tester) async {
    await pumpApp(tester, identity: identity, backupFiles: files);
    await _openExport(tester);
    final media = _tile(tester, BackupCategory.media);
    expect(media.value, isFalse);
    expect(media.onChanged, isNull);
    await completeEncryptedBackup(tester);
    expect(files.saved, hasLength(1));
    expect((await previewOfSaved()).includes(BackupCategory.media), isFalse);
  });

  testWidgets('saved recordings: off by default, the learner may opt in', (
    tester,
  ) async {
    identity.fakeBackupSizes = {
      BackupCategory.media: const BackupCategorySize(items: 1, bytes: 2048),
    };
    await pumpApp(tester, identity: identity, backupFiles: files);
    await _openExport(tester);
    expect(_tile(tester, BackupCategory.media).value, isFalse);
    final tile = find.byKey(const ValueKey('backup-x-media'));
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pump();
    expect(_tile(tester, BackupCategory.media).value, isTrue);
    await completeEncryptedBackup(tester);
    expect((await previewOfSaved()).includes(BackupCategory.media), isTrue);
  });

  testWidgets('too-large recordings are refused with their size', (
    tester,
  ) async {
    identity.fakeBackupSizes = {
      BackupCategory.media: const BackupCategorySize(
        items: 3,
        bytes: BackupMedia.maxBytes + 1,
      ),
    };
    await pumpApp(tester, identity: identity, backupFiles: files);
    await _openExport(tester);
    expect(_tile(tester, BackupCategory.media).onChanged, isNull);
    expect(
      find.textContaining(en.backupXMediaTooLarge(en.backupXSizeMb('100.0'))),
      findsOneWidget,
    );
  });

  testWidgets('unsent messages are offered and explained', (tester) async {
    identity.fakePendingMessages = 2;
    await pumpApp(tester, identity: identity, backupFiles: files);
    await _openExport(tester);
    expect(_tile(tester, BackupCategory.pendingMessages).value, isFalse);
    expect(find.textContaining(en.backupXPendingHint), findsOneWidget);
  });
}

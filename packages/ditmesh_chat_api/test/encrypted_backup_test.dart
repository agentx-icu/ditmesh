import 'dart:convert';
import 'dart:typed_data';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:test/test.dart';

Matcher _code(String code) =>
    throwsA(isA<ChatException>().having((e) => e.code, 'code', code));

void main() {
  group('isEncryptedBackup', () {
    test('recognises the MCQE envelope by its magic only', () {
      expect(
        isEncryptedBackup(Uint8List.fromList(utf8.encode('MCQE'))),
        isTrue,
      );
      expect(
        isEncryptedBackup(Uint8List.fromList([...utf8.encode('MCQE'), 9, 9])),
        isTrue,
      );
      expect(
        isEncryptedBackup(Uint8List.fromList(utf8.encode('MCQB1'))),
        isFalse,
      );
      expect(
        isEncryptedBackup(Uint8List.fromList(utf8.encode('MCQ'))),
        isFalse,
      );
      expect(isEncryptedBackup(Uint8List(0)), isFalse);
    });
  });

  group('value types', () {
    test('BackupInventory.sizeOf answers zero for an absent category', () {
      const inv = BackupInventory(
        sizes: {
          BackupCategory.identity: BackupCategorySize(items: 2, bytes: 10),
        },
        pendingMessages: 0,
        queuedInvites: 0,
        profileHasPassword: false,
      );
      expect(inv.sizeOf(BackupCategory.identity).items, 2);
      expect(inv.sizeOf(BackupCategory.media), BackupCategorySize.zero);
    });

    test('BackupPreview derives the public key and inclusion', () {
      final toxId = '${'AB' * 32}${'0' * 12}';
      final preview = BackupPreview(
        toxId: toxId,
        displayName: 'Ann',
        createdAt: DateTime.utc(2026),
        sizes: const {BackupCategory.identity: BackupCategorySize.zero},
        pendingMessages: 0,
        pendingIncluded: false,
        queuedInvites: 0,
        profileNeedsPassword: false,
      );
      expect(preview.publicKey, 'AB' * 32);
      expect(preview.sourcePlatform, isEmpty);
      expect(preview.includes(BackupCategory.identity), isTrue);
      expect(preview.includes(BackupCategory.chatHistory), isFalse);
      final short = BackupPreview(
        toxId: 'ABC',
        displayName: '',
        createdAt: DateTime.utc(2026),
        sizes: const {},
        pendingMessages: 0,
        pendingIncluded: false,
        queuedInvites: 0,
        profileNeedsPassword: false,
      );
      expect(short.publicKey, 'ABC');
    });

    test('RestoredPendingItem round-trips through JSON in UTC', () {
      final item = RestoredPendingItem(
        id: 'p1',
        conversationId: 'c_friend',
        text: 'CQ DE ANN',
        queuedAt: DateTime.utc(2026, 10, 9, 12, 30),
      );
      final json = item.toJson();
      expect(json.containsKey('recording'), isFalse);
      expect(json['queuedAt'], '2026-10-09T12:30:00.000Z');
      final back = RestoredPendingItem.fromJson(jsonDecode(jsonEncode(json)))!;
      expect(back.id, 'p1');
      expect(back.conversationId, 'c_friend');
      expect(back.text, 'CQ DE ANN');
      expect(back.queuedAt, item.queuedAt);
      expect(back.recording, isNull);
    });

    test('RestoredPendingItem.fromJson rejects malformed rows', () {
      final good = <String, Object?>{
        'id': 'p1',
        'conversationId': 'c',
        'text': 't',
        'queuedAt': '2026-10-09T12:30:00Z',
      };
      expect(RestoredPendingItem.fromJson(good), isNotNull);
      expect(RestoredPendingItem.fromJson(null), isNull);
      expect(RestoredPendingItem.fromJson('x'), isNull);
      expect(RestoredPendingItem.fromJson([good]), isNull);
      for (final field in good.keys) {
        expect(
          RestoredPendingItem.fromJson({...good}..remove(field)),
          isNull,
          reason: 'missing $field',
        );
      }
      expect(RestoredPendingItem.fromJson({...good, 'id': 1}), isNull);
      expect(
        RestoredPendingItem.fromJson({...good, 'queuedAt': 'yesterday'}),
        isNull,
      );
    });
  });

  group('FakeIdentityService encrypted backup', () {
    late FakeIdentityService source;
    late FakeIdentityService target;

    setUp(() async {
      source = FakeIdentityService(connectDelay: Duration.zero);
      target = FakeIdentityService(connectDelay: Duration.zero);
      await source.create(displayName: 'Ann');
    });
    tearDown(() async {
      await source.dispose();
      await target.dispose();
    });

    EncryptedBackupRequest request({
      String passphrase = 'correct horse',
      Set<BackupCategory> categories = const {},
      Uint8List? preferences,
    }) => EncryptedBackupRequest(
      passphrase: passphrase,
      categories: categories,
      preferences: preferences,
    );

    test('inventory lists identity and the scripted extras', () async {
      source
        ..fakePendingMessages = 3
        ..fakeBackupSizes = {
          BackupCategory.media: const BackupCategorySize(items: 4, bytes: 99),
        };
      final inv = await source.backupInventory();
      expect(inv.sizeOf(BackupCategory.identity).items, greaterThan(0));
      expect(inv.sizeOf(BackupCategory.pendingMessages).items, 3);
      expect(inv.sizeOf(BackupCategory.media).bytes, 99);
      expect(inv.pendingMessages, 3);
      expect(inv.profileHasPassword, isFalse);
    });

    test('export needs an identity and a passphrase', () async {
      await expectLater(
        target.exportEncryptedBackup(request()),
        _code('no_identity'),
      );
      await expectLater(
        source.exportEncryptedBackup(request(passphrase: '')),
        _code('wrong_passphrase'),
      );
    });

    test(
      'an export is an MCQE envelope that previews without changes',
      () async {
        final bytes = await source.exportEncryptedBackup(
          request(categories: {BackupCategory.training}),
        );
        expect(isEncryptedBackup(bytes), isTrue);
        final preview = await target.previewEncryptedBackup(
          bytes,
          'correct horse',
        );
        expect(preview.toxId, source.current!.toxId);
        expect(preview.displayName, 'Ann');
        // identity is implied; training was asked for.
        expect(preview.includes(BackupCategory.identity), isTrue);
        expect(preview.includes(BackupCategory.training), isTrue);
        expect(preview.includes(BackupCategory.chatHistory), isFalse);
        expect(preview.profileNeedsPassword, isFalse);
        expect(target.current, isNull, reason: 'preview changes nothing');
        target.forgetPreview();
      },
    );

    test(
      'a wrong passphrase, a foreign file or a newer version fail',
      () async {
        final bytes = await source.exportEncryptedBackup(request());
        await expectLater(
          target.previewEncryptedBackup(bytes, 'wrong'),
          _code('wrong_passphrase'),
        );
        await expectLater(
          target.previewEncryptedBackup(
            Uint8List.fromList(utf8.encode('MCQB not encrypted')),
            'correct horse',
          ),
          _code('invalid_backup'),
        );
        final newer = Uint8List.fromList(bytes)..[4] = 2;
        await expectLater(
          target.previewEncryptedBackup(newer, 'correct horse'),
          _code('unsupported_backup_version'),
        );
        final truncated = Uint8List.sublistView(bytes, 0, bytes.length - 5);
        await expectLater(
          target.previewEncryptedBackup(truncated, 'correct horse'),
          _code('wrong_passphrase'),
        );
        expect(target.current, isNull);
      },
    );

    test('restore installs the identity and reports what came along', () async {
      source.fakePendingMessages = 2;
      final prefs = Uint8List.fromList(utf8.encode('{"theme":"dark"}'));
      final bytes = await source.exportEncryptedBackup(
        request(
          categories: {
            BackupCategory.preferences,
            BackupCategory.pendingMessages,
          },
          preferences: prefs,
        ),
      );
      final report = await target.restoreEncryptedBackup(
        bytes,
        'correct horse',
      );
      expect(target.current!.toxId, source.current!.toxId);
      expect(target.current!.displayName, 'Ann');
      expect(report.restored, contains(BackupCategory.identity));
      expect(report.restored, contains(BackupCategory.pendingMessages));
      expect(report.notIncluded, contains(BackupCategory.media));
      expect(
        report.restored.intersection(report.notIncluded),
        isEmpty,
        reason: 'a category is either restored or not included',
      );
      expect(report.pendingForReview, 2);
      expect(report.pendingNotResumed, 0);
      expect(report.queuedInvitesNotResumed, 0);
      expect(utf8.decode(report.preferences!), '{"theme":"dark"}');
    });

    test('pending messages left out are reported as not resumed', () async {
      source.fakePendingMessages = 2;
      final bytes = await source.exportEncryptedBackup(request());
      final report = await target.restoreEncryptedBackup(
        bytes,
        'correct horse',
      );
      expect(report.pendingForReview, 0);
      expect(report.pendingNotResumed, 2);
      expect(report.preferences, isNull);
    });

    test('preferences are only carried when the category is chosen', () async {
      final bytes = await source.exportEncryptedBackup(
        request(preferences: Uint8List.fromList([1, 2, 3])),
      );
      final report = await target.restoreEncryptedBackup(
        bytes,
        'correct horse',
      );
      expect(report.preferences, isNull);
    });

    test('a password-protected profile restores only with it', () async {
      final locked = FakeIdentityService(connectDelay: Duration.zero);
      addTearDown(locked.dispose);
      await locked.create(displayName: 'Bob', password: 'pw');
      expect((await locked.backupInventory()).profileHasPassword, isTrue);
      final bytes = await locked.exportEncryptedBackup(request());
      final preview = await target.previewEncryptedBackup(
        bytes,
        'correct horse',
      );
      expect(preview.profileNeedsPassword, isTrue);
      await expectLater(
        target.restoreEncryptedBackup(bytes, 'correct horse'),
        _code('wrong_password'),
      );
      await expectLater(
        target.restoreEncryptedBackup(
          bytes,
          'correct horse',
          identityPassword: 'nope',
        ),
        _code('wrong_password'),
      );
      expect(
        target.current,
        isNull,
        reason: 'a failed restore changes nothing',
      );
      await target.restoreEncryptedBackup(
        bytes,
        'correct horse',
        identityPassword: 'pw',
      );
      expect(target.current!.displayName, 'Bob');
      expect(target.current!.hasPassword, isTrue);
    });
  });
}

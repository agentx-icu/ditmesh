import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/chat/conversation_meta_store.dart';
import 'package:ditmesh_chat/src/identity/backup_snapshot.dart';
import 'package:ditmesh_chat/src/identity/identity_record.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tim2tox_dart/models/chat_message.dart';
import 'package:tim2tox_dart/utils/offline_message_queue_persistence.dart';

import 'helpers/fakes.dart';

/// Low findings of the 2026-10-08 chat review on the identity side: the
/// password verifier (L7 / L12), v1 import commit and cleanup (L6), the
/// preview cache (L13), and withdrawn rows in a backup (item 3).

const _otherKey =
    '3333333333333333333333333333333333333333333333333333333333333333';
const _otherToxId = '${_otherKey}000000000000';
String _verifierKey(String toxId) => 'ditmesh.password.${toxId.toUpperCase()}';

class _CountingCrypto extends FakeProfileCrypto {
  int decrypts = 0;
  @override
  Uint8List decrypt(Uint8List ciphertext, String password) {
    decrypts++;
    return super.decrypt(ciphertext, password);
  }
}

class _FlakySecure extends MemorySecureStore {
  String? failDelete;
  String? failWrite;
  @override
  Future<void> delete(String key) async {
    if (key == failDelete) throw StateError('keychain delete failed');
    return super.delete(key);
  }

  @override
  Future<void> write(String key, String value) async {
    if (key == failWrite) throw StateError('keychain write failed');
    return super.write(key, value);
  }
}

class _FlakyStore extends MemoryKeyValueStore {
  /// Removes fail once this many more have succeeded (null: never).
  int? failRemoveAfter;
  @override
  Future<void> remove(String key) async {
    final left = failRemoveAfter;
    if (left != null) {
      if (left == 0) {
        failRemoveAfter = null;
        throw StateError('prefs remove failed');
      }
      failRemoveAfter = left - 1;
    }
    return super.remove(key);
  }
}

OfflineMessageItem _item(String text, DateTime at, String id) => (
  kind: 'text',
  text: text,
  filePath: null,
  fileName: null,
  timestamp: at,
  msgID: id,
  cloudCustomData: null,
  contentKind: ChatMessageContentKind.normal,
);

void main() {
  late Directory tempRoot;
  late IdentityPaths paths;
  late _FlakySecure secure;
  late _FlakyStore store;
  late FakeChatEngine engine;
  late _CountingCrypto crypto;

  Tim2ToxIdentityService service({int iterations = 10, IdentityPaths? at}) =>
      Tim2ToxIdentityService(
        paths: at ?? paths,
        engine: engine,
        crypto: crypto,
        verifier: PasswordVerifier(secure, iterations: iterations),
        store: store,
      );

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ditmesh_leftovers_');
    paths = IdentityPaths(p.join(tempRoot.path, 'identity'));
    secure = _FlakySecure();
    store = _FlakyStore();
    crypto = _CountingCrypto();
    engine = FakeChatEngine(crypto: crypto);
  });

  tearDown(() async {
    await engine.dispose();
    if (tempRoot.existsSync()) await tempRoot.delete(recursive: true);
  });

  Future<void> lockedIdentity(String password) async {
    final svc = service();
    await svc.create(displayName: 'W1AW', password: password);
    await svc.disconnect();
    expect(crypto.isEncrypted(File(paths.profileFile).readAsBytesSync()), isTrue);
    await svc.dispose();
  }

  group('L7 malformed verifier', () {
    for (final bad in <String>[
      r'pbkdf2-sha256$10$zz$zz',
      // Odd length: an appended nibble must not be silently dropped.
      r'pbkdf2-sha256$10$' '${'ab' * 16}0' r'$' '${'cd' * 32}',
      r'pbkdf2-sha256$10$' '${'ab' * 15}' r'$' '${'cd' * 32}',
      r'pbkdf2-sha256$0$' '${'ab' * 16}' r'$' '${'cd' * 32}',
      'not-a-verifier',
    ]) {
      test('verify answers false, never throws: $bad', () async {
        final s = MemorySecureStore();
        final v = PasswordVerifier(s, iterations: 10);
        s.values[_verifierKey(kSelfToxId)] = bad;
        expect(await v.verify(kSelfToxId, 'pw'), isFalse);
        expect(await v.needsRehash(kSelfToxId), isTrue);
      });
    }

    test('an appended nibble no longer verifies', () async {
      final s = MemorySecureStore();
      final v = PasswordVerifier(s, iterations: 10);
      await v.setPassword(kSelfToxId, 'pw');
      final good = s.values[_verifierKey(kSelfToxId)]!;
      expect(await v.verify(kSelfToxId, 'pw'), isTrue);
      s.values[_verifierKey(kSelfToxId)] = '${good}0';
      expect(await v.verify(kSelfToxId, 'pw'), isFalse);
    });

    test('a secure-store read failure still throws', () async {
      final v = PasswordVerifier(_ThrowingRead(), iterations: 10);
      await expectLater(v.verify(kSelfToxId, 'pw'), throwsStateError);
    });

    test('unlock of an encrypted profile heals a malformed verifier', () async {
      await lockedIdentity('pw');
      secure.values[_verifierKey(kSelfToxId)] = r'pbkdf2-sha256$10$zz$zz';
      final svc = service();
      expect(await svc.inspect(), IdentityState.locked);
      final id = await svc.unlock('pw');
      expect(id.toxId, kSelfToxId);
      expect(
        await PasswordVerifier(secure, iterations: 10).verify(kSelfToxId, 'pw'),
        isTrue,
      );
      await svc.dispose();
    });
  });

  group('L12 verifier rounds', () {
    test('default rounds are raised and stored in the value', () {
      expect(PasswordVerifier.defaultIterations, 200000);
      expect(PasswordVerifier(MemorySecureStore()).iterations, 200000);
    });

    test('a weaker verifier is upgraded by the next unlock', () async {
      await lockedIdentity('pw');
      expect(secure.values[_verifierKey(kSelfToxId)], startsWith(r'pbkdf2-sha256$10$'));
      final svc = service(iterations: 20);
      await svc.unlock('pw');
      expect(secure.values[_verifierKey(kSelfToxId)], startsWith(r'pbkdf2-sha256$20$'));
      final v = PasswordVerifier(secure, iterations: 20);
      expect(await v.verify(kSelfToxId, 'pw'), isTrue);
      expect(await v.needsRehash(kSelfToxId), isFalse);
      await svc.dispose();
    });

    test('a stronger verifier is left as it is', () async {
      await lockedIdentity('pw');
      await PasswordVerifier(secure, iterations: 30).setPassword(kSelfToxId, 'pw');
      final before = secure.values[_verifierKey(kSelfToxId)];
      final svc = service(iterations: 20);
      await svc.unlock('pw');
      expect(secure.values[_verifierKey(kSelfToxId)], before);
      await svc.dispose();
    });

    test('a failed upgrade write does not fail the unlock', () async {
      await lockedIdentity('pw');
      final before = secure.values[_verifierKey(kSelfToxId)];
      secure.failWrite = _verifierKey(kSelfToxId);
      final svc = service(iterations: 20);
      expect((await svc.unlock('pw')).toxId, kSelfToxId);
      expect(secure.values[_verifierKey(kSelfToxId)], before);
      expect(
        await PasswordVerifier(secure, iterations: 20).verify(kSelfToxId, 'pw'),
        isTrue,
        reason: 'the old rounds keep verifying',
      );
      await svc.dispose();
    });
  });

  group('L6 v1 import', () {
    Uint8List otherBackup() => BackupContainer(
      entries: {
        BackupContainer.identityEntry: const IdentityRecord(
          toxId: _otherToxId,
          displayName: 'K1ABC',
        ).encode(),
        BackupContainer.profileEntry: FakeProfileCrypto.plainProfile(
          _otherKey,
          'K1ABC',
        ),
      },
      profileEncrypted: false,
    ).encode();

    test('a failed old-verifier removal after the commit still succeeds', () async {
      final svc = service();
      await svc.create(displayName: 'W1AW', password: 'pw');
      secure.failDelete = _verifierKey(kSelfToxId);
      final id = await svc.importBackup(otherBackup());
      expect(id.toxId, _otherToxId);
      expect(svc.current!.toxId, _otherToxId);
      expect(
        crypto.extractPublicKey(File(paths.profileFile).readAsBytesSync()),
        _otherKey,
      );
      await svc.dispose();
    });

    test('a failed preference reset rolls the import back', () async {
      final svc = service();
      await svc.create(displayName: 'W1AW');
      final prefix = kSelfToxId.substring(0, 16);
      await store.setString('a_$prefix', '1');
      await store.setString('b_$prefix', '2');
      // The first scoped removal lands, the second fails.
      store.failRemoveAfter = 1;
      await expectLater(svc.importBackup(otherBackup()), throwsStateError);
      expect(svc.current!.toxId, kSelfToxId);
      expect(
        crypto.extractPublicKey(File(paths.profileFile).readAsBytesSync()),
        kSelfKey,
      );
      expect(store.getString('a_$prefix'), '1');
      expect(store.getString('b_$prefix'), '2');
      await svc.dispose();
    });
  });

  group('L13 preview cache', () {
    Future<Uint8List> encryptedBackup() async {
      engine.nextToxId = _otherToxId;
      final source = service(at: IdentityPaths(p.join(tempRoot.path, 'src')));
      await source.create(displayName: 'K1ABC');
      final bytes = await source.exportEncryptedBackup(
        const EncryptedBackupRequest(passphrase: 'horse', categories: {}),
      );
      await source.dispose();
      engine.nextToxId = kSelfToxId;
      return bytes;
    }

    test('a restore right after the preview reuses its decryption', () async {
      final bytes = await encryptedBackup();
      final svc = service();
      await svc.previewEncryptedBackup(bytes, 'horse');
      final after = crypto.decrypts;
      await svc.restoreEncryptedBackup(bytes, 'horse');
      expect(crypto.decrypts, after);
      await svc.dispose();
    });

    for (final end in ['disconnect', 'deleteIdentity']) {
      test('$end drops the cached passphrase and archive', () async {
        final bytes = await encryptedBackup();
        final svc = service();
        await svc.create(displayName: 'W1AW');
        await svc.previewEncryptedBackup(bytes, 'horse');
        final after = crypto.decrypts;
        if (end == 'disconnect') {
          await svc.disconnect();
        } else {
          await svc.deleteIdentity();
        }
        await svc.restoreEncryptedBackup(bytes, 'horse');
        expect(crypto.decrypts, greaterThan(after));
        await svc.dispose();
      });
    }

    test('a failed deletion drops it too', () async {
      final bytes = await encryptedBackup();
      final svc = service();
      await svc.create(displayName: 'W1AW');
      await svc.previewEncryptedBackup(bytes, 'horse');
      final after = crypto.decrypts;
      engine.teardownConfirmed = false;
      await expectLater(svc.deleteIdentity(), throwsA(isA<ChatException>()));
      engine.teardownConfirmed = true;
      await expectLater(
        svc.restoreEncryptedBackup(bytes, 'horse'),
        anyOf(completes, throwsA(isA<ChatException>())),
      );
      expect(crypto.decrypts, greaterThan(after));
      await svc.dispose();
    });
  });

  group('item 3 withdrawn rows in a backup', () {
    final t0 = DateTime.utc(2026, 10, 8, 8);

    Future<Tim2ToxIdentityService> seeded() async {
      final svc = service();
      await svc.create(displayName: 'W1AW');
      await OfflineMessageQueuePersistence(
        queueFilePath: paths.offlineQueueFile,
      ).saveQueue({
        kPeerKey: [_item('WITHDRAWN', t0, 'm-1'), _item('KEEP', t0, 'm-2')],
        // Same durable id, another peer: unrelated, stays reviewable.
        _otherKey: [_item('OTHER', t0, 'm-1')],
      });
      final meta = ConversationMetaStore(
        store,
        accountPrefix: kSelfToxId.substring(0, 16),
      );
      // Recorded with a lower-case key: matched case-insensitively.
      await meta.addWithdrawal(kPeerKey.toLowerCase(), 'm-1');
      File(p.join(paths.trainingDirectory, BackupSnapshot.restoredPendingFile))
        ..createSync(recursive: true)
        ..writeAsBytesSync(
          BackupSnapshot.encodePending([
            RestoredPendingItem(
              id: 'r-1',
              conversationId: 'c2c_$kPeerKey',
              text: 'EARLIER REVIEW',
              queuedAt: t0,
            ),
          ]),
        );
      return svc;
    }

    test('inventory and export leave withdrawn rows out of review', () async {
      final svc = await seeded();
      final inventory = await svc.backupInventory();
      expect(inventory.pendingMessages, 3, reason: 'KEEP, OTHER, review item');
      final bytes = await svc.exportEncryptedBackup(
        const EncryptedBackupRequest(
          passphrase: 'horse',
          categories: {BackupCategory.pendingMessages},
        ),
      );
      final preview = await svc.previewEncryptedBackup(bytes, 'horse');
      expect(preview.pendingMessages, 3);
      expect(preview.pendingIncluded, isTrue);
      final other = IdentityPaths(p.join(tempRoot.path, 'device2'));
      final restored = service(at: other);
      final report = await restored.restoreEncryptedBackup(bytes, 'horse');
      expect(report.pendingForReview, 3);
      final items = BackupSnapshot.pendingItems(
        File(
          p.join(other.trainingDirectory, BackupSnapshot.restoredPendingFile),
        ).readAsBytesSync(),
      );
      expect(items.map((i) => i.text).toSet(), {
        'KEEP',
        'OTHER',
        'EARLIER REVIEW',
      });
      expect(File(other.offlineQueueFile).existsSync(), isFalse);
      await restored.dispose();
      await svc.dispose();
    });

    test('withdrawn rows stay withheld from exported history', () {
      final queue = [
        QueuedRow(
          queueKey: kPeerKey,
          conversationId: 'c2c_$kPeerKey',
          text: 'WITHDRAWN',
          queuedAt: t0,
          msgId: 'm-1',
        ),
      ];
      final history = Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'conversationId': kPeerKey,
            'messages': [
              {'text': 'WITHDRAWN', 'isSelf': true, 'msgID': 'm-1'},
            ],
          }),
        ),
      );
      expect(
        BackupSnapshot.withoutWithdrawn(queue, {'${kPeerKey.toLowerCase()}\tm-1'}),
        isEmpty,
      );
      // The history filter is given the full queue, not the reviewable one.
      final (_, removed) = BackupSnapshot.withoutQueued(
        '$kPeerKey.json',
        history,
        queue,
      );
      expect(removed, 1);
    });
  });
}

class _ThrowingRead extends MemorySecureStore {
  @override
  Future<String?> read(String key) async => throw StateError('keychain locked');
}

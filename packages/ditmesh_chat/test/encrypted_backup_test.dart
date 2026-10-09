import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/chat/conversation_meta_store.dart';
import 'package:ditmesh_chat/src/identity/backup_envelope.dart';
import 'package:ditmesh_chat/src/identity/backup_snapshot.dart';
import 'package:ditmesh_chat/src/chat/recording_metadata.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;
import 'package:tim2tox_dart/models/chat_message.dart';
import 'package:tim2tox_dart/utils/offline_message_queue_persistence.dart';

import 'helpers/fakes.dart';

const _all = {
  BackupCategory.training,
  BackupCategory.chatHistory,
  BackupCategory.conversationMeta,
  BackupCategory.preferences,
};

OfflineMessageItem _item(String text, DateTime at, String? id) => (
  kind: 'text',
  text: text,
  filePath: null,
  fileName: null,
  timestamp: at,
  msgID: id,
  cloudCustomData: null,
  contentKind: ChatMessageContentKind.normal,
);

Map<String, Object?> _row(
  String text,
  DateTime at,
  String id, {
  bool mine = true,
}) => {
  'text': text,
  'fromUserId': mine ? 'self' : kPeerKey,
  'isSelf': mine,
  'timestamp': at.toIso8601String(),
  'isPending': false,
  'msgID': id,
  'version': 1,
};

void main() {
  late Directory tempRoot;
  late IdentityPaths paths;
  late MemorySecureStore secure;
  late MemoryKeyValueStore store;
  late FakeChatEngine engine;
  final crypto = FakeProfileCrypto();
  final t0 = DateTime.utc(2026, 10, 4, 8);
  final t1 = t0.add(const Duration(minutes: 1));

  Tim2ToxIdentityService service(IdentityPaths at, {KeyValueStore? kv}) =>
      Tim2ToxIdentityService(
        paths: at,
        engine: engine,
        crypto: crypto,
        verifier: PasswordVerifier(secure, iterations: 10),
        store: kv ?? store,
      );

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ditmesh_f10_');
    paths = IdentityPaths(p.join(tempRoot.path, 'identity'));
    secure = MemorySecureStore();
    store = MemoryKeyValueStore();
    engine = FakeChatEngine();
  });

  tearDown(() async {
    await engine.dispose();
    if (tempRoot.existsSync()) await tempRoot.delete(recursive: true);
  });

  Matcher throwsCode(String code) =>
      throwsA(isA<ChatException>().having((e) => e.code, 'code', code));

  String historyFile(IdentityPaths at) =>
      p.join(at.historyDirectory, '$kPeerKey.json');

  /// An identity with training data, history (one sent row, one still
  /// queued), the matching outbox, conversation metadata and a bookmark.
  Future<Tim2ToxIdentityService> seeded({String? password}) async {
    final svc = service(paths);
    await svc.create(displayName: 'DL1ABC', password: password);
    final training = await svc.dataDirectory();
    File(p.join(training, 'progress.json')).writeAsStringSync('{"wpm":18}');
    Directory(p.join(training, 'chat')).createSync(recursive: true);
    File(
      p.join(training, 'chat', 'bookmarks.json'),
    ).writeAsStringSync('{"b":1}');
    File(historyFile(paths)).writeAsStringSync(
      jsonEncode({
        'conversationId': kPeerKey,
        'version': 2,
        'messages': [
          _row('CQ CQ', t0, 'sent-1'),
          _row('R R', t0, 'in-1', mine: false),
          _row('QRL?', t1, 'queued-1'),
        ],
      }),
    );
    await OfflineMessageQueuePersistence(
      queueFilePath: paths.offlineQueueFile,
    ).saveQueue({
      kPeerKey: [_item('QRL?', t1, 'queued-1')],
    });
    final meta = ConversationMetaStore(
      store,
      accountPrefix: kSelfToxId.substring(0, 16),
    );
    await meta.setPinned('c2c_$kPeerKey', true);
    await meta.setDraft('c2c_$kPeerKey', 'DE DL1ABC');
    await meta.queueInvite('tox_1', kPeerKey);
    return svc;
  }

  final prefs = Uint8List.fromList(utf8.encode('{"chat.playback":{"wpm":22}}'));

  test(
    'encrypted backup preserves actual rhythm in history and inert pending items',
    () async {
      final svc = await seeded();
      final recording = KeyedRecording(durationsMs: [83, 113, 251]);
      final metadata = RecordingMetadata.encode(recording)!;
      final history =
          jsonDecode(File(historyFile(paths)).readAsStringSync())
              as Map<String, dynamic>;
      for (final row in history['messages'] as List) {
        (row as Map)['cloudCustomData'] = metadata;
      }
      File(historyFile(paths)).writeAsStringSync(jsonEncode(history));
      await OfflineMessageQueuePersistence(
        queueFilePath: paths.offlineQueueFile,
      ).saveQueue({
        kPeerKey: [
          (
            kind: 'text',
            text: 'QRL?',
            filePath: null,
            fileName: null,
            timestamp: t1,
            msgID: 'queued-1',
            cloudCustomData: metadata,
            contentKind: ChatMessageContentKind.normal,
          ),
        ],
      });
      final bytes = await svc.exportEncryptedBackup(
        EncryptedBackupRequest(
          passphrase: 'correct horse',
          categories: {..._all, BackupCategory.pendingMessages},
          preferences: prefs,
        ),
      );
      await svc.dispose();
      final other = IdentityPaths(p.join(tempRoot.path, 'device2'));
      final restored = service(other);
      try {
        final report = await restored.restoreEncryptedBackup(
          bytes,
          'correct horse',
        );
        expect(report.pendingForReview, 1);
        final document =
            jsonDecode(File(historyFile(other)).readAsStringSync()) as Map;
        expect(
          RecordingMetadata.decode(
            (document['messages'] as List).first['cloudCustomData'] as String,
          ),
          recording,
        );
        final pending =
            jsonDecode(
                  File(
                    p.join(other.trainingDirectory, restoredPendingDoc),
                  ).readAsStringSync(),
                )
                as Map;
        expect(
          RestoredPendingItem.fromJson(
            (pending['items'] as List).single,
          )?.recording,
          recording,
        );
      } finally {
        await restored.dispose();
      }
    },
  );

  EncryptedBackupRequest request(Set<BackupCategory> cats) =>
      EncryptedBackupRequest(
        passphrase: 'correct horse',
        categories: cats,
        preferences: prefs,
      );

  test('inventory reports sizes, the outbox and queued invites', () async {
    final svc = await seeded();
    final inv = await svc.backupInventory();
    expect(inv.sizeOf(BackupCategory.training).items, 1);
    expect(inv.sizeOf(BackupCategory.chatHistory).items, 1);
    expect(
      inv.sizeOf(BackupCategory.conversationMeta).items,
      3,
    ); // file + pin + draft
    expect(inv.pendingMessages, 1);
    expect(inv.queuedInvites, 1);
    expect(inv.profileHasPassword, isFalse);
    await svc.dispose();
  });

  test(
    'round trip: same identity, selected categories, queued rows held back',
    () async {
      final svc = await seeded();
      final bytes = await svc.exportEncryptedBackup(request(_all));
      expect(isEncryptedBackup(bytes), isTrue);
      await svc.dispose();

      final other = IdentityPaths(p.join(tempRoot.path, 'device2'));
      final store2 = MemoryKeyValueStore();
      final restored = service(other, kv: store2);
      final preview = await restored.previewEncryptedBackup(
        bytes,
        'correct horse',
      );
      expect(preview.toxId, kSelfToxId);
      expect(preview.displayName, 'DL1ABC');
      expect(preview.includes(BackupCategory.chatHistory), isTrue);
      expect(preview.includes(BackupCategory.media), isFalse);
      expect(preview.pendingMessages, 1);
      expect(preview.pendingIncluded, isFalse);
      expect(preview.queuedInvites, 1);
      expect(other.profileExists, isFalse, reason: 'preview writes nothing');

      final report = await restored.restoreEncryptedBackup(
        bytes,
        'correct horse',
      );
      expect(restored.current!.toxId, kSelfToxId);
      expect(report.restored, containsAll(_all));
      expect(
        report.notIncluded,
        containsAll({BackupCategory.media, BackupCategory.pendingMessages}),
      );
      expect(report.pendingNotResumed, 1);
      expect(report.pendingForReview, 0);
      expect(report.queuedInvitesNotResumed, 1);
      expect(report.preferences, prefs);

      expect(
        File(
          p.join(other.trainingDirectory, 'progress.json'),
        ).readAsStringSync(),
        '{"wpm":18}',
      );
      expect(
        File(
          p.join(other.trainingDirectory, 'chat', 'bookmarks.json'),
        ).readAsStringSync(),
        '{"b":1}',
      );
      final history =
          jsonDecode(File(historyFile(other)).readAsStringSync()) as Map;
      final ids = [
        for (final m in history['messages'] as List) (m as Map)['msgID'],
      ];
      expect(ids, [
        'sent-1',
        'in-1',
      ], reason: 'a queued row would read as sent');
      expect(File(other.offlineQueueFile).existsSync(), isFalse);
      final meta2 = ConversationMetaStore(
        store2,
        accountPrefix: kSelfToxId.substring(0, 16),
      );
      expect(meta2.pinned, {'c2c_$kPeerKey'});
      expect(meta2.draft('c2c_$kPeerKey'), 'DE DL1ABC');
      expect(
        meta2.queuedInvites,
        isEmpty,
        reason: 'invites are never replayed',
      );
      await restored.dispose();
    },
  );

  test('pending payloads come back as inert review items only', () async {
    final svc = await seeded();
    final bytes = await svc.exportEncryptedBackup(
      request({..._all, BackupCategory.pendingMessages}),
    );
    await svc.dispose();
    final other = IdentityPaths(p.join(tempRoot.path, 'device2'));
    final restored = service(other, kv: MemoryKeyValueStore());
    final report = await restored.restoreEncryptedBackup(
      bytes,
      'correct horse',
    );
    expect(report.pendingForReview, 1);
    expect(report.pendingNotResumed, 0);
    final doc = File(p.join(other.trainingDirectory, restoredPendingDoc));
    final items = BackupSnapshot.pendingItems(doc.readAsBytesSync());
    expect(items.single.text, 'QRL?');
    expect(items.single.conversationId, 'c2c_$kPeerKey');
    // Nothing for the transport to drain, now or after a restart.
    expect(File(other.offlineQueueFile).existsSync(), isFalse);
    await restored.connect();
    expect(File(other.offlineQueueFile).existsSync(), isFalse);
    await restored.dispose();
  });

  test('omitted categories are reported and not written', () async {
    final svc = await seeded();
    final bytes = await svc.exportEncryptedBackup(
      request({BackupCategory.training}),
    );
    await svc.dispose();
    final other = IdentityPaths(p.join(tempRoot.path, 'device2'));
    final restored = service(other, kv: MemoryKeyValueStore());
    final report = await restored.restoreEncryptedBackup(
      bytes,
      'correct horse',
    );
    expect(report.restored, {BackupCategory.identity, BackupCategory.training});
    expect(
      report.notIncluded,
      containsAll({
        BackupCategory.chatHistory,
        BackupCategory.conversationMeta,
        BackupCategory.preferences,
      }),
    );
    expect(report.preferences, isNull);
    expect(File(historyFile(other)).existsSync(), isFalse);
    expect(
      File(
        p.join(other.trainingDirectory, 'chat', 'bookmarks.json'),
      ).existsSync(),
      isFalse,
    );
    await restored.dispose();
  });

  test(
    'saved recordings are counted, exported on request and restored',
    () async {
      final svc = await seeded();
      // Where the app keeps them: the materials document under the training
      // documents, the audio under the identity root.
      final training = await svc.dataDirectory();
      File(p.join(training, BackupMedia.materialsDoc))
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '{"v":1,"materials":[{"id":"x","file":"media/recordings/rec_a.wav"}]}',
        );
      File(p.join(paths.root, 'media', 'recordings', 'rec_a.wav'))
        ..createSync(recursive: true)
        ..writeAsBytesSync(List<int>.filled(2048, 7));
      final inv = await svc.backupInventory();
      expect(
        inv.sizeOf(BackupCategory.media),
        isA<BackupCategorySize>().having((x) => x.items, 'items', 1),
      );
      final without = await svc.exportEncryptedBackup(request(_all));
      final withMedia = await svc.exportEncryptedBackup(
        request({..._all, BackupCategory.media}),
      );
      expect(
        (await svc.previewEncryptedBackup(
          without,
          'correct horse',
        )).includes(BackupCategory.media),
        isFalse,
      );
      await svc.dispose();
      final other = IdentityPaths(p.join(tempRoot.path, 'device2'));
      final restored = service(other, kv: MemoryKeyValueStore());
      final report = await restored.restoreEncryptedBackup(
        withMedia,
        'correct horse',
      );
      expect(report.restored, contains(BackupCategory.media));
      expect(
        File(
          p.join(other.root, 'media', 'recordings', 'rec_a.wav'),
        ).lengthSync(),
        2048,
      );
      await restored.dispose();
    },
  );

  test('export pauses and resumes a running node', () async {
    final svc = await seeded();
    await svc.connect();
    expect(engine.startCalls, hasLength(1));
    await svc.exportEncryptedBackup(request(_all));
    expect(engine.stopCalls, 1);
    expect(engine.startCalls, hasLength(2));
    await svc.dispose();
  });

  group('rejections leave the current installation alone', () {
    late Tim2ToxIdentityService current;
    late Uint8List good;

    setUp(() async {
      final source = await seeded();
      good = await source.exportEncryptedBackup(request(_all));
      await source.dispose();
      // The device being restored onto has its own, different identity.
      paths = IdentityPaths(p.join(tempRoot.path, 'target'));
      engine.nextToxId = kPeerToxId;
      current = service(paths);
      await current.create(displayName: 'K1ABC');
      File(
        p.join(await current.dataDirectory(), 'mine.json'),
      ).writeAsStringSync('keep');
    });

    tearDown(() => current.dispose());

    Future<void> expectUntouched() async {
      expect(current.current!.toxId, kPeerToxId);
      expect(
        File(p.join(paths.trainingDirectory, 'mine.json')).readAsStringSync(),
        'keep',
      );
      expect(
        Directory(tempRoot.path).listSync().where(
          (e) => p.basename(e.path).startsWith(IdentityPaths.importStagePrefix),
        ),
        isEmpty,
      );
    }

    test('wrong passphrase', () async {
      expect(
        () => current.previewEncryptedBackup(good, 'nope'),
        throwsCode('wrong_passphrase'),
      );
      await expectLater(
        current.restoreEncryptedBackup(good, 'nope'),
        throwsCode('wrong_passphrase'),
      );
      await expectUntouched();
    });

    test('truncated and unknown-version files', () async {
      await expectLater(
        current.restoreEncryptedBackup(
          Uint8List.sublistView(good, 0, 20),
          'correct horse',
        ),
        throwsCode('invalid_backup'),
      );
      final future = Uint8List.fromList(good)..[4] = 9;
      await expectLater(
        current.restoreEncryptedBackup(future, 'correct horse'),
        throwsCode('unsupported_backup_version'),
      );
      await expectUntouched();
    });

    Uint8List sealed(Map<String, Uint8List> entries) => BackupEnvelope.seal(
      BackupContainer(
        entries: entries,
        profileEncrypted: false,
        formatVersion: 2,
      ).encode(),
      'pw',
      crypto,
    );

    Map<String, Uint8List> innerOf(Uint8List bytes) => Map.of(
      BackupContainer.decode(
        BackupEnvelope.open(bytes, 'correct horse', crypto),
        inner: true,
      ).entries,
    );

    test('unknown paths, undeclared entries and size mismatches', () async {
      for (final mutate in <void Function(Map<String, Uint8List>)>[
        (e) => e['../escape'] = Uint8List(1),
        (e) => e['data/offline_message_queue.json'] = Uint8List(1),
        (e) => e['training/chat/restored_pending.json'] = Uint8List(1),
        (e) => e['training/extra.json'] = Uint8List(
          1,
        ), // not in the manifest counts
        (e) =>
            e['media/recordings/a.wav'] = Uint8List(1), // undeclared category
        (e) => e.remove('tox_profile.tox'),
      ]) {
        final entries = innerOf(good);
        mutate(entries);
        final Uint8List bytes;
        try {
          bytes = sealed(entries);
        } on ChatException {
          continue; // the encoder already refuses it
        }
        await expectLater(
          current.restoreEncryptedBackup(bytes, 'pw'),
          throwsCode('invalid_backup'),
        );
      }
      await expectUntouched();
    });

    test('duplicate entries and trailing bytes', () async {
      final inner = BackupContainer(
        entries: innerOf(good),
        profileEncrypted: false,
        formatVersion: 2,
      ).encode();
      final trailing = BackupEnvelope.seal(
        Uint8List.fromList([...inner, 0]),
        'pw',
        crypto,
      );
      await expectLater(
        current.restoreEncryptedBackup(trailing, 'pw'),
        throwsCode('invalid_backup'),
      );
      // Duplicate the first entry by appending its bytes and bumping count.
      final data = ByteData.sublistView(inner);
      final count = data.getUint32(6);
      final firstLen = 2 + data.getUint16(10) + 8;
      final size = data.getUint64(10 + 2 + data.getUint16(10));
      final dup = Uint8List.fromList([
        ...inner,
        ...inner.sublist(10, 10 + firstLen + size),
      ]);
      ByteData.sublistView(dup).setUint32(6, count + 1);
      await expectLater(
        current.restoreEncryptedBackup(
          BackupEnvelope.seal(dup, 'pw', crypto),
          'pw',
        ),
        throwsCode('invalid_backup'),
      );
      await expectUntouched();
    });

    test(
      'a failure between the file and preference commits rolls back',
      () async {
        final failing = _FailingStore();
        await current.dispose();
        current = service(paths, kv: failing);
        await current.open();
        // The current identity has metadata the restore clears first.
        final mine = ConversationMetaStore(
          failing,
          accountPrefix: kPeerToxId.substring(0, 16),
        );
        await mine.setPinned('c2c_$kSelfKey', true);
        await mine.setDraft('c2c_$kSelfKey', 'TU');
        Object? value(String k) {
          try {
            return failing.getString(k);
          } on TypeError {
            return failing.getStringList(k);
          }
        }

        final before = {for (final k in failing.keys()) k: value(k)};
        // Removes (the clear) succeed; the first write of the restored pins fails.
        failing.failNextListWrite = true;
        await expectLater(
          current.restoreEncryptedBackup(good, 'correct horse'),
          throwsA(isA<StateError>()),
        );
        await expectUntouched();
        expect({for (final k in failing.keys()) k: value(k)}, before);
        expect(paths.profileExists, isTrue);
        expect(
          crypto.extractPublicKey(File(paths.profileFile).readAsBytesSync()),
          kPeerKey,
        );
      },
    );
  });

  test(
    'an identity password stays separate and is asked for on restore',
    () async {
      final svc = await seeded(password: 'id-pass');
      final bytes = await svc.exportEncryptedBackup(request(_all));
      await svc.dispose();
      final other = IdentityPaths(p.join(tempRoot.path, 'device2'));
      final restored = service(other, kv: MemoryKeyValueStore());
      final preview = await restored.previewEncryptedBackup(
        bytes,
        'correct horse',
      );
      expect(preview.profileNeedsPassword, isTrue);
      await expectLater(
        restored.restoreEncryptedBackup(bytes, 'correct horse'),
        throwsCode('wrong_password'),
      );
      await expectLater(
        restored.restoreEncryptedBackup(
          bytes,
          'correct horse',
          identityPassword: 'bad',
        ),
        throwsCode('wrong_password'),
      );
      expect(other.profileExists, isFalse);
      await restored.restoreEncryptedBackup(
        bytes,
        'correct horse',
        identityPassword: 'id-pass',
      );
      expect(restored.current!.hasPassword, isTrue);
      await restored.dispose();
    },
  );

  test('restoring twice gives the same result, not duplicates', () async {
    final svc = await seeded();
    final bytes = await svc.exportEncryptedBackup(request(_all));
    await svc.restoreEncryptedBackup(bytes, 'correct horse');
    final once = File(historyFile(paths)).readAsStringSync();
    final progress = File(
      p.join(paths.trainingDirectory, 'progress.json'),
    ).readAsStringSync();
    await svc.restoreEncryptedBackup(bytes, 'correct horse');
    expect(File(historyFile(paths)).readAsStringSync(), once);
    expect(
      File(p.join(paths.trainingDirectory, 'progress.json')).readAsStringSync(),
      progress,
    );
    await svc.dispose();
  });

  group('snapshot helpers', () {
    final queued = [
      QueuedRow(
        queueKey: kPeerKey,
        conversationId: 'c2c_$kPeerKey',
        text: 'QRL?',
        queuedAt: t1,
        msgId: 'q1',
      ),
      QueuedRow(
        queueKey: kPeerKey,
        conversationId: 'c2c_$kPeerKey',
        text: 'old',
        queuedAt: t0,
      ),
    ];

    test('withoutQueued drops queued rows by id and by legacy match', () {
      final doc = utf8.encode(
        jsonEncode({
          'conversationId': kPeerKey.toLowerCase(),
          'messages': [
            _row('QRL?', t1, 'q1'),
            _row('old', t0, 'x'),
            _row('keep', t0, 'k'),
          ],
        }),
      );
      final (out, removed) = BackupSnapshot.withoutQueued(
        'a.json',
        Uint8List.fromList(doc),
        queued,
      );
      expect(removed, 2);
      expect(
        ((jsonDecode(utf8.decode(out)) as Map)['messages'] as List)
            .single['msgID'],
        'k',
      );
      final other = Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'conversationId': 'tox_1',
            'messages': [_row('QRL?', t1, 'q1')],
          }),
        ),
      );
      expect(BackupSnapshot.withoutQueued('b.json', other, queued).$2, 0);
      final jsonl = Uint8List.fromList(
        utf8.encode(
          '${jsonEncode(_row('QRL?', t1, 'q1'))}\n${jsonEncode(_row('keep', t0, 'k'))}\n',
        ),
      );
      final (lines, n) = BackupSnapshot.withoutQueued(
        'a.archive.jsonl',
        jsonl,
        queued,
      );
      expect(n, 1);
      expect(utf8.decode(lines), contains('"keep"'));
    });

    test('verifyStable notices a changed or a new file', () async {
      final dir = Directory(p.join(tempRoot.path, 'v'))..createSync();
      final a = File(p.join(dir.path, 'a'))..writeAsStringSync('1');
      final stamps = await BackupSnapshot.stamp([a]);
      await BackupSnapshot.verifyStable(stamps, [a]);
      final b = File(p.join(dir.path, 'b'))..writeAsStringSync('2');
      expect(
        () => BackupSnapshot.verifyStable(stamps, [a, b]),
        throwsA(isA<SnapshotUnstable>()),
      );
      a.writeAsStringSync('12');
      expect(
        () => BackupSnapshot.verifyStable(stamps, [a]),
        throwsA(isA<SnapshotUnstable>()),
      );
    });
  });
}

/// Fails the next `setStringList` once when [failNextListWrite] is set.
class _FailingStore extends MemoryKeyValueStore {
  bool failNextListWrite = false;

  @override
  Future<void> setStringList(String key, List<String> value) {
    if (failNextListWrite) {
      failNextListWrite = false;
      return Future.error(StateError('disk full'));
    }
    return super.setStringList(key, value);
  }
}

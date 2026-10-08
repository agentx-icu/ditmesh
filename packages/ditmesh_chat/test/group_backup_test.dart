import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/adapters/prefs_adapter.dart';
import 'package:ditmesh_chat/src/identity/backup_archive.dart';
import 'package:ditmesh_chat/src/identity/backup_snapshot.dart';
import 'package:ditmesh_chat/src/identity/group_descriptors.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;

import 'helpers/fakes.dart';

/// Group membership (ids, chat ids, kinds, names, left groups, retained
/// history) is what Tim2Tox rebinds and rejoins from on start. A complete
/// backup carries it in the identity category and a restore puts it back
/// after clearing the identity's preferences.
void main() {
  late Directory tempRoot;
  late IdentityPaths paths;
  late MemorySecureStore secure;
  late MemoryKeyValueStore store;
  late FakeChatEngine engine;
  final crypto = FakeProfileCrypto();
  final prefix = kSelfToxId.substring(0, 16);
  const retainedKey = 'groups_history_retained_v1';

  Tim2ToxIdentityService service(IdentityPaths at, KeyValueStore kv) =>
      Tim2ToxIdentityService(
        paths: at,
        engine: engine,
        crypto: crypto,
        verifier: PasswordVerifier(secure, iterations: 10),
        store: kv,
      );

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ditmesh_groups_');
    paths = IdentityPaths(p.join(tempRoot.path, 'identity'));
    secure = MemorySecureStore();
    store = MemoryKeyValueStore();
    engine = FakeChatEngine();
  });

  tearDown(() async {
    await engine.dispose();
    if (tempRoot.existsSync()) await tempRoot.delete(recursive: true);
  });

  const request = EncryptedBackupRequest(
    passphrase: 'correct horse',
    categories: {BackupCategory.chatHistory},
  );

  Future<Tim2ToxIdentityService> seeded({bool groups = true}) async {
    final svc = service(paths, store);
    await svc.create(displayName: 'DL1ABC');
    if (groups) {
      final prefs = Tim2ToxPreferencesAdapter(store, accountPrefix: prefix);
      await prefs.setGroups({'tox_1', 'tox_2'});
      await prefs.setGroupChatId('tox_1', 'aa11');
      await prefs.setGroupType('tox_1', 'group');
      await prefs.setGroupName('tox_1', 'CQ net');
      await prefs.setGroupChatId('tox_2', 'bb22');
      await prefs.setGroupType('tox_2', 'conference');
      await prefs.setQuitGroups({'tox_9'});
      await prefs.setStringList(prefs.accountScopedKey(retainedKey), ['tox_9']);
      // Pending invitations are Tim2Tox-scoped too and must not travel.
      await store.setString('pending_group_invites_v1_$prefix', '[{"x":1}]');
    }
    return svc;
  }

  Future<void> expectGroups(KeyValueStore kv) async {
    final prefs = Tim2ToxPreferencesAdapter(kv, accountPrefix: prefix);
    expect(await prefs.getGroups(), {'tox_1', 'tox_2'});
    expect(await prefs.getGroupChatId('tox_1'), 'aa11');
    expect(await prefs.getGroupType('tox_1'), 'group');
    expect(await prefs.getGroupName('tox_1'), 'CQ net');
    expect(await prefs.getGroupChatId('tox_2'), 'bb22');
    expect(await prefs.getGroupType('tox_2'), 'conference');
    expect(await prefs.getQuitGroups(), {'tox_9'});
    expect(await prefs.getStringSet(prefs.accountScopedKey(retainedKey)), {
      'tox_9',
    });
    expect(kv.getString('pending_group_invites_v1_$prefix'), isNull);
  }

  test('restore into a fresh store brings the groups back', () async {
    final svc = await seeded();
    final bytes = await svc.exportEncryptedBackup(request);
    await svc.dispose();

    final store2 = MemoryKeyValueStore();
    final other = IdentityPaths(p.join(tempRoot.path, 'device2'));
    final restored = service(other, store2);
    final report = await restored.restoreEncryptedBackup(bytes, 'correct horse');
    expect(report.restored, contains(BackupCategory.identity));
    await expectGroups(store2);
    await restored.dispose();
  });

  test('restore over the same identity keeps the groups', () async {
    final svc = await seeded();
    final bytes = await svc.exportEncryptedBackup(request);
    // Membership changed since the backup; the backup wins (like history).
    final prefs = Tim2ToxPreferencesAdapter(store, accountPrefix: prefix);
    await prefs.setGroups({'tox_1', 'tox_2', 'tox_3'});
    await prefs.setGroupChatId('tox_3', 'cc33');
    await svc.restoreEncryptedBackup(bytes, 'correct horse');
    await expectGroups(store);
    expect(await prefs.getGroupChatId('tox_3'), isNull);
    await svc.dispose();
  });

  test('an identity without groups writes no bindings entry', () async {
    final svc = await seeded(groups: false);
    final bytes = await svc.exportEncryptedBackup(request);
    await svc.dispose();
    final (_, container) = BackupArchive.open(bytes, 'correct horse', crypto);
    expect(container.entries.keys, isNot(contains(BackupSnapshot.groupsEntry)));
    expect(
      await GroupDescriptors.export(store, prefix),
      isNull,
    );
  });

  test('a malformed bindings document restores nothing and does not throw',
      () async {
    await GroupDescriptors.restore(store, prefix, {
      'groups': [
        1,
        {'id': ''},
        {'id': 'tox_7', 'chatId': 5, 'type': null, 'name': 'Seven'},
      ],
      'quit': 'nope',
      'historyRetained': [3],
      'unknown': true,
    });
    final prefs = Tim2ToxPreferencesAdapter(store, accountPrefix: prefix);
    expect(await prefs.getGroups(), {'tox_7'});
    expect(await prefs.getGroupChatId('tox_7'), isNull);
    expect(await prefs.getGroupName('tox_7'), 'Seven');
    expect(await prefs.getQuitGroups(), isEmpty);
    await GroupDescriptors.restore(store, prefix, 'not a map');
    await GroupDescriptors.restore(store, prefix, null);
    expect(await prefs.getGroups(), {'tox_7'});
  });

  test('export is a plain JSON document', () async {
    await seeded();
    final doc = await GroupDescriptors.export(store, prefix);
    final roundTrip = jsonDecode(jsonEncode(doc)) as Map;
    expect(roundTrip['groups'], [
      {'id': 'tox_1', 'chatId': 'aa11', 'type': 'group', 'name': 'CQ net'},
      {'id': 'tox_2', 'chatId': 'bb22', 'type': 'conference', 'name': ''},
    ]);
    expect(roundTrip['quit'], ['tox_9']);
    expect(roundTrip['historyRetained'], ['tox_9']);
    expect(Uint8List.fromList(utf8.encode(jsonEncode(doc))), isNotEmpty);
  });
}

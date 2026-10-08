import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/adapters/prefs_adapter.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:tim2tox_dart/interfaces/draft_preferences_service.dart';

import 'helpers/fakes.dart';

class _FailingCrypto extends FakeProfileCrypto {
  String? failPassword;

  @override
  Uint8List encrypt(Uint8List plaintext, String password) {
    if (password == failPassword) throw StateError('encryption failed');
    return super.encrypt(plaintext, password);
  }
}

class _FailingSecureStore extends MemorySecureStore {
  bool failWrite = false;

  @override
  Future<void> write(String key, String value) async {
    if (failWrite) throw StateError('secure store unavailable');
    await super.write(key, value);
  }
}

class _FailingPersistEngine extends FakeChatEngine {
  @override
  Future<void> persist() => throw StateError('native flush failed');
}

class _DataStore implements IdentityDataStore {
  Future<void> Function()? onFlush;
  Future<void> Function()? onReplacement;
  int flushes = 0;
  int replacements = 0;

  @override
  Future<void> flush() async {
    flushes++;
    await onFlush?.call();
  }

  @override
  Future<void> prepareForReplacement() async {
    replacements++;
    await onReplacement?.call();
  }
}

void main() {
  late Directory root;
  late IdentityPaths paths;
  late FakeChatEngine engine;
  late _FailingCrypto crypto;
  late _FailingSecureStore secure;
  late MemoryKeyValueStore preferences;

  Tim2ToxIdentityService newService() => Tim2ToxIdentityService(
    paths: paths,
    engine: engine,
    crypto: crypto,
    verifier: PasswordVerifier(secure, iterations: 10),
    store: preferences,
  );

  setUp(() async {
    root = await Directory.systemTemp.createTemp('identity_persistence_');
    paths = IdentityPaths('${root.path}/identity');
    engine = FakeChatEngine();
    crypto = _FailingCrypto();
    secure = _FailingSecureStore();
    preferences = MemoryKeyValueStore();
  });

  tearDown(() async {
    await engine.dispose();
    await root.delete(recursive: true);
  });

  test(
    'failed protected creation does not strand a locked plaintext identity',
    () async {
      final service = newService();
      secure.failWrite = true;
      await expectLater(
        service.create(displayName: 'CQ', password: 'pw'),
        throwsStateError,
      );
      secure.failWrite = false;
      final restarted = newService();
      expect(await restarted.inspect(), IdentityState.none);
      await restarted.create(displayName: 'Retry', password: 'pw');
      expect(restarted.current?.displayName, 'Retry');
      await service.dispose();
      await restarted.dispose();
    },
  );

  test(
    'failed password encryption keeps the old password usable after restart',
    () async {
      final service = newService();
      await service.create(displayName: 'CQ', password: 'old');
      final before = await File(paths.profileFile).readAsBytes();
      crypto.failPassword = 'new';
      await expectLater(
        service.changePassword(oldPassword: 'old', newPassword: 'new'),
        throwsStateError,
      );
      expect(await File(paths.profileFile).readAsBytes(), before);
      expect(
        await PasswordVerifier(
          secure,
          iterations: 10,
        ).verify(kSelfToxId, 'old'),
        isTrue,
      );
      await service.dispose();
      final restarted = newService();
      await restarted.unlock('old');
      await restarted.dispose();
    },
  );

  test(
    'concurrent profile edits retain both fields after a fresh open',
    () async {
      final service = newService();
      await service.create(displayName: 'Before');
      await Future.wait([
        service.updateProfile(displayName: 'After'),
        service.updateProfile(statusMessage: '73'),
      ]);
      await service.dispose();
      final restarted = newService();
      final identity = await restarted.open();
      expect(identity.displayName, 'After');
      expect(identity.statusMessage, '73');
      await restarted.dispose();
    },
  );

  test('preference clear removes full-address drafts and timestamps', () async {
    final store = MemoryKeyValueStore();
    final prefs = Tim2ToxPreferencesAdapter(
      store,
      accountPrefix: kSelfToxId.substring(0, 16),
    );
    await prefs.saveConversationDraft(
      accountToxId: kSelfToxId,
      draft: const ConversationDraft(
        conversationID: 'c2c_peer',
        text: 'unfinished',
        timestamp: 42,
      ),
    );
    await prefs.saveConversationDraft(
      accountToxId: kPeerToxId,
      draft: const ConversationDraft(
        conversationID: 'c2c_peer',
        text: 'other account',
        timestamp: 43,
      ),
    );
    await prefs.clear();
    expect(
      await prefs.loadConversationDraft(
        accountToxId: kSelfToxId,
        conversationID: 'c2c_peer',
      ),
      isNull,
    );
    expect(store.keys(), hasLength(2));
    expect(
      await prefs.loadConversationDraft(
        accountToxId: kPeerToxId,
        conversationID: 'c2c_peer',
      ),
      isNotNull,
    );
  });

  test(
    'delete before open clears the stored account preferences only',
    () async {
      final original = newService();
      await original.create(displayName: 'CQ');
      await preferences.setStringList(
        'groups_list_${kSelfToxId.substring(0, 16)}',
        ['tox_1'],
      );
      await preferences.setStringList(
        'groups_list_${kPeerToxId.substring(0, 16)}',
        ['tox_2'],
      );
      await preferences.setString('current_bootstrap_host', 'node.tox');
      await original.dispose();
      final restarted = newService();
      await restarted.deleteIdentity();
      expect(
        preferences.getStringList('groups_list_${kSelfToxId.substring(0, 16)}'),
        isNull,
      );
      expect(
        preferences.getStringList('groups_list_${kPeerToxId.substring(0, 16)}'),
        ['tox_2'],
      );
      expect(preferences.getString('current_bootstrap_host'), 'node.tox');
      await restarted.dispose();
    },
  );

  test(
    'backup awaits registered progress flushes before reading the bundle',
    () async {
      final service = newService();
      await service.create(displayName: 'CQ');
      final store = _DataStore()
        ..onFlush = () async {
          await File(
            '${paths.trainingDirectory}/progress.json',
          ).writeAsString('latest');
        };
      service.registerDataStore(store);
      final backup = BackupContainer.decode(await service.exportBackup());
      expect(backup.entries['training/progress.json'], 'latest'.codeUnits);
      expect(store.flushes, 1);
      expect(engine.saveCalls, 1);
      await service.dispose();
    },
  );

  test(
    'native flush failure still drains every registered data store',
    () async {
      await engine.dispose();
      engine = _FailingPersistEngine();
      final service = newService();
      await service.create(displayName: 'CQ');
      final first = _DataStore();
      final second = _DataStore();
      service.registerDataStore(first);
      service.registerDataStore(second);
      await expectLater(service.persist(), throwsStateError);
      expect(first.flushes, 1);
      expect(second.flushes, 1);
      await service.dispose();
    },
  );

  test(
    'delete drains registered writers and publishes null after removal',
    () async {
      final service = newService();
      await service.create(displayName: 'CQ');
      final hold = Completer<void>();
      final entered = Completer<void>();
      final store = _DataStore()
        ..onReplacement = () async {
          entered.complete();
          await hold.future;
        };
      service.registerDataStore(store);
      final deletion = service.deleteIdentity();
      await entered.future;
      expect(paths.profileExists, isTrue);
      hold.complete();
      await deletion;
      expect(service.current, isNull);
      expect(paths.profileExists, isFalse);
      expect(store.replacements, 1);
      await service.dispose();
    },
  );

  test(
    'replacement barrier failure republishes the preserved identity',
    () async {
      final service = newService();
      await service.create(displayName: 'CQ');
      final values = <Identity?>[];
      final sub = service.identityChanges.listen(values.add);
      service.registerDataStore(
        _DataStore()
          ..onReplacement = () async {
            throw StateError('pending data could not be saved');
          },
      );
      await expectLater(service.deleteIdentity(), throwsStateError);
      await pumpEventQueue();
      expect(paths.profileExists, isTrue);
      expect(
        values,
        hasLength(2),
        reason: 'republish so prepared modules reopen',
      );
      await sub.cancel();
      await service.dispose();
    },
  );

  test(
    'encrypted profile recovers a verifier interrupted during password change',
    () async {
      final service = newService();
      await service.create(displayName: 'CQ', password: 'old');
      await service.dispose();
      await PasswordVerifier(
        secure,
        iterations: 10,
      ).setPassword(kSelfToxId, 'new');
      final restarted = newService();
      await restarted.unlock('old');
      expect(
        await PasswordVerifier(
          secure,
          iterations: 10,
        ).verify(kSelfToxId, 'old'),
        isTrue,
      );
      await restarted.dispose();
    },
  );

  test(
    'failed import directory swap restores files without publishing null',
    () async {
      final service = newService();
      await service.create(displayName: 'Before');
      await File(
        '${paths.trainingDirectory}/progress.json',
      ).writeAsString('existing');
      final values = <Identity?>[];
      final sub = service.identityChanges.listen(values.add);
      service.registerDataStore(
        _DataStore()
          ..onReplacement = () async {
            // Remove the fully staged tree after preparation to force the final
            // rename to fail, after the existing tree has moved to `previous`.
            final stage = root.listSync().whereType<Directory>().singleWhere(
              (directory) => directory.path.contains('.ditmesh-import-'),
            );
            await Directory('${stage.path}/identity').delete(recursive: true);
          },
      );
      final backup = BackupContainer(
        entries: {
          BackupContainer.profileEntry: FakeProfileCrypto.plainProfile(
            kPeerKey,
            'After',
          ),
        },
        profileEncrypted: false,
      ).encode();
      await expectLater(
        service.importBackup(backup),
        throwsA(isA<FileSystemException>()),
      );
      await pumpEventQueue();
      expect(values, everyElement(isNotNull));
      expect(service.current?.displayName, 'Before');
      expect(
        crypto.extractPublicKey(await File(paths.profileFile).readAsBytes()),
        kSelfKey,
      );
      expect(
        await File('${paths.trainingDirectory}/progress.json').readAsString(),
        'existing',
      );
      await sub.cancel();
      await service.dispose();
    },
  );

  test(
    'failed import verifier write leaves the existing profile and progress intact',
    () async {
      final service = newService();
      await service.create(displayName: 'Before', password: 'old');
      await File(
        '${paths.trainingDirectory}/progress.json',
      ).writeAsString('existing');
      final backup = BackupContainer(
        entries: {
          BackupContainer.profileEntry: crypto.encrypt(
            FakeProfileCrypto.plainProfile(kPeerKey, 'After'),
            'new',
          ),
          'training/progress.json': Uint8List.fromList('replacement'.codeUnits),
        },
        profileEncrypted: true,
      ).encode();
      secure.failWrite = true;
      await expectLater(
        service.importBackup(backup, password: 'new'),
        throwsStateError,
      );
      secure.failWrite = false;
      expect(service.current?.displayName, 'Before');
      expect(
        crypto.extractPublicKey(
          crypto.decrypt(await File(paths.profileFile).readAsBytes(), 'old'),
        ),
        kSelfKey,
      );
      expect(
        await File('${paths.trainingDirectory}/progress.json').readAsString(),
        'existing',
      );
      await service.dispose();
    },
  );
}

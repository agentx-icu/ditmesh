import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;

import 'helpers/fakes.dart';

void main() {
  late Directory tempRoot;
  late IdentityPaths paths;
  late MemorySecureStore secure;
  late FakeChatEngine engine;
  final crypto = FakeProfileCrypto();

  Tim2ToxIdentityService newService() => Tim2ToxIdentityService(
        paths: paths,
        engine: engine,
        crypto: crypto,
        verifier: PasswordVerifier(secure, iterations: 10),
      );

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ditmesh_identity_');
    paths = IdentityPaths(p.join(tempRoot.path, 'identity'));
    secure = MemorySecureStore();
    engine = FakeChatEngine();
  });

  tearDown(() async {
    await engine.dispose();
    if (tempRoot.existsSync()) await tempRoot.delete(recursive: true);
  });

  Matcher throwsCode(String code) =>
      throwsA(isA<ChatException>().having((e) => e.code, 'code', code));

  group('first run', () {
    test('inspect → none, create → ready, connect starts the engine', () async {
      final svc = newService();
      expect(await svc.inspect(), IdentityState.none);
      expect(svc.current, isNull);
      expect(() => svc.open(), throwsCode('no_identity'));

      final id = await svc.create(displayName: 'W1AW');
      expect(id.toxId, kSelfToxId);
      expect(id.displayName, 'W1AW');
      expect(id.hasPassword, isFalse);
      expect(id.publicKey, kSelfKey);
      expect(svc.current, isNotNull);
      expect(await svc.inspect(), IdentityState.ready);
      expect(File(paths.identityFile).existsSync(), isTrue);
      expect(crypto.isEncrypted(File(paths.profileFile).readAsBytesSync()), isFalse);

      expect(svc.connectionStatus, ConnectionStatus.offline);
      await svc.connect();
      expect(engine.startCalls, hasLength(1));
      expect(engine.startCalls.single.toxId, kSelfToxId);
      expect(engine.startCalls.single.displayName, 'W1AW');
      expect(engine.startCalls.single.accountPrefix, kSelfToxId.substring(0, 16));
      await svc.connect(); // idempotent
      expect(engine.startCalls, hasLength(1));
      expect(svc.connectionStatus, ConnectionStatus.connecting);
      engine.setConnected(true);
      await pumpEventQueue();
      expect(svc.connectionStatus, ConnectionStatus.online);

      await svc.disconnect();
      expect(engine.stopCalls, 1);
      expect(svc.connectionStatus, ConnectionStatus.offline);
      expect(await svc.dataDirectory(), paths.trainingDirectory);
      await svc.dispose();
    });

    test('create refuses to overwrite an existing identity', () async {
      final svc = newService();
      await svc.create(displayName: 'A');
      expect(() => svc.create(displayName: 'B'), throwsCode('identity_exists'));
      await svc.dispose();
    });
  });

  group('password-protected identity', () {
    test('locked → wrong_password → unlock → ready; profile is encrypted at rest',
        () async {
      final first = newService();
      await first.create(displayName: 'K1ABC', password: 'pw');
      expect(first.current!.hasPassword, isTrue);
      final atRest = File(paths.profileFile).readAsBytesSync();
      expect(crypto.isEncrypted(atRest), isTrue,
          reason: 'engine stopped + password set ⇒ encrypted on disk');
      await first.dispose();

      // A fresh process.
      final second = newService();
      expect(await second.inspect(), IdentityState.locked);
      expect(() => second.open(), throwsCode('locked'));
      expect(() => second.unlock('nope'), throwsCode('wrong_password'));
      expect(() => second.unlock(''), throwsCode('wrong_password'));
      expect(second.current, isNull);

      final id = await second.unlock('pw');
      expect(id.displayName, 'K1ABC');
      expect(await second.inspect(), IdentityState.ready);

      await second.connect();
      expect(engine.startCalls.single.profilePassphrase, 'pw');
      expect(crypto.isEncrypted(File(paths.profileFile).readAsBytesSync()), isTrue,
          reason: 'native encrypts every save: never plaintext while running');
      await second.disconnect();
      expect(crypto.isEncrypted(File(paths.profileFile).readAsBytesSync()), isTrue);
      await second.dispose();
    });

    test('a crash while running leaves the profile encrypted', () async {
      final first = newService();
      await first.create(displayName: 'N0CALL', password: 'pw');
      await first.connect();
      await first.dispose(); // simulate a crash: no disconnect
      expect(crypto.isEncrypted(File(paths.profileFile).readAsBytesSync()), isTrue);
    });

    test('creation hands the password to the engine (no plaintext write)', () async {
      final svc = newService();
      await svc.create(displayName: 'N0CALL', password: 'pw');
      expect(crypto.decrypt(File(paths.profileFile).readAsBytesSync(), 'pw'),
          isNotEmpty);
      await svc.dispose();
    });

    test('a plaintext file from an older build: verifier unlocks, connect '
        'migrates it', () async {
      final first = newService();
      await first.create(displayName: 'N0CALL', password: 'pw');
      await first.dispose();
      // What an older build left after a crash: plaintext while it ran.
      final file = File(paths.profileFile);
      file.writeAsBytesSync(crypto.decrypt(file.readAsBytesSync(), 'pw'));

      final second = newService();
      expect(await second.inspect(), IdentityState.locked);
      expect(() => second.unlock('bad'), throwsCode('wrong_password'));
      await second.unlock('pw');
      await second.connect();
      expect(crypto.isEncrypted(file.readAsBytesSync()), isTrue);
      await second.disconnect();
      await second.dispose();
    });

    test('disconnect encrypts a plaintext file even when not started '
        '(retry after a failed earlier attempt)', () async {
      final first = newService();
      await first.create(displayName: 'N0CALL', password: 'pw');
      await first.dispose();
      final file = File(paths.profileFile);
      file.writeAsBytesSync(crypto.decrypt(file.readAsBytesSync(), 'pw'));
      final second = newService();
      await second.unlock('pw');
      await second.disconnect(); // never connected in this process
      expect(crypto.isEncrypted(file.readAsBytesSync()), isTrue);
      await second.dispose();
    });

    test('changing the password while connected re-keys the live profile',
        () async {
      final svc = newService();
      await svc.create(displayName: 'A', password: 'one');
      await svc.connect();
      await svc.changePassword(oldPassword: 'one', newPassword: 'two');
      expect(engine.rekeyCalls, ['two']);
      expect(crypto.decrypt(File(paths.profileFile).readAsBytesSync(), 'two'),
          isNotEmpty);
      await svc.changePassword(oldPassword: 'two');
      expect(engine.rekeyCalls, ['two', null]);
      expect(crypto.isEncrypted(File(paths.profileFile).readAsBytesSync()), isFalse);
      await svc.disconnect();
      await svc.dispose();
    });

    test('a failed live re-key keeps the old password everywhere', () async {
      final svc = newService();
      await svc.create(displayName: 'A', password: 'one');
      await svc.connect();
      engine.rekeyResults.add(false);
      await expectLater(
        svc.changePassword(oldPassword: 'one', newPassword: 'two'),
        throwsCode('rekey_failed'),
      );
      expect(crypto.decrypt(File(paths.profileFile).readAsBytesSync(), 'one'),
          isNotEmpty);
      await svc.disconnect();
      await svc.dispose();
      final again = newService();
      await again.unlock('one');
      await again.dispose();
    });

    test('a failure after the re-key rolls the live profile back', () async {
      final svc = newService();
      await svc.create(displayName: 'A', password: 'one');
      await svc.connect();
      // Removing the password: the re-key succeeds, then identity.json
      // cannot be written (its directory is gone and replaced by a file).
      final identity = File(paths.identityFile);
      identity.deleteSync();
      Directory(paths.identityFile).createSync();
      await expectLater(
        svc.changePassword(oldPassword: 'one'),
        throwsA(anything),
      );
      expect(engine.rekeyCalls, [null, 'one']);
      expect(crypto.decrypt(File(paths.profileFile).readAsBytesSync(), 'one'),
          isNotEmpty);
      Directory(paths.identityFile).deleteSync();
      await svc.disconnect();
      await svc.dispose();
    });

    test('if even the roll-back re-key fails, memory follows the file', () async {
      final svc = newService();
      await svc.create(displayName: 'A', password: 'one');
      await svc.connect();
      engine.rekeyResults.addAll([true, false]);
      final identity = File(paths.identityFile);
      final saved = identity.readAsBytesSync();
      identity.deleteSync();
      Directory(paths.identityFile).createSync();
      await expectLater(
        svc.changePassword(oldPassword: 'one', newPassword: 'two'),
        throwsCode('rekey_rollback_failed'),
      );
      Directory(paths.identityFile).deleteSync();
      identity.writeAsBytesSync(saved);
      // The running profile carries 'two'; disconnect must not mis-encrypt.
      await svc.disconnect();
      expect(crypto.decrypt(File(paths.profileFile).readAsBytesSync(), 'two'),
          isNotEmpty);
      await svc.dispose();
    });

    test('changePassword: add, change, remove', () async {
      final svc = newService();
      await svc.create(displayName: 'A');
      await svc.changePassword(newPassword: 'one');
      expect(svc.current!.hasPassword, isTrue);
      expect(crypto.isEncrypted(File(paths.profileFile).readAsBytesSync()), isTrue);

      expect(
        () => svc.changePassword(oldPassword: 'wrong', newPassword: 'two'),
        throwsCode('wrong_password'),
      );
      await svc.changePassword(oldPassword: 'one', newPassword: 'two');
      expect(crypto.decrypt(File(paths.profileFile).readAsBytesSync(), 'two'),
          isNotEmpty);

      await svc.changePassword(oldPassword: 'two');
      expect(svc.current!.hasPassword, isFalse);
      expect(crypto.isEncrypted(File(paths.profileFile).readAsBytesSync()), isFalse);
      expect(await svc.inspect(), IdentityState.ready);
      await svc.dispose();
    });
  });

  test('deleting the identity also removes leftover import staging', () async {
    final svc = newService();
    await svc.create(displayName: 'A', password: 'pw');
    // What a failed import's rollback leaves behind: the previous identity.
    final leftover = Directory(
      p.join(tempRoot.path, '.ditmesh-import-x', 'previous'),
    )..createSync(recursive: true);
    File(p.join(leftover.path, 'tox_profile.tox')).writeAsStringSync('old');
    final unrelated = Directory(p.join(tempRoot.path, 'keep'))..createSync();
    await svc.deleteIdentity();
    expect(leftover.parent.existsSync(), isFalse);
    expect(unrelated.existsSync(), isTrue);
    await svc.dispose();
  });

  test('leftover staging goes even when the identity root is already gone',
      () async {
    final leftover = Directory(p.join(tempRoot.path, '.ditmesh-import-y'))
      ..createSync(recursive: true);
    await paths.deleteAll();
    expect(leftover.existsSync(), isFalse);
  });

  group('backup', () {
    test('export/import round trip restores identity and training data', () async {
      final svc = newService();
      await svc.create(displayName: 'DL1ABC', password: 'pw');
      await svc.updateProfile(statusMessage: '73');
      final training = await svc.dataDirectory();
      File(p.join(training, 'progress.json')).writeAsStringSync('{"wpm":18}');
      Directory(p.join(training, 'nested')).createSync();
      File(p.join(training, 'nested', 'x.bin')).writeAsBytesSync([1, 2, 3]);

      final bytes = await svc.exportBackup();
      final container = BackupContainer.decode(bytes);
      expect(container.profileEncrypted, isTrue);
      expect(container.entries.keys, containsAll([
        'identity.json',
        'tox_profile.tox',
        'training/progress.json',
        'training/nested/x.bin',
      ]));
      await svc.dispose();

      // Restore into a different root, as on a new device.
      final otherRoot = IdentityPaths(p.join(tempRoot.path, 'other'));
      final otherSecure = MemorySecureStore();
      final restored = Tim2ToxIdentityService(
        paths: otherRoot,
        engine: engine,
        crypto: crypto,
        verifier: PasswordVerifier(otherSecure, iterations: 10),
      );
      expect(() => restored.importBackup(bytes), throwsCode('wrong_password'));
      expect(() => restored.importBackup(bytes, password: 'no'),
          throwsCode('wrong_password'));
      final id = await restored.importBackup(bytes, password: 'pw');
      expect(id.toxId, kSelfToxId);
      expect(id.displayName, 'DL1ABC');
      expect(id.statusMessage, '73');
      expect(id.hasPassword, isTrue);
      expect(
        File(p.join(otherRoot.trainingDirectory, 'progress.json')).readAsStringSync(),
        '{"wpm":18}',
      );
      expect(
        File(p.join(otherRoot.trainingDirectory, 'nested', 'x.bin')).readAsBytesSync(),
        [1, 2, 3],
      );
      // Password carried over: the restored identity unlocks and connects.
      await restored.connect();
      expect(engine.startCalls.last.toxId, kSelfToxId);
      await restored.disconnect();
      expect(await PasswordVerifier(otherSecure, iterations: 10).verify(kSelfToxId, 'pw'),
          isTrue);
      await restored.dispose();
    });

    test('an unencrypted backup imports without a password', () async {
      final svc = newService();
      await svc.create(displayName: 'plain');
      final bytes = await svc.exportBackup();
      expect(BackupContainer.decode(bytes).profileEncrypted, isFalse);
      await svc.deleteIdentity();
      expect(await svc.inspect(), IdentityState.none);
      final id = await svc.importBackup(bytes);
      expect(id.displayName, 'plain');
      expect(id.hasPassword, isFalse);
      expect(await svc.inspect(), IdentityState.ready);
      await svc.dispose();
    });

    test('recordings are left out unless the learner opts in', () async {
      final svc = newService();
      await svc.create(displayName: 'plain');
      final media = Directory(p.join(paths.root, 'media', 'recordings'))
        ..createSync(recursive: true);
      File(p.join(media.path, 'rec_a.wav')).writeAsBytesSync([7, 8, 9]);
      // Never carried: the working recording, an unreferenced file and a
      // staging leftover.
      File(p.join(media.path, 'current.wav')).writeAsBytesSync([1]);
      File(p.join(media.path, 'rec_orphan.wav')).writeAsBytesSync([2]);
      File(p.join(media.path, 'rec_a.wav.tmp')).writeAsBytesSync([3]);
      final doc = File(
        p.join(await svc.dataDirectory(), BackupMedia.materialsDoc),
      )..createSync(recursive: true);
      doc.writeAsStringSync(
        '{"v":1,"materials":[{"id":"x","file":"media/recordings/rec_a.wav"},'
        '{"id":"y","file":"media/recordings/current.wav"}]}',
      );

      final without = BackupContainer.decode(await svc.exportBackup());
      expect(without.mediaFiles, isEmpty);
      expect(without.entries.keys.where((k) => k.startsWith('media/')), isEmpty);

      final bytes = await svc.exportBackup(includeMedia: true);
      final withMedia = BackupContainer.decode(bytes);
      expect(withMedia.mediaFiles.map((e) => e.key), ['media/recordings/rec_a.wav']);
      await svc.dispose();

      final otherRoot = IdentityPaths(p.join(tempRoot.path, 'other'));
      final restored = Tim2ToxIdentityService(
        paths: otherRoot,
        engine: engine,
        crypto: crypto,
        verifier: PasswordVerifier(MemorySecureStore(), iterations: 10),
      );
      await restored.importBackup(bytes);
      expect(
        File(p.join(otherRoot.root, 'media', 'recordings', 'rec_a.wav'))
            .readAsBytesSync(),
        [7, 8, 9],
      );
      await restored.dispose();
    });

    test('garbage is rejected as invalid_backup', () async {
      final svc = newService();
      expect(
        () => svc.importBackup(
              Uint8List.fromList(utf8.encode('not a backup at all')),
            ),
        throwsCode('invalid_backup'),
      );
      await svc.dispose();
    });
  });

  test('deleteIdentity wipes disk, verifier and current', () async {
    final svc = newService();
    await svc.create(displayName: 'gone', password: 'pw');
    await svc.connect();
    await svc.deleteIdentity();
    expect(engine.stopCalls, 1);
    expect(Directory(paths.root).existsSync(), isFalse);
    expect(secure.values, isEmpty);
    expect(svc.current, isNull);
    expect(await svc.inspect(), IdentityState.none);
    await svc.dispose();
  });
}

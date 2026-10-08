import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;

import 'helpers/fakes.dart';

/// A stop whose native teardown did not confirm (Tim2Tox quarantined an
/// instance a background task was still using) must fail out loud, and
/// nothing may rewrite, replace or delete the profile tree until a later
/// teardown confirms.
void main() {
  late Directory tempRoot;
  late IdentityPaths paths;
  late MemorySecureStore secure;
  late MemoryKeyValueStore store;
  late FakeChatEngine engine;
  final crypto = FakeProfileCrypto();

  Tim2ToxIdentityService newService() => Tim2ToxIdentityService(
    paths: paths,
    engine: engine,
    crypto: crypto,
    verifier: PasswordVerifier(secure, iterations: 10),
    store: store,
  );

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ditmesh_teardown_');
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

  void unconfirmed() {
    engine.stopError = const ChatException(
      'teardown_unconfirmed',
      'fake: quarantined',
    );
    engine.teardownConfirmed = false;
  }

  void confirmed() {
    engine.stopError = null;
    engine.teardownConfirmed = true;
  }

  Future<Uint8List> backupOf(Tim2ToxIdentityService svc) =>
      svc.exportEncryptedBackup(
        const EncryptedBackupRequest(
          passphrase: 'pp',
          categories: {BackupCategory.training},
        ),
      );

  test('disconnect reports the unconfirmed teardown and leaves the profile',
      () async {
    final svc = newService();
    await svc.create(displayName: 'A', password: 'pw');
    await svc.connect();
    // The fake engine's start wrote the profile encrypted; make it plain so
    // the re-encryption at rest has something to do.
    final plain = crypto.decrypt(File(paths.profileFile).readAsBytesSync(), 'pw');
    File(paths.profileFile).writeAsBytesSync(plain);
    unconfirmed();
    await expectLater(svc.disconnect(), throwsCode('teardown_unconfirmed'));
    expect(svc.connectionStatus, ConnectionStatus.offline);
    expect(
      crypto.isEncrypted(File(paths.profileFile).readAsBytesSync()),
      isFalse,
      reason: 'no rewrite behind a possibly live native instance',
    );
    expect(svc.current?.toxId, kSelfToxId, reason: 'identity stays published');

    confirmed();
    await svc.connect();
    await svc.disconnect();
    expect(crypto.isEncrypted(File(paths.profileFile).readAsBytesSync()), isTrue);
    await svc.dispose();
  });

  test(
    'export, restore, import, delete and an offline password change all '
    'refuse while unconfirmed, and work after a confirmed stop',
    () async {
      final svc = newService();
      await svc.create(displayName: 'A');
      final good = await backupOf(svc);
      final legacy = await svc.exportBackup();
      await svc.connect();
      unconfirmed();
      await expectLater(svc.disconnect(), throwsCode('teardown_unconfirmed'));

      await expectLater(backupOf(svc), throwsCode('teardown_unconfirmed'));
      await expectLater(svc.exportBackup(), throwsCode('teardown_unconfirmed'));
      await expectLater(
        svc.restoreEncryptedBackup(good, 'pp'),
        throwsCode('teardown_unconfirmed'),
      );
      await expectLater(
        svc.importBackup(legacy),
        throwsCode('teardown_unconfirmed'),
      );
      await expectLater(
        svc.changePassword(newPassword: 'new'),
        throwsCode('teardown_unconfirmed'),
      );
      await expectLater(svc.deleteIdentity(), throwsCode('teardown_unconfirmed'));
      expect(paths.profileExists, isTrue);
      expect(svc.current?.displayName, 'A');
      expect(svc.current?.hasPassword, isFalse);
      expect(
        Directory(tempRoot.path).listSync().where(
          (e) => p.basename(e.path).startsWith(IdentityPaths.importStagePrefix),
        ),
        isEmpty,
        reason: 'a refused restore leaves no staging behind',
      );

      confirmed();
      await svc.connect();
      await svc.disconnect();
      await backupOf(svc);
      await svc.changePassword(newPassword: 'new');
      expect(svc.current?.hasPassword, isTrue);
      final report = await svc.restoreEncryptedBackup(good, 'pp');
      expect(report.restored, contains(BackupCategory.identity));
      await svc.deleteIdentity();
      expect(paths.profileExists, isFalse);
      await svc.dispose();
    },
  );

  test('a failed start does not rewrite the profile while unconfirmed',
      () async {
    final svc = newService();
    await svc.create(displayName: 'A', password: 'pw');
    // Make the next start fail: the fake refuses an encrypted profile when
    // the passphrase is missing. Drop the session password to provoke it.
    final plain = crypto.decrypt(File(paths.profileFile).readAsBytesSync(), 'pw');
    File(paths.profileFile).writeAsBytesSync(crypto.encrypt(plain, 'other'));
    engine.teardownConfirmed = false;
    engine.stopError = const ChatException('teardown_unconfirmed', 'fake');
    await expectLater(svc.connect(), throwsA(isA<ChatException>()));
    expect(svc.connectionStatus, ConnectionStatus.offline);
    // The connect failure is reported, not the stop error, and the file
    // is left exactly as it was.
    expect(
      crypto.decrypt(File(paths.profileFile).readAsBytesSync(), 'other'),
      plain,
    );
    await svc.dispose();
  });

  test(
    'a creation whose bootstrap instance did not stop keeps the new tree',
    () async {
      final svc = newService();
      engine.createProfileUnconfirmed = true;
      await expectLater(
        svc.create(displayName: 'A', password: 'pw'),
        throwsCode('teardown_unconfirmed'),
      );
      expect(
        paths.profileExists,
        isTrue,
        reason: 'the directory may still be written by native; not deleted',
      );
      expect(svc.current, isNull);
      expect(
        await PasswordVerifier(secure, iterations: 10).hasPassword(kSelfToxId),
        isFalse,
        reason: 'the verifier of the unfinished creation is still removed',
      );
      // Startup sees a profile without identity.json and recovers it.
      engine.teardownConfirmed = true;
      final again = newService();
      expect(await again.inspect(), IdentityState.locked);
      final id = await again.unlock('pw');
      // Rebuilt from the profile's public key (identity.json never landed).
      expect(id.toxId, startsWith(kSelfKey));
      await again.dispose();
      await svc.dispose();
    },
  );

  test('create refuses while a previous teardown is unconfirmed', () async {
    final svc = newService();
    engine.teardownConfirmed = false;
    await expectLater(
      svc.create(displayName: 'A'),
      throwsCode('teardown_unconfirmed'),
    );
    expect(paths.profileExists, isFalse);
    await svc.dispose();
  });
}

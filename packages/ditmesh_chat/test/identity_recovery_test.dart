import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/identity/identity_record.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;

import 'helpers/fakes.dart';

/// A restore commits with two renames (`root → <stage>/previous`, then
/// `<stage>/identity → root`). These tests reproduce a process killed
/// between them and check the previous identity comes back on its own.
void main() {
  late Directory tempRoot;
  late IdentityPaths paths;
  late MemorySecureStore secure;
  late FakeChatEngine engine;
  final crypto = FakeProfileCrypto();

  PasswordVerifier verifier() => PasswordVerifier(secure, iterations: 10);

  Tim2ToxIdentityService newService() => Tim2ToxIdentityService(
    paths: paths,
    engine: engine,
    crypto: crypto,
    verifier: verifier(),
  );

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ditmesh_recovery_');
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

  /// What the disk looks like after rename 1 of a restore of [incoming]:
  /// the live tree sits in `<stage>/previous`, the staged restore in
  /// `<stage>/identity`, and the incoming verifier is already written.
  Future<Directory> interruptAfterFirstRename(
    IdentityRecord incoming, {
    String? incomingPassword,
    String stageName = '.ditmesh-import-abc',
  }) async {
    final stage = Directory(p.join(tempRoot.path, stageName));
    await stage.create();
    await Directory(paths.root).rename(IdentityPaths.previousInStage(stage));
    final staged = IdentityPaths(p.join(stage.path, 'identity'));
    await staged.ensureDirectories();
    await File(staged.profileFile).writeAsBytes(
      FakeProfileCrypto.plainProfile(incoming.toxId.substring(0, 64), 'x'),
    );
    await incoming.write(staged.identityFile);
    if (incomingPassword != null) {
      await verifier().setPassword(incoming.toxId, incomingPassword);
    } else {
      await verifier().removePassword(incoming.toxId);
    }
    return stage;
  }

  test('the previous identity comes back on inspect and opens', () async {
    final first = newService();
    await first.create(displayName: 'Before');
    await File(
      p.join(await first.dataDirectory(), 'progress.json'),
    ).writeAsString('mine');
    await first.dispose();
    final stage = await interruptAfterFirstRename(
      const IdentityRecord(toxId: kPeerToxId, displayName: 'Incoming'),
      incomingPassword: 'their-pw',
    );
    expect(paths.profileExists, isFalse, reason: 'no root after rename 1');

    final second = newService();
    expect(await second.inspect(), IdentityState.ready);
    expect(stage.existsSync(), isFalse, reason: 'staging is consumed');
    final id = await second.open();
    expect(id.toxId, kSelfToxId);
    expect(id.displayName, 'Before');
    expect(
      File(p.join(paths.trainingDirectory, 'progress.json')).readAsStringSync(),
      'mine',
    );
    expect(
      await verifier().hasPassword(kPeerToxId),
      isFalse,
      reason: 'the orphan verifier of the never-restored identity is removed',
    );
    await second.dispose();
  });

  test('a password-protected previous identity unlocks again', () async {
    final first = newService();
    await first.create(displayName: 'Before', password: 'old');
    await first.dispose();
    await interruptAfterFirstRename(
      const IdentityRecord(toxId: kPeerToxId, displayName: 'Incoming'),
    );

    final second = newService();
    // unlock() never calls inspect(): recovery runs inside it as well.
    final id = await second.unlock('old');
    expect(id.toxId, kSelfToxId);
    expect(await second.inspect(), IdentityState.ready);
    await second.dispose();
  });

  test(
    'same Tox ID: a plaintext previous profile is not left behind a '
    'password it never had',
    () async {
      final first = newService();
      await first.create(displayName: 'Plain');
      await first.dispose();
      // The backup is the same identity, protected on the source device:
      // its verifier replaced ours before the swap.
      await interruptAfterFirstRename(
        const IdentityRecord(
          toxId: kSelfToxId,
          displayName: 'Plain',
          hasPassword: true,
        ),
        incomingPassword: 'their-pw',
      );

      final second = newService();
      expect(await second.inspect(), IdentityState.ready);
      final id = await second.open();
      expect(id.hasPassword, isFalse);
      expect(await verifier().hasPassword(kSelfToxId), isFalse);
      await second.dispose();
    },
  );

  test(
    'same Tox ID: an encrypted previous profile keeps proving its own '
    'password',
    () async {
      final first = newService();
      await first.create(displayName: 'Locked', password: 'old');
      await first.dispose();
      await interruptAfterFirstRename(
        const IdentityRecord(
          toxId: kSelfToxId,
          displayName: 'Locked',
          hasPassword: true,
        ),
        incomingPassword: 'their-pw',
      );

      final second = newService();
      expect(await second.inspect(), IdentityState.locked);
      expect(() => second.unlock('their-pw'), throwsCode('wrong_password'));
      final id = await second.unlock('old');
      expect(id.toxId, kSelfToxId);
      expect(
        await verifier().verify(kSelfToxId, 'old'),
        isTrue,
        reason: 'unlock repaired the verifier from the ciphertext',
      );
      await second.dispose();
    },
  );

  test(
    'a secure-store failure during reconciliation keeps the stage for a '
    'retry on the next start',
    () async {
      final first = newService();
      await first.create(displayName: 'Plain');
      await first.dispose();
      final stage = await interruptAfterFirstRename(
        const IdentityRecord(
          toxId: kSelfToxId,
          displayName: 'Plain',
          hasPassword: true,
        ),
        incomingPassword: 'their-pw',
      );
      final flaky = _FlakySecureStore()..values.addAll(secure.values);
      Tim2ToxIdentityService withStore() => Tim2ToxIdentityService(
        paths: paths,
        engine: engine,
        crypto: crypto,
        verifier: PasswordVerifier(flaky, iterations: 10),
      );

      flaky.failDelete = true;
      final second = withStore();
      expect(await second.inspect(), IdentityState.none);
      expect(stage.existsSync(), isTrue, reason: 'nothing moved');
      expect(paths.profileExists, isFalse);
      // Onboarding is shown, but a new identity must not bury the waiting
      // one: recovery only runs while there is no root.
      await expectLater(
        second.create(displayName: 'New'),
        throwsCode('identity_recovery_pending'),
      );
      expect(paths.profileExists, isFalse);
      expect(stage.existsSync(), isTrue);
      await second.dispose();

      // Next start: the store works again and recovery completes.
      flaky.failDelete = false;
      final third = withStore();
      expect(await third.inspect(), IdentityState.ready);
      expect(stage.existsSync(), isFalse);
      final id = await third.open();
      expect(id.hasPassword, isFalse);
      expect(
        await PasswordVerifier(flaky, iterations: 10).hasPassword(kSelfToxId),
        isFalse,
      );
      await third.dispose();
    },
  );

  test('two candidates are ambiguous: nothing moves, nothing is deleted',
      () async {
    final first = newService();
    await first.create(displayName: 'Before');
    await first.dispose();
    final a = await interruptAfterFirstRename(
      const IdentityRecord(toxId: kPeerToxId, displayName: 'A'),
      stageName: '.ditmesh-import-a',
    );
    // A second stray copy of a previous identity.
    final b = Directory(p.join(tempRoot.path, '.ditmesh-import-b'));
    final bPrev = IdentityPaths(IdentityPaths.previousInStage(b));
    await bPrev.ensureDirectories();
    await File(bPrev.profileFile).writeAsBytes(
      FakeProfileCrypto.plainProfile(kPeerKey, 'B'),
    );

    final second = newService();
    expect(await second.inspect(), IdentityState.none);
    expect(a.existsSync(), isTrue);
    expect(b.existsSync(), isTrue);
    expect(() => second.open(), throwsCode('no_identity'));
    // Neither candidate may be buried under a fresh identity.
    await expectLater(
      second.create(displayName: 'New'),
      throwsCode('identity_recovery_pending'),
    );
    expect(paths.profileExists, isFalse);
    expect(a.existsSync(), isTrue);
    expect(b.existsSync(), isTrue);
    // Discarding them is an explicit act.
    await second.deleteIdentity();
    expect(a.existsSync(), isFalse);
    expect(b.existsSync(), isFalse);
    final id = await second.create(displayName: 'New');
    expect(id.displayName, 'New');
    await second.dispose();
  });

  test('a failed create removes only the tree it built', () async {
    // A stray stage that holds no previous identity (nothing to recover),
    // next to a create() that fails natively.
    final stray = IdentityPaths(
      p.join(tempRoot.path, '.ditmesh-import-stray', 'identity'),
    );
    await stray.ensureDirectories();
    await File(stray.profileFile).writeAsBytes(
      FakeProfileCrypto.plainProfile(kPeerKey, 'Staged'),
    );
    engine.createProfileError = StateError('native refused');
    final svc = newService();
    await expectLater(svc.create(displayName: 'New'), throwsStateError);
    expect(paths.profileExists, isFalse);
    expect(Directory(paths.root).existsSync(), isFalse);
    expect(
      Directory(p.join(tempRoot.path, '.ditmesh-import-stray')).existsSync(),
      isTrue,
    );
    await svc.dispose();
  });

  test('a stage without a previous profile is not a recovery candidate',
      () async {
    // Death before rename 1 on a device that had no identity: only the
    // staged restore exists; there is nothing to roll back to.
    final stage = Directory(p.join(tempRoot.path, '.ditmesh-import-fresh'));
    final staged = IdentityPaths(p.join(stage.path, 'identity'));
    await staged.ensureDirectories();
    await File(staged.profileFile).writeAsBytes(
      FakeProfileCrypto.plainProfile(kPeerKey, 'Incoming'),
    );
    expect(await paths.interruptedImports(), isEmpty);
    final svc = newService();
    expect(await svc.inspect(), IdentityState.none);
    expect(stage.existsSync(), isTrue);
    await svc.dispose();
  });
}

/// A secure store whose deletes can be made to fail (a transient keychain
/// error), to interrupt recovery between its steps.
class _FlakySecureStore extends MemorySecureStore {
  bool failDelete = false;

  @override
  Future<void> delete(String key) async {
    if (failDelete) throw StateError('keychain unavailable');
    await super.delete(key);
  }
}

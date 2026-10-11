import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;

import 'helpers/fakes.dart';

/// identity.json + verifier of one identity paired with another identity's
/// `tox_profile.tox` (a crash window, a hand-copied file): nothing may
/// rewrite the other identity's savedata — not the native session (which
/// re-encrypts on init and saves on teardown), not the encrypt-at-rest
/// safety net, not an offline password change.
void main() {
  late Directory tempRoot;
  late IdentityPaths paths;
  late MemorySecureStore secure;
  late FakeChatEngine engine;
  final crypto = FakeProfileCrypto();
  final otherKey = 'B' * 64;

  Tim2ToxIdentityService newService() => Tim2ToxIdentityService(
    paths: paths,
    engine: engine,
    crypto: crypto,
    verifier: PasswordVerifier(secure, iterations: 10),
  );

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('ditmesh_ownership_');
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

  /// Creates identity A, then puts [foreign] where its profile was.
  Future<File> pairWithForeign(Uint8List foreign, {String? password}) async {
    final svc = newService();
    await svc.create(displayName: 'A', password: password);
    await svc.dispose();
    final file = File(paths.profileFile);
    await file.writeAsBytes(foreign, flush: true);
    return file;
  }

  /// Expects opening passwordless A to refuse with [code]; nothing is
  /// published, started or written.
  Future<void> expectOpenRefused(
    File file,
    Uint8List foreign, {
    String code = 'identity_mismatch',
  }) async {
    final svc = newService();
    expect(await svc.inspect(), IdentityState.ready);
    await expectLater(svc.open(), throwsCode(code));
    expect(svc.current, isNull);
    await svc.disconnect();
    await svc.dispose();
    expect(engine.startCalls, isEmpty);
    expect(await file.readAsBytes(), foreign);
  }

  /// Opens passwordless A on its own profile, then swaps [foreign] in.
  Future<(Tim2ToxIdentityService, File)> openThenSwap(Uint8List foreign) async {
    final svc = newService();
    await svc.create(displayName: 'A');
    final file = File(paths.profileFile);
    await file.writeAsBytes(foreign, flush: true);
    return (svc, file);
  }

  /// Expects unlocking A to refuse with [code] before any repair: profile,
  /// identity.json and A's verifier are exactly as they were.
  Future<void> expectUnlockRefused(
    File file,
    Uint8List foreign, {
    String code = 'identity_mismatch',
  }) async {
    final record = File(paths.identityFile).readAsBytesSync();
    final svc = newService();
    expect(await svc.inspect(), IdentityState.locked);
    await expectLater(svc.unlock('pw-a'), throwsCode(code));
    expect(svc.current, isNull);
    expect(() => svc.connect(), throwsCode('no_identity'));
    await svc.disconnect();
    await svc.dispose();
    expect(engine.startCalls, isEmpty);
    expect(await file.readAsBytes(), foreign);
    expect(File(paths.identityFile).readAsBytesSync(), record);
    expect(
      await PasswordVerifier(secure, iterations: 10).verify(kSelfToxId, 'pw-a'),
      isTrue,
    );
  }

  Uint8List foreignPlain() => FakeProfileCrypto.plainProfile(otherKey, 'B');

  test('plaintext savedata of another identity under a protected one: '
      'unlock refuses before repairing anything', () async {
    final foreign = foreignPlain();
    final file = await pairWithForeign(foreign, password: 'pw-a');
    await expectUnlockRefused(file, foreign);
  });

  test(
    'another identity encrypted under the same password: unlock refuses',
    () async {
      final foreign = crypto.encrypt(foreignPlain(), 'pw-a');
      final file = await pairWithForeign(foreign, password: 'pw-a');
      await expectUnlockRefused(file, foreign);
    },
  );

  test('another identity encrypted under another password: wrong_password, '
      'nothing touched', () async {
    final foreign = crypto.encrypt(foreignPlain(), 'pw-b');
    final file = await pairWithForeign(foreign, password: 'pw-a');
    await expectUnlockRefused(file, foreign, code: 'wrong_password');
  });

  test('plaintext savedata of another identity under a passwordless one: '
      'open refuses', () async {
    final foreign = foreignPlain();
    final file = await pairWithForeign(foreign);
    await expectOpenRefused(file, foreign);
  });

  test('an unreadable profile: open refuses', () async {
    final foreign = Uint8List.fromList('not a tox save'.codeUnits);
    final file = await pairWithForeign(foreign);
    await expectOpenRefused(file, foreign, code: 'invalid_profile');
  });

  for (final unreadable in [false, true]) {
    test('connect re-proves the profile: a '
        '${unreadable ? 'unreadable' : 'foreign'} file is never started, '
        'so native can neither re-encrypt nor replace it', () async {
      final foreign = unreadable
          ? Uint8List.fromList('not a tox save'.codeUnits)
          : foreignPlain();
      final (svc, file) = await openThenSwap(foreign);
      await expectLater(
        svc.connect(),
        throwsCode(unreadable ? 'invalid_profile' : 'identity_mismatch'),
      );
      expect(engine.startCalls, isEmpty);
      expect(svc.connectionStatus, ConnectionStatus.offline);
      await svc.disconnect();
      await svc.dispose();
      expect(await file.readAsBytes(), foreign);
    });
  }

  test('exports refuse to package another identity\'s savedata', () async {
    final (svc, file) = await openThenSwap(foreignPlain());
    await expectLater(svc.exportBackup(), throwsCode('identity_mismatch'));
    await expectLater(
      svc.exportEncryptedBackup(
        const EncryptedBackupRequest(passphrase: 'backup', categories: {}),
      ),
      throwsCode('identity_mismatch'),
    );
    expect(await file.readAsBytes(), foreignPlain());
    await svc.dispose();
  });

  test('a missing profile is refused before native could mint one', () async {
    final svc = newService();
    await svc.create(displayName: 'A');
    await File(paths.profileFile).delete();
    await expectLater(svc.connect(), throwsCode('no_identity'));
    expect(engine.startCalls, isEmpty);
    expect(File(paths.profileFile).existsSync(), isFalse);
    await svc.dispose();
  });

  test('the owned profile still connects and is encrypted at rest', () async {
    final svc = newService();
    await svc.create(displayName: 'A', password: 'pw');
    await svc.connect();
    expect(engine.startCalls, hasLength(1));
    await svc.disconnect();
    expect(
      crypto.isEncrypted(File(paths.profileFile).readAsBytesSync()),
      isTrue,
    );
    await svc.dispose();
  });

  for (final unreadable in [false, true]) {
    test(
      'encrypt-at-rest leaves a replaced '
      '${unreadable ? 'unreadable' : 'foreign'} plaintext file alone',
      () async {
        final svc = newService();
        await svc.create(displayName: 'A', password: 'pw-a');
        final foreign = unreadable
            ? Uint8List.fromList('not a tox save'.codeUnits)
            : foreignPlain();
        final file = File(paths.profileFile);
        await file.writeAsBytes(foreign, flush: true);
        await svc.disconnect(); // the safety net runs even when not started
        expect(await file.readAsBytes(), foreign);
        await svc.dispose();
      },
    );
  }

  for (final protected in [true, false]) {
    test('an offline password change refuses another identity\'s savedata '
        '(${protected ? 'protected' : 'passwordless'})', () async {
      final svc = newService();
      await svc.create(displayName: 'A', password: protected ? 'pw-a' : null);
      final foreign = foreignPlain();
      final file = File(paths.profileFile);
      await file.writeAsBytes(foreign, flush: true);
      final record = File(paths.identityFile).readAsBytesSync();
      await expectLater(
        svc.changePassword(
          oldPassword: protected ? 'pw-a' : null,
          newPassword: 'pw-new',
        ),
        throwsCode('identity_mismatch'),
      );
      if (protected) {
        await expectLater(
          svc.changePassword(oldPassword: 'pw-a'),
          throwsCode('identity_mismatch'),
        );
      }
      expect(await file.readAsBytes(), foreign);
      expect(File(paths.identityFile).readAsBytesSync(), record);
      final verifier = PasswordVerifier(secure, iterations: 10);
      expect(await verifier.hasPassword(kSelfToxId), protected);
      if (protected) expect(await verifier.verify(kSelfToxId, 'pw-a'), isTrue);
      await svc.dispose();
    });
  }
}

@Tags(['needs-native'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

/// identity.json, the password verifier and `tox_profile.tox` are written
/// separately, so a crash window or a hand-copied file can pair one
/// identity's metadata with another identity's savedata. Tim2Tox reports
/// the self address only after login, but its init already rewrites a
/// plaintext profile under the staged passphrase and its teardown saves
/// unconditionally: proving ownership after login was too late to keep the
/// other identity's file intact. These run the real library end to end.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final library = Platform.environment['TIM2TOX_FFI_LIB'];
  final available = library != null && File(library).existsSync();
  final skip = available
      ? null
      : 'Set TIM2TOX_FFI_LIB to a built native library';

  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('native_identity_mismatch_');
  });
  tearDown(() => root.delete(recursive: true));

  Future<DitmeshChatBackend> open(
    String name,
    SecureStore secure, {
    ChatEngine? engine,
    KeyValueStore? store,
  }) => DitmeshChatBackend.create(
    paths: IdentityPaths('${root.path}/$name'),
    store: store ?? MemoryKeyValueStore(),
    secureStore: secure,
    logger: MemoryChatLogger(),
    engine: engine,
    nativeLibraryPathOverride: library,
    pollInterval: const Duration(milliseconds: 50),
  );

  /// Creates an identity under [name] and returns its savedata bytes.
  Future<Uint8List> mint(String name, SecureStore secure, {String? pw}) async {
    final backend = await open(name, secure);
    try {
      await backend.identity.create(displayName: name, password: pw);
      return File(backend.paths.profileFile).readAsBytes();
    } finally {
      await backend.dispose();
    }
  }

  Matcher throwsCode(String code) =>
      throwsA(isA<ChatException>().having((e) => e.code, 'code', code));

  for (final protected in [true, false]) {
    final label = protected ? 'a protected' : 'a passwordless';
    test(
      "another identity's plaintext savedata under $label identity is "
      'refused before native touches it',
      () async {
        final secure = MemorySecureStore();
        await mint('a', secure, pw: protected ? 'pw-a' : null);
        final foreign = await mint('b', MemorySecureStore());
        expect(Tim2ToxProfileCrypto().isEncrypted(foreign), isFalse);
        final profile = File(IdentityPaths('${root.path}/a').profileFile);
        await profile.writeAsBytes(foreign, flush: true);

        final backend = await open('a', secure);
        try {
          if (protected) {
            // Refused before unlock repairs A's verifier or identity.json.
            expect(await backend.identity.inspect(), IdentityState.locked);
            await expectLater(
              backend.identity.unlock('pw-a'),
              throwsCode('identity_mismatch'),
            );
          } else {
            await expectLater(
              backend.identity.open(),
              throwsCode('identity_mismatch'),
            );
          }
          expect(backend.identity.connectionStatus, ConnectionStatus.offline);
          expect(await profile.readAsBytes(), foreign);
          await backend.identity.disconnect();
          expect(await profile.readAsBytes(), foreign);
        } finally {
          await backend.dispose();
        }
        expect(await profile.readAsBytes(), foreign);
        expect(profile.parent.listSync(), hasLength(1)); // no `.corrupted`
      },
      skip: skip,
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }

  test(
    'unreadable savedata under an identity is refused, not replaced by a '
    'new identity',
    () async {
      final secure = MemorySecureStore();
      await mint('a', secure);
      final garbage = Uint8List.fromList(List.filled(256, 7));
      final profile = File(IdentityPaths('${root.path}/a').profileFile);
      await profile.writeAsBytes(garbage, flush: true);
      final backend = await open('a', secure);
      try {
        await expectLater(
          backend.identity.open(),
          throwsCode('invalid_profile'),
        );
      } finally {
        await backend.dispose();
      }
      expect(await profile.readAsBytes(), garbage);
      expect(profile.parent.listSync(), hasLength(1)); // no `.corrupted`
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'a foreign plaintext file swapped in while unlocked is not encrypted '
    'under this identity\'s password on disconnect',
    () async {
      final secure = MemorySecureStore();
      await mint('a', secure, pw: 'pw-a');
      final foreign = await mint('b', MemorySecureStore());
      final backend = await open('a', secure);
      try {
        await backend.identity.unlock('pw-a');
        final profile = File(backend.paths.profileFile);
        await profile.writeAsBytes(foreign, flush: true);
        await backend.identity.disconnect();
        expect(await profile.readAsBytes(), foreign);
      } finally {
        await backend.dispose();
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'a foreign file swapped in after open is refused at connect, before '
    'native init could rewrite it',
    () async {
      final secure = MemorySecureStore();
      await mint('a', secure);
      final foreign = await mint('b', MemorySecureStore());
      final backend = await open('a', secure);
      try {
        await backend.identity.open();
        final profile = File(backend.paths.profileFile);
        await profile.writeAsBytes(foreign, flush: true);
        await expectLater(
          backend.identity.connect(),
          throwsCode('identity_mismatch'),
        );
        await backend.identity.disconnect();
        expect(await profile.readAsBytes(), foreign);
      } finally {
        await backend.dispose();
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

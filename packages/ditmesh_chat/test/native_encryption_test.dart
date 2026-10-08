@Tags(['needs-native'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

/// With a password, `tox_profile.tox` must never be plaintext on disk: not
/// right after creation, not while the session runs (Tim2Tox saves as it
/// goes), not after a forced persist, not after a live password change, and
/// not when the process dies without disconnecting.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final library = Platform.environment['TIM2TOX_FFI_LIB'];
  final available = library != null && File(library).existsSync();

  test(
    'the profile stays encrypted through create, run, persist, re-key, crash',
    () async {
      final root = await Directory.systemTemp.createTemp('native_encryption_');
      final paths = IdentityPaths('${root.path}/identity');
      final store = MemoryKeyValueStore();
      final secure = MemorySecureStore();
      final crypto = Tim2ToxProfileCrypto();
      Future<bool> encryptedOnDisk() async =>
          crypto.isEncrypted(await File(paths.profileFile).readAsBytes());
      Future<DitmeshChatBackend> createBackend() => DitmeshChatBackend.create(
        paths: paths,
        store: store,
        secureStore: secure,
        logger: MemoryChatLogger(),
        nativeLibraryPathOverride: library,
        pollInterval: const Duration(milliseconds: 50),
      );
      const unicode = 'pä55wörd-日本';
      DitmeshChatBackend? active;
      try {
        final first = active = await createBackend();
        await first.identity.create(displayName: 'Enc', password: 'pw');
        expect(await encryptedOnDisk(), isTrue, reason: 'after creation');

        await first.identity.connect();
        await pumpEventQueue();
        expect(await encryptedOnDisk(), isTrue, reason: 'while connected');

        await (first.identity as PersistentIdentityService).persist();
        expect(await encryptedOnDisk(), isTrue, reason: 'after persist');

        await first.identity.changePassword(
          oldPassword: 'pw',
          newPassword: unicode,
        );
        await (first.identity as PersistentIdentityService).persist();
        expect(await encryptedOnDisk(), isTrue, reason: 'after live re-key');
        expect(
          crypto.decrypt(await File(paths.profileFile).readAsBytes(), unicode),
          isNotEmpty,
        );
        // No disconnect: what a killed app leaves behind.
        expect(await encryptedOnDisk(), isTrue);
        await first.dispose();
        active = null;

        final second = active = await createBackend();
        expect(await second.identity.inspect(), IdentityState.locked);
        expect(
          () => second.identity.unlock('pw'),
          throwsA(isA<ChatException>()),
        );
        await second.identity.unlock(unicode);
        await second.identity.connect();
        await pumpEventQueue();
        expect(await encryptedOnDisk(), isTrue);
        await second.identity.disconnect();
      } finally {
        await active?.dispose();
        await root.delete(recursive: true);
      }
    },
    skip: available ? null : 'Set TIM2TOX_FFI_LIB to a built native library',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

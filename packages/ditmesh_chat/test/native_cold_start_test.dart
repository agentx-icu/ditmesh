@Tags(['needs-native'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'helpers/real_peer_store.dart';

/// Set by the parent test: reopen the identity under this root in THIS
/// (fresh) process instead of creating one.
const String _childRootVar = 'DITMESH_COLD_START_ROOT';

/// Every cold start of an existing identity failed with `identity_mismatch`
/// on the Android emulator and the iOS Simulator (simulator/emulator
/// evidence, 2026-10-10): the engine compared the Tox address before logging
/// in, and Tim2Tox reports the self address only once logged in. A restart
/// inside one process hides it, because the native instance keeps the
/// address of the previous login, so the reopen runs in a child process.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final library = Platform.environment['TIM2TOX_FFI_LIB'];
  final available = library != null && File(library).existsSync();
  final childRoot = Platform.environment[_childRootVar];

  Future<DitmeshChatBackend> open(String root) => DitmeshChatBackend.create(
    paths: IdentityPaths('$root/identity'),
    store: RealPeerStore(File('$root/prefs.json')),
    secureStore: MemorySecureStore(),
    logger: MemoryChatLogger(),
    nativeLibraryPathOverride: library,
    pollInterval: const Duration(milliseconds: 50),
  );

  if (childRoot != null) {
    test(
      'child: the identity reopens and its session starts',
      () async {
        final backend = await open(childRoot);
        try {
          expect(await backend.identity.inspect(), IdentityState.ready);
          final reopened = await backend.identity.open();
          expect(
            reopened.toxId,
            File('$childRoot/expected_tox_id').readAsStringSync(),
          );
          await backend.identity.connect();
          await pumpEventQueue(); // Chat binds through the session stream.
          expect(backend.chat.hasSession, isTrue);
          await backend.identity.disconnect();
        } finally {
          await backend.dispose();
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
    return;
  }

  test(
    'a passwordless identity reopens in a new process',
    () async {
      final root = await Directory.systemTemp.createTemp('native_cold_start_');
      try {
        final first = await open(root.path);
        try {
          final identity = await first.identity.create(displayName: 'Cold');
          await first.identity.connect();
          await (first.identity as PersistentIdentityService).persist();
          await first.identity.disconnect();
          File(
            '${root.path}/expected_tox_id',
          ).writeAsStringSync(identity.toxId);
        } finally {
          await first.dispose();
        }
        final child = await Process.run(
          'flutter',
          [
            'test',
            '--no-pub',
            '--tags=needs-native',
            'test/native_cold_start_test.dart',
          ],
          environment: {_childRootVar: root.path},
          runInShell: Platform.isWindows,
        );
        expect(
          child.exitCode,
          0,
          reason:
              'fresh-process reopen failed:\n${child.stdout}${child.stderr}',
        );
      } finally {
        await root.delete(recursive: true);
      }
    },
    skip: available ? null : 'Set TIM2TOX_FFI_LIB to a built native library',
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

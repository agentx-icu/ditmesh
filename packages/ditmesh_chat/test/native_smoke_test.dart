@Tags(['needs-native'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;
import 'package:tim2tox_dart/ffi/tim2tox_ffi.dart';

import 'helpers/fakes.dart';

/// Headless single-process smoke against the REAL `libtim2tox_ffi`.
///
/// Tim2Tox's default (singleton) instance model means one `FfiChatService`
/// session per process, so a two-peer exchange needs two processes; the
/// README's "Native smoke test" section describes that run. This test proves
/// the headless path itself: no `Tim2ToxSdkPlatform`, no UIKit, no
/// `TIMManager.initSDK` — just `setNativeLibraryName` + init/login/poll —
/// creates an identity, reaches the DHT, and cleanly tears down.
///
/// Skipped when the library is not loadable (this container, CI without the
/// native build). Build it first:
///   TIM2TOX_FFI_LIB=/abs/path/libtim2tox_ffi.{so,dylib} flutter test \
///       packages/ditmesh_chat/test/native_smoke_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final override = Platform.environment['TIM2TOX_FFI_LIB'];
  if (override != null && override.isNotEmpty) {
    Tim2ToxFfi.setLibraryPathOverride(override);
  }
  final loadable = NativeLibrarySetup.isNativeLibraryLoadable;

  test(
    'create identity, connect, reach the Tox DHT, send to an offline peer, stop',
    () async {
      final tempRoot = await Directory.systemTemp.createTemp('ditmesh_native_');
      final logger = MemoryChatLogger();
      final backend = await DitmeshChatBackend.create(
        logger: logger,
        paths: IdentityPaths(p.join(tempRoot.path, 'identity')),
        store: MemoryKeyValueStore(),
        secureStore: MemorySecureStore(),
        nativeLibraryPathOverride: override,
        pollInterval: const Duration(milliseconds: 500),
      );
      try {
        expect(await backend.identity.inspect(), IdentityState.none);
        final id = await backend.identity.create(displayName: 'smoke', password: 'pw');
        expect(id.toxId, matches(RegExp(r'^[0-9A-F]{76}$')));

        await backend.identity.connect();
        final online = await backend.identity.connectionChanges
            .firstWhere((s) => s == ConnectionStatus.online)
            .timeout(const Duration(seconds: 90));
        expect(online, ConnectionStatus.online);

        // A friend that will never answer: the send must queue, not fail.
        await backend.chat.addFriend(kPeerToxId);
        await Future<void>.delayed(const Duration(seconds: 2));
        final row = await backend.chat.sendText(
          'c2c_$kPeerKey',
          'CQ CQ DE SMOKE',
        );
        expect(row.status, MessageStatus.pending);
        expect(backend.chat.conversations.map((c) => c.id), contains('c2c_$kPeerKey'));

        final group = await backend.chat.createGroup('Net 40m');
        expect(group.kind, GroupKind.group);
        expect(backend.chat.groups.map((g) => g.id), contains(group.id));
        final members = await backend.chat.groupMembers(group.id);
        expect(members.where((m) => m.isSelf), hasLength(1));
        await backend.chat.leaveGroup(group.id); // DartQuitGroup path
        expect(backend.chat.groups, isEmpty);

        await backend.identity.disconnect();
        expect(backend.identity.connectionStatus, ConnectionStatus.offline);
        expect(await backend.identity.inspect(), IdentityState.ready);
      } finally {
        await backend.dispose();
        await tempRoot.delete(recursive: true);
      }
    },
    skip: loadable ? null : 'libtim2tox_ffi is not loadable here (see README)',
    timeout: const Timeout(Duration(minutes: 4)),
  );
}

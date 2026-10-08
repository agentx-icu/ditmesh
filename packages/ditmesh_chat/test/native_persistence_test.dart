@Tags(['needs-native'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final library = Platform.environment['TIM2TOX_FFI_LIB'];
  final available = library != null && File(library).existsSync();

  test(
    'native savedata, friend, group, queue, history and metadata survive restart',
    () async {
      final root = await Directory.systemTemp.createTemp('native_persistence_');
      final paths = IdentityPaths('${root.path}/identity');
      final store = MemoryKeyValueStore();
      final secure = MemorySecureStore();
      final logger = MemoryChatLogger();
      Future<DitmeshChatBackend> createBackend() => DitmeshChatBackend.create(
        paths: paths,
        store: store,
        secureStore: secure,
        logger: logger,
        nativeLibraryPathOverride: library,
        pollInterval: const Duration(milliseconds: 50),
      );
      DitmeshChatBackend? active;
      try {
        final first = active = await createBackend();
        final identity = await first.identity.create(
          displayName: 'Before',
          password: 'pw',
        );
        await first.identity.updateProfile(
          displayName: 'Persisted',
          statusMessage: '73',
        );
        await first.identity.connect();
        await pumpEventQueue(); // Chat binds through the engine's session stream.
        await first.chat.addFriend(kPeerToxId);
        final group = await first.chat.createGroup('Durable net');
        final conversation = 'c2c_$kPeerKey';
        final row = await first.chat.sendText(
          conversation,
          'CQ queued across restart',
        );
        expect(row.status, MessageStatus.pending);
        await first.chat.setDraft(conversation, 'unfinished draft');
        await first.chat.setPinned(conversation, true);
        await (first.identity as PersistentIdentityService).persist();
        await first.identity.disconnect();
        await first.dispose();
        active = null;
        expect(
          Tim2ToxProfileCrypto().isEncrypted(
            await File(paths.profileFile).readAsBytes(),
          ),
          isTrue,
        );

        final second = active = await createBackend();
        expect(await second.identity.inspect(), IdentityState.locked);
        final restored = await second.identity.unlock('pw');
        expect(restored.toxId, identity.toxId);
        expect(restored.displayName, 'Persisted');
        expect(restored.statusMessage, '73');
        await second.identity.connect();
        await second.chat.friendChanges
            .firstWhere(
              (friends) =>
                  friends.any((friend) => friend.publicKey == kPeerKey),
            )
            .timeout(const Duration(seconds: 10));
        await second.chat.groupChanges
            .firstWhere((groups) => groups.any((value) => value.id == group.id))
            .timeout(const Duration(seconds: 10));
        expect(
          second.chat.groups.firstWhere((value) => value.id == group.id).name,
          'Durable net',
        );
        final history = await second.chat.loadHistory(conversation);
        final message = history.singleWhere((message) => message.id == row.id);
        expect(message.text, 'CQ queued across restart');
        expect(message.status, MessageStatus.pending);
        final saved = second.chat.conversations.firstWhere(
          (value) => value.id == conversation,
        );
        expect(saved.draft, 'unfinished draft');
        expect(saved.pinned, isTrue);
        expect(
          await File(paths.offlineQueueFile).readAsString(),
          contains('CQ queued across restart'),
        );
        await second.identity.disconnect();
        expect(
          Tim2ToxProfileCrypto().isEncrypted(
            await File(paths.profileFile).readAsBytes(),
          ),
          isTrue,
        );
      } finally {
        await active?.dispose();
        await root.delete(recursive: true);
      }
    },
    skip: available ? null : 'Set TIM2TOX_FFI_LIB to a built native library',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

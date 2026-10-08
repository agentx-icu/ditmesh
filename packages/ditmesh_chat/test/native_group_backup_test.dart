@Tags(['needs-native'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;

/// A complete backup restored onto a fresh store (new device) brings the
/// NGC group back with its id, name and history once the identity connects.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final library = Platform.environment['TIM2TOX_FFI_LIB'];
  final available = library != null && File(library).existsSync();

  test(
    'NGC group membership and history survive backup → fresh-store restore',
    () async {
      final root = await Directory.systemTemp.createTemp('native_group_bk_');
      Future<DitmeshChatBackend> createBackend(String dir) =>
          DitmeshChatBackend.create(
            paths: IdentityPaths(p.join(root.path, dir, 'identity')),
            store: MemoryKeyValueStore(),
            secureStore: MemorySecureStore(),
            logger: MemoryChatLogger(),
            nativeLibraryPathOverride: library,
            pollInterval: const Duration(milliseconds: 50),
          );
      DitmeshChatBackend? active;
      try {
        final source = active = await createBackend('source');
        await source.identity.create(displayName: 'Source');
        await source.identity.connect();
        await pumpEventQueue();
        final group = await source.chat.createGroup('Durable net');
        final conversation = 'group_${group.id}';
        await (source.identity as PersistentIdentityService).persist();
        // A text sent now would sit in the outbox (no peer is online) and
        // be withheld from the backup as unsent, so the history row is laid
        // down the way Tim2Tox stores a delivered one, with the node stopped.
        await source.identity.disconnect();
        final historyFile = File(
          p.join(
            (source.identity as Tim2ToxIdentityService).paths.historyDirectory,
            '${group.id}.json',
          ),
        );
        await historyFile.parent.create(recursive: true);
        const rowId = 'restored-row-1';
        await historyFile.writeAsString(
          jsonEncode({
            'conversationId': group.id,
            'version': 2,
            'messages': [
              {
                'text': 'CQ net CQ net',
                'fromUserId': 'self',
                'isSelf': true,
                'timestamp': DateTime.utc(2026, 10, 8).toIso8601String(),
                'isPending': false,
                'msgID': rowId,
                'version': 1,
              },
            ],
          }),
        );
        final bytes =
            await (source.identity as EncryptedBackupService)
                .exportEncryptedBackup(
                  const EncryptedBackupRequest(
                    passphrase: 'backup pass',
                    categories: {BackupCategory.chatHistory},
                  ),
                );
        await source.identity.disconnect();
        await source.dispose();
        active = null;

        final target = active = await createBackend('target');
        expect(await target.identity.inspect(), IdentityState.none);
        final report = await (target.identity as EncryptedBackupService)
            .restoreEncryptedBackup(bytes, 'backup pass');
        expect(report.restored, contains(BackupCategory.chatHistory));
        await target.identity.connect();
        await target.chat.groupChanges
            .firstWhere((groups) => groups.any((g) => g.id == group.id))
            .timeout(const Duration(seconds: 10));
        final restored = target.chat.groups.firstWhere((g) => g.id == group.id);
        expect(restored.name, 'Durable net');
        expect(restored.kind, group.kind);
        final history = await target.chat.loadHistory(conversation);
        expect(
          history.map((m) => m.id),
          contains(rowId),
          reason: 'the restored group history opens under the same id',
        );
        await target.identity.disconnect();
      } finally {
        await active?.dispose();
        await root.delete(recursive: true);
      }
    },
    skip: available ? null : 'Set TIM2TOX_FFI_LIB to a built native library',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

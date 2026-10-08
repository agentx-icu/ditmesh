@Tags(['needs-native'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;

/// F10 with the real cipher: a complete backup hides the identity name,
/// chat text and training text from anyone reading the file, and any change
/// to the sealed bytes is refused before anything is restored.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final library = Platform.environment['TIM2TOX_FFI_LIB'];
  final available = library != null && File(library).existsSync();

  bool hasBytes(Uint8List hay, String needle) {
    final n = needle.codeUnits;
    outer:
    for (var i = 0; i + n.length <= hay.length; i++) {
      for (var j = 0; j < n.length; j++) {
        if (hay[i + j] != n[j]) continue outer;
      }
      return true;
    }
    return false;
  }

  test(
    'sealed archive conceals content and rejects tampering',
    () async {
      final root = await Directory.systemTemp.createTemp('native_f10_');
      DitmeshChatBackend? backend;
      try {
        backend = await DitmeshChatBackend.create(
          paths: IdentityPaths(p.join(root.path, 'identity')),
          store: MemoryKeyValueStore(),
          secureStore: MemorySecureStore(),
          logger: MemoryChatLogger(),
          nativeLibraryPathOverride: library,
        );
        final identity = backend.identity as Tim2ToxIdentityService;
        await identity.create(displayName: 'SECRETNAME');
        final training = await identity.dataDirectory();
        File(p.join(training, 'notes.txt')).writeAsStringSync('TRAININGMARK');
        final history = identity.paths.historyDirectory;
        Directory(history).createSync(recursive: true);
        File(p.join(history, 'peer.json')).writeAsStringSync(
          '{"conversationId":"peer","messages":[{"text":"CHATMARK"}]}',
        );

        final bytes = await identity.exportEncryptedBackup(
          const EncryptedBackupRequest(
            passphrase: 'backup pass',
            categories: {
              BackupCategory.training,
              BackupCategory.chatHistory,
            },
          ),
        );
        for (final marker in ['SECRETNAME', 'TRAININGMARK', 'CHATMARK',
            'identity.json', 'manifest']) {
          expect(hasBytes(bytes, marker), isFalse, reason: marker);
        }
        final preview = await identity.previewEncryptedBackup(
          bytes,
          'backup pass',
        );
        expect(preview.displayName, 'SECRETNAME');

        final Matcher refused = throwsA(
          isA<ChatException>().having(
            (e) => e.code,
            'code',
            anyOf('wrong_passphrase', 'invalid_backup'),
          ),
        );
        for (final at in [9, bytes.length ~/ 2, bytes.length - 1]) {
          final altered = Uint8List.fromList(bytes)..[at] ^= 0x01;
          await expectLater(
            identity.restoreEncryptedBackup(altered, 'backup pass'),
            refused,
            reason: 'byte $at',
          );
        }
        await expectLater(
          identity.restoreEncryptedBackup(
            Uint8List.sublistView(bytes, 0, bytes.length - 16),
            'backup pass',
          ),
          refused,
        );
        await expectLater(
          identity.restoreEncryptedBackup(bytes, 'other pass'),
          refused,
        );
        expect(identity.current!.displayName, 'SECRETNAME');
        expect(
          File(p.join(training, 'notes.txt')).readAsStringSync(),
          'TRAININGMARK',
        );
        final report = await identity.restoreEncryptedBackup(
          bytes,
          'backup pass',
        );
        expect(report.restored, contains(BackupCategory.chatHistory));
      } finally {
        await backend?.dispose();
        await root.delete(recursive: true);
      }
    },
    skip: available ? false : 'set TIM2TOX_FFI_LIB to the native library',
  );
}

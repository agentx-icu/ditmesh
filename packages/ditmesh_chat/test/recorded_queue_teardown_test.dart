import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/src/engine/ditmesh_ffi_chat_service.dart';
import 'package:ditmesh_chat/src/chat/recording_metadata.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:tim2tox_dart/utils/offline_message_queue_persistence.dart';
import 'helpers/fakes.dart';

class LegacyFfi extends FakeTim2ToxFfi {
  int controls = 0;
  @override
  int Function(ffi.Pointer<Utf8>, ffi.Pointer<ffi.Uint8>, int, int)
  get sendC2CControlNative => (_, _, _, _) {
    controls++;
    return 1;
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'logout during capability timeout preserves recorded queued send across restart',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'ditmesh_rhythm_queue_teardown_',
      );
      final native = LegacyFfi()
        ..friends.add((userId: kPeerKey, nick: 'Legacy Bob', online: false));
      final queuePath = '${root.path}/queue.json';
      final svc =
          DitmeshFfiChatService(
              historyDirectory: root.path,
              queueFilePath: queuePath,
              ffiForTesting: native,
            )
            ..debugBeginSessionForTest()
            ..debugSetSelfId(kSelfKey);
      try {
        await svc.sendTextWithResult(
          kPeerKey,
          'CQ',
          clientMessageID: 'dmr:${'a' * 32}',
          cloudCustomData: RecordingMetadata.encode(
            KeyedRecording(durationsMs: [83]),
          ),
        );
        svc.debugSetFriendOnline(kPeerKey, true);
        await svc.getFriendList();
        final drain = svc
            .retryPendingC2cMessages(kPeerKey)
            .then<Object?>((_) => null, onError: (Object e) => e);
        while (native.controls == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
        await svc.dispose();
        await drain;
        final restored = OfflineMessageQueuePersistence(
          queueFilePath: queuePath,
        );
        await restored.loadQueue();
        expect(native.uninitCalls, 1);
        expect(native.sentTextPeers, isEmpty);
        expect(restored.getMessages(kPeerKey), hasLength(1));
      } finally {
        await svc.dispose();
        await root.delete(recursive: true);
      }
    },
  );
}

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tim2tox_dart/models/chat_message.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';
import 'package:tim2tox_dart/utils/offline_message_queue_persistence.dart';
import 'helpers/fakes.dart';

class LegacyService extends FfiChatService {
  LegacyService(
    Directory root,
    OfflineMessageQueuePersistence queue,
    FakeTim2ToxFfi native,
  ) : super(
        historyDirectory: root.path,
        offlineMessageQueuePersistence: queue,
        ffiForTesting: native,
      );
  @override
  Future<String?> sendTextExtension(
    String peer,
    String text,
    String? metadata, {
    String? durableId,
    required ChatMessageContentKind kind,
  }) async => 'wire-alias';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'legacy queue without IDs clears its own row and aliases its own message',
    () async {
      final root = await Directory.systemTemp.createTemp('ditmesh_legacy_id_');
      final queue = OfflineMessageQueuePersistence(
        queueFilePath: '${root.path}/queue.json',
      );
      final native = FakeTim2ToxFfi()
        ..friends.add((userId: kPeerKey, nick: 'Bob', online: false));
      final svc = LegacyService(root, queue, native)
        ..debugBeginSessionForTest()
        ..debugSetSelfId(kSelfKey);
      final t = DateTime(2026, 1, 1);
      try {
        svc.addLocalMessage(
          kPeerKey,
          ChatMessage(
            text: 'other',
            fromUserId: kSelfKey,
            isSelf: true,
            timestamp: t.subtract(const Duration(minutes: 1)),
            isPending: false,
          ),
        );
        svc.addLocalMessage(
          kPeerKey,
          ChatMessage(
            text: 'CQ',
            fromUserId: kSelfKey,
            isSelf: true,
            timestamp: t,
            isPending: true,
          ),
        );
        await svc.flushPendingHistory();
        queue.setCache({
          kPeerKey: [
            (
              kind: 'text',
              text: 'CQ',
              filePath: null,
              fileName: null,
              timestamp: t,
              msgID: null,
              cloudCustomData: null,
              contentKind: ChatMessageContentKind.normal,
            ),
          ],
        });
        svc.debugSetFriendOnline(kPeerKey, true);
        await svc.getFriendList();
        await svc.retryPendingC2cMessages(kPeerKey);
        final rows = svc.getHistory(kPeerKey);
        expect(rows.singleWhere((r) => r.text == 'CQ').isPending, isFalse);
        expect(
          rows.singleWhere((r) => r.text == 'CQ').altMsgIds,
          contains('wire-alias'),
        );
        expect(rows.singleWhere((r) => r.text == 'other').altMsgIds, isEmpty);
      } finally {
        await svc.dispose();
        await root.delete(recursive: true);
      }
    },
  );
}

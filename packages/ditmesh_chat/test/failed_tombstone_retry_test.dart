import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tim2tox_dart/models/chat_message.dart';
import 'package:tim2tox_dart/models/send_control_result.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';
import 'package:tim2tox_dart/utils/offline_message_queue_persistence.dart';
import 'helpers/fakes.dart';

/// A drain failure commits a failed tombstone before the row's own write.
/// If that write is lost (a crash, a failing disk), the reloaded row does
/// not say failed, yet DitMesh shows it failed from the tombstone; Retry
/// must still queue it while the peer is offline (overlay 0014).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  OfflineMessageItem tombstone(String id, DateTime at) => (
    kind: 'text',
    text: 'CQ $id',
    filePath: null,
    fileName: null,
    timestamp: at,
    msgID: id,
    cloudCustomData: null,
    contentKind: ChatMessageContentKind.normal,
    control: OfflineSendControl.failed,
  );

  test('Retry re-queues a row whose failure only its tombstone records; a '
      'delivered row is left alone', () async {
    final root = await Directory.systemTemp.createTemp('ditmesh_tomb_retry_');
    final queue = OfflineMessageQueuePersistence(
      queueFilePath: '${root.path}/queue.json',
    );
    final native = FakeTim2ToxFfi()
      ..friends.add((userId: kPeerKey, nick: 'Bob', online: false));
    final svc =
        FfiChatService(
            historyDirectory: root.path,
            offlineMessageQueuePersistence: queue,
            ffiForTesting: native,
          )
          ..debugBeginSessionForTest()
          ..debugSetSelfId(kSelfKey);
    final t = DateTime(2026, 1, 1);
    try {
      for (final (id, received) in [('f1', false), ('d1', true)]) {
        svc.addLocalMessage(
          kPeerKey,
          ChatMessage(
            text: 'CQ $id',
            fromUserId: kSelfKey,
            isSelf: true,
            timestamp: t,
            msgID: id,
            isPending: false,
            isReceived: received,
          ),
        );
      }
      await svc.flushPendingHistory();
      queue.setCache({
        kPeerKey: [tombstone('f1', t), tombstone('d1', t)],
      });

      expect(
        await svc.retryFailedMessage(kPeerKey, 'f1'),
        SendControlResult.success,
      );
      final item = queue
          .getMessages(kPeerKey)
          .singleWhere((i) => i.msgID == 'f1');
      expect(item.control, OfflineSendControl.retry);
      final row = svc.getHistory(kPeerKey).singleWhere((r) => r.msgID == 'f1');
      expect(row.isPending, isTrue);
      expect(row.isFailed, isFalse);

      // Delivery proof beats the failure: nothing to retry.
      expect(
        await svc.retryFailedMessage(kPeerKey, 'd1'),
        SendControlResult.notApplicable,
      );
      expect(
        queue.getMessages(kPeerKey).singleWhere((i) => i.msgID == 'd1').control,
        OfflineSendControl.failed,
      );
    } finally {
      await svc.dispose();
      await root.delete(recursive: true);
    }
  });
}

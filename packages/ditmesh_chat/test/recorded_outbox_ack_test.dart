import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tim2tox_dart/models/chat_message.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';
import 'package:tim2tox_dart/utils/offline_message_queue_persistence.dart';
import 'helpers/fakes.dart';

class RaceQueue extends OfflineMessageQueuePersistence {
  RaceQueue(String path) : super(queueFilePath: path);
  late FfiChatService service;
  bool sawReceivedDuringRemoval = false;
  @override
  Future<void> removeItem(String peer, OfflineMessageItem item) async {
    // An actual peer ACK received while the queue's durable clear is awaited.
    service.applyNativeDeliveryAck(peer, 'dmr:wire');
    sawReceivedDuringRemoval = service.getHistory(peer).single.isReceived;
    await super.removeItem(peer, item);
  }
}

class RaceService extends FfiChatService {
  RaceService(Directory root, RaceQueue queue, FakeTim2ToxFfi native)
    : super(
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
  }) async => 'dmr:wire';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'C2C queued send must retain peer ACK received during durable queue removal',
    () async {
      final root = await Directory.systemTemp.createTemp('ditmesh_ack_race_');
      final queue = RaceQueue('${root.path}/queue.json');
      final native = FakeTim2ToxFfi()
        ..friends.add((userId: kPeerKey, nick: 'Bob', online: false));
      final service = RaceService(root, queue, native)
        ..debugBeginSessionForTest()
        ..debugSetSelfId(kSelfKey);
      queue.service = service;
      try {
        await service.sendTextWithResult(
          kPeerKey,
          'CQ',
          clientMessageID: 'dmr:wire',
        );
        await service.flushPendingHistory();
        service.debugSetFriendOnline(kPeerKey, true);
        await service.getFriendList();
        await service.retryPendingC2cMessages(kPeerKey);
        expect(queue.sawReceivedDuringRemoval, isTrue);
        expect(service.getHistory(kPeerKey).single.isPending, isFalse);
        expect(service.getHistory(kPeerKey).single.isReceived, isTrue);
      } finally {
        await service.dispose();
        await root.delete(recursive: true);
      }
    },
  );
}

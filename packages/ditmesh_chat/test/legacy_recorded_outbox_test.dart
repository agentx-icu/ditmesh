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

/// Delivers the peer's ACK while the queue's durable clear is awaited: it
/// replaces the legacy (msgID-less) row the drain captured before the await.
class AckDuringRemovalQueue extends OfflineMessageQueuePersistence {
  AckDuringRemovalQueue(String path) : super(queueFilePath: path);
  late FfiChatService service;
  bool sawReceivedDuringRemoval = false;
  @override
  Future<void> removeItem(String peer, OfflineMessageItem item) async {
    service.applyNativeDeliveryAck(peer, 'wire-alias');
    sawReceivedDuringRemoval = service
        .getHistory(peer)
        .singleWhere((r) => r.text == 'CQ')
        .isReceived;
    await super.removeItem(peer, item);
  }
}

Future<void> _drainLegacy({required bool ackDuringRemoval}) async {
  final root = await Directory.systemTemp.createTemp('ditmesh_legacy_id_');
  final path = '${root.path}/queue.json';
  final ackQueue = ackDuringRemoval ? AckDuringRemovalQueue(path) : null;
  final queue = ackQueue ?? OfflineMessageQueuePersistence(queueFilePath: path);
  final native = FakeTim2ToxFfi()
    ..friends.add((userId: kPeerKey, nick: 'Bob', online: false));
  final svc = LegacyService(root, queue, native)
    ..debugBeginSessionForTest()
    ..debugSetSelfId(kSelfKey);
  ackQueue?.service = svc;
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
          control: null,
        ),
      ],
    });
    svc.debugSetFriendOnline(kPeerKey, true);
    await svc.getFriendList();
    await svc.retryPendingC2cMessages(kPeerKey);
    final rows = svc.getHistory(kPeerKey);
    final cq = rows.singleWhere((r) => r.text == 'CQ');
    expect(cq.isPending, isFalse);
    expect(cq.altMsgIds, contains('wire-alias'));
    expect(rows.singleWhere((r) => r.text == 'other').altMsgIds, isEmpty);
    if (ackQueue != null) {
      expect(ackQueue.sawReceivedDuringRemoval, isTrue);
      expect(cq.isReceived, isTrue, reason: 'the ACK is kept');
    }
  } finally {
    await svc.dispose();
    await root.delete(recursive: true);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'legacy queue without IDs clears its own row and aliases its own message',
    () => _drainLegacy(ackDuringRemoval: false),
  );
  test(
    'a legacy row replaced by an ACK during queue removal is still '
    'reconciled, keeping the ACK',
    () => _drainLegacy(ackDuringRemoval: true),
  );
}

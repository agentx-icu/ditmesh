import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tim2tox_dart/models/chat_message.dart';
import 'package:tim2tox_dart/models/send_control_result.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';
import 'package:tim2tox_dart/utils/offline_message_queue_persistence.dart';

import 'helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const groupId = 'tox_7';
  const groupKey = 'group:$groupId';
  final timestamp = DateTime(2026, 1, 1);
  late Directory root;
  late String queuePath;
  late FakeTim2ToxFfi native;

  OfflineMessageItem item(String? id, {String? control, String? text}) => (
    kind: 'text',
    text: text ?? 'CQ $id',
    filePath: null,
    fileName: null,
    timestamp: timestamp,
    msgID: id,
    cloudCustomData: '{"recorded":true}',
    contentKind: ChatMessageContentKind.normal,
    control: control,
  );

  Future<void> seedQueue(Map<String, List<OfflineMessageItem>> entries) async {
    await OfflineMessageQueuePersistence(
      queueFilePath: queuePath,
    ).saveQueue(entries);
  }

  Future<FfiChatService> open() async {
    final svc =
        FfiChatService(
            historyDirectory: root.path,
            offlineMessageQueuePersistence: OfflineMessageQueuePersistence(
              queueFilePath: queuePath,
            ),
            ffiForTesting: native,
          )
          ..debugBeginSessionForTest()
          ..debugSetSelfId(kSelfKey)
          ..debugAddKnownGroupForTest(groupId);
    addTearDown(svc.dispose);
    await svc.installAccountStorage(
      historyDirectory: root.path,
      queueFilePath: queuePath,
    );
    return svc;
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('ditmesh_outbox_recovery_');
    addTearDown(() => root.delete(recursive: true));
    queuePath = '${root.path}/queue/offline.json';
    native = FakeTim2ToxFfi()
      ..friends.add((userId: kPeerKey, nick: 'Bob', online: false));
  });

  test('boot restores exactly one outgoing row per queue-only text', () async {
    await seedQueue({
      kPeerKey: [item('c2c'), item(null, text: 'legacy')],
      groupKey: [
        item('ngc'),
        item('cancelled', control: OfflineSendControl.cancelled),
      ],
    });
    final first = await open();
    final dm = first.getHistory(kPeerKey);
    expect(dm.map((row) => row.text), unorderedEquals(['CQ c2c', 'legacy']));
    expect(dm.every((row) => row.isPending && row.isSelf), isTrue);
    final legacy = dm.singleWhere((row) => row.text == 'legacy');
    expect(legacy.msgID, isNotEmpty);
    final groupRow = first.getHistory(groupId).single;
    expect(groupRow.msgID, 'ngc');
    expect(groupRow.groupId, groupId);
    expect(groupRow.timestamp, timestamp);
    expect(groupRow.cloudCustomData, item('ngc').cloudCustomData);
    expect(groupRow.isPending, isTrue);
    await first.flushPendingHistory();
    await first.dispose();

    final reopened = await open();
    expect(
      reopened.getHistory(kPeerKey).map((row) => row.msgID),
      unorderedEquals(['c2c', legacy.msgID]),
    );
    expect(
      await reopened.cancelQueuedMessage(kPeerKey, legacy.msgID!),
      SendControlResult.success,
    );
    expect(
      await reopened.cancelQueuedMessage(groupId, 'ngc', isGroup: true),
      SendControlResult.success,
    );
    expect(reopened.getHistory(groupId).single.isCancelled, isTrue);
  });

  test(
    'an archived failed row retries and settles under its original ID',
    () async {
      final before = ChatMessage(
        text: 'CQ archived',
        fromUserId: kSelfKey,
        isSelf: true,
        timestamp: timestamp,
        msgID: 'archived',
        isFailed: true,
        cloudCustomData: item('archived').cloudCustomData,
      );
      await File(
        '${root.path}/$kPeerKey.archive.jsonl',
      ).writeAsString('${jsonEncode(before.toJson())}\n');
      final svc = await open();
      expect((await svc.getArchivedHistory(kPeerKey)).single.isFailed, isTrue);
      expect(
        await svc.retryFailedMessage(kPeerKey, 'archived'),
        SendControlResult.success,
      );
      final queued = svc.offlineMessageQueuePersistence
          .getMessages(kPeerKey)
          .single;
      expect(queued.msgID, before.msgID);
      expect(queued.cloudCustomData, before.cloudCustomData);
      expect(queued.control, OfflineSendControl.retry);
      final pending = (await svc.getArchivedHistory(kPeerKey)).single;
      expect(pending.isPending, isTrue);
      expect(pending.isFailed, isFalse);
      expect(
        await svc.retryFailedMessage(kPeerKey, 'archived'),
        SendControlResult.notApplicable,
      );
      expect(
        await svc.cancelQueuedMessage(kPeerKey, 'archived'),
        SendControlResult.success,
      );
      final cancelled = (await svc.getArchivedHistory(kPeerKey)).single;
      expect(cancelled.msgID, before.msgID);
      expect(cancelled.isCancelled, isTrue);
      expect(svc.getHistory(kPeerKey), isEmpty);
      expect(svc.offlineMessageQueuePersistence.getMessages(kPeerKey), isEmpty);
    },
  );

  test(
    'archived retry waits for failure clearance before sending once',
    () async {
      final before = ChatMessage(
        text: 'CQ archived',
        fromUserId: kSelfKey,
        isSelf: true,
        timestamp: timestamp,
        msgID: 'archived',
        isFailed: true,
      );
      final archive = File('${root.path}/$kPeerKey.archive.jsonl');
      await archive.writeAsString(
        '${jsonEncode({...before.toJson(), 'futureField': 'keep me'})}\n',
      );
      final svc = await open();
      expect(
        await svc.retryFailedMessage(kPeerKey, 'archived'),
        SendControlResult.success,
      );
      final blockedWrite = await Directory('${archive.path}.tmp').create();
      await svc.retryPendingC2cMessages(kPeerKey);
      expect(native.sentTextPeers, isEmpty);
      expect(
        svc.offlineMessageQueuePersistence.getMessages(kPeerKey).single.control,
        OfflineSendControl.retry,
      );

      await blockedWrite.delete();
      await svc.retryPendingC2cMessages(kPeerKey);
      await svc.retryPendingC2cMessages(kPeerKey);
      expect(native.sentTextPeers, [kPeerKey]);
      expect(svc.offlineMessageQueuePersistence.getMessages(kPeerKey), isEmpty);
      expect(svc.getHistory(kPeerKey), isEmpty);
      final after = (await svc.getArchivedHistory(kPeerKey)).single;
      expect(after.msgID, before.msgID);
      expect(after.isFailed, isFalse);
      expect(after.isPending, isFalse);
      expect(
        jsonDecode((await archive.readAsLines()).single)['futureField'],
        'keep me',
      );
    },
  );

  test(
    'boot consolidates C2C aliases without dropping distinct IDs or tombstones',
    () async {
      final legacy = kPeerToxId.toLowerCase();
      await seedQueue({
        kPeerKey: [item('shared'), item('current')],
        legacy: [
          item('other'),
          item('shared', control: OfflineSendControl.cancelled),
        ],
        groupKey: [item('group')],
      });
      final svc = await open();
      final queue = svc.offlineMessageQueuePersistence;
      expect(queue.getMessages(legacy), isEmpty);
      expect(
        queue.getMessages(kPeerKey).map((row) => (row.msgID, row.control)),
        unorderedEquals([
          ('shared', OfflineSendControl.cancelled),
          ('current', null),
          ('other', null),
        ]),
      );
      expect(queue.getMessages(groupKey).single.msgID, 'group');
      expect(
        svc.getHistory(kPeerKey).map((row) => row.msgID),
        unorderedEquals(['current', 'other']),
      );
      final before = await File(queuePath).readAsString();
      await svc.dispose();
      final restarted = await open();
      expect(
        restarted.offlineMessageQueuePersistence.getMessages(legacy),
        isEmpty,
      );
      expect(await File(queuePath).readAsString(), before);
      await restarted.retryPendingC2cMessages(kPeerKey);
      expect(native.sentTextPeers, [kPeerKey, kPeerKey]);
      expect(
        restarted.offlineMessageQueuePersistence
            .getMessages(kPeerKey)
            .where((item) => OfflineSendControl.dispatchable(item.control)),
        isEmpty,
      );
    },
  );
}

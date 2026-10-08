import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/src/chat/message_mapper.dart';
import 'package:ditmesh_chat/src/chat/pending_message_status.dart';
import 'package:tim2tox_dart/models/chat_message.dart';
import 'package:tim2tox_dart/utils/offline_message_queue_persistence.dart';

OfflineMessageItem _item({
  required String text,
  required DateTime at,
  String? msgID,
  ChatMessageContentKind contentKind = ChatMessageContentKind.normal,
}) => (
  kind: 'text',
  text: text,
  filePath: null,
  fileName: null,
  timestamp: at,
  msgID: msgID,
  cloudCustomData: null,
  contentKind: contentKind,
);

ChatMessage _row({
  required String text,
  required DateTime at,
  String? msgID,
  bool isSelf = true,
  String? groupId,
  ChatMessageContentKind contentKind = ChatMessageContentKind.normal,
}) => ChatMessage(
  text: text,
  fromUserId: 'self',
  isSelf: isSelf,
  timestamp: at,
  msgID: msgID,
  groupId: groupId,
  contentKind: contentKind,
);

void main() {
  final peer = 'A' * 64;
  final c2c = ConversationIds.c2c(peer);
  const group = 'group_tox_1';
  final t0 = DateTime(2026, 10, 3, 12);
  final t1 = t0.add(const Duration(seconds: 1));

  late OfflineMessageQueuePersistence queue;
  late PendingMessageStatus status;

  setUp(() {
    queue = OfflineMessageQueuePersistence(queueFilePath: '/nonexistent/q.json');
    status = PendingMessageStatus(queue);
  });

  test('a received row is never queued', () {
    queue.setCache({
      peer: [_item(text: 'hi', at: t0, msgID: 'm1')],
    });
    expect(status.isQueued(_row(text: 'hi', at: t0, msgID: 'm1', isSelf: false), c2c), isFalse);
  });

  test('matches a queue item by durable message id', () {
    queue.setCache({
      peer: [_item(text: 'queued', at: t0, msgID: 'm1')],
    });
    expect(status.isQueued(_row(text: 'queued', at: t0, msgID: 'm1'), c2c), isTrue);
    expect(status.isQueued(_row(text: 'queued', at: t0, msgID: 'm2'), c2c), isFalse);
    // Same id but another peer's queue: not ours.
    expect(status.isQueued(_row(text: 'queued', at: t0, msgID: 'm1'), ConversationIds.c2c('B' * 64)), isFalse);
  });

  test('legacy items without an id fall back to timestamp, text and kind', () {
    queue.setCache({
      peer: [_item(text: 'old', at: t0)],
    });
    expect(status.isQueued(_row(text: 'old', at: t0, msgID: 'whatever'), c2c), isTrue);
    expect(status.isQueued(_row(text: 'old', at: t1), c2c), isFalse, reason: 'timestamp');
    expect(status.isQueued(_row(text: 'new', at: t0), c2c), isFalse, reason: 'text');
    expect(
      status.isQueued(_row(text: 'old', at: t0, contentKind: ChatMessageContentKind.action), c2c),
      isFalse,
      reason: 'content kind',
    );
  });

  test('group conversations look up the group: slot, not the bare id', () {
    final row = _row(text: 'net', at: t0, msgID: 'g1', groupId: 'tox_1');
    queue.setCache({
      'group:tox_1': [_item(text: 'net', at: t0, msgID: 'g1')],
    });
    expect(status.isQueued(row, group), isTrue);
    queue.setCache({
      'tox_1': [_item(text: 'net', at: t0, msgID: 'g1')],
    });
    expect(status.isQueued(row, group), isFalse, reason: 'bare slot is a peer');
  });

  test('an empty queue is never pending', () {
    expect(status.isQueued(_row(text: 'x', at: t0, msgID: 'm1'), c2c), isFalse);
  });

  test('summary counts the durable queue once per id, per conversation', () {
    queue.setCache({
      peer: [
        _item(text: 'a', at: t1, msgID: 'm1'),
        _item(text: 'a', at: t1, msgID: 'm1'), // re-enqueued duplicate
        _item(text: 'legacy', at: t0), // no id: counted
      ],
      'group:tox_1': [_item(text: 'net', at: t1, msgID: 'g1')],
      'B' * 64: [_item(text: 'other', at: t1, msgID: 'm9')],
    });
    final mine = status.summary(conversationId: c2c);
    expect(mine.count, 2);
    expect(mine.oldest, t0);
    expect(status.summary(conversationId: group).count, 1);
    final all = status.summary();
    expect(all.count, 4);
    expect(all.oldest, t0);
    expect(
      status.summary(conversationId: ConversationIds.c2c('C' * 64)).count,
      0,
    );
    expect(status.summary(conversationId: ConversationIds.c2c('C' * 64)).oldest, isNull);
  });
}

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart'
    show PendingOutboxSummary;
import 'package:tim2tox_dart/models/chat_message.dart';
import 'package:tim2tox_dart/utils/offline_message_queue_persistence.dart';

import 'message_mapper.dart';

/// The durable outbox is authoritative after history reload: Tim2Tox clears
/// historical `isPending` flags on load even when their queue items survive.
class PendingMessageStatus {
  const PendingMessageStatus(this.queue);

  final OfflineMessageQueuePersistence queue;

  bool isQueued(ChatMessage message, String conversationId) {
    if (!message.isSelf) return false;
    final key = queueKeyOf(conversationId);
    return queue.getMessages(key).any((item) {
      final id = item.msgID;
      if (id != null && id.isNotEmpty) return message.msgID == id;
      // Older queues predate durable message ids; match their shared enqueue
      // timestamp and content within this conversation only.
      return item.timestamp.millisecondsSinceEpoch ==
              message.timestamp.millisecondsSinceEpoch &&
          item.text == message.text &&
          item.contentKind == message.contentKind;
    });
  }

  /// Queue key of [conversationId], as the Tim2Tox drain loop stores it.
  static String queueKeyOf(String conversationId) {
    final peer = ConversationIds.peerOf(conversationId);
    return ConversationIds.isGroup(conversationId) ? 'group:$peer' : peer;
  }

  /// Durable outbox contents (F09): for one conversation, or every queue key
  /// (a legacy entry stored under a raw, un-normalized address counts for
  /// the identity but, like [isQueued], not for its conversation)
  /// when [conversationId] is null. An item that appears twice (same durable
  /// id, e.g. re-enqueued by an interrupted drain) counts once.
  PendingOutboxSummary summary({String? conversationId}) {
    final keys = conversationId == null
        ? queue.getPeerIds()
        : {queueKeyOf(conversationId)};
    final seen = <String>{};
    var count = 0;
    DateTime? oldest;
    for (final key in keys) {
      for (final item in queue.getMessages(key)) {
        final id = item.msgID;
        if (id != null && id.isNotEmpty && !seen.add('$key/$id')) continue;
        count++;
        if (oldest == null || item.timestamp.isBefore(oldest)) {
          oldest = item.timestamp;
        }
      }
    }
    return PendingOutboxSummary(count: count, oldest: oldest);
  }
}

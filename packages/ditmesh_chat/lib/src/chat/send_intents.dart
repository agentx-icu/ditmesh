import 'package:tim2tox_dart/service/ffi_chat_service.dart';

import 'conversation_meta_store.dart';
import 'message_mapper.dart';
import 'pending_message_status.dart';

/// Settles the send intents a previous run left behind (see
/// [ConversationMetaStore.setSendIntent]), on a session whose history and
/// queue are loaded but that cannot dispatch yet: the engine runs this after
/// login, before polling and before group-join callbacks can start a drain,
/// so a queued row is still in the outbox here.
///
/// A send whose message id is in the durable outbox or in the history
/// committed; if the stored draft is still the one it was sent from, the
/// process died before the composer cleared it, and it is removed. Any other
/// intent is dropped: either a later draft write superseded it, or the send
/// never committed and the draft is rightly still there.
Future<void> reconcileSendIntents(
  ConversationMetaStore meta,
  FfiChatService svc,
) async {
  final queue = svc.offlineMessageQueuePersistence;
  for (final MapEntry(key: conversationId, value: intent)
      in meta.allSendIntents().entries) {
    final peer = ConversationIds.peerOf(conversationId);
    var committed = queue
        .getMessages(PendingMessageStatus.queueKeyOf(conversationId))
        .any((item) => item.msgID == intent.id);
    if (!committed) {
      await svc.loadHistory(peer);
      committed = svc
          .getHistory(peer)
          .any((m) => m.msgID == intent.id || m.altMsgIds.contains(intent.id));
    }
    // Re-read after the await: a draft write meanwhile (the chat service
    // writes drafts without a session) superseded the intent.
    if (meta.sendIntent(conversationId) != intent) continue;
    if (committed && meta.draft(conversationId) == intent.draft) {
      // Checked and submitted in one synchronous step: a later draft write
      // lands after this removal (and removes the intent itself).
      await meta.setDraft(conversationId, '');
    } else {
      await meta.clearSendIntent(conversationId);
    }
  }
}

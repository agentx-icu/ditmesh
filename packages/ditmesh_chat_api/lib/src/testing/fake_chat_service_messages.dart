part of 'fake_chat_service.dart';

/// Search, deep jumps, retry and cancel for [FakeChatService]. A mixin in a
/// part file keeps the service under the 500-line gate while still
/// implementing the [ChatService] members; the abstract members below are
/// the service's own private state.
mixin _FakeMessageManagement implements ChatService, OutboxInspector {
  Map<String, List<ChatMessage>> get _messages;
  Map<String, Conversation> get _conversations;
  Map<String, Friend> get _friends;
  Set<String> get _disconnectedGroups;
  void _applyStatus(String messageId, MessageStatus status);
  List<ChatMessage> _visibleRows(String conversationId);

  /// Like history, every operation here needs a live session.
  void _requireSession();

  /// The fake keeps every row, so its "durable queue" is our pending rows
  /// across the whole history (not one loaded page). Null without a session,
  /// like the transport whose queue is unloaded while detached.
  @override
  PendingOutboxSummary? pendingOutbox({String? conversationId}) {
    if (!hasSession) return null;
    final Iterable<List<ChatMessage>> lists = conversationId == null
        ? _messages.values
        : [_messages[conversationId] ?? const <ChatMessage>[]];
    final Set<String> ids = <String>{};
    DateTime? oldest;
    for (final List<ChatMessage> list in lists) {
      for (final ChatMessage m in list) {
        if (!m.isMine || m.status != MessageStatus.pending) continue;
        if (!ids.add(m.id)) continue;
        if (oldest == null || m.timestamp.isBefore(oldest)) {
          oldest = m.timestamp;
        }
      }
    }
    return PendingOutboxSummary(count: ids.length, oldest: oldest);
  }

  @override
  Future<MessageSearchPage> searchMessages(
    String conversationId,
    MessageSearchQuery query, {
    MessageSearchCursor? cursor,
    int limit = 20,
    MessageSearchCancel? cancel,
  }) async {
    _requireSession();
    if (cancel?.isCancelled ?? false) throw const MessageSearchCancelled();
    return MessageOrder.page(
      _visibleRows(conversationId),
      query,
      cursor: cursor,
      limit: limit,
    );
  }

  @override
  Future<List<ChatMessage>> loadAround(
    String conversationId,
    String messageId, {
    int before = 25,
    int after = 25,
  }) async {
    _requireSession();
    return MessageOrder.around(
      _visibleRows(conversationId),
      messageId,
      before: before,
      after: after,
    );
  }

  @override
  bool get supportsSendControl => true;

  ChatMessage? _ownRow(String conversationId, String messageId) {
    for (final m in _messages[conversationId] ?? const <ChatMessage>[]) {
      if (m.id == messageId) return m;
    }
    return null;
  }

  @override
  Future<MessageActionResult> retryMessage(
    String conversationId,
    String messageId,
  ) async {
    _requireSession();
    final m = _ownRow(conversationId, messageId);
    if (m == null || !m.isMine || conversationId == selfConversationId) {
      return MessageActionResult.unavailable;
    }
    if (m.status == MessageStatus.cancelled) {
      return MessageActionResult.unavailable;
    }
    if (m.status != MessageStatus.failed) {
      return MessageActionResult.stateChanged;
    }
    final conversation = _conversations[conversationId];
    // The same delivery rule as sendText: a group whose transport is down
    // keeps the retry pending.
    final deliverable =
        (conversation?.kind == ConversationKind.group &&
            !_disconnectedGroups.contains(conversation?.peerId)) ||
        (_friends[conversation?.peerId]?.online ?? false);
    _applyStatus(messageId, MessageStatus.pending);
    if (deliverable) _applyStatus(messageId, MessageStatus.sent);
    return MessageActionResult.success;
  }

  @override
  Future<MessageActionResult> cancelPendingMessage(
    String conversationId,
    String messageId,
  ) async {
    _requireSession();
    final m = _ownRow(conversationId, messageId);
    if (m == null || !m.isMine || conversationId == selfConversationId) {
      return MessageActionResult.unavailable;
    }
    if (m.status != MessageStatus.pending) {
      return MessageActionResult.stateChanged;
    }
    _applyStatus(messageId, MessageStatus.cancelled);
    return MessageActionResult.success;
  }
}

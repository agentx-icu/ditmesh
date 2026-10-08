part of 'tim2tox_chat_service.dart';

/// Message management over Tim2Tox (functional spec F07): history search,
/// deep jumps, and single-message retry / cancel. A mixin in a part file so
/// [Tim2ToxChatService] stays under the 500-line gate; the abstract members
/// are the service's own.
mixin _MessageManagement implements ChatService {
  FfiChatService _requireService();
  void _ensureCurrent(FfiChatService svc);
  MessageMapper get _mapper;

  /// Whether a row is shown (chat text, not from a blocked peer).
  bool _shows(t2t.ChatMessage m);

  /// A mapped row from a peer blocked now (re-checked at the end of a scan:
  /// a block during one of its yields must not leak earlier rows).
  bool _hiddenNow(ChatMessage m);

  /// Rows mapped between yields while scanning a long history, so a search
  /// never blocks the UI isolate for long.
  static const int _scanChunk = 500;

  /// Every persisted row of [conversationId] (live window plus archive),
  /// mapped, in no particular order. Scanned in chunks.
  Future<List<ChatMessage>> _allRows(
    String conversationId, {
    MessageSearchCancel? cancel,
  }) async {
    final svc = _requireService();
    final peer = ConversationIds.peerOf(conversationId);
    final rows = List<t2t.ChatMessage>.of(svc.getHistory(peer));
    final hasArchive = await svc.hasArchivedHistory(peer);
    // The session may have changed during any await: never map old rows.
    _ensureCurrent(svc);
    if (hasArchive) {
      final archived = await svc.getArchivedHistory(peer);
      _ensureCurrent(svc);
      final seen = rows.map((r) => r.msgID).whereType<String>().toSet();
      rows.addAll(archived.where((r) => !seen.contains(r.msgID)));
    }
    final mapper = _mapper;
    final out = <ChatMessage>[];
    for (var i = 0; i < rows.length; i++) {
      // Files, media and custom rows are not chat messages, and blocked
      // peers' rows are hidden (as in history).
      if (_shows(rows[i])) {
        out.add(mapper.map(rows[i], conversationId: conversationId));
      }
      if (i % _scanChunk == _scanChunk - 1) {
        await Future<void>.delayed(Duration.zero);
        _ensureCurrent(svc);
        if (cancel?.isCancelled ?? false) throw const MessageSearchCancelled();
      }
    }
    if (cancel?.isCancelled ?? false) throw const MessageSearchCancelled();
    out.removeWhere(_hiddenNow);
    return out;
  }

  @override
  Future<MessageSearchPage> searchMessages(
    String conversationId,
    MessageSearchQuery query, {
    MessageSearchCursor? cursor,
    int limit = 20,
    MessageSearchCancel? cancel,
  }) async {
    final rows = await _allRows(conversationId, cancel: cancel);
    // Filter in chunks, yielding and honouring cancellation, so a long
    // history never blocks the UI isolate; only the matches are sorted.
    final hits = <ChatMessage>[];
    for (var i = 0; i < rows.length; i += 500) {
      if (cancel?.isCancelled ?? false) throw const MessageSearchCancelled();
      final end = i + 500 < rows.length ? i + 500 : rows.length;
      hits.addAll(rows.sublist(i, end).where(query.matches));
      await Future<void>.delayed(Duration.zero);
    }
    if (cancel?.isCancelled ?? false) throw const MessageSearchCancelled();
    return MessageOrder.page(hits, query, cursor: cursor, limit: limit);
  }

  @override
  Future<List<ChatMessage>> loadAround(
    String conversationId,
    String messageId, {
    int before = 25,
    int after = 25,
  }) async => MessageOrder.around(
    await _allRows(conversationId),
    messageId,
    before: before,
    after: after,
  );

  @override
  bool get supportsSendControl => true;

  @override
  Future<MessageActionResult> retryMessage(
    String conversationId,
    String messageId,
  ) => _control(
    conversationId,
    messageId,
    (svc, peer, isGroup) =>
        svc.retryFailedMessage(peer, messageId, isGroup: isGroup),
  );

  @override
  Future<MessageActionResult> cancelPendingMessage(
    String conversationId,
    String messageId,
  ) => _control(
    conversationId,
    messageId,
    (svc, peer, isGroup) =>
        svc.cancelQueuedMessage(peer, messageId, isGroup: isGroup),
  );

  Future<MessageActionResult> _control(
    String conversationId,
    String messageId,
    Future<SendControlResult> Function(
      FfiChatService svc,
      String peer,
      bool isGroup,
    )
    action,
  ) async {
    if (conversationId == selfConversationId) {
      return MessageActionResult.unavailable;
    }
    final svc = _requireService();
    final peer = ConversationIds.peerOf(conversationId);
    final result = await action(
      svc,
      peer,
      ConversationIds.isGroup(conversationId),
    );
    _ensureCurrent(svc);
    switch (result) {
      case SendControlResult.success:
        return MessageActionResult.success;
      case SendControlResult.alreadyClaimed:
        return MessageActionResult.stateChanged;
      case SendControlResult.persistFailed:
        return MessageActionResult.failure;
      case SendControlResult.notApplicable:
        // Our own row that simply moved on (sent, already cancelled, no
        // longer failed) is a state change; anything else is unavailable.
        final own = svc
            .getHistory(peer)
            .any((r) => r.isSelf && r.msgID == messageId);
        return own
            ? MessageActionResult.stateChanged
            : MessageActionResult.unavailable;
    }
  }
}

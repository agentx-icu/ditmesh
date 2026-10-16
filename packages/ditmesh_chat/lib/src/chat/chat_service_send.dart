part of 'tim2tox_chat_service.dart';

/// Sending text. Tim2Tox queues a C2C text for any key it does not see
/// online, friend or not, and a queue item for a non-friend never drains
/// (and never fails), so the target is checked against native state first.
extension _Sending on Tim2ToxChatService {
  Future<ChatMessage> _sendText(
    String conversationId,
    String text, {
    KeyedRecording? recording,
  }) async {
    final svc = _requireService();
    final bytes = utf8.encode(text).length;
    if (bytes > Tim2ToxChatService.toxMessageBudget) {
      throw ChatException(
        'message_too_long',
        '$bytes bytes exceeds the ${Tim2ToxChatService.toxMessageBudget}'
            '-byte Tox message budget',
      );
    }
    if (text.trim().isEmpty) {
      throw const ChatException('empty_message', 'Message is empty');
    }
    final isGroup = ConversationIds.isGroup(conversationId);
    final peer = ConversationIds.peerOf(conversationId);
    final key = ConversationIds.normalizeKey(peer);
    // The note to self is stored locally, never sent.
    final checked = !isGroup && key != _selfKey;
    final removals = _friendsPart.removals;
    // The originating session's view: a row committed there is mapped with
    // its self key and names even if the session detached meanwhile.
    final mapper = _mapper;
    // Every send carries its own id (recordings the rhythm transport's
    // `dmr:` form), journalled before the first await so a draft write the
    // composer starts later is ordered after it.
    final id = recording == null
        ? 'dmt:${RhythmProtocol.freshId()}'
        : 'dmr:${RhythmProtocol.freshId()}';
    final intent = _conversationsPart.recordSendIntent(conversationId, id)
      ..ignore();
    if (checked) await _requireFriend(svc, key);
    try {
      await intent;
    } on ChatException {
      rethrow;
    } on Object catch (e) {
      // Nothing is queued yet: the draft stays and the send can be retried.
      throw ChatException('send_failed', 'Could not record the send: $e');
    }
    _ensureCurrent(svc);
    final t2t.ChatMessage row;
    try {
      if (isGroup) {
        svc.armNextSendCloudCustomData(RecordingMetadata.encode(recording));
      }
      row = isGroup
          ? await svc.sendGroupTextWithResult(peer, text, clientMessageID: id)
          : await svc.sendTextWithResult(
              peer,
              text,
              clientMessageID: id,
              cloudCustomData: RecordingMetadata.encode(recording),
            );
    } on ArgumentError catch (e) {
      throw ChatException('invalid_message', e.message?.toString() ?? '$e');
    } on StateError catch (e) {
      throw ChatException('send_failed', e.message);
    }
    final message = mapper.map(row, conversationId: conversationId);
    // Committed (queued or sent): from here on the send succeeds. Failing it
    // would leave the composer offering the same text again.
    if (!_isCurrent(svc)) return message;
    // A remove or block that ran while this send awaited: a row it left
    // queued would never drain, so it is cancelled and the send refused.
    if (checked &&
        message.status == MessageStatus.pending &&
        (removals != _friendsPart.removals || _blockingPart.isBlocked(key))) {
      try {
        await _requireFriend(svc, key);
      } on ChatException {
        await _withdraw(svc, peer, row.msgID);
        rethrow;
      }
    }
    if (_meta.hidden.contains(conversationId)) {
      try {
        await _meta.unhide(conversationId);
      } on Object catch (e, st) {
        // The row's own message event unhides it again (_onEngineMessage).
        _logger.error('[Chat] unhide after a send failed', e, st);
      }
      if (!_isCurrent(svc)) return message;
    }
    _conversationsPart.rebuild(svc);
    return message;
  }

  /// Takes a refused send's queued row back out of the durable outbox. If
  /// that cannot be persisted now, the send fails as `send_failed` and the
  /// withdrawal is retried on every refresh round.
  Future<void> _withdraw(FfiChatService svc, String peer, String? id) async {
    if (id == null) return;
    final prefix = _accountPrefix;
    final result = await svc.cancelQueuedMessage(peer, id);
    // Judged by the outbox, not the answer: notApplicable also comes back
    // while another cancel of the row is still persisting.
    final queued = _friendsPart.stillQueued(svc, peer, id);
    if (queued && !_isCurrent(svc)) {
      _friendsPart.rememberWithdrawal(prefix, peer, id);
    }
    _ensureCurrent(svc);
    if (queued) await _friendsPart.recordWithdrawal(peer, id);
    if (result == SendControlResult.persistFailed) {
      throw const ChatException(
        'send_failed',
        'The message was queued for someone no longer a friend and could '
            'not be withdrawn yet; it is retried in the background',
      );
    }
  }

  /// `peer_blocked` / `not_friend` unless [key] is in the native friend
  /// list (which includes friends we sent a request to) and not blocked.
  /// Native, not [friends]: that list lags a bind or a removal by a tick.
  Future<void> _requireFriend(FfiChatService svc, String key) async {
    void refuseBlocked() {
      if (_blockingPart.isBlocked(key)) {
        throw const ChatException('peer_blocked', 'Unblock them first');
      }
    }

    refuseBlocked();
    if (_friendsPart.removing.contains(key)) {
      throw const ChatException('not_friend', 'Being removed as a friend');
    }
    final native = await svc.getFriendList();
    _ensureCurrent(svc);
    refuseBlocked();
    if (_friendsPart.removing.contains(key) ||
        !native.any((f) => ConversationIds.normalizeKey(f.userId) == key)) {
      throw const ChatException('not_friend', 'Not in your friend list');
    }
  }
}

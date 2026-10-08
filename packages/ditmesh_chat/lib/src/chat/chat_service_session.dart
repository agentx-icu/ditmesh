part of 'tim2tox_chat_service.dart';

/// Following the engine's session: binding to a live `FfiChatService`, the
/// polling refresh round, and turning its message stream into contract
/// events.
extension _SessionBinding on Tim2ToxChatService {
  void _bindSession(FfiChatService? svc) {
    _unbindSession();
    _service = svc;
    // Before the session is published or any listener is installed.
    _blockingPart.bind(svc);
    _session.add(svc != null);
    if (svc == null) {
      _friendsPart.reset();
      _groupsPart.reset();
      _conversationsPart.reset();
      return;
    }
    _serviceSubs.addAll([
      svc.messages.listen(_onEngineMessage),
      svc.nicknameUpdated.listen(
        (_) => unawaited(
          _friendsPart.refresh(svc).catchError((Object e, StackTrace st) {
            _logger.error('[Chat] friend refresh after rename failed', e, st);
          }),
        ),
      ),
      svc.pendingGroupInvitesChanged.listen(
        (_) => _groupsPart.refreshInvites(svc),
      ),
      svc.groupJoinFailures.listen(_groupsPart.onJoinFailure),
    ]);
    _poll = Timer.periodic(_pollInterval, (_) => _tick());
    unawaited(_tick());
  }

  void _unbindSession() {
    _poll?.cancel();
    _poll = null;
    for (final s in _serviceSubs) {
      unawaited(s.cancel());
    }
    _serviceSubs.clear();
    _service = null;
  }

  /// One refresh round: presence, requests, groups, invites, conversations.
  /// Serialised: a slow FFI round never overlaps the next.
  Future<void> _tick() async {
    final svc = _service;
    if (svc == null || _disposed || identical(_ticking, svc)) return;
    _ticking = svc;
    try {
      // The blacklist filters everything published below.
      await _blockingPart.ensureLoaded(svc);
      if (!_isCurrent(svc)) return;
      await _friendsPart.refresh(svc);
      if (!_isCurrent(svc)) return;
      await _friendsPart.refreshRequests(svc);
      if (!_isCurrent(svc)) return;
      await _groupsPart.refresh(svc);
      if (!_isCurrent(svc)) return;
      await _groupsPart.refreshInvites(svc);
      if (!_isCurrent(svc)) return;
      _conversationsPart.rebuild(svc);
    } catch (e, st) {
      _logger.error('[Chat] refresh tick failed', e, st);
    } finally {
      if (identical(_ticking, svc)) _ticking = null;
    }
  }

  void _onEngineMessage(t2t.ChatMessage m) {
    final svc = _service;
    if (svc == null) return;
    var conversationId = MessageMapper.conversationOf(m);
    if (conversationId == null) {
      // Our own C2C row: Tim2Tox stamps the login alias, not the peer.
      final peer = m.msgID == null ? null : svc.c2cPeerOfSelfRow(m.msgID!);
      if (peer == null) return;
      conversationId = ConversationIds.c2c(peer);
    }
    // DitMesh has no file feature: a file a toxee peer pushed is not a
    // chat message here (and must not reach auto-play as an empty one).
    if (!MessageMapper.isChatText(m)) return;
    // Blocked peers: Tim2Tox already drops their C2C rows; group rows it
    // stores, so they are hidden here (and in every history read).
    if (!_blockingPart.shows(m)) return;
    if (_meta.hidden.contains(conversationId)) {
      unawaited(_meta.unhide(conversationId));
    }
    _messageEvents.add(_mapper.map(m, conversationId: conversationId));
    _conversationsPart.rebuild(svc);
  }
}

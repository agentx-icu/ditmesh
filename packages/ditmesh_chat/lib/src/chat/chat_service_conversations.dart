part of 'tim2tox_chat_service.dart';

/// Derives the conversation list from Tim2Tox state (history ids, friends,
/// groups, unread counters, last messages) plus our own metadata (pinned,
/// drafts, hidden). Rebuilt on every tick and after every mutation; only
/// published when something changed.
class _ConversationsPart {
  _ConversationsPart(this._owner);

  final Tim2ToxChatService _owner;

  final ValueStream<List<Conversation>> conversations = ValueStream(const []);

  void reset() => conversations.add(const []);

  void rebuild(FfiChatService svc) {
    final meta = _owner._meta;
    final hidden = meta.hidden;
    final pinned = meta.pinned;
    final quit = svc.quitGroups;
    final groupIds = svc.knownGroups;
    final friendById = {
      for (final f in _owner._friendsPart.friends.value) f.publicKey: f,
    };
    final groupById = {
      for (final g in _owner._groupsPart.groups.value) g.id: g,
    };

    final selfKey = _owner._selfKey;
    final selfId = selfKey.isEmpty ? null : ConversationIds.c2c(selfKey);
    final ids = <String>{
      for (final id in svc.getConversationIds())
        if (groupIds.contains(id))
          ConversationIds.group(id)
        else if (!quit.contains(id))
          ConversationIds.c2c(id),
      for (final f in friendById.keys) ConversationIds.c2c(f),
      for (final g in groupIds) ConversationIds.group(g),
    }..removeAll(hidden);
    // A blocked peer's c2c conversation is not listed.
    final blocking = _owner._blockingPart;
    ids.removeWhere(
      (id) =>
          !ConversationIds.isGroup(id) &&
          blocking.isBlocked(ConversationIds.peerOf(id)),
    );
    // Note to self: always listed, never hidden (it cannot be deleted).
    if (selfId != null) ids.add(selfId);

    final mapper = _owner._mapper;
    final next = <Conversation>[];
    for (final id in ids) {
      final peer = ConversationIds.peerOf(id);
      final isGroup = ConversationIds.isGroup(id);
      if (!isGroup && !ConversationIds.publicKey.hasMatch(peer)) {
        continue; // foreign history key (e.g. an IRC channel), not a peer
      }
      final last = _lastMessage(svc, peer, blocking.shows);
      final isSelf = id == selfId;
      final title = isSelf
          ? (_owner._identity.current?.displayName ?? '')
          : isGroup
          ? (groupById[peer]?.name ??
                PeerText.singleLine(svc.sharedGroupName(peer) ?? peer))
          : (friendById[peer]?.displayName ??
                _owner._friendsPart.nameOf(peer) ??
                ConversationIds.shortKey(peer));
      next.add(
        Conversation(
          id: id,
          kind: isGroup ? ConversationKind.group : ConversationKind.c2c,
          title: title,
          lastMessage: last == null
              ? null
              : mapper.map(last, conversationId: id),
          unreadCount: visibleUnread(
            svc.getUnreadOf(peer),
            svc.getHistory(peer),
            shows: blocking.shows,
            // Rows past the in-memory window may be a blocked member's;
            // only group histories can hold them (Tim2Tox drops blocked
            // C2C rows before storing them).
            countArchived: !isGroup || blocking.blocked.value.isEmpty,
          ),
          pinned: pinned.contains(id),
          draft: meta.draft(id),
          isSelf: isSelf,
        ),
      );
    }
    next.sort(_compare);
    if (!listEqualsBy(conversations.value, next, _same)) {
      conversations.force(next);
    }
  }

  /// Newest row [shows] accepts: a file row a toxee peer pushed, or a
  /// blocked group member's message, is not a preview. Only the in-memory
  /// window (Tim2Tox keeps the newest 1000 rows) is searched on this hot
  /// path: when all of those are hidden, the row has no preview.
  static t2t.ChatMessage? _lastMessage(
    FfiChatService svc,
    String peer,
    bool Function(t2t.ChatMessage) shows,
  ) {
    final cached = svc.lastMessages[peer];
    if (cached != null && shows(cached)) return cached;
    t2t.ChatMessage? newest;
    for (final m in svc.getHistory(peer)) {
      if (!shows(m)) continue;
      if (newest == null || !m.timestamp.isBefore(newest.timestamp)) {
        newest = m;
      }
    }
    return newest;
  }

  static int _compare(Conversation a, Conversation b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    final ta = a.lastMessage?.timestamp;
    final tb = b.lastMessage?.timestamp;
    if (ta != null && tb != null && ta != tb) return tb.compareTo(ta);
    if (ta == null && tb != null) return 1;
    if (ta != null && tb == null) return -1;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  static bool _same(Conversation a, Conversation b) =>
      a.id == b.id &&
      a.isSelf == b.isSelf &&
      a.title == b.title &&
      a.unreadCount == b.unreadCount &&
      a.pinned == b.pinned &&
      a.draft == b.draft &&
      a.lastMessage?.id == b.lastMessage?.id &&
      a.lastMessage?.status == b.lastMessage?.status &&
      a.lastMessage?.text == b.lastMessage?.text;

  Future<void> markRead(FfiChatService svc, String conversationId) async {
    await svc.markConversationRead(ConversationIds.peerOf(conversationId));
    _owner._ensureCurrent(svc);
    rebuild(svc);
  }

  // Pin and draft work offline too (metadata only), so no session is
  // required; but only the session that was bound when the write started
  // may be republished - a rebind during the await gets its own tick.
  Future<void> setPinned(String conversationId, bool pinned) async {
    if (_owner._identity.current == null || _owner._replacing) {
      throw const ChatException('no_identity', 'No identity is open');
    }
    final svc = _owner._service;
    final meta = _owner._meta;
    await meta.setPinned(conversationId, pinned);
    if (svc != null && _owner._isCurrent(svc)) rebuild(svc);
  }

  Future<void> setDraft(String conversationId, String draft) async {
    if (_owner._identity.current == null || _owner._replacing) {
      throw const ChatException('no_identity', 'No identity is open');
    }
    final svc = _owner._service;
    final meta = _owner._meta;
    await meta.setDraft(conversationId, draft);
    if (svc != null && _owner._isCurrent(svc)) rebuild(svc);
  }

  /// Throws `self_conversation` for the note to self, which cannot be
  /// deleted (only emptied explicitly with `clearHistory`). Needs no session,
  /// so callers run it before anything else, offline included.
  void refuseSelf(String conversationId) {
    if (ConversationIds.isGroup(conversationId)) return;
    final selfKey = _owner._selfKey;
    final peer = ConversationIds.normalizeKey(
      ConversationIds.peerOf(conversationId),
    );
    if (selfKey.isNotEmpty && peer == selfKey) {
      throw const ChatException(
        'self_conversation',
        'The note-to-self conversation cannot be deleted',
      );
    }
  }

  /// Clears the history and hides the conversation until the next message
  /// (a friend or group stays; deleting the relationship is a separate call).
  /// The note to self is refused ([refuseSelf]) before anything changes.
  Future<void> delete(FfiChatService svc, String conversationId) async {
    refuseSelf(conversationId);
    final peer = ConversationIds.peerOf(conversationId);
    if (ConversationIds.isGroup(conversationId)) {
      await svc.clearGroupHistory(peer);
    } else {
      await svc.clearC2CHistory(peer);
    }
    _owner._ensureCurrent(svc);
    await _owner._meta.setPinned(conversationId, false);
    _owner._ensureCurrent(svc);
    await _owner._meta.setDraft(conversationId, '');
    _owner._ensureCurrent(svc);
    await _owner._meta.hide(conversationId);
    _owner._ensureCurrent(svc);
    rebuild(svc);
  }

  Future<void> close() => conversations.close();
}

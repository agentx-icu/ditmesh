part of 'fake_chat_service.dart';

/// Row bookkeeping shared by the service and its test hooks: which
/// conversations are listed, and how a message or status change updates
/// them.
extension _FakeConversationRows on FakeChatService {
  /// Every row, plus one for each friend that has none yet (the backend
  /// lists all friends), minus deleted ones until their next message (a
  /// draft or pin does not bring one back). Empty without a session, like
  /// the backend's lists.
  List<Conversation> _listedConversations() {
    if (!_sessionUp) return const <Conversation>[];
    final Map<String, Conversation> rows = <String, Conversation>{
      for (final MapEntry<String, Conversation> e in _conversations.entries)
        if (!_hidden.contains(e.key) && !_blockedRow(e.value))
          e.key: _withoutBlockedPreview(e.value),
    };
    for (final Friend friend in _friends.values) {
      final String id = FakeChatService.c2cConversationId(friend.publicKey);
      if (rows.containsKey(id) || _hidden.contains(id)) continue;
      rows[id] = Conversation(
        id: id,
        kind: ConversationKind.c2c,
        title: friend.displayName,
      );
    }
    return List<Conversation>.unmodifiable(rows.values);
  }

  /// A blocked peer's c2c conversation is not listed (blocking hides it).
  bool _blockedRow(Conversation c) =>
      c.kind == ConversationKind.c2c && !c.isSelf && _isBlocked(c.peerId);

  /// A group row with a blocked member's rows shows the newest visible row
  /// as its preview and does not count their rows as unread (like the
  /// transport, which counts only shown rows).
  Conversation _withoutBlockedPreview(Conversation c) {
    if (_blocked.isEmpty || c.kind != ConversationKind.group) return c;
    final List<ChatMessage> all = _messages[c.id] ?? const <ChatMessage>[];
    // The unread rows are the newest c.unreadCount inbound rows.
    final List<ChatMessage> inbound = [
      for (final m in all)
        if (!m.isMine) m,
    ];
    final int start = inbound.length > c.unreadCount
        ? inbound.length - c.unreadCount
        : 0;
    final int hiddenUnread = inbound
        .sublist(start)
        .where((m) => _isBlocked(m.senderId))
        .length;
    final ChatMessage? last = c.lastMessage;
    final bool previewHidden =
        last != null && !last.isMine && _isBlocked(last.senderId);
    if (hiddenUnread == 0 && !previewHidden) return c;
    final List<ChatMessage> visible = _visibleRows(c.id);
    return Conversation(
      id: c.id,
      kind: c.kind,
      title: c.title,
      lastMessage: previewHidden
          ? (visible.isEmpty ? null : visible.last)
          : last,
      unreadCount: c.unreadCount - hiddenUnread,
      pinned: c.pinned,
      draft: c.draft,
      isSelf: c.isSelf,
    );
  }

  /// The newest [limit] visible rows strictly before [before], oldest first.
  List<ChatMessage> _history(String id, int limit, DateTime? before) {
    final List<ChatMessage> all = _visibleRows(id);
    final List<ChatMessage> eligible = before == null
        ? all
        : all.where((m) => m.timestamp.isBefore(before)).toList();
    final int start = eligible.length > limit ? eligible.length - limit : 0;
    return List<ChatMessage>.unmodifiable(eligible.sublist(start));
  }

  void _clear(String conversationId) {
    _messages.remove(conversationId);
    final Conversation? existing = _conversations[conversationId];
    if (existing == null) return;
    _conversations[conversationId] = Conversation(
      id: existing.id,
      kind: existing.kind,
      title: existing.title,
      pinned: existing.pinned,
      draft: existing.draft,
      isSelf: existing.isSelf,
    );
    _publishConversations();
  }

  /// Everything a block or unblock changes.
  void _publishBlocking() {
    _blockedChanges.add(blockedPeers);
    _friendRequestChanges.add(friendRequests);
    _groupInviteChanges.add(groupInvites);
    _publishConversations();
  }

  void _updateConversation(
    String id,
    Conversation Function(Conversation) change,
  ) {
    final Conversation? existing = _conversations[id] ?? _materialize(id);
    if (existing == null) {
      throw ChatException('conversation_not_found', 'No conversation $id');
    }
    _conversations[id] = change(existing);
    _publishConversations();
  }

  /// Builds the conversation row for a known friend / group that has no row
  /// yet (first message, first draft). Returns null for unknown peers.
  Conversation? _materialize(String id) {
    final String peer = id.substring(id.indexOf('_') + 1);
    if (_isSelfConversation(id)) return _selfConversation();
    if (id.startsWith('c2c_')) {
      final Friend? friend = _friends[peer];
      if (friend == null) return null;
      return Conversation(
        id: id,
        kind: ConversationKind.c2c,
        title: friend.displayName,
      );
    }
    if (id.startsWith('group_')) {
      final Group? group = _groups[peer];
      if (group == null) return null;
      return Conversation(
        id: id,
        kind: ConversationKind.group,
        title: group.name,
      );
    }
    return null;
  }

  void _append(
    Conversation conversation,
    ChatMessage message, {
    required int unreadDelta,
  }) {
    _hidden.remove(message.conversationId);
    _messages.putIfAbsent(message.conversationId, () => <ChatMessage>[]);
    _messages[message.conversationId]!.add(message);
    _conversations[conversation.id] = _copyConversation(
      conversation,
      lastMessage: message,
      unreadCount: conversation.unreadCount + unreadDelta,
    );
    _publishConversations();
    _messageEvents.add(message);
  }

  void _setStatus(String messageId, MessageStatus status) {
    for (final List<ChatMessage> list in _messages.values) {
      final int index = list.indexWhere((m) => m.id == messageId);
      if (index < 0) continue;
      final ChatMessage updated = list[index].copyWith(status: status);
      list[index] = updated;
      final Conversation? conversation = _conversations[updated.conversationId];
      if (conversation != null && conversation.lastMessage?.id == messageId) {
        _conversations[conversation.id] = _copyConversation(
          conversation,
          lastMessage: updated,
        );
        _publishConversations();
      }
      _messageEvents.add(updated);
      return;
    }
  }
}

part of 'fake_chat_service.dart';

/// Test-only hooks that drive the fake from the outside: inbound messages,
/// friend requests, group invites, online toggles. Kept as an extension in
/// a part file so the service itself stays under the 500-line gate; being
/// part of the same library it may touch the private state directly.
extension FakeChatServiceTestHooks on FakeChatService {
  /// Mirrors optional group timing received after its text, without unread
  /// increment or another new-message event.
  void attachRecording(String messageId, KeyedRecording recording) {
    for (final list in _messages.values) {
      final index = list.indexWhere((m) => m.id == messageId);
      if (index < 0) continue;
      final updated = list[index].copyWith(recording: recording);
      list[index] = updated;
      final conversation = _conversations[updated.conversationId];
      if (conversation?.lastMessage?.id == messageId) {
        _conversations[conversation!.id] = _copyConversation(
          conversation,
          lastMessage: updated,
        );
        _publishConversations();
      }
      _messageEvents.add(updated.copyWith(isUpdate: true));
      return;
    }
  }

  /// Adds (or replaces) a friend without going through a request.
  void addFakeFriend(Friend friend) {
    _friends[friend.publicKey] = friend;
    _publishFriends();
    final Conversation? existing =
        _conversations[FakeChatService.c2cConversationId(friend.publicKey)];
    if (existing != null && existing.title != friend.displayName) {
      _conversations[existing.id] = _copyConversation(
        existing,
        title: friend.displayName,
      );
      _publishConversations();
    }
  }

  /// Toggles a friend's connection; coming online flushes pending messages
  /// to `sent`, exactly what the Tox transport does.
  void setFriendOnline(String publicKey, bool online) {
    final Friend? friend = _friends[publicKey];
    if (friend == null) return;
    _friends[publicKey] = friend.copyWith(online: online);
    _publishFriends();
    if (!online) return;
    final List<ChatMessage> pending =
        (_messages[FakeChatService.c2cConversationId(publicKey)] ??
                const <ChatMessage>[])
            .where((m) => m.isMine && m.status == MessageStatus.pending)
            .toList();
    for (final ChatMessage m in pending) {
      _setStatus(m.id, MessageStatus.sent);
    }
  }

  /// Toggles a group's transport; while down, sends stay pending, and
  /// coming back flushes them to `sent` (Tim2Tox's group outbox).
  void setGroupConnected(String groupId, bool connected) {
    if (!connected) {
      _disconnectedGroups.add(groupId);
      return;
    }
    if (!_disconnectedGroups.remove(groupId)) return;
    final List<ChatMessage> pending =
        (_messages[FakeChatService.groupConversationId(groupId)] ??
                const <ChatMessage>[])
            .where((m) => m.isMine && m.status == MessageStatus.pending)
            .toList();
    for (final ChatMessage m in pending) {
      _setStatus(m.id, MessageStatus.sent);
    }
  }

  /// Marks one of our messages as failed (emits a status event).
  void failMessage(String messageId) =>
      _setStatus(messageId, MessageStatus.failed);

  /// The transport claimed one of our pending messages (it is now
  /// `sending`): cancelling it reports `stateChanged`.
  void claimMessage(String messageId) =>
      _setStatus(messageId, MessageStatus.sending);

  /// Delivers an inbound message; bumps the conversation's unread count.
  /// From a blocked sender it is dropped like the transport drops it: the
  /// row is returned but never stored, counted or emitted.
  ChatMessage receiveMessage(
    String conversationId,
    String text, {
    String? senderId,
    String? senderName,
    DateTime? timestamp,
  }) {
    final Conversation? conversation =
        _conversations[conversationId] ?? _materialize(conversationId);
    if (conversation == null) {
      throw ChatException(
        'conversation_not_found',
        'No conversation $conversationId',
      );
    }
    final String sender = senderId ?? conversation.peerId;
    final ChatMessage message = ChatMessage(
      id: _nextId('msg'),
      conversationId: conversationId,
      senderId: sender,
      senderName: senderName ?? _friends[sender]?.displayName,
      text: text,
      timestamp: timestamp ?? _clock(),
      status: MessageStatus.received,
      isMine: false,
    );
    if (_isBlocked(sender)) return message;
    _append(conversation, message, unreadDelta: 1);
    return message;
  }

  /// Adds (or replaces) a member of [groupId] and bumps the group's
  /// [Group.memberCount] to match, as a peer joining the NGC group would.
  void addFakeGroupMember(String groupId, GroupMember member) {
    final Group group = _requireGroup(groupId);
    final List<GroupMember> members = _members.putIfAbsent(
      groupId,
      () => <GroupMember>[_selfMember()],
    );
    members.removeWhere((m) => m.publicKey == member.publicKey);
    members.add(member);
    _groups[groupId] = Group(
      id: group.id,
      name: group.name,
      kind: group.kind,
      chatId: group.chatId,
      memberCount: members.length,
      topic: group.topic,
    );
    _groupChanges.add(groups);
  }

  /// Dropped when [publicKey] is blocked.
  void receiveFriendRequest(String publicKey, {String message = 'CQ CQ'}) {
    if (_isBlocked(publicKey)) return;
    _friendRequests.add(
      FriendRequest(
        publicKey: publicKey,
        message: message,
        receivedAt: _clock(),
      ),
    );
    _friendRequestChanges.add(friendRequests);
  }

  GroupInvite receiveGroupInvite({
    required String fromPublicKey,
    required String groupName,
    GroupKind kind = GroupKind.group,
  }) {
    final GroupInvite invite = GroupInvite(
      inviteId: _nextId('inv'),
      fromPublicKey: fromPublicKey,
      groupName: groupName,
      kind: kind,
    );
    // Dropped (returned but never listed) when the inviter is blocked.
    if (_isBlocked(fromPublicKey)) return invite;
    _groupInvites.add(invite);
    _groupInviteChanges.add(groupInvites);
    return invite;
  }

  /// Installs a group (and its conversation) as if we were already a member.
  Group addFakeGroup(Group group, {List<GroupMember>? members}) {
    _installGroup(group);
    if (members != null) {
      _members[group.id] = List<GroupMember>.of(members);
      _groups[group.id] = Group(
        id: group.id,
        name: group.name,
        kind: group.kind,
        chatId: group.chatId,
        memberCount: members.length,
        topic: group.topic,
      );
      _groupChanges.add(groups);
    }
    return _groups[group.id]!;
  }
}

/// Group bookkeeping shared by the service and the hooks above.
extension _FakeGroups on FakeChatService {
  GroupMember _selfMember() =>
      GroupMember(publicKey: selfPublicKey, displayName: 'Me', isSelf: true);

  Group _installGroup(Group group) {
    _groups[group.id] = group;
    _members[group.id] = <GroupMember>[_selfMember()];
    _groupChanges.add(groups);
    final String cid = FakeChatService.groupConversationId(group.id);
    _conversations[cid] = Conversation(
      id: cid,
      kind: ConversationKind.group,
      title: group.name,
    );
    _publishConversations();
    return group;
  }

  /// Normalised [chatId], or `invalid_chat_id` unless it is 64 hex chars.
  String _requireValidChatId(String chatId) {
    final String id = chatId.trim().toUpperCase();
    if (!FakeChatService.isValidChatId(id)) {
      throw const ChatException(
        'invalid_chat_id',
        'Chat id must be 64 hex chars',
      );
    }
    return id;
  }

  Group _requireGroup(String groupId) {
    final Group? group = _groups[groupId];
    if (group == null) {
      throw ChatException('group_not_found', 'No group $groupId');
    }
    return group;
  }

  GroupInvite _takeInvite(String inviteId) {
    final int index = _groupInvites.indexWhere((i) => i.inviteId == inviteId);
    if (index < 0) {
      throw const ChatException('invite_not_found', 'No such group invite');
    }
    final GroupInvite invite = _groupInvites.removeAt(index);
    _groupInviteChanges.add(groupInvites);
    return invite;
  }
}

String _shortKey(String publicKey) =>
    publicKey.length > 8 ? publicKey.substring(0, 8) : publicKey;

Conversation _copyConversation(
  Conversation c, {
  String? title,
  ChatMessage? lastMessage,
  int? unreadCount,
  bool? pinned,
  String? draft,
}) => Conversation(
  id: c.id,
  kind: c.kind,
  title: title ?? c.title,
  lastMessage: lastMessage ?? c.lastMessage,
  unreadCount: unreadCount ?? c.unreadCount,
  pinned: pinned ?? c.pinned,
  draft: draft ?? c.draft,
  isSelf: c.isSelf,
);

String _fakeChatIdFor(String groupId) {
  final String hex = groupId.codeUnits
      .map((c) => c.toRadixString(16).padLeft(2, '0'))
      .join()
      .toUpperCase();
  return (hex * (64 ~/ hex.length + 1)).substring(0, 64);
}

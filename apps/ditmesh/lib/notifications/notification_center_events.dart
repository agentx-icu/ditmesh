part of 'notification_center.dart';

/// Converts inbound chat and conversation events into platform notifications.
extension _NotificationEvents on NotificationCenter {
  void _onMessage(ChatMessage message) {
    if (message.isMine ||
        message.isUpdate ||
        message.status != MessageStatus.received) {
      return;
    }
    final String id = message.conversationId;
    if (_isForeground.value && _activeConversation == id) return;
    if (!_prefs.enabled || _prefs.isMuted(id)) return;

    final Conversation? conversation = _conversationFor(id);
    final bool isGroup =
        (conversation?.kind ?? NotificationComposer.kindFromId(id)) ==
        ConversationKind.group;
    final String title =
        conversation?.title ??
        (isGroup
            ? NotificationComposer.shortKey(NotificationComposer.peerFromId(id))
            : NotificationComposer.senderLabel(message));

    final List<ChatMessage> recent = _inbox.putIfAbsent(
      id,
      () => <ChatMessage>[],
    );
    recent.add(message);
    if (recent.length > NotificationComposer.maxInboxLines) {
      recent.removeRange(0, recent.length - NotificationComposer.maxInboxLines);
    }
    final int generation = _ledger.posted(id, message);
    unawaited(
      _post(
        () => _composer.message(
          message: message,
          title: title,
          isGroup: isGroup,
          lines: [
            for (final m in recent) _composer.inboxLine(m, isGroup: isGroup),
          ],
        ),
        stillWanted: () =>
            !_prefs.isMuted(id) && _ledger.isCurrent(id, generation),
      ),
    );
  }

  void _onFriendRequests(List<FriendRequest> requests) {
    final DateTime? since = _startedAt;
    final Set<String> current = <String>{};
    for (final FriendRequest request in requests) {
      current.add(request.publicKey);
      final bool fresh = since != null && !request.receivedAt.isBefore(since);
      if (_knownFriendRequests.add(request.publicKey) &&
          fresh &&
          _prefs.enabled) {
        final String key = request.publicKey;
        unawaited(
          _post(
            () => _composer.friendRequest(request),
            stillWanted: () => _knownFriendRequests.contains(key),
          ),
        );
      }
    }
    // Answered (or withdrawn) requests: forget them so a repeat notifies
    // again, and take their banner down.
    for (final String gone in _knownFriendRequests.difference(current)) {
      unawaited(_cancel(FriendRequestTarget(gone, account: _account).encode()));
    }
    _knownFriendRequests
      ..clear()
      ..addAll(current);
  }

  void _onGroupInvites(List<GroupInvite> invites) {
    final Set<String> current = <String>{};
    for (final GroupInvite invite in invites) {
      current.add(invite.inviteId);
      if (_knownInvites.add(invite.inviteId) && _prefs.enabled) {
        final String inviteId = invite.inviteId;
        unawaited(
          _post(
            () => _composer.groupInvite(
              invite,
              fromName: _friendName(invite.fromPublicKey),
            ),
            stillWanted: () => _knownInvites.contains(inviteId),
          ),
        );
      }
    }
    for (final String gone in _knownInvites.difference(current)) {
      unawaited(_cancel(GroupInviteTarget(gone, account: _account).encode()));
    }
    _knownInvites
      ..clear()
      ..addAll(current);
  }

  void _onConversations(List<Conversation> conversations) {
    var total = 0;
    final Set<String> live = <String>{};
    for (final Conversation conversation in conversations) {
      live.add(conversation.id);
      total += conversation.unreadCount;
      // Read in-app (markRead) or from another surface: drop the banner.
      if (_inbox.containsKey(conversation.id) &&
          _ledger.showsRead(conversation)) {
        unawaited(_clearConversation(conversation.id));
      }
    }
    // Deleted conversations: drop their banners (a materialised list:
    // _clearConversation mutates _inbox synchronously).
    for (final String id in _ledger.deleted(_inbox.keys, live)) {
      unawaited(_clearConversation(id));
    }
    _updateBadge(total);
  }
}

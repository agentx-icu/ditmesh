part of 'fake_chat_service.dart';

/// The fake's note-to-self conversation, bound to the [IdentityService] given
/// to the constructor: seeded from `current` (its `identityChanges` does not
/// replay), then following creation, rename, replacement and removal. Without
/// an identity service there is no self conversation, as before.
extension _FakeSelfConversation on FakeChatService {
  void _followIdentity(IdentityService identity) {
    _bindSelf(identity.current);
    _identitySub = identity.identityChanges.listen(_bindSelf);
  }

  void _bindSelf(Identity? identity) {
    if (_disposed) return;
    // Deleted (null) or replaced by another key: the old chat state goes.
    if (_selfBound &&
        (identity == null || identity.publicKey != _selfKey)) {
      _resetForReplacement();
    }
    final String? previous = selfConversationId;
    _selfBound = identity != null;
    if (identity != null) {
      _selfKey = identity.publicKey;
      _selfName = identity.displayName;
    }
    final String? next = selfConversationId;
    if (previous != null && previous != next) {
      // The notes belonged to that identity: removing or replacing it erases
      // them, so restoring the same key later cannot resurrect them.
      _conversations.remove(previous);
      _messages.remove(previous);
    }
    if (next != null) {
      final Conversation? existing = _conversations[next];
      _conversations[next] = existing == null
          ? _selfConversation()
          : _copyConversation(existing, title: _selfName);
    }
    _publishConversations();
  }

  Conversation _selfConversation() => Conversation(
    id: selfConversationId!,
    kind: ConversationKind.c2c,
    title: _selfName,
    isSelf: true,
  );

  /// Like the backend: a c2c send other than the note to self needs a
  /// friend (`not_friend`) who is not blocked (`peer_blocked`).
  void _requireFriendTarget(String conversationId) {
    if (!conversationId.startsWith('c2c_')) return;
    final String peer = conversationId.substring(4).toUpperCase();
    if (peer == _selfKey.toUpperCase()) return;
    if (_isBlocked(peer)) {
      throw const ChatException('peer_blocked', 'Unblock them first');
    }
    if (!_friends.keys.any((k) => k.toUpperCase() == peer)) {
      throw const ChatException('not_friend', 'Not in your friend list');
    }
  }

  /// Whether [id] is the note to self, which `deleteConversation` refuses.
  bool _isSelfConversation(String id) => _selfBound && id == selfConversationId;
}

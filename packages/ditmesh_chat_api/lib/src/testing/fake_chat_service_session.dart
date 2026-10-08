part of 'fake_chat_service.dart';

/// The fake's model of a chat session, as the Tox backend has it: a session
/// exists from `IdentityService.connect` until `disconnect` (connecting
/// counts; network drop-outs do not end it). Without one, operations other
/// than pin / draft throw `not_connected`. A fake built without an identity
/// service is always in session; a disposed one never is.
extension _FakeSession on FakeChatService {
  bool get _sessionUp {
    if (_disposed) return false;
    final IdentityService? identity = _identityService;
    return identity == null ||
        identity.connectionStatus != ConnectionStatus.offline;
  }

  /// Waits for [FakeChatService.holdAnswers] (if set), then re-checks that
  /// the same session is still up: an answer must not land on a replacement
  /// identity that connected meanwhile.
  Future<void> _holdAnswer() async {
    final int generation = _sessionGeneration;
    await holdAnswers?.future;
    if (generation != _sessionGeneration) {
      throw const ChatException(
        'not_connected',
        'Chat disconnected before the answer could be sent',
      );
    }
    _requireSession();
  }

  void _requireSession() {
    if (_sessionUp) return;
    throw const ChatException(
      'not_connected',
      'Chat is not connected (call IdentityService.connect first)',
    );
  }

  void _followSession(IdentityService identity) {
    _connectionSub = identity.connectionChanges.listen((status) {
      if (_disposed) return;
      if (status == ConnectionStatus.offline) _sessionGeneration++;
      _publishAll();
    });
  }

  /// Every list, as the getters show it now (empty without a session).
  void _publishAll() {
    if (_sessionChanges.value != _sessionUp) _sessionChanges.add(_sessionUp);
    _friendChanges.add(friends);
    _friendRequestChanges.add(friendRequests);
    _groupChanges.add(groups);
    _groupInviteChanges.add(groupInvites);
    _blockedChanges.add(blockedPeers);
    _publishConversations();
  }

  /// The identity was deleted or replaced: like the backend's reset,
  /// nothing of the old identity's chat state survives.
  void _resetForReplacement() {
    _sessionGeneration++;
    _friends.clear();
    _friendRequests.clear();
    _conversations.clear();
    _messages.clear();
    _groups.clear();
    _members.clear();
    _groupInvites.clear();
    _hidden.clear();
    _disconnectedGroups.clear();
    _blocked.clear();
    _joins.passwords.clear();
    outgoingFriendRequests.clear();
    _friendChanges.add(friends);
    _friendRequestChanges.add(friendRequests);
    _groupChanges.add(groups);
    _groupInviteChanges.add(groupInvites);
    _blockedChanges.add(blockedPeers);
  }
}

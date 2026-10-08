part of 'fake_chat_service.dart';

/// Blocking for [FakeChatService], with the transport's semantics
/// ([ChatService.blockedPeers]): a local hide. Rows already stored stay in
/// `_messages` (so an unblock shows them again) and every read filters them;
/// inbound messages, requests and invites from a blocked key are dropped by
/// the test hooks. A mixin in a part file keeps the service under the
/// 500-line gate.
mixin _FakeBlocking implements ChatService {
  Map<String, Friend> get _friends;
  List<FriendRequest> get _friendRequests;
  List<GroupInvite> get _groupInvites;
  Map<String, List<ChatMessage>> get _messages;
  String get selfPublicKey;
  void _requireSession();
  void _publishFriends();
  void _publishBlocking();

  final Set<String> _blocked = <String>{};
  late final ReplaySubject<Set<String>> _blockedChanges =
      ReplaySubject<Set<String>>(const <String>{});

  @override
  Set<String> get blockedPeers =>
      hasSession ? Set<String>.unmodifiable(_blocked) : const <String>{};

  @override
  Stream<Set<String>> get blockedPeerChanges => _blockedChanges.stream;

  bool _isBlocked(String key) => _blocked.contains(key.toUpperCase());

  /// The rows of [conversationId] a reader may see: everything except what
  /// a blocked peer sent.
  List<ChatMessage> _visibleRows(String conversationId) => [
    for (final m in _messages[conversationId] ?? const <ChatMessage>[])
      if (m.isMine || !_isBlocked(m.senderId)) m,
  ];

  String _blockKey(String publicKey) {
    final String id = publicKey.trim().toUpperCase();
    final String key = id.length == 76 ? id.substring(0, 64) : id;
    if (!RegExp(r'^[0-9A-F]{64}$').hasMatch(key)) {
      throw const ChatException('invalid_tox_id', 'Not a Tox public key');
    }
    if (key == selfPublicKey.toUpperCase()) {
      throw const ChatException('own_id', 'That is your own Tox ID');
    }
    return key;
  }

  @override
  Future<void> blockPeer(String publicKey) async {
    _requireSession();
    final String key = _blockKey(publicKey);
    _blocked.add(key);
    // Like the transport: removing the friend deletes the conversation.
    for (final String k in _friends.keys.toList()) {
      if (k.toUpperCase() == key) await removeFriend(k);
    }
    _friendRequests.removeWhere((r) => r.publicKey.toUpperCase() == key);
    _groupInvites.removeWhere((i) => i.fromPublicKey.toUpperCase() == key);
    _publishFriends();
    _publishBlocking();
  }

  @override
  Future<void> unblockPeer(String publicKey) async {
    _requireSession();
    if (!_blocked.remove(_blockKey(publicKey))) return;
    _publishBlocking();
  }
}

part of 'tim2tox_chat_service.dart';

/// Blocking (App Review 1.2) over Tim2Tox's account-scoped blacklist.
///
/// Tox has no network-level block, so this is a local receive-side hide.
/// Keys are stored once, upper case, in the preferences family Tim2Tox's
/// S29 filter reads; [DitmeshFfiChatService] makes that filter compare case
/// insensitively, and it then drops a blocked peer's C2C texts and files
/// before they are stored. Tim2Tox does not filter friend requests, group
/// invites or group messages, so this part owns those, plus every read this
/// class derives from history (pages, search, previews, unread counts).
///
/// Tox NGC gives each group member a separate key per group, so a group
/// member is blocked by that key (their rows in that group) and a friend by
/// their long-term key; the two are independent.
class _BlockingPart {
  _BlockingPart(this._owner);

  final Tim2ToxChatService _owner;

  /// Upper-case 64-hex keys of the bound session's identity (unmodifiable).
  final ValueStream<Set<String>> blocked = ValueStream(const <String>{});

  /// The session whose stored blacklist [blocked] reflects.
  FfiChatService? _loadedFor;

  /// Block / unblock run one at a time: the preferences adapter's list
  /// update is a read-modify-write.
  Future<void> _tail = Future<void>.value();

  static String _key(String id) => ConversationIds.normalizeKey(id);

  /// Seeds [blocked] synchronously from the cache Tim2Tox hydrated at
  /// login, so the very first events of a session are already filtered.
  /// The mutation chain is NOT reset: an action of the previous session
  /// still running its read-modify-write must finish before the next one
  /// reads (it then fails at its own `_ensureCurrent`).
  void bind(FfiChatService? svc) {
    _loadedFor = null;
    _publish(svc == null ? const <String>{} : svc.blockedUsers);
  }

  void _publish(Iterable<String> ids) {
    final next = {
      for (final id in ids)
        if (ConversationIds.publicKey.hasMatch(_key(id))) _key(id),
    };
    final old = blocked.value;
    if (old.length != next.length || !old.containsAll(next)) {
      blocked.force(Set.unmodifiable(next));
    }
  }

  bool isBlocked(String id) {
    final keys = blocked.value;
    return keys.isNotEmpty && id.isNotEmpty && keys.contains(_key(id));
  }

  /// A history row DitMesh shows: chat text, and not from a blocked peer.
  bool shows(t2t.ChatMessage m) =>
      MessageMapper.isChatText(m) && (m.isSelf || !isBlocked(m.fromUserId));

  /// Re-reads the stored blacklist once per session (the login-time cache
  /// may predate the identity being resolvable), before the first refresh
  /// round publishes requests, invites or conversations.
  Future<void> ensureLoaded(FfiChatService svc) async {
    if (identical(_loadedFor, svc)) return;
    final scope = svc.prefsAccountScopeToxId;
    if (scope == null) return; // identity not resolvable yet: next tick
    final stored = await _owner._prefs.getBlackList(scope);
    if (!_owner._isCurrent(svc)) return;
    _loadedFor = svc;
    _publish(stored);
  }

  String _validated(String publicKey) {
    final key = _key(publicKey.trim());
    if (!ConversationIds.publicKey.hasMatch(key)) {
      throw const ChatException('invalid_tox_id', 'Not a Tox public key');
    }
    if (key == _owner._selfKey) {
      throw const ChatException('own_id', 'That is your own Tox ID');
    }
    return key;
  }

  Future<void> _serialized(Future<void> Function() action) {
    final run = _tail.then((_) => action());
    _tail = run.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return run;
  }

  /// Persists the change, refreshes Tim2Tox's cache from it and publishes
  /// what is stored (the single source of truth).
  Future<void> _store(
    FfiChatService svc,
    Future<void> Function(String scope) write,
  ) async {
    final scope = svc.prefsAccountScopeToxId;
    if (scope == null) {
      throw const ChatException('not_connected', 'No Tox identity yet');
    }
    await write(scope);
    _owner._ensureCurrent(svc);
    await svc.refreshBlockedUsers();
    _owner._ensureCurrent(svc);
    final stored = await _owner._prefs.getBlackList(scope);
    // Never publish one identity's list into another session's view.
    _owner._ensureCurrent(svc);
    _loadedFor = svc;
    _publish(stored);
  }

  /// Blocks [publicKey]. A friend is removed (Tim2Tox deletes the
  /// conversation with them); their pending request and group invites are
  /// declined; both are looked up in native state.
  ///
  /// `async`, so validation errors travel through the Future as in the fake.
  Future<void> block(FfiChatService svc, String publicKey) async {
    final key = _validated(publicKey);
    return _serialized(() async {
      _owner._ensureCurrent(svc);
      // Persist first, so Tim2Tox drops their traffic from here on.
      await _store(svc, (scope) => _owner._prefs.addToBlackList([key], scope));
      // From native state, not the published lists: those may not have
      // been refreshed yet in a new session.
      final friends = _owner._friendsPart;
      final nativeFriends = await svc.getFriendList();
      _owner._ensureCurrent(svc);
      if (nativeFriends.any((f) => _key(f.userId) == key)) {
        await friends.remove(svc, key);
      }
      final nativeRequests = await svc.getFriendApplications();
      _owner._ensureCurrent(svc);
      if (nativeRequests.any((a) => _key(a.userId) == key) ||
          friends.requests.value.any((r) => r.publicKey == key)) {
        await friends.reject(svc, key);
      }
      for (final invite in svc.getPendingGroupInvites()) {
        if (_key(invite.inviterUserId) == key) svc.rejectGroupInvite(invite.id);
      }
      await _republish(svc);
    });
  }

  Future<void> unblock(FfiChatService svc, String publicKey) async {
    final key = _validated(publicKey);
    return _serialized(() async {
      _owner._ensureCurrent(svc);
      await _store(
        svc,
        (scope) => _owner._prefs.removeFromBlackList([key], scope),
      );
      await _republish(svc);
    });
  }

  /// Requests, invites and conversations all depend on the blacklist.
  Future<void> _republish(FfiChatService svc) async {
    _owner._ensureCurrent(svc);
    await _owner._friendsPart.refreshRequests(svc);
    _owner._ensureCurrent(svc);
    await _owner._groupsPart.refreshInvites(svc);
    _owner._ensureCurrent(svc);
    _owner._conversationsPart.rebuild(svc);
  }

  Future<void> close() => blocked.close();
}

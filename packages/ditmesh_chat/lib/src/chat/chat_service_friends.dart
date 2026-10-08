part of 'tim2tox_chat_service.dart';

/// Friends and friend requests: Tim2Tox has no push for presence or new
/// requests, so both are polled on the service tick (toxee's UIKit polls the
/// same two calls every few seconds).
class _FriendsPart {
  _FriendsPart(this._owner);

  final Tim2ToxChatService _owner;

  final ValueStream<List<Friend>> friends = ValueStream(const []);
  final ValueStream<List<FriendRequest>> requests = ValueStream(const []);

  Future<void> _requestTail = Future<void>.value();
  final Map<String, String> _names = {};
  final Set<String> _online = {};

  String? nameOf(String publicKey) => _names[publicKey];

  bool isOnline(String publicKey) => _online.contains(publicKey);

  void reset() {
    _online.clear();
    _names.clear();
    friends.add(const []);
    requests.add(const []);
  }

  Future<void> refresh(FfiChatService svc) async {
    final raw = await svc.getFriendList();
    if (!_owner._isCurrent(svc)) return;
    final next = <Friend>[];
    final onlineNow = <String>{};
    for (final f in raw) {
      final key = ConversationIds.normalizeKey(f.userId);
      if (key.isEmpty) continue;
      // A blocked key is never listed, even if removing the friendship
      // failed natively.
      if (_owner._blockingPart.isBlocked(key)) continue;
      // Peer-chosen: no bidi overrides or control characters in a label.
      final nick = PeerText.singleLine(f.nickName);
      final name = nick.isNotEmpty ? nick : ConversationIds.shortKey(key);
      _names[key] = name;
      if (f.online) onlineNow.add(key);
      next.add(
        Friend(
          publicKey: key,
          displayName: name,
          statusMessage: f.status,
          online: f.online,
        ),
      );
    }
    _online
      ..clear()
      ..addAll(onlineNow);
    next.sort((a, b) {
      if (a.online != b.online) return a.online ? -1 : 1;
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    if (!listEqualsBy(friends.value, next, _sameFriend)) friends.force(next);
    // Never awaited here: an invite waits on a native callback, and the
    // refresh round (presence, requests, add/accept/remove) must not stall
    // behind it.
    _owner._groupsPart.scheduleInviteFlush(svc, onlineNow);
  }

  static bool _sameFriend(Friend a, Friend b) =>
      a.publicKey == b.publicKey &&
      a.displayName == b.displayName &&
      a.statusMessage == b.statusMessage &&
      a.online == b.online;

  Future<void> refreshRequests(FfiChatService svc) =>
      _serializeRequests(svc, () => _refreshRequests(svc), strict: false);

  /// Runs [action] after every earlier request operation. When the session
  /// detached while it waited, a [strict] action (an answer the user gave)
  /// throws `not_connected` instead of silently reporting success; a
  /// background refresh just stops.
  Future<void> _serializeRequests(
    FfiChatService svc,
    Future<void> Function() action, {
    bool strict = true,
  }) {
    final run = _requestTail.then((_) async {
      if (_owner._isCurrent(svc)) {
        await action();
      } else if (strict) {
        throw const ChatException(
          'not_connected',
          'Chat disconnected before the request could be answered',
        );
      }
    });
    _requestTail = run.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return run;
  }

  Future<void> _refreshRequests(FfiChatService svc) async {
    final apps = await svc.getFriendApplications();
    if (!_owner._isCurrent(svc)) return;
    final store = _owner._requestStore;
    final nextByKey = {
      for (final request in store.pending) request.publicKey: request,
    };
    final nativeKeys = <String>{};
    for (final a in apps) {
      final key = ConversationIds.normalizeKey(a.userId);
      if (!ConversationIds.publicKey.hasMatch(key)) continue;
      nativeKeys.add(key);
      final old = nextByKey[key];
      final wording = PeerText.clean(a.wording);
      nextByKey[key] = FriendRequest(
        publicKey: key,
        message: wording,
        receivedAt: old?.message == wording
            ? old!.receivedAt
            : DateTime.now(),
      );
    }
    final fingerprints =
        await _owner._prefs.getStringList('dismissed_friend_applications') ??
        [];
    if (!_owner._isCurrent(svc)) return;
    final dismissed = await store.dismissedKeys(fingerprints);
    if (!_owner._isCurrent(svc)) return;
    final friendKeys = friends.value.map((friend) => friend.publicKey).toSet();
    final blocking = _owner._blockingPart;
    nextByKey.removeWhere(
      (key, _) =>
          friendKeys.contains(key) ||
          dismissed.contains(key) ||
          blocking.isBlocked(key),
    );
    final next = _bounded(nextByKey.values, nativeKeys);
    next.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    if (!listEqualsBy(store.pending, next, _sameRequest)) {
      await store.save(next);
    }
    if (!_owner._isCurrent(svc)) return;
    if (!listEqualsBy(requests.value, next, _sameRequest)) requests.force(next);
  }

  /// Requests come from anyone who knows the address. Everything native
  /// still holds is kept (Tim2Tox bounds that queue itself, and dropping one
  /// here would make it reappear with a fresh arrival time on the next
  /// poll); requests only we remember fill the rest, newest first.
  static const int maxPendingRequests = 100;

  static List<FriendRequest> _bounded(
    Iterable<FriendRequest> all,
    Set<String> nativeKeys,
  ) {
    final live = [
      for (final r in all)
        if (nativeKeys.contains(r.publicKey)) r,
    ];
    final remembered = [
      for (final r in all)
        if (!nativeKeys.contains(r.publicKey)) r,
    ]..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    final room = maxPendingRequests - live.length;
    return [...live, ...remembered.take(room < 0 ? 0 : room)];
  }

  static bool _sameRequest(FriendRequest a, FriendRequest b) =>
      a.publicKey == b.publicKey &&
      a.message == b.message &&
      a.receivedAt == b.receivedAt;

  Future<void> addFriend(
    FfiChatService svc,
    String toxId,
    String message,
  ) async {
    final id = toxId.trim().toUpperCase();
    if (!ToxAddress.isValid(id)) {
      throw const ChatException(
        'invalid_tox_id',
        'A Tox ID is 76 hexadecimal characters with a valid checksum',
      );
    }
    final key = ConversationIds.normalizeKey(id);
    if (key == _owner._selfKey) {
      throw const ChatException('own_id', 'That is your own Tox ID');
    }
    if (friends.value.any((f) => f.publicKey == key)) {
      throw const ChatException(
        'already_friend',
        'Already in your friend list',
      );
    }
    if (_owner._blockingPart.isBlocked(key)) {
      throw const ChatException('peer_blocked', 'Unblock them first');
    }
    final result = await svc.addFriend(id, requestMessage: message);
    if (!result.isSuccess) {
      final code = result.resultCode;
      // V2TIM 30515: the peer is already a friend; 30539: request pending.
      if (code == 30515) {
        throw const ChatException(
          'already_friend',
          'Already in your friend list',
        );
      }
      throw ChatException(
        'add_friend_failed',
        result.resultInfo.isEmpty
            ? 'Friend request failed ($code)'
            : result.resultInfo,
      );
    }
    _owner._ensureCurrent(svc);
    await refresh(svc);
    _owner._ensureCurrent(svc);
    _owner._conversationsPart.rebuild(svc);
  }

  Future<void> accept(FfiChatService svc, String publicKey) =>
      _serializeRequests(svc, () => _accept(svc, publicKey));

  Future<void> _accept(FfiChatService svc, String publicKey) async {
    final key = ConversationIds.normalizeKey(publicKey);
    try {
      await svc.acceptFriendRequest(key);
    } on StateError catch (e) {
      throw ChatException('accept_failed', e.message);
    }
    _owner._ensureCurrent(svc);
    final store = _owner._requestStore;
    await store.save(store.pending.where((r) => r.publicKey != key).toList());
    _owner._ensureCurrent(svc);
    await refresh(svc);
    await _refreshRequests(svc);
    _owner._ensureCurrent(svc);
    _owner._conversationsPart.rebuild(svc);
  }

  Future<void> reject(FfiChatService svc, String publicKey) =>
      _serializeRequests(svc, () => _reject(svc, publicKey));

  Future<void> _reject(FfiChatService svc, String publicKey) async {
    final key = ConversationIds.normalizeKey(publicKey);
    final store = _owner._requestStore;
    // Keyed by sender alone: rewording the request must not bring a
    // rejected sender back into the inbox.
    await store.dismiss(
      key,
      tim2toxFingerprints:
          await _owner._prefs.getStringList('dismissed_friend_applications') ??
          const [],
    );
    _owner._ensureCurrent(svc);
    await svc.refuseFriendApplication(key);
    _owner._ensureCurrent(svc);
    await store.save(store.pending.where((r) => r.publicKey != key).toList());
    _owner._ensureCurrent(svc);
    await _refreshRequests(svc);
  }

  Future<void> remove(FfiChatService svc, String publicKey) async {
    final key = ConversationIds.normalizeKey(publicKey);
    await svc.removeFriend(key);
    _owner._ensureCurrent(svc);
    _names.remove(key);
    _online.remove(key);
    await _owner._forgetMeta(svc, ConversationIds.c2c(key));
    await refresh(svc);
    _owner._ensureCurrent(svc);
    _owner._conversationsPart.rebuild(svc);
  }

  Future<void> close() => Future.wait([friends.close(), requests.close()]);
}

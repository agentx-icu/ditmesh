part of 'tim2tox_chat_service.dart';

/// Groups and group invites. Membership lives in Tim2Tox (`knownGroups`,
/// persisted through the preferences adapter and rebound to Tox on every
/// start); names and kinds come from the network first (`sharedGroupName`,
/// `group_type_*`) and our own records second.
class _GroupsPart {
  _GroupsPart(this._owner);

  final Tim2ToxChatService _owner;

  final ValueStream<List<Group>> groups = ValueStream(const []);
  final ValueStream<List<GroupInvite>> invites = ValueStream(const []);
  final Map<String, int> _memberCounts = {};

  /// After a failed queued invite, the pair is not retried before this.
  static const Duration inviteRetryBackoff = Duration(seconds: 30);
  final Map<(String, String), DateTime> _inviteRetryAt = {};
  FfiChatService? _flushing;

  void reset() {
    groups.add(const []);
    invites.add(const []);
    // Identity-scoped caches: a new identity must not see these.
    _memberCounts.clear();
    _inviteRetryAt.clear();
    _flushing = null;
  }

  static GroupKind _kindOf(String? type) =>
      type == 'conference' || type == 'av_conference'
          ? GroupKind.conference
          : GroupKind.group;

  Future<String> _nameOf(FfiChatService svc, String id) async {
    // The network name is chosen by whoever created the group.
    final shared = PeerText.singleLine(svc.sharedGroupName(id) ?? '');
    if (shared.isNotEmpty) return shared;
    final local = await _owner._prefs.getGroupName(id);
    if (local != null && local.trim().isNotEmpty) return local.trim();
    return id;
  }

  Future<Group> _describe(FfiChatService svc, String id) async {
    final kind = _kindOf(await _owner._prefs.getGroupType(id));
    return Group(
      id: id,
      name: await _nameOf(svc, id),
      kind: kind,
      chatId: kind == GroupKind.group ? svc.getGroupChatId(id) : null,
      memberCount: _memberCounts[id] ?? 0,
    );
  }

  Future<void> refresh(FfiChatService svc) async {
    final ids = svc.knownGroups.toList()..sort();
    final next = <Group>[for (final id in ids) await _describe(svc, id)];
    if (!_owner._isCurrent(svc)) return;
    if (!listEqualsBy(groups.value, next, _sameGroup)) groups.force(next);
  }

  static bool _sameGroup(Group a, Group b) =>
      a.id == b.id &&
      a.name == b.name &&
      a.kind == b.kind &&
      a.chatId == b.chatId &&
      a.memberCount == b.memberCount &&
      a.topic == b.topic;

  Future<void> refreshInvites(FfiChatService svc) async {
    final blocking = _owner._blockingPart;
    final next = <GroupInvite>[
      for (final i in svc.getPendingGroupInvites())
        if (!blocking.isBlocked(i.inviterUserId))
          GroupInvite(
            inviteId: i.id,
            fromPublicKey: ConversationIds.normalizeKey(i.inviterUserId),
            groupName: PeerText.singleLine(i.groupName),
            kind: _kindOf(i.kind),
          ),
    ];
    if (!listEqualsBy(invites.value, next, _sameInvite)) invites.force(next);
  }

  static bool _sameInvite(GroupInvite a, GroupInvite b) =>
      a.inviteId == b.inviteId &&
      a.fromPublicKey == b.fromPublicKey &&
      a.groupName == b.groupName &&
      a.kind == b.kind;

  void onJoinFailure(GroupJoinFailure f) {
    _owner._logger.warn(
      '[Chat] group join refused: ${f.groupId} (${f.reason.name})',
    );
    final svc = _owner._service;
    if (svc == null) return;
    unawaited(
      refresh(svc).catchError((Object e, StackTrace st) {
        _owner._logger.error('[Chat] group refresh after join failure', e, st);
      }),
    );
  }

  Future<Group> create(FfiChatService svc, String name, GroupKind kind) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ChatException('invalid_name', 'Group name is empty');
    }
    final id = await svc.createGroup(trimmed, groupType: kind.name);
    if (id == null || id.isEmpty) {
      throw const ChatException('create_group_failed', 'Tox refused the group');
    }
    _owner._ensureCurrent(svc);
    await _owner._prefs.setGroupName(id, trimmed);
    _owner._ensureCurrent(svc);
    await _owner._prefs.setGroupType(id, kind.name);
    _owner._ensureCurrent(svc);
    await refresh(svc);
    _owner._ensureCurrent(svc);
    _owner._conversationsPart.rebuild(svc);
    return groups.value.firstWhere(
      (g) => g.id == id,
      orElse: () => Group(id: id, name: trimmed, kind: kind),
    );
  }

  Future<void> join(FfiChatService svc, String chatId, String? password) async {
    final id = chatId.trim().toUpperCase();
    if (!ConversationIds.publicKey.hasMatch(id)) {
      throw const ChatException(
        'invalid_chat_id',
        'A group chat id is 64 hexadecimal characters',
      );
    }
    try {
      await svc.joinGroup(id.toLowerCase(), password: password);
    } on GroupAlreadyJoinedException {
      throw const ChatException('already_joined', 'Already a member of that group');
    } on StateError catch (e) {
      throw ChatException('join_failed', e.message);
    }
    _owner._ensureCurrent(svc);
    await refresh(svc);
  }

  Future<void> invite(FfiChatService svc, String groupId, String friendPublicKey) async {
    if (!svc.knownGroups.contains(groupId)) {
      throw const ChatException('group_not_found', 'Not a member of that group');
    }
    final key = ConversationIds.normalizeKey(friendPublicKey);
    if (!_owner._friendsPart.isOnline(key)) {
      // Tim2Tox's own offline-invite replay goes through TIMGroupManager,
      // which needs TIMManager.initSDK (never called headless), so the queue
      // is ours: drained by _FriendsPart when the friend comes online.
      await _owner._meta.queueInvite(groupId, key);
      return;
    }
    if (!await GroupBindings.invite(groupId, key)) {
      throw const ChatException('invite_failed', 'Tox refused the invite');
    }
  }

  /// Sends the invites queued for any of [onlineKeys] in the background,
  /// one flush at a time. Called on every refresh round (not only when a
  /// friend comes online), so an invite that failed is retried while the
  /// friend stays online, after [inviteRetryBackoff].
  void scheduleInviteFlush(FfiChatService svc, Set<String> onlineKeys) {
    if (identical(_flushing, svc)) return;
    final due = [
      for (final key in onlineKeys)
        if (_owner._meta.queuedGroupsFor(key).isNotEmpty) key,
    ];
    if (due.isEmpty) return;
    _flushing = svc;
    unawaited(() async {
      try {
        for (final key in due) {
          if (!_owner._isCurrent(svc)) return;
          await flushQueuedInvites(svc, key);
        }
      } catch (e, st) {
        _owner._logger.error('[Chat] queued invite flush failed', e, st);
      } finally {
        if (identical(_flushing, svc)) _flushing = null;
      }
    }());
  }

  Future<void> flushQueuedInvites(FfiChatService svc, String friendKey) async {
    final now = DateTime.now();
    for (final groupId in _owner._meta.queuedGroupsFor(friendKey)) {
      final retryAt = _inviteRetryAt[(groupId, friendKey)];
      if (retryAt != null && now.isBefore(retryAt)) continue;
      // Re-checked every iteration: after a detach the loop must neither
      // keep inviting through the native bindings nor edit the queue, which
      // by then may belong to a newly selected identity.
      if (!_owner._isCurrent(svc)) return;
      if (!svc.knownGroups.contains(groupId)) {
        await _owner._meta.dequeueInvite(groupId, friendKey);
        continue;
      }
      var invited = false;
      try {
        invited = await GroupBindings.invite(groupId, friendKey);
        if (!_owner._isCurrent(svc)) return;
        if (invited) {
          _inviteRetryAt.remove((groupId, friendKey));
          await _owner._meta.dequeueInvite(groupId, friendKey);
        }
      } catch (e, st) {
        _owner._logger.error('[Chat] queued group invite failed', e, st);
      }
      if (!invited) {
        _inviteRetryAt[(groupId, friendKey)] = DateTime.now().add(
          inviteRetryBackoff,
        );
      }
    }
  }

  Future<void> acceptInvite(FfiChatService svc, String inviteId, String? password) async {
    try {
      await svc.acceptGroupInvite(inviteId, password: password);
    } on StateError catch (e) {
      throw ChatException('accept_failed', e.message);
    }
    _owner._ensureCurrent(svc);
    await refreshInvites(svc);
    await refresh(svc);
  }

  Future<void> rejectInvite(FfiChatService svc, String inviteId) async {
    svc.rejectGroupInvite(inviteId);
    await refreshInvites(svc);
  }

  Future<List<GroupMember>> members(FfiChatService svc, String groupId) async {
    if (!svc.knownGroups.contains(groupId)) {
      throw const ChatException('group_not_found', 'Not a member of that group');
    }
    final list = await GroupBindings.members(
      groupId,
      selfKey: _owner._selfKey,
      nameOf: _owner._friendsPart.nameOf,
    );
    _owner._ensureCurrent(svc);
    _memberCounts[groupId] = list.length;
    return list;
  }

  Future<void> leave(FfiChatService svc, String groupId) async {
    try {
      // Routed through the Tencent DartQuitGroup binding by Tim2Tox.
      await svc.quitGroup(groupId);
    } catch (e) {
      throw ChatException('leave_failed', 'Could not leave the group: $e');
    }
    _owner._ensureCurrent(svc);
    _memberCounts.remove(groupId);
    await _owner._forgetMeta(svc, ConversationIds.group(groupId));
    await refresh(svc);
    _owner._ensureCurrent(svc);
    _owner._conversationsPart.rebuild(svc);
  }

  Future<void> close() => Future.wait([groups.close(), invites.close()]);
}

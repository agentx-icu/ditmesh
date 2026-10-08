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
  final StreamController<GroupJoinRefusal> refusals =
      StreamController<GroupJoinRefusal>.broadcast();

  /// Invites declined because their sender was blocked: a refusal of an
  /// earlier accept of one is not reported.
  final Set<String> declinedByBlock = {};
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
    declinedByBlock.clear();
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
    // Never publish a detached session's invites into the next one.
    if (!_owner._isCurrent(svc)) return;
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

  /// A refusal from [svc]'s session: the lists are refreshed (best effort;
  /// the invite of a refused accept is listed again) and the refusal is
  /// published on [refusals] unless the session ended meanwhile or the
  /// invite came from a blocked peer.
  void onJoinFailure(FfiChatService svc, GroupJoinFailure f) {
    _owner._logger.warn(
      '[Chat] group join refused: ${f.groupId} (${f.reason.name})',
    );
    // Correlated now: native hands the refused invite back before it
    // reports the refusal, and a block during the refresh below may drop it.
    final invite = _inviteOf(svc, f);
    unawaited(
      () async {
        try {
          await refresh(svc);
          await refreshInvites(svc);
        } catch (e, st) {
          _owner._logger.error('[Chat] group refresh after join failure', e, st);
        }
        if (!_owner._isCurrent(svc) || refusals.isClosed) return;
        final refusal = await _refusalOf(svc, f, invite);
        final inviter = invite?.inviterUserId;
        if (refusal == null ||
            !_owner._isCurrent(svc) ||
            refusals.isClosed ||
            (inviter != null && _owner._blockingPart.isBlocked(inviter))) {
          return;
        }
        refusals.add(refusal);
      }().catchError((Object e, StackTrace st) {
        _owner._logger.error('[Chat] group join refusal not reported', e, st);
      }),
    );
  }

  /// The chat id an NGC invite leads to (its cookie starts with it), the
  /// way Tim2Tox matches a refused join to the invite it hands back.
  static String? _inviteChatId(PendingGroupInvite i) =>
      i.kind == 'group' && i.cookieHex.length >= 64
          ? i.cookieHex.substring(0, 64).toUpperCase()
          : null;

  /// The pending invite [f] refused. An invite accepted in an earlier
  /// session comes back under its own id while the refusal carries none:
  /// matched by chat id when unambiguous.
  PendingGroupInvite? _inviteOf(FfiChatService svc, GroupJoinFailure f) {
    final pending = svc.getPendingGroupInvites();
    if (f.inviteId.isNotEmpty) {
      return pending.where((i) => i.id == f.inviteId).firstOrNull;
    }
    if (f.chatId.isEmpty || f.established) return null;
    final chatId = f.chatId.toUpperCase();
    final matches = pending.where((i) => _inviteChatId(i) == chatId);
    return matches.length == 1 ? matches.single : null;
  }

  Future<GroupJoinRefusal?> _refusalOf(
    FfiChatService svc,
    GroupJoinFailure f,
    PendingGroupInvite? invite,
  ) async {
    if (declinedByBlock.contains(f.inviteId) ||
        (invite != null &&
            _owner._blockingPart.isBlocked(invite.inviterUserId))) {
      return null;
    }
    // An invite refusal whose invite is no longer listed now (declined,
    // also during the refresh, or never handed back) has no retry: it is
    // reported without one.
    final live =
        invite != null &&
        svc.getPendingGroupInvites().any((i) => i.id == invite.id);
    final orphaned = (f.inviteId.isNotEmpty || invite != null) && !live;
    final chatId = f.chatId.isEmpty || orphaned
        ? null
        : f.chatId.toUpperCase();
    final inviteId = orphaned
        ? null
        : f.inviteId.isNotEmpty
        ? f.inviteId
        : invite?.id;
    var name = PeerText.singleLine(invite?.groupName ?? '');
    if (name.isEmpty && svc.knownGroups.contains(f.groupId)) {
      final known = await _nameOf(svc, f.groupId);
      if (known != f.groupId) name = known;
    }
    return GroupJoinRefusal(
      groupId: f.groupId,
      chatId: chatId,
      inviteId: inviteId,
      groupName: name,
      established: f.established,
      reason: switch (f.reason) {
        GroupJoinFailureReason.invalidPassword =>
          GroupJoinRefusalReason.invalidPassword,
        GroupJoinFailureReason.groupFull => GroupJoinRefusalReason.groupFull,
        GroupJoinFailureReason.unknown => GroupJoinRefusalReason.unknown,
      },
    );
  }

  /// Joins a group we hold again by its own id: native resolves the stored
  /// chat id and rejoins with the new password (a join by chat id would be
  /// refused as a second binding of the same group).
  Future<void> rejoin(FfiChatService svc, String groupId, String? password) async {
    if (!svc.knownGroups.contains(groupId)) {
      throw const ChatException('group_not_found', 'Not a member of that group');
    }
    try {
      await svc.joinGroup(groupId, password: password);
    } on GroupAlreadyJoinedException {
      throw const ChatException('already_joined', 'Already a member of that group');
    } on StateError catch (e) {
      throw ChatException('join_failed', e.message);
    }
    _owner._ensureCurrent(svc);
    await refresh(svc);
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

  Future<void> close() =>
      Future.wait([groups.close(), invites.close(), refusals.close()]);
}

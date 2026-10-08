part of 'fake_chat_service.dart';

/// Group-join state of the fake: the refusal stream and the passwords the
/// test made groups require.
final class _FakeJoinState {
  final StreamController<GroupJoinRefusal> refusals =
      StreamController<GroupJoinRefusal>.broadcast();

  /// Required password per invite id, upper-case chat id or group id.
  final Map<String, String> passwords = <String, String>{};

  Future<void> close() => refusals.close();
}

/// Joins as the Tox transport does them: the call returns once the
/// handshake is under way, and a group that wants a password refuses
/// afterwards, on [FakeChatService.groupJoinRefusals] (an invite is then
/// listed again, unanswered). Set up with [FakeChatServiceJoinHooks].
extension _FakeJoins on FakeChatService {
  bool _passwordMatches(String key, String? password) {
    final String? required = _joins.passwords[key];
    return required == null || required == (password ?? '');
  }

  /// Emits [refusal] after the current call returned, unless the session
  /// ended (or the identity changed) meanwhile; [before] runs first.
  void _refuseLater(GroupJoinRefusal refusal, {void Function()? before}) {
    final int generation = _sessionGeneration;
    scheduleMicrotask(() {
      if (_disposed || generation != _sessionGeneration || !_sessionUp) {
        return;
      }
      before?.call();
      if (!_joins.refusals.isClosed) _joins.refusals.add(refusal);
    });
  }

  Future<void> _join(String chatId, String? password) async {
    _requireSession();
    final String id = _requireValidChatId(chatId);
    if (_groups.values.any((g) => g.chatId == id)) {
      throw const ChatException('already_joined', 'Already in that group');
    }
    final String groupId = _nextId('tox');
    if (!_passwordMatches(id, password)) {
      _refuseLater(
        GroupJoinRefusal(
          groupId: groupId,
          chatId: id,
          reason: GroupJoinRefusalReason.invalidPassword,
        ),
      );
      return;
    }
    _installGroup(
      Group(
        id: groupId,
        name: 'Group ${id.substring(0, 8)}',
        kind: GroupKind.group,
        chatId: id,
        memberCount: 1,
      ),
    );
  }

  Future<void> _accept(String inviteId, String? password) async {
    _requireSession();
    await _holdAnswer();
    final GroupInvite invite = _takeInvite(inviteId);
    final String id = _nextId('tox');
    if (!_passwordMatches(inviteId, password)) {
      _refuseLater(
        GroupJoinRefusal(
          groupId: id,
          inviteId: inviteId,
          groupName: invite.groupName,
          reason: GroupJoinRefusalReason.invalidPassword,
        ),
        before: () {
          _groupInvites.add(invite);
          _groupInviteChanges.add(groupInvites);
        },
      );
      return;
    }
    _installGroup(
      Group(
        id: id,
        name: invite.groupName,
        kind: invite.kind,
        chatId: invite.kind == GroupKind.group
            ? FakeChatService.fakeChatIdFor(id)
            : null,
        memberCount: 2,
      ),
    );
  }

  Future<void> _rejoin(String groupId, String? password) async {
    _requireSession();
    final Group group = _requireGroup(groupId);
    if (_passwordMatches(groupId, password)) return;
    _refuseLater(
      GroupJoinRefusal(
        groupId: groupId,
        chatId: group.chatId,
        groupName: group.name,
        reason: GroupJoinRefusalReason.invalidPassword,
        established: true,
      ),
    );
  }
}

/// Test hooks for group joins that the group refuses.
extension FakeChatServiceJoinHooks on FakeChatService {
  /// Joins of [key] (an invite id, a chat id or a held group's id) are
  /// refused with `invalidPassword` unless they pass [password].
  void requireGroupPassword(String key, String password) {
    final String normalized = FakeChatService.isValidChatId(key)
        ? key.toUpperCase()
        : key;
    _joins.passwords[normalized] = password;
  }

  /// Emits [refusal] now (a full group, a reconnect refusal, ...).
  void refuseGroupJoin(GroupJoinRefusal refusal) {
    if (!_sessionUp || _joins.refusals.isClosed) return;
    _joins.refusals.add(refusal);
  }
}

import 'dart:async';
import 'dart:convert';

import '../chat_service.dart';
import '../identity_service.dart';
import '../message_search.dart';
import '../models.dart';
import '../outbox.dart';
import '../tox_address.dart';
import 'replay_stream.dart';

part 'fake_chat_service_blocking.dart';
part 'fake_chat_service_hooks.dart';
part 'fake_chat_service_messages.dart';
part 'fake_chat_service_rows.dart';
part 'fake_chat_service_self.dart';
part 'fake_chat_service_session.dart';

/// In-memory [ChatService] for widget tests and UI development without a
/// Tox node. Mirrors the Tox transport where the UI can tell: deterministic
/// ids (`msg_1`, `tox_1`, `inv_1`); [sendText] to an offline friend is
/// [MessageStatus.pending] until `setFriendOnline` flips it to `sent` (Tox has
/// no server); [addFriend] adds the friend immediately, offline, like
/// `tox_friend_add`; a `c2c_<pk>` / `group_<id>` conversation not yet in
/// [conversations] is created on first send / draft; every friend and group
/// has a row, like the Tox backend lists them. Given an [identity], the fake
/// also follows its session the way the backend does
/// (`fake_chat_service_session.dart`): without one (`connect` not called)
/// operations other than pin / draft throw `not_connected` and the
/// note-to-self row is not listed; replacing or deleting the identity
/// empties everything. A fake without an identity is always "connected".
/// Test hooks live in [FakeChatServiceTestHooks] (`fake_chat_service_hooks.dart`).
final class FakeChatService
    with _FakeMessageManagement, _FakeBlocking
    implements ChatService {
  FakeChatService({
    String? selfPublicKey,
    IdentityService? identity,
    DateTime Function()? clock,
    this.maxMessageBytes = 1322,
  }) : _selfKey = selfPublicKey ?? identity?.current?.publicKey ?? 'F' * 64,
       _clock = clock ?? DateTime.now {
    if (identity != null) {
      _identityService = identity;
      _followIdentity(identity);
      _followSession(identity);
    }
  }

  IdentityService? _identityService;
  StreamSubscription<ConnectionStatus>? _connectionSub;

  /// Bumped when a session ends or the identity is replaced.
  int _sessionGeneration = 0;

  late final ReplaySubject<bool> _sessionChanges = ReplaySubject<bool>(
    _sessionUp,
  );

  @override
  bool get hasSession => _sessionUp;

  @override
  Stream<bool> get sessionChanges => _sessionChanges.stream;

  /// Conversations removed by [deleteConversation]: not listed again until
  /// the next message, even for a friend.
  final Set<String> _hidden = <String>{};

  /// Groups whose transport is down (`setGroupConnected`): sends stay pending.
  @override
  final Set<String> _disconnectedGroups = <String>{};

  /// When set, friend-request and group-invite answers wait for it (lets a
  /// test catch the UI while an answer is in flight).
  Completer<void>? holdAnswers;

  /// Our own 64-hex public key; `addFriend(<own id>)` throws `own_id`.
  @override
  String get selfPublicKey => _selfKey;
  String _selfKey;
  String _selfName = '';
  bool _selfBound = false;
  StreamSubscription<Identity?>? _identitySub;

  @override
  String? get selfConversationId =>
      _selfBound ? c2cConversationId(_selfKey) : null;

  @override
  final int maxMessageBytes;

  final DateTime Function() _clock;
  int _seq = 0;

  @override
  final Map<String, Friend> _friends = <String, Friend>{};
  @override
  final List<FriendRequest> _friendRequests = <FriendRequest>[];
  @override
  final Map<String, Conversation> _conversations = <String, Conversation>{};
  @override
  final Map<String, List<ChatMessage>> _messages =
      <String, List<ChatMessage>>{};
  final Map<String, Group> _groups = <String, Group>{};
  final Map<String, List<GroupMember>> _members = <String, List<GroupMember>>{};
  @override
  final List<GroupInvite> _groupInvites = <GroupInvite>[];

  /// Tox IDs handed to [addFriend], oldest first (for assertions).
  final List<String> outgoingFriendRequests = <String>[];

  final ReplaySubject<List<Friend>> _friendChanges =
      ReplaySubject<List<Friend>>(const <Friend>[]);
  final ReplaySubject<List<FriendRequest>> _friendRequestChanges =
      ReplaySubject<List<FriendRequest>>(const <FriendRequest>[]);
  final ReplaySubject<List<Conversation>> _conversationChanges =
      ReplaySubject<List<Conversation>>(const <Conversation>[]);
  final ReplaySubject<List<Group>> _groupChanges = ReplaySubject<List<Group>>(
    const <Group>[],
  );
  final ReplaySubject<List<GroupInvite>> _groupInviteChanges =
      ReplaySubject<List<GroupInvite>>(const <GroupInvite>[]);
  final StreamController<ChatMessage> _messageEvents =
      StreamController<ChatMessage>.broadcast();

  bool _disposed = false;

  List<ReplaySubject<Object>> get _subjects => <ReplaySubject<Object>>[
    _friendChanges,
    _friendRequestChanges,
    _conversationChanges,
    _groupChanges,
    _groupInviteChanges,
    _blockedChanges,
  ];

  String _nextId(String prefix) => '${prefix}_${++_seq}';

  // ---- Friends -------------------------------------------------------------

  @override
  List<Friend> get friends => _sessionUp
      ? List<Friend>.unmodifiable(_friends.values)
      : const <Friend>[];

  @override
  Stream<List<Friend>> get friendChanges => _friendChanges.stream;

  @override
  List<FriendRequest> get friendRequests => _sessionUp
      ? List<FriendRequest>.unmodifiable(_friendRequests)
      : const <FriendRequest>[];

  @override
  Stream<List<FriendRequest>> get friendRequestChanges =>
      _friendRequestChanges.stream;

  @override
  Future<void> addFriend(String toxId, {String message = 'ditmesh CQ'}) async {
    _requireSession();
    final String id = toxId.trim().toUpperCase();
    if (!isValidToxId(id)) {
      throw const ChatException(
        'invalid_tox_id',
        'Tox ID must be 76 hex chars',
      );
    }
    final String pk = id.substring(0, 64);
    if (pk == selfPublicKey.toUpperCase()) {
      throw const ChatException('own_id', 'That is your own Tox ID');
    }
    if (_friends.containsKey(pk)) {
      throw const ChatException('already_friend', 'Already a friend');
    }
    if (_isBlocked(pk)) {
      throw const ChatException('peer_blocked', 'Unblock them first');
    }
    outgoingFriendRequests.add(id);
    _friends[pk] = Friend(publicKey: pk, displayName: _shortKey(pk));
    _publishFriends();
  }

  @override
  Future<void> acceptFriendRequest(String publicKey) async {
    _requireSession();
    await _holdAnswer();
    final FriendRequest? request = _takeFriendRequest(publicKey);
    if (request == null) {
      throw const ChatException('accept_failed', 'No such friend request');
    }
    _friends[publicKey] = Friend(
      publicKey: publicKey,
      displayName: _shortKey(publicKey),
    );
    _publishFriends();
  }

  @override
  Future<void> rejectFriendRequest(String publicKey) async {
    _requireSession();
    await _holdAnswer();
    // Like the backend: rejecting an unknown request is a no-op.
    _takeFriendRequest(publicKey);
  }

  @override
  Future<void> removeFriend(String publicKey) async {
    _requireSession();
    if (_friends.remove(publicKey) == null) {
      throw const ChatException('friend_not_found', 'No such friend');
    }
    _publishFriends();
    await deleteConversation(c2cConversationId(publicKey));
  }

  FriendRequest? _takeFriendRequest(String publicKey) {
    final int index = _friendRequests.indexWhere(
      (r) => r.publicKey == publicKey,
    );
    if (index < 0) return null;
    final FriendRequest request = _friendRequests.removeAt(index);
    _friendRequestChanges.add(friendRequests);
    return request;
  }

  /// Friends change the conversation list too (every friend has a row).
  @override
  void _publishFriends() {
    _friendChanges.add(friends);
    _publishConversations();
  }

  // ---- Conversations -------------------------------------------------------

  @override
  List<Conversation> get conversations => _listedConversations();

  @override
  Stream<List<Conversation>> get conversationChanges =>
      _conversationChanges.stream;

  @override
  Future<void> markRead(String conversationId) async {
    _requireSession();
    _updateConversation(
      conversationId,
      (c) => _copyConversation(c, unreadCount: 0),
    );
  }

  @override
  Future<void> setPinned(String conversationId, bool pinned) async {
    _updateConversation(
      conversationId,
      (c) => _copyConversation(c, pinned: pinned),
    );
  }

  @override
  Future<void> setDraft(String conversationId, String draft) async {
    _updateConversation(
      conversationId,
      (c) => _copyConversation(c, draft: draft),
    );
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    if (_isSelfConversation(conversationId)) {
      throw const ChatException(
        'self_conversation',
        'The note-to-self conversation cannot be deleted',
      );
    }
    _requireSession();
    _messages.remove(conversationId);
    _conversations.remove(conversationId);
    _hidden.add(conversationId);
    _publishConversations();
  }

  void _publishConversations() => _conversationChanges.add(conversations);

  // ---- Messages ------------------------------------------------------------

  @override
  Future<List<ChatMessage>> loadHistory(
    String conversationId, {
    int limit = 50,
    DateTime? before,
  }) async {
    _requireSession();
    return _FakeConversationRows(this)._history(conversationId, limit, before);
  }

  @override
  Stream<ChatMessage> get messageEvents => _messageEvents.stream;

  @override
  Future<ChatMessage> sendText(String conversationId, String text) async {
    _requireSession();
    if (utf8.encode(text).length > maxMessageBytes) {
      throw ChatException(
        'message_too_long',
        'Message exceeds $maxMessageBytes bytes',
      );
    }
    if (text.trim().isEmpty) {
      throw const ChatException('empty_message', 'Message is empty');
    }
    final Conversation? conversation =
        _conversations[conversationId] ?? _materialize(conversationId);
    if (conversation == null) {
      throw ChatException(
        'conversation_not_found',
        'No conversation $conversationId',
      );
    }
    final bool delivered =
        conversation.isSelf || // local only: stored, never sent
        (conversation.kind == ConversationKind.group &&
            !_disconnectedGroups.contains(conversation.peerId)) ||
        (_friends[conversation.peerId]?.online ?? false);
    final ChatMessage message = ChatMessage(
      id: _nextId('msg'),
      conversationId: conversationId,
      senderId: selfPublicKey,
      text: text,
      timestamp: _clock(),
      status: delivered ? MessageStatus.sent : MessageStatus.pending,
      isMine: true,
    );
    _append(conversation, message, unreadDelta: 0);
    return message;
  }

  @override
  Future<void> clearHistory(String conversationId) async {
    _requireSession();
    _FakeConversationRows(this)._clear(conversationId);
  }

  @override
  void _publishBlocking() => _FakeConversationRows(this)._publishBlocking();

  /// The session check and status write the message-management mixin
  /// needs (row bookkeeping lives in `fake_chat_service_rows.dart`).
  @override
  void _requireSession() => _FakeSession(this)._requireSession();
  @override
  void _applyStatus(String messageId, MessageStatus status) =>
      _FakeConversationRows(this)._setStatus(messageId, status);

  // ---- Groups --------------------------------------------------------------

  @override
  List<Group> get groups =>
      _sessionUp ? List<Group>.unmodifiable(_groups.values) : const <Group>[];

  @override
  Stream<List<Group>> get groupChanges => _groupChanges.stream;

  @override
  List<GroupInvite> get groupInvites => _sessionUp
      ? List<GroupInvite>.unmodifiable(_groupInvites)
      : const <GroupInvite>[];

  @override
  Stream<List<GroupInvite>> get groupInviteChanges =>
      _groupInviteChanges.stream;

  @override
  Future<Group> createGroup(
    String name, {
    GroupKind kind = GroupKind.group,
  }) async {
    _requireSession();
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ChatException('invalid_name', 'Group name is empty');
    }
    final String id = _nextId('tox');
    return _installGroup(
      Group(
        id: id,
        name: trimmed,
        kind: kind,
        chatId: kind == GroupKind.group ? fakeChatIdFor(id) : null,
        memberCount: 1,
      ),
    );
  }

  @override
  Future<void> joinGroup(String chatId, {String? password}) async {
    _requireSession();
    final String id = _requireValidChatId(chatId);
    if (_groups.values.any((g) => g.chatId == id)) {
      throw const ChatException('already_joined', 'Already in that group');
    }
    _installGroup(
      Group(
        id: _nextId('tox'),
        name: 'Group ${id.substring(0, 8)}',
        kind: GroupKind.group,
        chatId: id,
        memberCount: 1,
      ),
    );
  }

  @override
  /// Like the backend, an invite to someone not online (or not a friend)
  /// is queued rather than refused.
  Future<void> inviteToGroup(String groupId, String friendPublicKey) async {
    _requireSession();
    _requireGroup(groupId);
  }

  @override
  Future<void> acceptGroupInvite(String inviteId, {String? password}) async {
    _requireSession();
    await _holdAnswer();
    final GroupInvite invite = _takeInvite(inviteId);
    final String id = _nextId('tox');
    _installGroup(
      Group(
        id: id,
        name: invite.groupName,
        kind: invite.kind,
        chatId: invite.kind == GroupKind.group ? fakeChatIdFor(id) : null,
        memberCount: 2,
      ),
    );
  }

  @override
  Future<void> rejectGroupInvite(String inviteId) async {
    _requireSession();
    await _holdAnswer();
    _takeInvite(inviteId);
  }

  @override
  Future<List<GroupMember>> groupMembers(String groupId) async {
    _requireSession();
    _requireGroup(groupId);
    return List<GroupMember>.unmodifiable(
      _members[groupId] ?? <GroupMember>[_selfMember()],
    );
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    _requireSession();
    _requireGroup(groupId);
    _groups.remove(groupId);
    _members.remove(groupId);
    _groupChanges.add(groups);
    await deleteConversation(groupConversationId(groupId));
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final Future<void>? identityCancelled = _identitySub?.cancel();
    final Future<void>? connectionCancelled = _connectionSub?.cancel();
    await Future.wait(<Future<void>>[
      ?identityCancelled,
      ?connectionCancelled,
      _sessionChanges.close(),
      for (final ReplaySubject<Object> s in _subjects) s.close(),
      _messageEvents.close(),
    ]);
  }

  static String c2cConversationId(String publicKey) => 'c2c_$publicKey';

  static String groupConversationId(String groupId) => 'group_$groupId';

  /// Same rule as the Tox backend: length, hex and checksum.
  static bool isValidToxId(String value) => ToxAddress.isValid(value);

  static bool isValidChatId(String value) =>
      RegExp(r'^[0-9A-Fa-f]{64}$').hasMatch(value);

  /// Deterministic 64-hex chat id for a fake NGC group.
  static String fakeChatIdFor(String groupId) => _fakeChatIdFor(groupId);
}

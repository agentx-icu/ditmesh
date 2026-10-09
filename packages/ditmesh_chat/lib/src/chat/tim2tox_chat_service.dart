import 'dart:async';
import 'dart:convert';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:meta/meta.dart';
import 'package:tim2tox_dart/models/chat_message.dart' as t2t;
import 'package:tim2tox_dart/models/send_control_result.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

import '../adapters/key_value_store.dart';
import '../adapters/prefs_adapter.dart';
import '../engine/chat_engine.dart';
import '../logging/chat_logger.dart';
import '../util/value_stream.dart';
import 'conversation_meta_store.dart';
import 'friend_request_store.dart';
import 'group_bindings.dart';
import 'history_page.dart';
import 'message_mapper.dart';
import 'recording_metadata.dart';
import '../engine/rhythm_protocol.dart';
import 'pending_message_status.dart';

part 'chat_service_blocking.dart';
part 'chat_service_conversations.dart';
part 'chat_service_friends.dart';
part 'chat_service_groups.dart';
part 'chat_service_messages.dart';
part 'chat_service_send.dart';
part 'chat_service_session.dart';

/// [ChatService] over one live `FfiChatService` (Tim2Tox), following the
/// [ChatEngine]'s session: bound while the identity is connected, detached
/// while it is not.
///
/// Data model: Tim2Tox owns friends, requests, history, the offline queue and
/// group membership; this class owns conversation metadata (pinned, drafts,
/// hidden) and the derivation of the conversation list from all of it.
///
/// Before `IdentityService.connect()` (and after `disconnect()`) every getter
/// and stream works (lists are empty, streams replay), and every mutation
/// throws [ChatException] `not_connected`. Once connected, a send to a friend
/// who is offline on the Tox network is queued by Tim2Tox and surfaces as a
/// `pending` row; it drains when the friend comes back.
class Tim2ToxChatService
    with _MessageManagement
    implements ChatService, IdentityDataStore, OutboxInspector {
  Tim2ToxChatService({
    required ChatEngine engine,
    required IdentityService identity,
    required KeyValueStore store,
    ChatLogger logger = const SilentChatLogger(),
    Duration pollInterval = const Duration(seconds: 3),
  }) : _engine = engine,
       _identity = identity,
       _store = PendingKeyValueStore(store),
       _logger = logger,
       _pollInterval = pollInterval {
    _friendsPart = _FriendsPart(this);
    _groupsPart = _GroupsPart(this);
    _conversationsPart = _ConversationsPart(this);
    _blockingPart = _BlockingPart(this);
    _sessionSub = _engine.sessionChanges.listen(_bindSession);
    _identitySub = identity.identityChanges.listen((value) {
      if (value != null && !identical(value, _replacementIdentity)) {
        final restoring = _replacing;
        _replacing = false;
        final live = _engine.service;
        if (restoring && _service == null && live != null && !_disposed) {
          _bindSession(live);
        }
      }
      // The own display name is the self conversation's title.
      final svc = _service;
      if (value != null && svc != null && _isCurrent(svc)) {
        _conversationsPart.rebuild(svc);
      }
    });
    if (identity is PersistentIdentityService) identity.registerDataStore(this);
  }

  /// Tox single-message budget after Tim2Tox's fragment header. Longer texts
  /// are fragmented by Tim2Tox and arrive as separate messages, which the UI
  /// must avoid (plan §5.2).
  static const int toxMessageBudget = 1322;

  /// Test seam: awaited (instead of a plain event-loop turn) at every chunk
  /// boundary of a history scan, with the phase (`map` or `filter`), so a
  /// test can change the session or the blacklist inside one phase.
  @visibleForTesting
  static Future<void> Function(String phase)? debugScanYield;

  final ChatEngine _engine;
  final IdentityService _identity;
  final PendingKeyValueStore _store;
  final ChatLogger _logger;
  final Duration _pollInterval;

  late final _FriendsPart _friendsPart;
  late final _GroupsPart _groupsPart;
  late final _ConversationsPart _conversationsPart;
  late final _BlockingPart _blockingPart;

  FfiChatService? _service;
  StreamSubscription<FfiChatService?>? _sessionSub;
  StreamSubscription<Identity?>? _identitySub;
  final List<StreamSubscription<Object?>> _serviceSubs = [];
  Timer? _poll;

  /// The session whose refresh round is in flight, or null. Keyed on the
  /// session (not a bool) so a rebind is never starved by the previous
  /// session's unfinished tick: the new session's initial refresh runs at
  /// once, and the old tick's `finally` cannot clear the new session's slot.
  FfiChatService? _ticking;
  bool _disposed = false;
  bool _replacing = false;
  Identity? _replacementIdentity;

  final StreamController<ChatMessage> _messageEvents =
      StreamController<ChatMessage>.broadcast();

  final ValueStream<bool> _session = ValueStream(false);

  @override
  bool get hasSession => _session.value;

  @override
  Stream<bool> get sessionChanges => _session.stream;

  // ---- session binding ------------------------------------------------------

  String get _accountPrefix {
    final toxId = _identity.current?.toxId ?? '';
    return toxId.length >= 16 ? toxId.substring(0, 16).toUpperCase() : toxId;
  }

  ConversationMetaStore get _meta =>
      ConversationMetaStore(_store, accountPrefix: _accountPrefix);

  Tim2ToxPreferencesAdapter get _prefs =>
      Tim2ToxPreferencesAdapter(_store, accountPrefix: _accountPrefix);

  FriendRequestStore get _requestStore =>
      FriendRequestStore(_store, accountPrefix: _accountPrefix);

  String get _selfKey {
    final svc = _service;
    final full = svc?.getSelfToxId() ?? _identity.current?.toxId ?? '';
    return ConversationIds.normalizeKey(full);
  }

  @override
  MessageMapper get _mapper => MessageMapper(
    selfKey: _selfKey,
    selfName: _identity.current?.displayName ?? '',
    nameOf: _friendsPart.nameOf,
    isQueued: _service == null
        ? null
        : PendingMessageStatus(
            _service!.offlineMessageQueuePersistence,
          ).isQueued,
  );

  /// Whether [svc] is still the bound session. Every refresh that awaited
  /// something checks this before publishing: a tick or callback started on
  /// a session that has since been detached must not repopulate the lists
  /// that [_bindSession] just emptied (or write into a newer session's view).
  bool _isCurrent(FfiChatService svc) => identical(_service, svc) && !_disposed;

  /// Mutation-side counterpart of [_isCurrent]: a mutation that awaited the
  /// old session must neither publish nor touch this identity's metadata,
  /// so it fails the same way a call made while detached does
  /// ([_requireService]: `not_connected`). Callers place it after every
  /// await; the native side effect already happened and is not undone.
  @override
  void _ensureCurrent(FfiChatService svc) {
    if (_isCurrent(svc)) return;
    throw const ChatException(
      'not_connected',
      'Chat session was detached while the operation was in flight',
    );
  }

  /// [ConversationMetaStore.forget] with the session re-checked between
  /// its writes: [_meta] follows the bound identity, so a detach or rebind
  /// during the first write must not let the next ones land in another
  /// identity's keys.
  Future<void> _forgetMeta(FfiChatService svc, String conversationId) async {
    await _meta.setPinned(conversationId, false);
    _ensureCurrent(svc);
    await _meta.setDraft(conversationId, '');
    _ensureCurrent(svc);
    await _meta.unhide(conversationId);
    _ensureCurrent(svc);
  }

  @override
  FfiChatService _requireService() {
    final svc = _service;
    if (svc == null) {
      throw const ChatException(
        'not_connected',
        'Chat is not connected (call IdentityService.connect first)',
      );
    }
    return svc;
  }

  // ---- Friends (delegated) -------------------------------------------------

  @override
  List<Friend> get friends => _friendsPart.friends.value;

  @override
  Stream<List<Friend>> get friendChanges => _friendsPart.friends.stream;

  @override
  List<FriendRequest> get friendRequests => _friendsPart.requests.value;

  @override
  Stream<List<FriendRequest>> get friendRequestChanges =>
      _friendsPart.requests.stream;

  @override
  Future<void> addFriend(String toxId, {String message = 'ditmesh CQ'}) =>
      _friendsPart.addFriend(_requireService(), toxId, message);

  @override
  Future<void> acceptFriendRequest(String publicKey) =>
      _friendsPart.accept(_requireService(), publicKey);

  @override
  Future<void> rejectFriendRequest(String publicKey) =>
      _friendsPart.reject(_requireService(), publicKey);

  @override
  Future<void> removeFriend(String publicKey) =>
      _friendsPart.remove(_requireService(), publicKey);

  // ---- Blocking (delegated) ------------------------------------------------

  @override
  Set<String> get blockedPeers => _blockingPart.blocked.value;

  @override
  Stream<Set<String>> get blockedPeerChanges => _blockingPart.blocked.stream;

  @override
  Future<void> blockPeer(String publicKey) =>
      _blockingPart.block(_requireService(), publicKey);

  @override
  Future<void> unblockPeer(String publicKey) =>
      _blockingPart.unblock(_requireService(), publicKey);

  @override
  bool _shows(t2t.ChatMessage m) => _blockingPart.shows(m);

  @override
  bool _hiddenNow(ChatMessage m) =>
      !m.isMine && _blockingPart.isBlocked(m.senderId);

  // ---- Conversations (delegated) -------------------------------------------

  /// Derived from the identity, not the session, so the UI can show the
  /// entry while disconnected. Tim2Tox keeps everything sent to it local.
  @override
  String? get selfConversationId {
    final current = _identity.current;
    if (current == null || _replacing) return null;
    return ConversationIds.c2c(current.publicKey);
  }

  @override
  List<Conversation> get conversations =>
      _conversationsPart.conversations.value;

  @override
  Stream<List<Conversation>> get conversationChanges =>
      _conversationsPart.conversations.stream;

  @override
  Future<void> markRead(String conversationId) =>
      _conversationsPart.markRead(_requireService(), conversationId);

  @override
  Future<void> setPinned(String conversationId, bool pinned) =>
      _conversationsPart.setPinned(conversationId, pinned);

  @override
  Future<void> setDraft(String conversationId, String draft) =>
      _conversationsPart.setDraft(conversationId, draft);

  /// The self guard runs before [_requireService], so deleting the note to
  /// self is refused with `self_conversation` even while disconnected.
  @override
  Future<void> deleteConversation(String conversationId) async {
    _conversationsPart.refuseSelf(conversationId);
    await _conversationsPart.delete(_requireService(), conversationId);
  }

  // ---- Messages -------------------------------------------------------------

  @override
  Stream<ChatMessage> get messageEvents => _messageEvents.stream;

  @override
  int get maxMessageBytes => toxMessageBudget;

  /// The durable Tim2Tox queue of the bound session; null while detached
  /// (the queue file of a detached identity is not loaded).
  @override
  PendingOutboxSummary? pendingOutbox({String? conversationId}) {
    final svc = _service;
    if (svc == null || !_isCurrent(svc)) return null;
    return PendingMessageStatus(
      svc.offlineMessageQueuePersistence,
    ).summary(conversationId: conversationId);
  }

  @override
  Future<List<ChatMessage>> loadHistory(
    String conversationId, {
    int limit = 50,
    DateTime? before,
  }) async {
    final svc = _requireService();
    final peer = ConversationIds.peerOf(conversationId);
    final page = await readHistoryPage(
      svc.getHistory(peer),
      limit: limit,
      before: before,
      shows: _blockingPart.shows,
      archive: () async {
        final hasArchive = await svc.hasArchivedHistory(peer);
        _ensureCurrent(svc);
        if (!hasArchive) return null;
        final archived = await svc.getArchivedHistory(peer);
        _ensureCurrent(svc);
        return archived;
      },
    );
    // Rows of a detached session must not be mapped with the next one's
    // self key and names.
    _ensureCurrent(svc);
    final mapper = _mapper;
    return [
      for (final r in page) mapper.map(r, conversationId: conversationId),
    ];
  }

  @override
  Future<ChatMessage> sendText(
    String conversationId,
    String text, {
    KeyedRecording? recording,
  }) => _sendText(conversationId, text, recording: recording);

  @override
  Future<void> clearHistory(String conversationId) async {
    final svc = _requireService();
    final peer = ConversationIds.peerOf(conversationId);
    if (ConversationIds.isGroup(conversationId)) {
      await svc.clearGroupHistory(peer);
    } else {
      await svc.clearC2CHistory(peer);
    }
    _ensureCurrent(svc);
    _conversationsPart.rebuild(svc);
  }

  // ---- Groups (delegated) --------------------------------------------------

  @override
  List<Group> get groups => _groupsPart.groups.value;

  @override
  Stream<List<Group>> get groupChanges => _groupsPart.groups.stream;

  @override
  List<GroupInvite> get groupInvites => _groupsPart.invites.value;

  @override
  Stream<List<GroupInvite>> get groupInviteChanges =>
      _groupsPart.invites.stream;

  @override
  Future<Group> createGroup(String name, {GroupKind kind = GroupKind.group}) =>
      _groupsPart.create(_requireService(), name, kind);

  @override
  Future<void> joinGroup(String chatId, {String? password}) =>
      _groupsPart.join(_requireService(), chatId, password);

  @override
  Future<void> rejoinGroup(String groupId, {String? password}) =>
      _groupsPart.rejoin(_requireService(), groupId, password);

  @override
  Stream<GroupJoinRefusal> get groupJoinRefusals => _groupsPart.refusals.stream;

  @override
  Future<void> inviteToGroup(String groupId, String friendPublicKey) =>
      _groupsPart.invite(_requireService(), groupId, friendPublicKey);

  @override
  Future<void> acceptGroupInvite(String inviteId, {String? password}) =>
      _groupsPart.acceptInvite(_requireService(), inviteId, password);

  @override
  Future<void> rejectGroupInvite(String inviteId) =>
      _groupsPart.rejectInvite(_requireService(), inviteId);

  @override
  Future<List<GroupMember>> groupMembers(String groupId) =>
      _groupsPart.members(_requireService(), groupId);

  @override
  Future<void> leaveGroup(String groupId) =>
      _groupsPart.leave(_requireService(), groupId);

  // ---- lifecycle --------------------------------------------------------------

  /// Durable writes are what must not be lost; the request refresh in front
  /// of them is a best-effort cache update and never fails the flush (a
  /// failing FFI read must not abort an identity delete or import).
  @override
  Future<void> flush() async {
    final svc = _service;
    if (svc != null) {
      try {
        await _friendsPart.refreshRequests(svc);
      } catch (e, st) {
        _logger.error('[Chat] request refresh before flush failed', e, st);
      }
    }
    await _store.flush();
  }

  @override
  Future<void> prepareForReplacement() async {
    _replacing = true;
    _replacementIdentity = _identity.current;
    try {
      await flush();
    } finally {
      _bindSession(null);
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final identity = _identity;
    if (identity is PersistentIdentityService) {
      identity.unregisterDataStore(this);
    }
    // Synchronous releases first; the awaited futures are only the closes'
    // done-futures and the root-zone cancel future.
    final cancelled = _sessionSub?.cancel();
    final identityCancelled = _identitySub?.cancel();
    _sessionSub = null;
    _identitySub = null;
    _unbindSession();
    await Future.wait([
      ?cancelled,
      ?identityCancelled,
      _store.flush(),
      _messageEvents.close(),
      _session.close(),
      _friendsPart.close(),
      _groupsPart.close(),
      _conversationsPart.close(),
      _blockingPart.close(),
    ]);
  }
}

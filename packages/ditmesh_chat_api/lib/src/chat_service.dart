import 'message_search.dart';
import 'models.dart';
import 'keyed_recording.dart';

/// Friends, conversations, C2C and group messaging.
///
/// All lists are exposed as broadcast streams that replay the current value
/// to new listeners (BehaviorSubject semantics), plus a synchronous getter.
///
/// **Session.** Chat works on a *session*: it exists from
/// [IdentityService.connect] until [IdentityService.disconnect], whatever the
/// network does meanwhile (DHT drop-outs do not end it). Without a session
/// every getter and stream still works (lists are empty), [setPinned] and
/// [setDraft] still work for the open identity, and every other operation —
/// including [loadHistory], [markRead], [sendText] and [clearHistory] —
/// throws `ChatException('not_connected', ...)`. The UI should retry such a
/// read when [IdentityService.connectionChanges] reports a change.
///
/// **Peers offline.** Within a session, a send to a friend (or group) that is
/// not reachable right now is queued and returned as [MessageStatus.pending];
/// it is delivered automatically when the peer comes back.
///
/// **Error codes** ([ChatException.code]) used by the implementations:
/// `not_connected`, `invalid_tox_id`, `own_id`, `already_friend`,
/// `add_friend_failed`, `accept_failed`, `message_too_long`,
/// `empty_message`, `invalid_message`, `send_failed`, `self_conversation`,
/// `invalid_name`, `invalid_chat_id`, `already_joined`, `join_failed`,
/// `group_not_found`, `invite_failed`, `create_group_failed`,
/// `leave_failed`, `timeout`, `peer_blocked`, `not_friend`.
abstract interface class ChatService {
  // ---- Session -------------------------------------------------------------

  /// Whether a chat session is up (see the class docs). Not the same as the
  /// network being online: a session exists while Tox is still connecting.
  bool get hasSession;

  /// [hasSession] changes; replays the current value to new listeners. A
  /// read that failed with `not_connected` should be retried when this
  /// turns true.
  Stream<bool> get sessionChanges;

  // ---- Friends -------------------------------------------------------------

  List<Friend> get friends;
  Stream<List<Friend>> get friendChanges;

  List<FriendRequest> get friendRequests;
  Stream<List<FriendRequest>> get friendRequestChanges;

  /// Send a friend request to a Tox ID ([ToxAddress.isValid]: 76 hex with a
  /// valid checksum). Throws `invalid_tox_id`, `already_friend`, `own_id`,
  /// and `peer_blocked` when the key is in [blockedPeers] (unblock first).
  Future<void> addFriend(String toxId, {String message = 'ditmesh CQ'});

  Future<void> acceptFriendRequest(String publicKey);
  Future<void> rejectFriendRequest(String publicKey);
  Future<void> removeFriend(String publicKey);

  // ---- Blocking (App Review 1.2) -------------------------------------------

  /// Public keys (64 hex, upper case) the open identity blocked. Empty
  /// without a session. Replays the current value to new listeners.
  ///
  /// Blocking is a local, receive-side hide: Tox has no network block, so
  /// a blocked peer can still send; this device drops it. From
  /// [blockPeer] until [unblockPeer], nothing of theirs surfaces: no c2c
  /// conversation row, no friend request, no group invite, and none of
  /// their messages in [messageEvents], [loadHistory], [searchMessages],
  /// [loadAround], conversation previews or unread counts (group
  /// conversations included).
  ///
  /// Keys: a friend, a friend request or a group inviter is blocked by
  /// their long-term key; a group member by [GroupMember.publicKey], which
  /// Tox NGC mints per group. The two are independent: blocking a friend
  /// does not hide them in groups, and blocking a member hides them in
  /// that group only.
  Set<String> get blockedPeers;
  Stream<Set<String>> get blockedPeerChanges;

  /// Blocks [publicKey] (64 hex or a 76-hex Tox ID): a friend is removed
  /// (which deletes the conversation with them, as [removeFriend] does) and
  /// their pending friend request and group invites are declined. Throws
  /// `own_id` for our own key, `invalid_tox_id` for anything that is not a
  /// key.
  Future<void> blockPeer(String publicKey);

  /// Shows [publicKey]'s future messages, requests and invites again, and
  /// their group rows that were hidden. A deleted friendship and
  /// conversation are not restored. A no-op when they are not blocked.
  Future<void> unblockPeer(String publicKey);

  // ---- Conversations -------------------------------------------------------

  /// The note-to-self conversation (`c2c_<own public key>`) of the open
  /// identity, or null when none is open. Shown as "me" with the own display
  /// name: a drafts box, a practice partner, a place to keep notes. It is in
  /// [conversations] (with [Conversation.isSelf]) whenever the other
  /// conversations are, i.e. while chat is connected. [sendText] to it is
  /// local only — stored, never sent — and returns [MessageStatus.sent] at
  /// once. It cannot be deleted: [deleteConversation] refuses it (see there);
  /// [clearHistory] is the explicit way to empty it.
  String? get selfConversationId;

  List<Conversation> get conversations;
  Stream<List<Conversation>> get conversationChanges;

  Future<void> markRead(String conversationId);
  Future<void> setPinned(String conversationId, bool pinned);
  Future<void> setDraft(String conversationId, String draft);

  /// Clears the conversation's history and removes it from [conversations]
  /// until the next message. For [selfConversationId] it throws
  /// `ChatException('self_conversation', ...)` and changes nothing (history,
  /// draft and pin all stay).
  Future<void> deleteConversation(String conversationId);

  // ---- Messages ------------------------------------------------------------

  /// Persisted history for a conversation, oldest first: the newest [limit]
  /// rows, or with [before] the newest [limit] rows strictly older than that
  /// instant. [before] is a coarse time filter, not a paging cursor: rows
  /// sharing the boundary timestamp are excluded, so paging by the oldest
  /// row's timestamp can skip rows. Page by id with [loadAround] (or by
  /// growing [limit]) instead.
  Future<List<ChatMessage>> loadHistory(
    String conversationId, {
    int limit = 50,
    DateTime? before,
  });

  /// Live message events: new inbound messages and status updates for our
  /// own messages (pending → sent, or pending → failed when a queued send
  /// could not be delivered), for every conversation.
  Stream<ChatMessage> get messageEvents;

  /// Send plain text. Returns the local row immediately (status pending or
  /// sending). Throws `message_too_long` when [text] exceeds
  /// [maxMessageBytes] in UTF-8 — the UI shows the remaining budget so this
  /// should be rare. A c2c target other than [selfConversationId] must be a
  /// friend (an outgoing, unanswered request counts): otherwise this throws
  /// `not_friend`, or `peer_blocked` for a blocked key, and nothing is
  /// queued.
  Future<ChatMessage> sendText(
    String conversationId,
    String text, {
    KeyedRecording? recording,
  });

  /// Tox single-message budget after Tim2Tox's fragment header (1322 bytes).
  int get maxMessageBytes;

  Future<void> clearHistory(String conversationId);

  // ---- Message management (F07) ---------------------------------------------

  /// Searches the whole persisted history of [conversationId] (not only the
  /// rows a screen loaded), newest first by (timestamp, id). Pass the
  /// previous page's [MessageSearchPage.next] as [cursor] for the next page;
  /// pages never lose or repeat rows, even with equal timestamps.
  /// A fired [cancel] stops the scan and throws [MessageSearchCancelled].
  Future<MessageSearchPage> searchMessages(
    String conversationId,
    MessageSearchQuery query, {
    MessageSearchCursor? cursor,
    int limit = 20,
    MessageSearchCancel? cancel,
  });

  /// Up to [before] older and [after] newer rows around [messageId], oldest
  /// first, including the message itself; empty when it is not in the
  /// history (deleted, cleared). For jumping to a search result.
  Future<List<ChatMessage>> loadAround(
    String conversationId,
    String messageId, {
    int before = 25,
    int after = 25,
  });

  /// Whether [retryMessage] / [cancelPendingMessage] are backed by the
  /// transport. When false both return [MessageActionResult.unavailable]
  /// and the UI must not offer them.
  bool get supportsSendControl;

  /// Re-sends our [MessageStatus.failed] message under its stable local id
  /// (no second row); the row turns [MessageStatus.pending] and drains when
  /// the peer is reachable. Only confirmed failures qualify. A stable local
  /// id is not end-to-end exactly-once delivery.
  Future<MessageActionResult> retryMessage(
    String conversationId,
    String messageId,
  );

  /// Cancels our [MessageStatus.pending] message while it is still only
  /// queued locally. Returns [MessageActionResult.stateChanged] when the
  /// transport already claimed it (it may be delivered). The row is kept as
  /// [MessageStatus.cancelled] and emitted on [messageEvents].
  Future<MessageActionResult> cancelPendingMessage(
    String conversationId,
    String messageId,
  );

  // ---- Groups --------------------------------------------------------------

  List<Group> get groups;
  Stream<List<Group>> get groupChanges;

  List<GroupInvite> get groupInvites;
  Stream<List<GroupInvite>> get groupInviteChanges;

  Future<Group> createGroup(String name, {GroupKind kind = GroupKind.group});

  /// Join an NGC group by its 64-hex chat id (async on the Tox side; the
  /// group appears in [groups] once the DHT finds a peer). A wrong password
  /// or a full group is reported later on [groupJoinRefusals].
  Future<void> joinGroup(String chatId, {String? password});

  /// Joins the group we already hold as [groupId] again, with [password]:
  /// the retry for an [GroupJoinRefusal.established] refusal. Throws
  /// `group_not_found` when [groupId] is not in [groups]. A refusal is
  /// reported on [groupJoinRefusals], as for [joinGroup].
  Future<void> rejoinGroup(String groupId, {String? password});

  /// Joins the group refused after the call that started them had returned
  /// (see [GroupJoinRefusal]). Broadcast, not replayed: only refusals of the
  /// current session, from the moment of listening.
  Stream<GroupJoinRefusal> get groupJoinRefusals;

  Future<void> inviteToGroup(String groupId, String friendPublicKey);
  Future<void> acceptGroupInvite(String inviteId, {String? password});
  Future<void> rejectGroupInvite(String inviteId);
  Future<List<GroupMember>> groupMembers(String groupId);
  Future<void> leaveGroup(String groupId);

  /// Release streams and stop timers.
  Future<void> dispose();
}

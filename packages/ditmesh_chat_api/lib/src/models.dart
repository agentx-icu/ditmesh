import 'package:meta/meta.dart';

/// Tox network connection state of the local identity.
enum ConnectionStatus { offline, connecting, online }

/// Delivery state of a message we sent, or `received` for inbound.
enum MessageStatus {
  /// Queued locally because the peer is offline (Tox has no server store).
  pending,
  sending,
  sent,
  failed,
  received,

  /// Our queued message that the user cancelled before it was handed to
  /// transport. The local row is kept; it is never re-queued after a
  /// restart and never delivered.
  cancelled,
}

enum ConversationKind { c2c, group }

/// Tox group transport. `group` = NGC (new group chat, chat_id persistent,
/// recommended); `conference` = legacy, kept only for old clients.
enum GroupKind { group, conference }

/// The local user's Tox identity.
@immutable
final class Identity {
  const Identity({
    required this.toxId,
    required this.displayName,
    this.statusMessage = '',
    this.hasPassword = false,
  });

  /// 76-hex-char Tox ID (public key + nospam + checksum). Share to be added.
  final String toxId;
  final String displayName;
  final String statusMessage;

  /// Whether the on-disk profile is encrypted with a user password.
  final bool hasPassword;

  /// Public key part (first 64 hex chars); stable across nospam changes.
  String get publicKey => toxId.length >= 64 ? toxId.substring(0, 64) : toxId;

  Identity copyWith({
    String? displayName,
    String? statusMessage,
    bool? hasPassword,
  }) => Identity(
    toxId: toxId,
    displayName: displayName ?? this.displayName,
    statusMessage: statusMessage ?? this.statusMessage,
    hasPassword: hasPassword ?? this.hasPassword,
  );
}

/// What the startup gate finds on disk.
enum IdentityState {
  /// First run: no profile exists yet.
  none,

  /// Profile exists and is encrypted; [IdentityService.unlock] is required.
  locked,

  /// Profile exists and is usable (plain, or already unlocked this run).
  ready,
}

@immutable
final class Friend {
  const Friend({
    required this.publicKey,
    required this.displayName,
    this.statusMessage = '',
    this.online = false,
  });

  /// 64-hex-char public key; the stable peer identifier.
  final String publicKey;
  final String displayName;
  final String statusMessage;
  final bool online;

  Friend copyWith({String? displayName, String? statusMessage, bool? online}) =>
      Friend(
        publicKey: publicKey,
        displayName: displayName ?? this.displayName,
        statusMessage: statusMessage ?? this.statusMessage,
        online: online ?? this.online,
      );
}

@immutable
final class FriendRequest {
  const FriendRequest({
    required this.publicKey,
    required this.message,
    required this.receivedAt,
  });

  final String publicKey;
  final String message;
  final DateTime receivedAt;
}

@immutable
final class Conversation {
  const Conversation({
    required this.id,
    required this.kind,
    required this.title,
    this.lastMessage,
    this.unreadCount = 0,
    this.pinned = false,
    this.draft = '',
    this.isSelf = false,
  });

  /// `c2c_<publicKey>` or `group_<groupId>`.
  final String id;
  final ConversationKind kind;
  final String title;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final bool pinned;
  final String draft;

  /// The note-to-self conversation ([ChatService.selfConversationId]): a c2c
  /// conversation with our own key whose messages never leave the device.
  final bool isSelf;

  /// Peer public key for c2c, group id for groups.
  String get peerId => id.substring(id.indexOf('_') + 1);
}

/// A chat message. On the wire this is plain text (readable by any Tim2Tox
/// client such as toxee); Morse rendering is derived on the receiving side
/// from [text] at the listener's own speed (plan §5.2, layer 1).
@immutable
final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.status,
    required this.isMine,
    this.senderName,
  });

  final String id;
  final String conversationId;

  /// Sender public key (c2c and group) — for groups this is the peer key.
  final String senderId;
  final String? senderName;
  final String text;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isMine;

  ChatMessage copyWith({MessageStatus? status, String? senderName}) =>
      ChatMessage(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName ?? this.senderName,
        text: text,
        timestamp: timestamp,
        status: status ?? this.status,
        isMine: isMine,
      );
}

@immutable
final class Group {
  const Group({
    required this.id,
    required this.name,
    required this.kind,
    this.chatId,
    this.memberCount = 0,
    this.topic = '',
  });

  /// App-level id (`tox_<n>` in Tim2Tox).
  final String id;
  final String name;
  final GroupKind kind;

  /// 64-hex NGC chat id used to (re)join; null for conferences.
  final String? chatId;
  final int memberCount;
  final String topic;
}

@immutable
final class GroupMember {
  const GroupMember({
    required this.publicKey,
    required this.displayName,
    this.isSelf = false,
    this.online = true,
  });

  final String publicKey;
  final String displayName;
  final bool isSelf;
  final bool online;
}

@immutable
final class GroupInvite {
  const GroupInvite({
    required this.inviteId,
    required this.fromPublicKey,
    required this.groupName,
    required this.kind,
  });

  final String inviteId;
  final String fromPublicKey;
  final String groupName;
  final GroupKind kind;
}

/// Why a group refused our join ([GroupJoinRefusal.reason]).
enum GroupJoinRefusalReason {
  /// The group needs a password and ours was missing or wrong.
  invalidPassword,

  /// The group has reached its member limit.
  groupFull,

  /// Any other refusal.
  unknown,
}

/// A group refused a join after [ChatService.joinGroup],
/// [ChatService.acceptGroupInvite] or [ChatService.rejoinGroup] had already
/// returned (the Tox handshake is asynchronous), or refused to take back a
/// group we held when reconnecting ([established]).
///
/// Retrying: an invite refusal ([inviteId]) is retried by accepting that
/// invite again (it is listed in [ChatService.groupInvites] once more); an
/// [established] group by [ChatService.rejoinGroup] with [groupId]; any
/// other join by [ChatService.joinGroup] with [chatId].
@immutable
final class GroupJoinRefusal {
  const GroupJoinRefusal({
    required this.groupId,
    required this.reason,
    this.chatId,
    this.inviteId,
    this.groupName = '',
    this.established = false,
  });

  /// The group's app-level id; for an invite join only a temporary alias.
  final String groupId;

  /// 64-hex NGC chat id; null when the transport could not read it.
  final String? chatId;

  /// The invite the refused join came from; null for a join by chat id.
  final String? inviteId;

  /// Best-effort display name (the group's or the invite's); may be empty.
  final String groupName;

  final GroupJoinRefusalReason reason;

  /// A group we already held: it stays in [ChatService.groups] with its
  /// history.
  final bool established;
}

/// Thrown by the services for user-facing failures.
final class ChatException implements Exception {
  const ChatException(this.code, this.message);

  /// Stable machine-readable code, e.g. `wrong_password`, `peer_offline`,
  /// `invalid_tox_id`, `already_friend`, `group_not_found`, `message_too_long`.
  final String code;
  final String message;

  @override
  String toString() => 'ChatException($code): $message';
}

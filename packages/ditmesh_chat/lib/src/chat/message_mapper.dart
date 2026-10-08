import 'dart:convert';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart' as api;
import 'package:tim2tox_dart/models/chat_message.dart' as t2t;
import 'package:tim2tox_dart/utils/conversation_id_utils.dart';

/// Conversation-id helpers shared by the chat service parts.
///
/// The contract uses `c2c_<publicKey>` / `group_<groupId>`; Tim2Tox keys its
/// history by the bare, normalised id (64-hex key or `tox_<n>`).
class ConversationIds {
  ConversationIds._();

  static const c2cPrefix = 'c2c_';
  static const groupPrefix = 'group_';

  static String c2c(String publicKey) => '$c2cPrefix${normalizeKey(publicKey)}';
  static String group(String groupId) => '$groupPrefix$groupId';

  static bool isGroup(String conversationId) =>
      conversationId.startsWith(groupPrefix);

  /// Bare peer key / group id — what Tim2Tox wants.
  static String peerOf(String conversationId) =>
      ConversationIdUtils.normalize(conversationId);

  /// 76-hex Tox address → 64-hex public key, upper-cased and trimmed.
  static String normalizeKey(String id) =>
      ConversationIdUtils.normalize(id).toUpperCase();

  static final RegExp publicKey = RegExp(r'^[0-9A-Fa-f]{64}$');

  /// Short human label for a bare key (`A1B2C3D4…`).
  static String shortKey(String key) =>
      key.length > 8 ? '${key.substring(0, 8).toUpperCase()}…' : key;
}

/// Maps Tim2Tox rows to contract [api.ChatMessage]s.
class MessageMapper {
  const MessageMapper({
    required this.selfKey,
    required this.selfName,
    required this.nameOf,
    this.isQueued,
  });

  /// Our 64-hex public key (upper-case). Empty before login.
  final String selfKey;
  final String selfName;

  /// Display name for a peer key, or null when unknown.
  final String? Function(String publicKey) nameOf;

  /// Checks the durable outbox when history's transient pending flag was lost.
  final bool Function(t2t.ChatMessage message, String conversationId)? isQueued;

  /// [conversationId] is required for our own C2C rows: Tim2Tox stamps them
  /// with the login alias and no peer, so the caller must know the target.
  api.ChatMessage map(t2t.ChatMessage m, {required String conversationId}) {
    final isMine = m.isSelf;
    final sender = isMine
        ? selfKey
        : ConversationIds.normalizeKey(m.fromUserId);
    final body = isMine ? m.text : api.PeerText.clean(m.text);
    final text = m.contentKind == t2t.ChatMessageContentKind.action
        ? '/me $body'
        : body;
    return api.ChatMessage(
      id: m.msgID ?? fallbackId(m),
      conversationId: conversationId,
      senderId: sender,
      senderName: isMine ? selfName : nameOf(sender),
      text: text,
      timestamp: m.timestamp,
      // A cancelled or failed row keeps that state even while its queue item
      // lingers (Tim2Tox emits the row before the durable removal);
      // otherwise the durable queue says pending.
      status:
          isMine &&
              !m.isCancelled &&
              !m.isFailed &&
              (isQueued?.call(m, conversationId) ?? false)
          ? api.MessageStatus.pending
          : statusOf(m),
      isMine: isMine,
    );
  }

  /// Our rows: cancelled (`isCancelled`), failed (a queued send whose
  /// drain failed: `isFailed`), still queued (`isPending`), else sent.
  static api.MessageStatus statusOf(t2t.ChatMessage m) {
    if (!m.isSelf) return api.MessageStatus.received;
    if (m.isCancelled) return api.MessageStatus.cancelled;
    if (m.isFailed) return api.MessageStatus.failed;
    return m.isPending ? api.MessageStatus.pending : api.MessageStatus.sent;
  }

  /// Id for a row Tim2Tox stored without a native one: deterministic across
  /// processes (a bubble keeps its id over restarts) and distinct per time,
  /// sender, direction, content kind and text, so two peers' identical texts
  /// in the same microsecond never collapse into one bubble. History merges
  /// use the same identity ([historyRowKey]).
  static String fallbackId(t2t.ChatMessage m) {
    final digest = _fnv1a64(
      utf8.encode(
        [
          m.fromUserId,
          m.isSelf ? 'out' : 'in',
          m.contentKind.name,
          m.text,
        ].join('\u0000'),
      ),
    );
    return 'local_${m.timestamp.microsecondsSinceEpoch}_'
        '${digest.toUnsigned(64).toRadixString(16).padLeft(16, '0')}';
  }

  /// FNV-1a, 64-bit: stable, unlike `String.hashCode`.
  static int _fnv1a64(List<int> bytes) {
    var hash = 0xcbf29ce484222325;
    for (final b in bytes) {
      hash ^= b;
      hash *= 0x100000001b3;
    }
    return hash;
  }

  /// Whether [m] is a text (or `/me` action) message DitMesh shows. File
  /// transfers and custom payloads that toxee peers can send are not.
  static bool isChatText(t2t.ChatMessage m) =>
      m.filePath == null &&
      m.mediaKind == null &&
      m.contentKind != t2t.ChatMessageContentKind.custom;

  /// The contract conversation id of a row when it can be derived from the
  /// row alone (inbound C2C, any group row). Null for our own C2C rows.
  static String? conversationOf(t2t.ChatMessage m) {
    final gid = m.groupId;
    if (gid != null && gid.isNotEmpty) return ConversationIds.group(gid);
    if (m.isSelf) return null;
    return ConversationIds.c2c(m.fromUserId);
  }
}

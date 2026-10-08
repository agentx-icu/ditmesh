import 'package:flutter/foundation.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

/// What the conversation screen needs to open: the id, a title for the app
/// bar and the kind. Built from a [Conversation], a [Friend] (before any
/// message exists), a [Group] or the note-to-self entry.
@immutable
final class ConversationTarget {
  const ConversationTarget({
    required this.id,
    required this.title,
    required this.kind,
    this.isSelf = false,
  });

  ConversationTarget.fromConversation(Conversation c)
    : this(id: c.id, title: c.title, kind: c.kind, isSelf: c.isSelf);

  /// [ChatService.selfConversationId], titled with the own display name.
  const ConversationTarget.self({required String id, required String title})
    : this(id: id, title: title, kind: ConversationKind.c2c, isSelf: true);

  ConversationTarget.fromFriend(Friend f)
    : this(
        id: 'c2c_${f.publicKey}',
        title: f.displayName,
        kind: ConversationKind.c2c,
      );

  ConversationTarget.fromGroup(Group g)
    : this(id: 'group_${g.id}', title: g.name, kind: ConversationKind.group);

  final String id;
  final String title;
  final ConversationKind kind;

  /// The note-to-self conversation: local only, no peer presence.
  final bool isSelf;

  /// Peer public key for c2c, group id for groups.
  String get peerId => id.substring(id.indexOf('_') + 1);

  @override
  bool operator ==(Object other) =>
      other is ConversationTarget && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../chat/chat_layout.dart';

/// Who is being blocked, which decides what the confirmation explains.
enum BlockScope {
  /// A friend, a friend request or a group inviter: their long-term Tox
  /// key. Blocking removes the friendship and deletes the conversation.
  contact,

  /// A group member: Tox NGC gives every member a separate key per group,
  /// so this hides them in that group only.
  groupMember,
}

/// Confirms, then blocks [publicKey] ([ChatService.blockPeer]). Returns
/// whether the peer is now blocked; failures are shown as a snack.
Future<bool> confirmAndBlock(
  BuildContext context, {
  required ChatService service,
  required String publicKey,
  required String name,
  required BlockScope scope,
}) async {
  final S s = context.s;
  final bool ok = await confirm(
    context,
    title: s.moderationBlockTitle(name),
    body: scope == BlockScope.contact
        ? s.moderationBlockFriendBody
        : s.moderationBlockMemberBody,
    confirmLabel: s.moderationBlock,
  );
  if (!ok || !context.mounted) return false;
  return blockQuietly(context, service: service, publicKey: publicKey);
}

/// Blocks without asking (the caller already confirmed). Shows the
/// outcome as a snack; returns whether the peer is now blocked.
Future<bool> blockQuietly(
  BuildContext context, {
  required ChatService service,
  required String publicKey,
}) async {
  final S s = context.s;
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await service.blockPeer(publicKey);
  } on Object catch (e) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(describeChatError(s, e))));
    return false;
  }
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(s.moderationBlocked)));
  return true;
}

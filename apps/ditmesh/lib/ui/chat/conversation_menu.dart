import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import 'chat_layout.dart';
import 'conversation_target.dart';
import 'morse_playback_settings.dart';
import 'search/message_bookmarks.dart';
import 'search/message_search_screen.dart';

/// Conversation actions that do not need the screen's state: leaving a
/// group, history search, bookmarks and send control (functional spec §10).
abstract final class ConversationMenu {
  /// Confirms and leaves [groupId]; true when the group was left.
  static Future<bool> leaveGroup(
    BuildContext context,
    ChatService service,
    String groupId,
  ) async {
    final S s = context.s;
    final bool ok = await confirm(
      context,
      title: s.chatLeaveGroupTitle,
      body: s.chatLeaveGroupBody,
      confirmLabel: s.chatLeave,
    );
    if (!ok || !context.mounted) return false;
    try {
      await service.leaveGroup(groupId);
      return true;
    } on Object catch (e) {
      if (context.mounted) showSnack(context, describeChatError(s, e));
      return false;
    }
  }

  static String _selfKey(BuildContext context) {
    try {
      return context.read<IdentityService>().current?.publicKey ?? '';
    } on Object {
      return '';
    }
  }

  /// History search for [target]; returns the picked message.
  static Future<ChatMessage?> openSearch(
    BuildContext context, {
    required ChatService service,
    required ConversationTarget target,
    required MessageBookmarks bookmarks,
  }) => Navigator.of(context).push<ChatMessage>(
    MaterialPageRoute<ChatMessage>(
      builder: (_) => MessageSearchScreen(
        service: service,
        conversationId: target.id,
        peerKey: target.kind == ConversationKind.c2c && !target.isSelf
            ? target.peerId.toUpperCase()
            : null,
        selfKey: _selfKey(context),
        bookmarks: bookmarks,
        hideText: MorsePlaybackSettings.of(context, listen: false).listenOnly,
      ),
    ),
  );

  /// Clearing history removes the conversation's bookmarks.
  static Future<void> forgetBookmarks(
    BuildContext context,
    String conversationId,
  ) async {
    try {
      final store = await MessageBookmarks.of(context);
      await store.removeConversation(conversationId);
    } on Object {
      // A stale bookmark resolves to nothing and is dropped on next use.
    }
  }

  static Future<void> toggleBookmark(
    BuildContext context,
    ChatMessage message,
  ) async {
    try {
      final store = await MessageBookmarks.of(context);
      await store.toggle(message.conversationId, message.id, message.timestamp);
    } on Object {
      if (context.mounted) showSnack(context, context.s.chatBookmarkFailed);
    }
  }

  /// Retry of a confirmed failure, or cancel of a still-queued send. Shows
  /// what actually happened; never pretends a claimed send was cancelled.
  static Future<void> sendControl(
    BuildContext context,
    ChatService service,
    ChatMessage message, {
    required bool retry,
  }) async {
    final S s = context.s;
    MessageActionResult result;
    try {
      result = retry
          ? await service.retryMessage(message.conversationId, message.id)
          : await service.cancelPendingMessage(
              message.conversationId,
              message.id,
            );
    } on Object {
      result = MessageActionResult.failure;
    }
    if (!context.mounted) return;
    showSnack(context, switch ((result, retry)) {
      (MessageActionResult.success, true) => s.chatRetryQueued,
      (MessageActionResult.success, false) => s.chatSendCancelled,
      (MessageActionResult.stateChanged, true) => s.chatRetryNotNeeded,
      (MessageActionResult.stateChanged, false) => s.chatCancelTooLate,
      (MessageActionResult.unavailable, _) => s.chatSendControlUnavailable,
      (MessageActionResult.failure, _) => s.chatSendControlFailed,
    });
  }
}

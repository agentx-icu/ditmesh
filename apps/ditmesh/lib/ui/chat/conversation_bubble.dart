import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'conversation_learning.dart';
import 'conversation_menu.dart';
import 'message_bubble.dart';
import 'morse_playback_controller.dart';
import 'morse_playback_settings.dart';
import 'message_playback_panel.dart';

/// One timeline bubble of a conversation, with its playback, reveal and
/// learning actions wired.
Widget conversationBubble(
  BuildContext context, {
  required ChatMessage message,
  required MorsePlaybackSettings settings,
  required MorsePlaybackController playback,
  required bool isGroup,
  required bool revealed,
  required VoidCallback onReveal,
  required String fallbackTitle,
  required ChatService service,
  required bool isSelf,
  bool bookmarked = false,
}) {
  final m = message;
  final title = m.senderName ?? fallbackTitle;
  // Send control only where the transport backs it; the note to self never
  // queues, so it has nothing to retry or cancel.
  final control = service.supportsSendControl && m.isMine && !isSelf;
  return MessageBubble(
    key: ValueKey<String>(m.id),
    message: m,
    trainingMode: settings.trainingMode,
    listenOnly: settings.listenOnly,
    revealed: revealed,
    playing: playback.playingId == m.id,
    activeMark: playback.activeMarkFor(m.id),
    activeWord: playback.playingId == m.id ? playback.activeWord : null,
    playbackControls: playback.playingId == m.id
        ? InlineMessagePlayback(playback: playback)
        : null,
    onPlaybackSettings: () => unawaited(
      showMessagePlaybackPanel(
        context,
        message: m,
        settings: settings,
        playback: playback,
      ),
    ),
    showSender: isGroup,
    onReveal: onReveal,
    onPlay: () => unawaited(
      playback.toggle(
        m.id,
        m.text,
        settings.timing,
        toneHz: settings.toneHz,
        recording: m.recording,
        original: settings.originalRhythm,
        firstWord: settings.repeatLoop ? settings.repeatStart : 0,
        lastWord: settings.repeatLoop ? settings.repeatEnd : null,
        loop: settings.repeatLoop,
      ),
    ),
    bookmarked: bookmarked,
    onBookmark: () => unawaited(ConversationMenu.toggleBookmark(context, m)),
    onRetry: control && m.status == MessageStatus.failed
        ? () => unawaited(
            ConversationMenu.sendControl(context, service, m, retry: true),
          )
        : null,
    onCancelSend: control && m.status == MessageStatus.pending
        ? () => unawaited(
            ConversationMenu.sendControl(context, service, m, retry: false),
          )
        : null,
    onPractice: m.isMine
        ? null
        : () => unawaited(
            ConversationLearning.practise(
              context,
              message: m,
              settings: settings,
              playback: playback,
              title: title,
            ),
          ),
  );
}

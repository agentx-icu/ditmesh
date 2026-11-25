import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import 'message_input.dart';
import 'morse_playback_controller.dart';
import 'morse_playback_settings.dart';

/// The real keyed composer, bounded for landscape and large text. Draft
/// restoration still belongs to the open conversation, including self notes.
class ConversationComposer extends StatelessWidget {
  const ConversationComposer({
    super.key,
    required this.service,
    required this.conversationId,
    required this.playback,
    required this.settings,
    required this.maxHeight,
    required this.onSent,
    this.guidance,
  });

  final ChatService service;
  final String conversationId;
  final MorsePlaybackController playback;
  final MorsePlaybackSettings settings;
  final double maxHeight;
  final ValueChanged<ChatMessage> onSent;
  final Widget? guidance;

  String get _draft {
    for (final conversation in service.conversations) {
      if (conversation.id == conversationId) return conversation.draft;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxHeight: maxHeight),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          guidance ?? const SizedBox.shrink(),
          ChangeNotifierProvider<MorsePlaybackSettings>.value(
            value: settings,
            child: MessageInput(
              key: ValueKey<String>('input_$conversationId'),
              service: service,
              conversationId: conversationId,
              playback: playback,
              initialDraft: _draft,
              onSent: onSent,
            ),
          ),
        ],
      ),
    ),
  );
}

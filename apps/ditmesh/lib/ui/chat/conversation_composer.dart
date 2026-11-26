import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import 'conversation_target.dart';
import 'message_input.dart';
import 'morse_playback_controller.dart';
import 'morse_playback_settings.dart';

/// The real keyed composer, bounded for landscape and large text. Draft
/// restoration still belongs to the open conversation, including self notes.
class ConversationComposer extends StatelessWidget {
  const ConversationComposer({
    super.key,
    required this.service,
    required this.target,
    required this.playback,
    required this.settings,
    required this.paneHeight,
    required this.onSent,
    this.guidance,
  });

  final ChatService service;
  final ConversationTarget target;
  String get conversationId => target.id;
  bool get _tracksPresence =>
      target.kind == ConversationKind.c2c && !target.isSelf;
  final MorsePlaybackController playback;
  final MorsePlaybackSettings settings;
  final double paneHeight;
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
    constraints: BoxConstraints(maxHeight: paneHeight * .75),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          guidance ?? const SizedBox.shrink(),
          ChangeNotifierProvider<MorsePlaybackSettings>.value(
            value: settings,
            child: StreamBuilder<List<Friend>>(
              stream: _tracksPresence ? service.friendChanges : null,
              initialData: _tracksPresence ? service.friends : null,
              builder: (context, snapshot) => MessageInput(
                key: ValueKey<String>('input_$conversationId'),
                service: service,
                conversationId: conversationId,
                playback: playback,
                initialDraft: _draft,
                peerOffline:
                    _tracksPresence &&
                    (snapshot.data?.any(
                          (friend) =>
                              !friend.online &&
                              friend.publicKey == target.peerId,
                        ) ??
                        false),
                paneHeight: paneHeight,
                onSent: onSent,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

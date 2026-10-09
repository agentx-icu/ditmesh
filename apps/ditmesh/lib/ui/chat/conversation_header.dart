import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/l10n_extension.dart';
import 'conversation_target.dart';

/// The app-bar title of [target]: the peer or group name, or "Me" for an
/// unnamed note to self.
String conversationTitleText(S s, ConversationTarget target) =>
    target.isSelf && target.title.isEmpty ? s.chatSelfMe : target.title;

/// Title plus a live subtitle: online/offline for a friend, member count for
/// a group, "saved on this device only" for the note to self.
/// Text scale the two-line conversation title (name over status) stops at:
/// at the AppBar's own 1.34 the two lines are ~58 px, taller than the 56 px
/// toolbar, and the name ran into the status bar.
const double kConversationTitleMaxTextScale = 1.2;

class ConversationTitle extends StatelessWidget {
  const ConversationTitle({
    super.key,
    required this.service,
    required this.target,
  });

  final ChatService service;
  final ConversationTarget target;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final S s = context.s;
    final Widget subtitle = target.isSelf
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 12, color: scheme.outline),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  s.chatSelfLocalOnly,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall,
                ),
              ),
            ],
          )
        : target.kind == ConversationKind.c2c
        ? StreamBuilder<List<Friend>>(
            stream: service.friendChanges,
            initialData: service.friends,
            builder: (context, snapshot) {
              Friend? friend;
              for (final Friend f in snapshot.data ?? const <Friend>[]) {
                if (f.publicKey == target.peerId) friend = f;
              }
              final bool online = friend?.online ?? false;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 4,
                    backgroundColor: online
                        ? Colors.green
                        : scheme.outlineVariant,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      online ? s.connectionOnline : s.connectionOffline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall,
                    ),
                  ),
                ],
              );
            },
          )
        : StreamBuilder<List<Group>>(
            stream: service.groupChanges,
            initialData: service.groups,
            builder: (context, snapshot) {
              Group? group;
              for (final Group g in snapshot.data ?? const <Group>[]) {
                if (g.id == target.peerId) group = g;
              }
              if (group == null) return const SizedBox.shrink();
              return Text(
                [
                  s.chatMemberCount(group.memberCount),
                  if (group.kind == GroupKind.conference) s.chatConferenceBadge,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelSmall,
              );
            },
          );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: kConversationTitleMaxTextScale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            conversationTitleText(s, target),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle,
        ],
      ),
    );
  }
}

class ConferenceNote extends StatelessWidget {
  const ConferenceNote({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: scheme.onTertiaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.s.chatConferenceNote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

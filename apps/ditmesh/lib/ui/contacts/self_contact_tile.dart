import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/l10n_extension.dart';
import '../chat/conversation_target.dart';
import '../chat/self_badge.dart';

/// The default "me" entry at the top of Contacts: the note-to-self
/// conversation, titled with the own display name. Messages sent there are
/// stored on this device only — a drafts box, a practice partner, notes.
/// Hidden while no identity is open.
class SelfContactTile extends StatelessWidget {
  const SelfContactTile({
    super.key,
    required this.service,
    required this.identity,
    required this.onOpen,
  });

  final ChatService service;
  final IdentityService? identity;
  final ValueChanged<ConversationTarget> onOpen;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Identity?>(
      stream: identity?.identityChanges,
      initialData: identity?.current,
      builder: (context, snapshot) {
        final String? id = service.selfConversationId;
        if (id == null) return const SizedBox.shrink();
        final S s = context.s;
        final String name = snapshot.data?.displayName ?? '';
        final String title = name.isEmpty ? s.chatSelfMe : name;
        return ListTile(
          key: const ValueKey<String>('contacts_self'),
          leading: const SelfAvatar(),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SelfBadge(),
            ],
          ),
          subtitle: Text(
            s.chatSelfContactSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => onOpen(ConversationTarget.self(id: id, title: name)),
        );
      },
    );
  }
}

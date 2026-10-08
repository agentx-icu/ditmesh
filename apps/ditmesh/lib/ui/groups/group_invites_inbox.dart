import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../chat/chat_layout.dart';
import '../contacts/tox_id.dart';
import '../moderation/block_actions.dart';

/// Pending group invites with block / reject / accept; hidden when empty. An
/// invite's buttons stay disabled while an answer to it is in flight.
class GroupInvitesInbox extends StatefulWidget {
  const GroupInvitesInbox({super.key, required this.service});

  final ChatService service;

  @override
  State<GroupInvitesInbox> createState() => _GroupInvitesInboxState();
}

class _GroupInvitesInboxState extends State<GroupInvitesInbox> {
  final Set<String> _busy = <String>{};

  ChatService get service => widget.service;

  Future<void> _run(String id, Future<void> Function() op) async {
    if (!_busy.add(id)) return;
    setState(() {});
    final S s = context.s;
    try {
      await op();
    } on Object catch (e) {
      if (mounted) showSnack(context, describeChatError(s, e));
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final S s = context.s;
    return StreamBuilder<List<GroupInvite>>(
      stream: service.groupInviteChanges,
      initialData: service.groupInvites,
      builder: (context, snapshot) {
        final List<GroupInvite> invites =
            snapshot.data ?? const <GroupInvite>[];
        if (invites.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                s.chatGroupInvitesCount(invites.length),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            for (final GroupInvite i in invites)
              ListTile(
                key: ValueKey<String>('invite_${i.inviteId}'),
                leading: const CircleAvatar(child: Icon(Icons.group_add)),
                title: Text(i.groupName),
                subtitle: Text(
                  [
                    s.chatInvitedByName(shortKey(i.fromPublicKey, length: 12)),
                    if (i.kind == GroupKind.conference) s.chatConferenceBadge,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: ValueKey<String>('invite_block_${i.inviteId}'),
                      tooltip: s.moderationBlock,
                      icon: const Icon(Icons.block),
                      onPressed: _busy.contains(i.inviteId)
                          ? null
                          : () => unawaited(
                              _run(
                                i.inviteId,
                                () => confirmAndBlock(
                                  context,
                                  service: service,
                                  publicKey: i.fromPublicKey,
                                  name: shortKey(i.fromPublicKey, length: 12),
                                  scope: BlockScope.contact,
                                ),
                              ),
                            ),
                    ),
                    IconButton(
                      tooltip: s.chatReject,
                      icon: Icon(Icons.close, color: theme.colorScheme.error),
                      onPressed: _busy.contains(i.inviteId)
                          ? null
                          : () => unawaited(
                              _run(
                                i.inviteId,
                                () => service.rejectGroupInvite(i.inviteId),
                              ),
                            ),
                    ),
                    IconButton.filled(
                      tooltip: s.chatAccept,
                      icon: const Icon(Icons.check),
                      onPressed: _busy.contains(i.inviteId)
                          ? null
                          : () => unawaited(
                              _run(
                                i.inviteId,
                                () => service.acceptGroupInvite(i.inviteId),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            const Divider(),
          ],
        );
      },
    );
  }
}

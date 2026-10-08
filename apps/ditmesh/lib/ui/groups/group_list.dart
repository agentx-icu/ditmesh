import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../chat/chat_layout.dart';
import 'group_invites_inbox.dart';
import 'group_members_sheet.dart';

/// Groups we belong to, with the invite inbox above. Long press / right
/// click / overflow menu: members, copy chat id (NGC only), leave.
class GroupList extends StatelessWidget {
  const GroupList({
    super.key,
    required this.service,
    required this.onOpen,
    this.selectedId,
  });

  final ChatService service;
  final ValueChanged<Group> onOpen;
  final String? selectedId;

  Future<void> _leave(BuildContext context, Group g) async {
    final S s = context.s;
    final bool ok = await confirm(
      context,
      title: s.chatLeaveGroupTitle,
      body: s.chatLeaveGroupBody,
      confirmLabel: s.chatLeave,
    );
    if (!ok) return;
    try {
      await service.leaveGroup(g.id);
    } on Object catch (e) {
      if (context.mounted) showSnack(context, describeChatError(s, e));
    }
  }

  Future<void> _action(BuildContext context, Group g, String action) async {
    switch (action) {
      case 'members':
        await showGroupMembersSheet(context, service: service, group: g);
      case 'copy':
        final String? chatId = g.chatId;
        if (chatId == null) return;
        final String copied = context.s.chatCopied;
        await Clipboard.setData(ClipboardData(text: chatId));
        if (context.mounted) showSnack(context, copied);
      case 'leave':
        await _leave(context, g);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Group>>(
      stream: service.groupChanges,
      initialData: service.groups,
      builder: (context, snapshot) {
        final List<Group> groups = List<Group>.of(
          snapshot.data ?? const <Group>[],
        )..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return ListView(
          children: [
            GroupInvitesInbox(service: service),
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.s.chatNoGroups,
                  textAlign: TextAlign.center,
                ),
              ),
            for (final Group g in groups)
              _GroupTile(
                key: ValueKey<String>('group_${g.id}'),
                group: g,
                selected: g.id == selectedId,
                onTap: () => onOpen(g),
                onAction: (a) => unawaited(_action(context, g, a)),
              ),
          ],
        );
      },
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    super.key,
    required this.group,
    required this.selected,
    required this.onTap,
    required this.onAction,
  });

  final Group group;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;

  List<PopupMenuEntry<String>> _items(S s) => [
    PopupMenuItem(value: 'members', child: Text(s.chatMembers)),
    if (group.chatId != null)
      PopupMenuItem(value: 'copy', child: Text(s.chatCopyChatId)),
    PopupMenuItem(value: 'leave', child: Text(s.chatLeaveGroup)),
  ];

  Future<void> _contextMenu(BuildContext context, Offset at) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final String? picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(at, at),
        Offset.zero & overlay.size,
      ),
      items: _items(context.s),
    );
    if (picked != null) onAction(picked);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final S s = context.s;
    final bool conference = group.kind == GroupKind.conference;
    return GestureDetector(
      onSecondaryTapUp: (d) =>
          unawaited(_contextMenu(context, d.globalPosition)),
      onLongPressStart: (d) =>
          unawaited(_contextMenu(context, d.globalPosition)),
      child: ListTile(
        selected: selected,
        selectedTileColor: scheme.secondaryContainer.withValues(alpha: 0.5),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.tertiaryContainer,
          child: Icon(Icons.groups, color: scheme.onTertiaryContainer),
        ),
        title: Text(group.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            s.chatMemberCount(group.memberCount),
            if (conference) s.chatConferenceBadge,
            if (group.topic.isNotEmpty) group.topic,
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: onAction,
          itemBuilder: (context) => _items(context.s),
        ),
      ),
    );
  }
}

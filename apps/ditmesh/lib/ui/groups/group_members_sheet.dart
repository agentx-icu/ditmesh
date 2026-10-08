import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../chat/chat_layout.dart';
import '../moderation/block_actions.dart';

/// Bottom sheet listing a group's members with online dots; every other
/// member can be blocked (or unblocked) from here.
Future<void> showGroupMembersSheet(
  BuildContext context, {
  required ChatService service,
  required Group group,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // Dragged to full height the handle must stay below the status bar.
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      builder: (context, scroll) => _MembersBody(
        future: service.groupMembers(group.id),
        service: service,
        group: group,
        scroll: scroll,
      ),
    ),
  );
}

class _MembersBody extends StatelessWidget {
  const _MembersBody({
    required this.future,
    required this.service,
    required this.group,
    required this.scroll,
  });

  final Future<List<GroupMember>> future;
  final ChatService service;
  final Group group;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final S s = context.s;
    return FutureBuilder<List<GroupMember>>(
      future: future,
      builder: (context, snapshot) {
        final Object? error = snapshot.error;
        if (error != null) {
          return Center(child: Text(describeChatError(s, error)));
        }
        final List<GroupMember>? members = snapshot.data;
        if (members == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          controller: scroll,
          // The sheet is edge-to-edge: the last member's menu must end above
          // the home indicator / gesture bar once the list is scrolled down.
          padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                s.chatMembersTitleCount(members.length),
                style: theme.textTheme.titleMedium,
              ),
            ),
            for (final GroupMember m in members)
              ListTile(
                leading: _OnlineDot(online: m.online),
                title: Text(
                  m.isSelf ? s.chatMemberSelf(m.displayName) : m.displayName,
                ),
                subtitle: Text(
                  m.publicKey.length > 16
                      ? '${m.publicKey.substring(0, 16)}…'
                      : m.publicKey,
                  style: theme.textTheme.bodySmall,
                ),
                trailing: m.isSelf
                    ? null
                    : _MemberMenu(service: service, member: m),
              ),
          ],
        );
      },
    );
  }
}

enum _MemberAction { block, unblock }

class _MemberMenu extends StatelessWidget {
  const _MemberMenu({required this.service, required this.member});

  final ChatService service;
  final GroupMember member;

  Future<void> _run(BuildContext context, _MemberAction action) async {
    switch (action) {
      case _MemberAction.block:
        await confirmAndBlock(
          context,
          service: service,
          publicKey: member.publicKey,
          name: member.displayName,
          scope: BlockScope.groupMember,
        );
      case _MemberAction.unblock:
        final S s = context.s;
        try {
          await service.unblockPeer(member.publicKey);
          if (context.mounted) showSnack(context, s.moderationUnblocked);
        } on Object catch (e) {
          if (context.mounted) showSnack(context, describeChatError(s, e));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = context.s;
    return PopupMenuButton<_MemberAction>(
      key: ValueKey<String>('member-menu-${member.publicKey}'),
      onSelected: (a) => unawaited(_run(context, a)),
      itemBuilder: (_) => [
        // Read when the menu opens, so a member blocked a moment ago offers
        // Unblock instead.
        if (service.blockedPeers.contains(member.publicKey.toUpperCase()))
          PopupMenuItem(
            value: _MemberAction.unblock,
            child: Text(s.moderationUnblock),
          )
        else
          PopupMenuItem(
            value: _MemberAction.block,
            child: Text(s.moderationBlock),
          ),
      ],
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot({required this.online});

  final bool online;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 6,
      backgroundColor: online ? Colors.green : scheme.outlineVariant,
    );
  }
}

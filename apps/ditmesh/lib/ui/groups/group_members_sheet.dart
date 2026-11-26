import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../account/account_widgets.dart';
import '../chat/chat_layout.dart';
import '../common/app_bar_title.dart';
import '../moderation/block_actions.dart';

/// Lists a group's members with online dots; every other
/// member can be blocked (or unblocked) from here.
Future<void> showGroupMembersSheet(
  BuildContext context, {
  required ChatService service,
  required Group group,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (context) => Scaffold(
        appBar: AppBar(title: AppBarTitle(context.s.chatMembers)),
        body: _MembersBody(
          service: service,
          group: group,
          wide: isMasterDetail(context),
        ),
      ),
    ),
  );
}

class _MembersBody extends StatefulWidget {
  const _MembersBody({
    required this.service,
    required this.group,
    this.wide = false,
  });

  final ChatService service;
  final Group group;
  final bool wide;

  @override
  State<_MembersBody> createState() => _MembersBodyState();
}

class _MembersBodyState extends State<_MembersBody> {
  late Future<List<GroupMember>> _future;
  late final StreamSubscription<List<Group>> _changes;

  @override
  void initState() {
    super.initState();
    _future = _loadMembers();
    _changes = widget.service.groupChanges.listen((groups) {
      if (groups.any((group) => group.id == widget.group.id)) _refresh();
    });
  }

  Future<List<GroupMember>> _loadMembers() =>
      widget.service.groupMembers(widget.group.id)..ignore();

  void _refresh() {
    if (!mounted) return;
    final future = _loadMembers();
    setState(() {
      _future = future;
    });
  }

  @override
  void dispose() {
    unawaited(_changes.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = widget.wide;
    final group = widget.group;
    final ThemeData theme = Theme.of(context);
    final S s = context.s;
    return FutureBuilder<List<GroupMember>>(
      future: _future,
      builder: (context, snapshot) {
        final Object? error = snapshot.error;
        if (error != null) {
          return Center(child: Text(describeChatError(s, error)));
        }
        final List<GroupMember>? members = snapshot.data;
        if (members == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = ListView(
          key: const ValueKey('group-members-list'),
          padding: EdgeInsets.only(top: wide ? 16 : 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!wide)
                          Semantics(
                            header: true,
                            child: Text(
                              group.name,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                        Text(
                          s.chatMembersTitleCount(members.length),
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('group-members-refresh'),
                    tooltip: s.chatRefreshMembers,
                    onPressed:
                        snapshot.connectionState == ConnectionState.waiting
                        ? null
                        : _refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            for (final GroupMember m in members)
              ListTile(
                leading: _OnlineDot(online: m.online),
                title: Text(
                  m.isSelf ? s.chatMemberSelf(m.displayName) : m.displayName,
                ),
                subtitle: Wrap(
                  spacing: 8,
                  children: [
                    Text(m.online ? s.connectionOnline : s.connectionOffline),
                    Text(
                      m.publicKey.length > 16
                          ? '${m.publicKey.substring(0, 16)}…'
                          : m.publicKey,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                trailing: m.isSelf
                    ? null
                    : _MemberMenu(service: widget.service, member: m),
              ),
          ],
        );
        if (!wide) return SafeArea(child: list);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: list,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: AccountPanel(
                    children: [
                      Text(group.name, style: theme.textTheme.titleMedium),
                      Text(s.chatMemberCount(members.length)),
                      if (group.kind == GroupKind.conference)
                        Text(s.chatConferenceBadge),
                      if (group.chatId case final id?) ...[
                        const SizedBox(height: 12),
                        Text(
                          s.chatChatIdLabel,
                          style: theme.textTheme.labelLarge,
                        ),
                        SelectableText(groupToxId(id)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Member preview alongside the history when the conversation has space.
class GroupMembersPreview extends StatefulWidget {
  const GroupMembersPreview({
    super.key,
    required this.service,
    required this.group,
    required this.onMembers,
    required this.onPractice,
  });

  final ChatService service;
  final Group group;
  final VoidCallback onMembers;
  final VoidCallback onPractice;

  @override
  State<GroupMembersPreview> createState() => _GroupMembersPreviewState();
}

class _GroupMembersPreviewState extends State<GroupMembersPreview> {
  late Future<List<GroupMember>> _members;
  late StreamSubscription<List<Group>> _changes;

  void _load() {
    _members = widget.service.groupMembers(widget.group.id)..ignore();
  }

  void _listen() {
    _load();
    _changes = widget.service.groupChanges.listen((groups) {
      if (mounted && groups.any((group) => group.id == widget.group.id)) {
        setState(_load);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(GroupMembersPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service ||
        oldWidget.group.id != widget.group.id) {
      unawaited(_changes.cancel());
      _listen();
    }
  }

  @override
  void dispose() {
    unawaited(_changes.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return FutureBuilder<List<GroupMember>>(
      future: _members,
      builder: (context, snapshot) {
        final members = snapshot.data;
        return AccountPanel(
          children: [
            Text(s.chatMembers, style: Theme.of(context).textTheme.titleMedium),
            if (members != null)
              for (final member in members.take(4))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: _OnlineDot(online: member.online),
                  title: Text(
                    member.isSelf
                        ? s.chatMemberSelf(member.displayName)
                        : member.displayName,
                  ),
                  subtitle: Text(
                    member.online ? s.connectionOnline : s.connectionOffline,
                  ),
                )
            else if (snapshot.hasError)
              Text(describeChatError(s, snapshot.error!))
            else
              const LinearProgressIndicator(),
            TextButton(onPressed: widget.onMembers, child: Text(s.chatMembers)),
            TextButton(
              onPressed: widget.onPractice,
              child: Text(s.groupPracticeTitle),
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

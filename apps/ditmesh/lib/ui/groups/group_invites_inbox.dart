import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../chat/chat_layout.dart';
import '../chat/chat_session_epoch.dart';
import '../contacts/tox_id.dart';
import '../moderation/block_actions.dart';
import 'group_password_dialog.dart';

/// Pending group invites with accept and a menu (accept with password,
/// reject, block); hidden when empty. An invite's actions stay disabled
/// while an answer to it is in flight, password prompt included. An invite
/// whose group refused us for its password (it is listed again) asks for
/// the password on the next accept.
class GroupInvitesInbox extends StatefulWidget {
  const GroupInvitesInbox({super.key, required this.service});

  final ChatService service;

  @override
  State<GroupInvitesInbox> createState() => _GroupInvitesInboxState();
}

class _GroupInvitesInboxState extends State<GroupInvitesInbox> {
  final Set<String> _busy = <String>{};

  /// Bumped when the service or its session changes: an answer of the old
  /// one finishing later must not release the new one's busy marker.
  int _busyGeneration = 0;

  /// Invites refused for their password. Not pruned when an invite leaves
  /// the list: an accept removes it until the refusal hands it back.
  final Set<String> _needsPassword = <String>{};
  StreamSubscription<GroupJoinRefusal>? _refusals;
  late ChatSessionEpoch _epoch;

  ChatService get service => widget.service;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(GroupInvitesInbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.service, service)) return;
    _listen();
  }

  void _forgetSession() {
    _needsPassword.clear();
    _busy.clear();
    _busyGeneration++;
  }

  @override
  void dispose() {
    unawaited(_refusals?.cancel());
    _epoch.dispose();
    super.dispose();
  }

  void _listen() {
    if (_refusals != null) {
      unawaited(_refusals!.cancel());
      _epoch.dispose();
    }
    // Invite ids are per session: a new one forgets the old markers.
    _forgetSession();
    _epoch = ChatSessionEpoch(
      service,
      onBoundary: () {
        if (mounted) setState(_forgetSession);
      },
    );
    _refusals = service.groupJoinRefusals.listen((r) {
      final String? id = r.inviteId;
      if (id == null || r.reason != GroupJoinRefusalReason.invalidPassword) {
        return;
      }
      if (mounted) setState(() => _needsPassword.add(id));
    });
  }

  /// Accepts [i], first asking for the password when [withPassword]; a
  /// cancelled prompt answers nothing.
  Future<void> _accept(GroupInvite i, {required bool withPassword}) async {
    final ChatService target = service;
    final ChatSessionToken session = _epoch.capture();
    String? password;
    if (withPassword) {
      password = await showGroupPasswordDialog(context, groupName: i.groupName);
      // The prompt outlived the session (or the service) it was for: the
      // invite id may now name another invite.
      if (password == null || !mounted || !session.isCurrent(service)) {
        return;
      }
    }
    await target.acceptGroupInvite(i.inviteId, password: password);
  }

  Future<void> _menu(GroupInvite i, String action) => switch (action) {
    'password' => _run(i.inviteId, () => _accept(i, withPassword: true)),
    'reject' => _run(i.inviteId, () async {
      await service.rejectGroupInvite(i.inviteId);
      _needsPassword.remove(i.inviteId);
    }),
    _ => _run(
      i.inviteId,
      () => confirmAndBlock(
        context,
        service: service,
        publicKey: i.fromPublicKey,
        name: shortKey(i.fromPublicKey, length: 12),
        scope: BlockScope.contact,
      ),
    ),
  };

  Future<void> _run(String id, Future<void> Function() op) async {
    if (!_busy.add(id)) return;
    final int generation = _busyGeneration;
    setState(() {});
    final S s = context.s;
    try {
      await op();
    } on Object catch (e) {
      if (mounted) showSnack(context, describeChatError(s, e));
    } finally {
      if (mounted && generation == _busyGeneration) {
        setState(() => _busy.remove(id));
      }
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
                    PopupMenuButton<String>(
                      key: ValueKey<String>('invite_menu_${i.inviteId}'),
                      enabled: !_busy.contains(i.inviteId),
                      onSelected: (a) => unawaited(_menu(i, a)),
                      itemBuilder: (context) => [
                        if (i.kind == GroupKind.group)
                          PopupMenuItem(
                            value: 'password',
                            child: Text(s.chatAcceptWithPassword),
                          ),
                        PopupMenuItem(
                          value: 'reject',
                          child: Text(s.chatReject),
                        ),
                        PopupMenuItem(
                          value: 'block',
                          child: Text(s.moderationBlock),
                        ),
                      ],
                    ),
                    IconButton.filled(
                      tooltip: s.chatAccept,
                      icon: const Icon(Icons.check),
                      onPressed: _busy.contains(i.inviteId)
                          ? null
                          : () => unawaited(
                              _run(
                                i.inviteId,
                                () => _accept(
                                  i,
                                  withPassword: _needsPassword.contains(
                                    i.inviteId,
                                  ),
                                ),
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

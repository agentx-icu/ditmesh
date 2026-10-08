import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../chat/chat_layout.dart';
import '../moderation/block_actions.dart';
import 'tox_id.dart';

/// Pending inbound friend requests with block / reject / accept. Renders nothing
/// when the inbox is empty and [showWhenEmpty] is false. A request's buttons
/// stay disabled while an answer to it is in flight, so a double tap cannot
/// send a second accept (or race an accept against a reject).
class FriendRequestInbox extends StatefulWidget {
  const FriendRequestInbox({
    super.key,
    required this.service,
    this.showWhenEmpty = false,
  });

  final ChatService service;
  final bool showWhenEmpty;

  @override
  State<FriendRequestInbox> createState() => _FriendRequestInboxState();
}

class _FriendRequestInboxState extends State<FriendRequestInbox> {
  final Set<String> _busy = <String>{};

  ChatService get service => widget.service;

  Future<void> _run(String key, Future<void> Function() op) async {
    if (!_busy.add(key)) return;
    setState(() {});
    final S s = context.s;
    try {
      await op();
    } on Object catch (e) {
      if (mounted) showSnack(context, describeChatError(s, e));
    } finally {
      if (mounted) setState(() => _busy.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final S s = context.s;
    return StreamBuilder<List<FriendRequest>>(
      stream: service.friendRequestChanges,
      initialData: service.friendRequests,
      builder: (context, snapshot) {
        final List<FriendRequest> requests =
            snapshot.data ?? const <FriendRequest>[];
        if (requests.isEmpty && !widget.showWhenEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                s.chatFriendRequestsCount(requests.length),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            if (requests.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(s.chatNoRequests),
              ),
            for (final FriendRequest r in requests)
              ListTile(
                key: ValueKey<String>('req_${r.publicKey}'),
                leading: const CircleAvatar(child: Icon(Icons.person_add_alt)),
                title: Text(shortKey(r.publicKey, length: 16)),
                subtitle: Text(
                  r.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: ValueKey<String>('req_block_${r.publicKey}'),
                      tooltip: s.moderationBlock,
                      icon: const Icon(Icons.block),
                      onPressed: _busy.contains(r.publicKey)
                          ? null
                          : () => unawaited(
                              _run(
                                r.publicKey,
                                () => confirmAndBlock(
                                  context,
                                  service: service,
                                  publicKey: r.publicKey,
                                  name: shortKey(r.publicKey, length: 16),
                                  scope: BlockScope.contact,
                                ),
                              ),
                            ),
                    ),
                    IconButton(
                      tooltip: s.chatReject,
                      icon: Icon(Icons.close, color: theme.colorScheme.error),
                      onPressed: _busy.contains(r.publicKey)
                          ? null
                          : () => unawaited(
                              _run(
                                r.publicKey,
                                () => service.rejectFriendRequest(r.publicKey),
                              ),
                            ),
                    ),
                    IconButton.filled(
                      tooltip: s.chatAccept,
                      icon: const Icon(Icons.check),
                      onPressed: _busy.contains(r.publicKey)
                          ? null
                          : () => unawaited(
                              _run(
                                r.publicKey,
                                () => service.acceptFriendRequest(r.publicKey),
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../../nearby/nearby_controller.dart';
import '../account/account_widgets.dart';
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
    this.showPublicKeys = false,
  });

  final ChatService service;
  final bool showWhenEmpty;
  final bool showPublicKeys;

  @override
  State<FriendRequestInbox> createState() => _FriendRequestInboxState();
}

class _FriendRequestInboxState extends State<FriendRequestInbox> {
  final Set<String> _busy = <String>{};

  ChatService get service => widget.service;

  Future<void> _reject(FriendRequest request) async {
    final s = context.s;
    final agrees = await confirm(
      context,
      title: s.chatRejectRequestTitle,
      body: s.chatRejectRequestBody,
      confirmLabel: s.chatReject,
    );
    if (!agrees || !mounted) return;
    await service.rejectFriendRequest(request.publicKey);
    if (mounted) showSnack(context, s.chatRequestRejected);
  }

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
    final nearby = context.watch<NearbyController?>();
    String replyName(String raw) {
      final name = PeerText.singleLine(raw);
      return name.isEmpty ? s.nearbyUnnamed : name;
    }

    String requestText(FriendRequest request) {
      final reply = nearby?.replyFor(request.publicKey);
      return reply == null
          ? request.message
          : '${shortKey(request.publicKey, length: 16)}\n${s.nearbyReplyBody(replyName(reply.targetName))}';
    }

    String requestTitle(FriendRequest request) {
      final reply = nearby?.replyFor(request.publicKey);
      return reply == null
          ? shortKey(request.publicKey, length: 16)
          : replyName(reply.targetName);
    }

    return StreamBuilder<List<FriendRequest>>(
      stream: service.friendRequestChanges,
      initialData: service.friendRequests,
      builder: (context, snapshot) {
        final List<FriendRequest> requests =
            snapshot.data ?? const <FriendRequest>[];
        if (requests.isEmpty && !widget.showWhenEmpty) {
          return const SizedBox.shrink();
        }
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
            for (final FriendRequest r in requests) ...[
              ListTile(
                key: ValueKey<String>('req_${r.publicKey}'),
                leading: const CircleAvatar(child: Icon(Icons.person_add_alt)),
                title: Text(requestTitle(r)),
                subtitle: Text(
                  requestText(r),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.showPublicKeys)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.chatRequestPublicKey,
                        style: theme.textTheme.labelMedium,
                      ),
                      SelectableText(
                        groupToxId(r.publicKey),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Tooltip(
                      message: s.chatAccept,
                      child: FilledButton.icon(
                        onPressed: _busy.contains(r.publicKey)
                            ? null
                            : () => unawaited(
                                _run(
                                  r.publicKey,
                                  () =>
                                      service.acceptFriendRequest(r.publicKey),
                                ),
                              ),
                        icon: const Icon(Icons.check),
                        label: Text(s.chatAccept),
                      ),
                    ),
                    Tooltip(
                      message: s.chatReject,
                      child: OutlinedButton.icon(
                        onPressed: _busy.contains(r.publicKey)
                            ? null
                            : () => unawaited(
                                _run(r.publicKey, () => _reject(r)),
                              ),
                        icon: const Icon(Icons.close),
                        label: Text(s.chatReject),
                      ),
                    ),
                    Tooltip(
                      message: s.moderationBlock,
                      child: TextButton.icon(
                        key: ValueKey<String>('req_block_${r.publicKey}'),
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
                                    scope: BlockScope.friendRequest,
                                  ),
                                ),
                              ),
                        icon: const Icon(Icons.block),
                        label: Text(s.moderationBlock),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(),
          ],
        );
      },
    );
  }
}

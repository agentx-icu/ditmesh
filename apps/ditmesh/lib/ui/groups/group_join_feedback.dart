import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../chat/chat_layout.dart';
import '../chat/chat_session_epoch.dart';
import '../contacts/tox_id.dart';
import 'group_password_dialog.dart';

/// Tells the user when a group refused a join after the request had been
/// sent (wrong or missing password, full group, a held group refusing to
/// reconnect), with a Retry that asks for the password. Wraps the groups
/// page, which the shell keeps mounted, so the message reaches every tab.
class GroupJoinFeedback extends StatefulWidget {
  const GroupJoinFeedback({
    super.key,
    required this.service,
    required this.child,
  });

  final ChatService service;
  final Widget child;

  @override
  State<GroupJoinFeedback> createState() => _GroupJoinFeedbackState();
}

/// The name shown for [r]: the group's, else a short chat id, else its id.
String refusedGroupLabel(GroupJoinRefusal r) {
  if (r.groupName.isNotEmpty) return r.groupName;
  final String? chatId = r.chatId;
  if (chatId != null) return shortKey(chatId, length: 12);
  return r.groupId;
}

/// Localized text for [r].
String groupJoinRefusalMessage(S s, GroupJoinRefusal r) {
  final String name = refusedGroupLabel(r);
  if (r.established) return s.chatGroupReconnectRefused(name);
  return switch (r.reason) {
    GroupJoinRefusalReason.invalidPassword => s.chatGroupJoinRefusedPassword(
      name,
    ),
    GroupJoinRefusalReason.groupFull => s.chatGroupJoinRefusedFull(name),
    GroupJoinRefusalReason.unknown => s.chatGroupJoinRefused(name),
  };
}

/// The call that retries [r] with [password], or null when there is none:
/// the invite again (a private group cannot be joined by chat id), a held
/// group by its own id, any other join by chat id.
Future<void> Function(String password)? groupJoinRetry(
  ChatService service,
  GroupJoinRefusal r,
) {
  final String? inviteId = r.inviteId;
  final String? chatId = r.chatId;
  if (inviteId != null) {
    return (p) => service.acceptGroupInvite(inviteId, password: p);
  }
  if (r.established) {
    return (p) => service.rejoinGroup(r.groupId, password: p);
  }
  if (chatId != null) return (p) => service.joinGroup(chatId, password: p);
  return null;
}

class _GroupJoinFeedbackState extends State<GroupJoinFeedback> {
  StreamSubscription<GroupJoinRefusal>? _sub;
  late ChatSessionEpoch _epoch;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(GroupJoinFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.service, widget.service)) _listen();
  }

  void _listen() {
    if (_sub != null) {
      unawaited(_sub!.cancel());
      _epoch.dispose();
    }
    _epoch = ChatSessionEpoch(widget.service);
    _sub = widget.service.groupJoinRefusals.listen(_onRefusal);
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    _epoch.dispose();
    super.dispose();
  }

  void _onRefusal(GroupJoinRefusal r) {
    if (!mounted) return;
    final S s = context.s;
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    if (messenger == null) return;
    final retry = groupJoinRetry(widget.service, r);
    final ChatSessionToken session = _epoch.capture();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(groupJoinRefusalMessage(s, r)),
          duration: const Duration(seconds: 8),
          action: retry == null
              ? null
              : SnackBarAction(
                  label: s.actionRetry,
                  onPressed: () => unawaited(_retry(r, retry, session)),
                ),
        ),
      );
  }

  /// A refusal from an earlier session (or service) is not retried: its
  /// ids may name something else in the session now open.
  bool _stale(ChatSessionToken session) =>
      !mounted || !session.isCurrent(widget.service);

  Future<void> _retry(
    GroupJoinRefusal r,
    Future<void> Function(String password) retry,
    ChatSessionToken session,
  ) async {
    if (_stale(session)) return;
    final S s = context.s;
    final String? password = await showGroupPasswordDialog(
      context,
      groupName: refusedGroupLabel(r),
    );
    if (password == null || _stale(session)) return;
    try {
      await retry(password);
    } on Object catch (e) {
      if (mounted) showSnack(context, describeChatError(s, e));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

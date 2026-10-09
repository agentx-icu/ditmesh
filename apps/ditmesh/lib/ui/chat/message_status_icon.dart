import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/l10n_extension.dart';
import 'chat_scope.dart';

/// Delivery glyph for our own messages. Pending gets a tooltip explaining
/// that Tox has no server: nothing is lost, it waits for the peer.
class MessageStatusIcon extends StatelessWidget {
  const MessageStatusIcon(
    this.status, {
    super.key,
    this.size = 14,
    this.message,
  });

  final MessageStatus status;
  final double size;
  final ChatMessage? message;

  bool get _self =>
      message != null &&
      message!.isMine &&
      message!.conversationId.toUpperCase() ==
          'C2C_${message!.senderId.toUpperCase()}';
  bool get _group => message?.conversationId.startsWith('group_') ?? false;

  String _detail(BuildContext context, MessageStatus current) {
    final s = context.s;
    if (_self) return s.deliveryLocalDetail;
    return switch (current) {
      MessageStatus.sent => s.deliverySentDetail,
      MessageStatus.delivered =>
        _group ? s.deliveryGroupDetail : s.deliveryPeerDetail,
      MessageStatus.pending => _pendingReason(context),
      MessageStatus.sending => s.messageStatusSending,
      MessageStatus.failed => s.messageStatusFailed,
      MessageStatus.cancelled => s.messageStatusCancelled,
      MessageStatus.received => s.deliveryPeerDetail,
    };
  }

  String _pendingReason(BuildContext context) {
    final s = context.s;
    final local = maybeIdentityService(context)?.connectionStatus;
    if (local == ConnectionStatus.offline ||
        local == ConnectionStatus.connecting) {
      return '${s.deliveryLocalOffline}\n${s.messageStatusPendingDetail}';
    }
    if (_group) {
      return '${s.deliveryGroupWaiting}\n${s.messageStatusPendingDetail}';
    }
    final m = message;
    if (m != null) {
      final peer = m.conversationId
          .substring(m.conversationId.indexOf('_') + 1)
          .toUpperCase();
      final friends = maybeChatService(context)?.friends;
      if (friends?.any((f) => f.publicKey.toUpperCase() == peer && !f.online) ??
          false) {
        return '${s.deliveryPeerOffline}\n${s.messageStatusPendingDetail}';
      }
    }
    return s.messageStatusPendingDetail;
  }

  void _showDetail(BuildContext context) {
    final service = maybeChatService(context);
    final identity = maybeIdentityService(context);
    final m = message;
    final latest = ValueNotifier<ChatMessage?>(null);
    var active = true;
    var liveUpdate = false;
    // Start observing before the sheet's route is built: a transport receipt
    // between this tap and the next frame must not disappear.
    final subscription = m == null
        ? null
        : service?.messageEvents
              .where(
                (event) =>
                    event.conversationId == m.conversationId &&
                    event.id == m.id,
              )
              .listen((event) {
                if (!active) return;
                liveUpdate = true;
                latest.value = event;
              });
    if (m != null && service != null) {
      unawaited(
        service
            .loadAround(m.conversationId, m.id, before: 0, after: 0)
            .then((rows) {
              if (active && !liveUpdate && rows.isNotEmpty) {
                latest.value = rows.first;
              }
            })
            .catchError((Object _) {}),
      );
    }
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => StreamBuilder<List<Friend>>(
          stream: service?.friendChanges,
          builder: (context, _) => StreamBuilder<ConnectionStatus>(
            stream: identity?.connectionChanges,
            builder: (context, _) => ValueListenableBuilder<ChatMessage?>(
              valueListenable: latest,
              builder: (context, current, _) => SafeArea(
                child: SingleChildScrollView(
                  key: const ValueKey('delivery-details'),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.s.deliveryDetailsTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(_detail(context, current?.status ?? status)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ).whenComplete(() {
        active = false;
        unawaited(subscription?.cancel());
        latest.dispose();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (status == MessageStatus.received) return const SizedBox.shrink();
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final S s = context.s;
    final (IconData icon, Color color, String tip) = switch (status) {
      MessageStatus.pending => (
        Icons.schedule,
        scheme.onSurfaceVariant,
        '${s.messageStatusPending}\n${s.messageStatusPendingDetail}',
      ),
      MessageStatus.sending => (
        Icons.more_horiz,
        scheme.onSurfaceVariant,
        s.messageStatusSending,
      ),
      MessageStatus.sent => (
        _self ? Icons.save_outlined : Icons.check,
        scheme.primary,
        _self ? s.deliveryLocalTitle : s.messageStatusSent,
      ),
      MessageStatus.delivered => (
        Icons.done_all,
        scheme.primary,
        _group ? s.deliveryGroupTitle : s.deliveryPeerTitle,
      ),
      MessageStatus.failed => (
        Icons.error_outline,
        scheme.error,
        s.messageStatusFailed,
      ),
      MessageStatus.cancelled => (
        Icons.block,
        scheme.onSurfaceVariant,
        s.messageStatusCancelled,
      ),
      MessageStatus.received => (Icons.check, Colors.transparent, ''),
    };
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: () => _showDetail(context),
        child: SizedBox.square(
          dimension: 48,
          child: Icon(icon, size: size, color: color, semanticLabel: tip),
        ),
      ),
    );
  }
}

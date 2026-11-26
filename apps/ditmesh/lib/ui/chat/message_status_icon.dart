import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/l10n_extension.dart';
import '../../i18n/system_date_time.dart';
import '../account/account_widgets.dart';
import '../common/app_bar_title.dart';
import 'chat_scope.dart';
import 'morse_pattern_text.dart';
import 'pending_messages_page.dart';
import 'playback_timeline.dart';

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
      MessageStatus.failed => s.deliveryFailedNext,
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
    Widget observe(Widget Function(BuildContext, ChatMessage?) content) =>
        StreamBuilder<List<Friend>>(
          stream: service?.friendChanges,
          builder: (context, _) => StreamBuilder<ConnectionStatus>(
            stream: identity?.connectionChanges,
            builder: (context, _) => ValueListenableBuilder<ChatMessage?>(
              valueListenable: latest,
              builder: (context, current, _) => content(context, current ?? m),
            ),
          ),
        );
    final route = Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: AppBarTitle(context.s.deliveryDetailsTitle)),
          body: observe(_detailPage),
        ),
      ),
    );
    unawaited(
      route.whenComplete(() {
        active = false;
        unawaited(subscription?.cancel());
        latest.dispose();
      }),
    );
  }

  Widget _detailPage(BuildContext context, ChatMessage? row) {
    final s = context.s;
    final state = row?.status ?? status;
    final colors = Theme.of(context).colorScheme;
    final acknowledged = state == MessageStatus.delivered && !_self;
    final stages = <Widget>[
      if (acknowledged)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.check, color: colors.primary),
          title: Text(s.messageStatusSent),
        ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          switch (state) {
            MessageStatus.failed => Icons.error_outline,
            MessageStatus.pending => Icons.schedule,
            MessageStatus.sending => Icons.more_horiz,
            MessageStatus.cancelled => Icons.block,
            MessageStatus.delivered => Icons.done_all,
            _ => _self ? Icons.save_outlined : Icons.check,
          },
          color: state == MessageStatus.failed ? colors.error : colors.primary,
        ),
        title: Text(
          _self
              ? s.deliveryLocalTitle
              : switch (state) {
                  MessageStatus.pending => s.messageStatusPending,
                  MessageStatus.sending => s.messageStatusSending,
                  MessageStatus.sent => s.messageStatusSent,
                  MessageStatus.delivered =>
                    _group ? s.deliveryGroupTitle : s.deliveryPeerTitle,
                  MessageStatus.failed => s.messageStatusFailed,
                  MessageStatus.cancelled => s.messageStatusCancelled,
                  MessageStatus.received => s.deliveryPeerTitle,
                },
        ),
        subtitle: Text(_detail(context, state)),
      ),
      if (maybeChatService(context) case final ChatService service
          when state == MessageStatus.failed)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            icon: const Icon(Icons.outbox_outlined),
            label: Text(s.pendingMessagesTitle),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => PendingMessagesPage(service: service),
              ),
            ),
          ),
        ),
    ];
    return AccountPageBody(
      key: const ValueKey('delivery-details'),
      aside: [
        if (row != null)
          AccountPanel(
            children: [
              if (!row.isLocation) ...[
                MorsePatternText(PlaybackTimeline.patternFor(row.text)),
                const SizedBox(height: 8),
                SelectableText(row.text),
              ],
              const SizedBox(height: 8),
              Text(
                s.deliveryMessageTime,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Text(formatSystemDateTime(context, row.timestamp)),
            ],
          ),
      ],
      children: [AccountPanel(children: stages)],
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

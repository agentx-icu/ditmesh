import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/l10n_extension.dart';

/// Delivery glyph for our own messages. Pending gets a tooltip explaining
/// that Tox has no server: nothing is lost, it waits for the peer.
class MessageStatusIcon extends StatelessWidget {
  const MessageStatusIcon(this.status, {super.key, this.size = 14});

  final MessageStatus status;
  final double size;

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
      MessageStatus.sent => (Icons.check, scheme.primary, s.messageStatusSent),
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
      child: Icon(icon, size: size, color: color, semanticLabel: tip),
    );
  }
}

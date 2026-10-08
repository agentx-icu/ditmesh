import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../i18n/l10n_extension.dart';
import '../../startup/startup_controller.dart';

/// [child] (the shell) below a strip that holds the [ConnectionChip] while
/// the node is not online.
///
/// The chip used to float over the shell's top-right corner — exactly where
/// every page puts its app-bar actions — and swallowed their taps for as long
/// as the node was connecting or offline (the Chat page's Contacts button on a
/// phone, the detail pane's menu on desktop). In its own strip it covers
/// nothing. The strip takes the top safe-area inset and removes it from
/// [child], so nothing is padded twice; the tree keeps the same shape in both
/// states, so the shell is never remounted when the status flips.
class ConnectionStrip extends StatelessWidget {
  const ConnectionStrip({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final identity = context.read<IdentityService>();
    return StreamBuilder<ConnectionStatus>(
      stream: identity.connectionChanges,
      initialData: identity.connectionStatus,
      builder: (context, snapshot) {
        final bool visible = snapshot.data != ConnectionStatus.online;
        final MediaQueryData media = MediaQuery.of(context);
        return Column(
          children: [
            if (visible) const _Strip() else const SizedBox.shrink(),
            Expanded(
              child: MediaQuery(
                data: visible
                    ? media
                          .removePadding(removeTop: true)
                          .removeViewPadding(removeTop: true)
                    : media,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: const SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ConnectionChip(),
          ),
        ),
      ),
    );
  }
}

/// Small status chip: visible while connecting or offline, gone once online.
/// Tapping an offline chip retries `connect()`.
class ConnectionChip extends StatelessWidget {
  const ConnectionChip({super.key, this.alwaysVisible = false});

  /// Show the chip even when online (Me page uses this).
  final bool alwaysVisible;

  @override
  Widget build(BuildContext context) {
    final identity = context.read<IdentityService>();
    return StreamBuilder<ConnectionStatus>(
      stream: identity.connectionChanges,
      initialData: identity.connectionStatus,
      builder: (context, snapshot) {
        final status = snapshot.data ?? ConnectionStatus.offline;
        if (status == ConnectionStatus.online && !alwaysVisible) {
          return const SizedBox.shrink();
        }
        return _StatusChip(status: status);
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final scheme = Theme.of(context).colorScheme;
    // Shared `connection*` keys: the chat list uses the same words.
    final (label, color, icon) = switch (status) {
      ConnectionStatus.online => (
        s.connectionOnline,
        scheme.primary,
        Icons.cloud_done_outlined,
      ),
      ConnectionStatus.connecting => (
        s.connectionConnecting,
        scheme.tertiary,
        Icons.cloud_sync_outlined,
      ),
      ConnectionStatus.offline => (
        s.connectionOffline,
        scheme.error,
        Icons.cloud_off_outlined,
      ),
    };
    final offline = status == ConnectionStatus.offline;
    // The gate's strip shows this chip outside any Scaffold, so bring our own
    // Material ancestor; inside a card it is transparent and harmless.
    return Material(
      type: MaterialType.transparency,
      child: Tooltip(
        message: offline ? s.accountConnectionTapToReconnect : label,
        child: ActionChip(
          avatar: Icon(icon, size: 18, color: color),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          labelStyle: TextStyle(color: color, fontSize: 12),
          visualDensity: VisualDensity.compact,
          onPressed: offline
              ? () => context.read<StartupController>().reconnect().ignore()
              : null,
        ),
      ),
    );
  }
}

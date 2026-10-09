import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../diagnostics/connection_diagnostics.dart';
import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../common/app_bar_title.dart';

/// Connection diagnostics (F09): what the device observed about its own Tox
/// connection, the selected contact and the durable outbox, in plain words,
/// plus the one recovery action (reconnect). Read-only otherwise.
class ConnectionDiagnosticsPage extends StatelessWidget {
  const ConnectionDiagnosticsPage({super.key, this.conversationId});

  /// Scope the contact and queue facts to this conversation; null shows the
  /// whole identity.
  final String? conversationId;

  static Future<void> open(BuildContext context, {String? conversationId}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ConnectionDiagnosticsPage(conversationId: conversationId),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final diagnostics = context.watch<ConnectionDiagnostics>();
    final snap = diagnostics.snapshot(conversationId: conversationId);
    final locale = Localizations.localeOf(context).toString();
    String time(DateTime at) =>
        DateFormat.yMd(locale).add_Hm().format(at.toLocal());
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(s.diagTitle)),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _SummaryCard(snapshot: snap),
                if (snap.identityKey != null) ...[
                  _Fact(
                    icon: _statusIcon(snap.status),
                    label: s.diagLocalLabel,
                    value: _statusLabel(s, snap.status),
                    detail: _since(s, snap, time),
                  ),
                  _Fact(
                    icon: Icons.history,
                    label: s.diagLastOnlineLabel,
                    value: snap.status == ConnectionStatus.online
                        ? s.diagLastOnlineNow
                        : snap.lastOnlineAt == null
                        ? s.diagLastOnlineNone
                        : time(snap.lastOnlineAt!),
                    detail: s.diagLastOnlineHint,
                  ),
                  if (conversationId != null &&
                      snap.peer != PeerAvailability.notApplicable)
                    _Fact(
                      icon: Icons.person_outline,
                      label: s.diagPeerLabel,
                      value: switch (snap.peer) {
                        PeerAvailability.online => s.connectionOnline,
                        PeerAvailability.offline => s.connectionOffline,
                        _ => s.diagUnknown,
                      },
                      detail: snap.peer == PeerAvailability.unknown
                          ? (conversationId!.startsWith('group_')
                                ? s.diagPeerGroupHint
                                : s.diagPeerUnknownHint)
                          : null,
                    ),
                  _Fact(
                    icon: Icons.outbox_outlined,
                    label: s.diagPendingLabel,
                    value: _pendingValue(s, snap.pending),
                    detail: [
                      if (snap.pending?.oldest case final DateTime oldest)
                        s.diagPendingOldest(time(oldest)),
                      s.diagPendingHint,
                    ].join('\n'),
                  ),
                  _ReconnectSection(snapshot: snap),
                ],
                const Divider(height: 32),
                ListTile(
                  leading: const Icon(Icons.hub_outlined),
                  title: Text(s.diagAboutTitle),
                  subtitle: Text(s.diagAboutBody),
                ),
                if (snap.identityKey != null) _Details(snapshot: snap),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String? _since(
    S s,
    ConnectionDiagnosticsSnapshot snap,
    String Function(DateTime) time,
  ) {
    final since = snap.statusSince;
    if (since == null) return null;
    return switch (snap.statusSinceKind) {
      StatusSinceKind.changed => s.diagSinceChanged(time(since)),
      StatusSinceKind.firstObserved => s.diagSinceFirst(time(since)),
      StatusSinceKind.resumed => s.diagSinceResumed(time(since)),
    };
  }

  static String _pendingValue(S s, PendingOutboxSummary? pending) {
    if (pending == null) return s.diagPendingUnknown;
    if (pending.count == 0) return s.diagPendingNone;
    return s.diagPendingCount(pending.count);
  }
}

String _statusLabel(S s, ConnectionStatus status) => switch (status) {
  ConnectionStatus.online => s.connectionOnline,
  ConnectionStatus.connecting => s.connectionConnecting,
  ConnectionStatus.offline => s.connectionOffline,
};

IconData _statusIcon(ConnectionStatus status) => switch (status) {
  ConnectionStatus.online => Icons.cloud_done_outlined,
  ConnectionStatus.connecting => Icons.cloud_sync_outlined,
  ConnectionStatus.offline => Icons.cloud_off_outlined,
};

/// The user's situation in one paragraph. Local state and contact state are
/// separate: "you are online, they are not" never reads like "you are
/// offline".
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.snapshot});

  final ConnectionDiagnosticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final scheme = Theme.of(context).colorScheme;
    final snap = snapshot;
    final String text;
    final bool good;
    if (snap.identityKey == null) {
      text = s.diagSummaryNoIdentity;
      good = false;
    } else {
      switch (snap.status) {
        case ConnectionStatus.online:
          good = snap.peer != PeerAvailability.offline;
          text = switch (snap.peer) {
            PeerAvailability.online => s.diagSummaryOnlinePeerOnline,
            PeerAvailability.offline => s.diagSummaryOnlinePeerOffline,
            _ => s.diagSummaryOnline,
          };
        case ConnectionStatus.connecting:
          good = false;
          text = s.diagSummaryConnecting;
        case ConnectionStatus.offline:
          good = false;
          text = s.diagSummaryOffline;
      }
    }
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: good ? scheme.secondaryContainer : scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _statusIcon(snap.status),
              color: good
                  ? scheme.onSecondaryContainer
                  : scheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                key: const ValueKey('diag-summary'),
                style: TextStyle(
                  color: good
                      ? scheme.onSecondaryContainer
                      : scheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: theme.textTheme.labelLarge),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.titleMedium),
          if (detail case final String d) Text(d),
        ],
      ),
    );
  }
}

class _ReconnectSection extends StatelessWidget {
  const _ReconnectSection({required this.snapshot});

  final ConnectionDiagnosticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final running = snapshot.reconnect == ReconnectState.running;
    final code = snapshot.errorCode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            key: const ValueKey('diag-reconnect'),
            // Disabled while running: taps cannot start a second attempt
            // (the controller coalesces them too).
            onPressed: running
                ? null
                : () => context.read<ConnectionDiagnostics>().reconnect(),
            icon: running
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: Text(running ? s.diagReconnecting : s.diagReconnect),
          ),
          const SizedBox(height: 8),
          if (code != null)
            Text(
              s.diagReconnectFailed(chatErrorMessage(s, code)),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          Text(s.diagReconnectNote),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.snapshot});

  final ConnectionDiagnosticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final snap = snapshot;
    final key = snap.identityKey ?? '';
    final rows = <(String, String)>[
      (s.diagDetailIdentity, key.length > 16 ? key.substring(0, 16) : key),
      (s.diagDetailStatus, snap.status.name),
      (s.diagDetailObserved, snap.observedAt.toLocal().toIso8601String()),
      if (snap.pending case final PendingOutboxSummary p)
        (s.diagDetailQueued, '${p.count}'),
      if (snap.errorCode case final String code) (s.diagDetailError, code),
    ];
    return ExpansionTile(
      leading: const Icon(Icons.info_outline),
      title: Text(s.diagDetailsTitle),
      children: [
        for (final (label, value) in rows)
          ListTile(
            dense: true,
            title: Text(label),
            subtitle: SelectableText(value),
          ),
      ],
    );
  }
}

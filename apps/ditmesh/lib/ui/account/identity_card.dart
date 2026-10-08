import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/l10n_extension.dart';
import 'account_widgets.dart';
import 'avatar_initial.dart';
import 'connection_chip.dart';
import 'tox_id_qr_dialog.dart';

/// Header card on the Me page: avatar initial, name, status message,
/// connection chip, and the Tox ID with copy + QR actions.
class IdentityCard extends StatelessWidget {
  const IdentityCard({super.key, required this.identity});

  final Identity identity;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final initial = avatarInitial(identity.displayName);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: Text(initial, style: theme.textTheme.headlineSmall),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        identity.displayName,
                        style: theme.textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (identity.statusMessage.isNotEmpty)
                        Text(
                          identity.statusMessage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Flexible: on a 320 px phone at large text the
                          // chip is wider than the column; let it ellipsize.
                          const Flexible(
                            child: ConnectionChip(alwaysVisible: true),
                          ),
                          if (identity.hasPassword) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: s.accountPassword,
                              child: Icon(
                                Icons.lock_outline,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              s.accountToxId,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SelectableText(
                    groupToxId(identity.toxId),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: s.actionCopy,
                  icon: const Icon(Icons.copy),
                  onPressed: () => copyToClipboard(context, identity.toxId),
                ),
                IconButton(
                  tooltip: s.accountShowQr,
                  icon: const Icon(Icons.qr_code_2),
                  onPressed: () => showToxIdQrDialog(context, identity.toxId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

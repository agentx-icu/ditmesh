import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../i18n/l10n_extension.dart';
import '../chat/chat_layout.dart';

/// Shows the local identity's Tox ID as a QR code (scannable by another
/// ditmesh / toxee) plus the hex text with a copy button.
Future<void> showMyToxIdSheet(BuildContext context, Identity? identity) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => MyToxIdCard(identity: identity),
  );
}

class MyToxIdCard extends StatelessWidget {
  const MyToxIdCard({super.key, required this.identity});

  final Identity? identity;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final S s = context.s;
    final Identity? id = identity;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.chatMyToxId, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            if (id == null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(s.chatNoIdentity),
              )
            else ...[
              Text(id.displayName, style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: QrImageView(
                    data: 'tox:${id.toxId}',
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                id.toxId,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: id.toxId));
                  if (context.mounted) showSnack(context, s.chatCopied);
                },
                icon: const Icon(Icons.copy),
                label: Text(s.actionCopy),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

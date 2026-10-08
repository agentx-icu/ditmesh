import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../i18n/l10n_extension.dart';
import 'account_widgets.dart';

/// Shows the Tox ID as a QR code (plain 76-hex payload, the format other Tox
/// clients scan) with the text underneath and a copy button.
Future<void> showToxIdQrDialog(BuildContext context, String toxId) {
  return showDialog<void>(
    context: context,
    builder: (context) => ToxIdQrDialog(toxId: toxId),
  );
}

class ToxIdQrDialog extends StatelessWidget {
  const ToxIdQrDialog({super.key, required this.toxId});

  final String toxId;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(s.accountToxId),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // White quiet zone regardless of theme so scanners lock on. The
            // tight SizedBox matters: AlertDialog measures its content's
            // intrinsic size and QrImageView's LayoutBuilder cannot answer.
            SizedBox.square(
              dimension: 236,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: QrImageView(
                  data: toxId,
                  size: 220,
                  backgroundColor: Colors.white,
                  semanticsLabel: s.accountToxIdQrSemantics,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              groupToxId(toxId),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => copyToClipboard(context, toxId),
          icon: const Icon(Icons.copy, size: 18),
          label: Text(s.actionCopy),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.actionClose),
        ),
      ],
    );
  }
}

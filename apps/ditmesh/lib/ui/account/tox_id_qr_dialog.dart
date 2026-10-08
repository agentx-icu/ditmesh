import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../i18n/l10n_extension.dart';
import 'account_widgets.dart';

/// The QR square (quiet zone included) when the dialog has room for it.
const double kQrDialogSide = 236;

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
    // The dialog is inset 40 px per side and pads its content 24 px: on a
    // 320 px phone or an iPad 1/3 Split View pane that leaves 192 px. A
    // fixed 236 px square was squeezed to 176 x 220 there (the clamped width
    // with the full height), and a non-square QR does not scan.
    final double side = math.min(
      kQrDialogSide,
      MediaQuery.sizeOf(context).width - 2 * 40 - 2 * 24,
    );
    return AlertDialog(
      title: Text(s.accountToxId),
      // Title and content scroll together: at 3x text the title, the id and
      // the two stacked actions do not fit a 568 px phone otherwise.
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // White quiet zone regardless of theme so scanners lock on. The
          // tight SizedBox matters: AlertDialog measures its content's
          // intrinsic size and QrImageView's LayoutBuilder cannot answer.
          SizedBox.square(
            dimension: side,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: QrImageView(
                data: toxId,
                size: side - 16,
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

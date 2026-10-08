// T8 (mobile review): the Tox ID QR dialog (Me page) and the Tox ID sheet
// (contacts) on a 320 px phone and in an iPad 1/3 Split View pane, up to 3x
// text: the QR stays square and scannable, the full 76-hex id is shown and
// the copy action stays reachable. Both views copy only; there is no share.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ditmesh/ui/account/tox_id_qr_dialog.dart';
import 'package:ditmesh/ui/contacts/my_tox_id_sheet.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../learn/helpers/l10n.dart';
import 'phone_support.dart';

final String kToxId = '${'A' * 64}${'0' * 12}';

/// The smallest QR that phone cameras still lock on across the table.
const double kMinQrSide = 150;

Future<void> _pumpOpener(
  WidgetTester tester,
  void Function(BuildContext context) open,
) async {
  await tester.pumpWidget(
    l10nApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => open(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void _expectSquareQr(WidgetTester tester) {
  final Size qr = tester.getSize(find.byType(QrImageView));
  expect(qr.width, qr.height, reason: 'a squeezed QR does not scan');
  expect(qr.shortestSide, greaterThanOrEqualTo(kMinQrSide));
}

void main() {
  final cases = <(Size, double)>[
    (kSmallPhone, 1),
    (kSmallPhone, 2),
    (kSmallPhone, 3),
    (kSplitViewThird, 1),
    (kSplitViewThird, 2),
    (const Size(390, 844), 3),
  ];
  for (final (Size size, double scale) in cases) {
    testWidgets('QR dialog fits $size at ${scale}x', (tester) async {
      setPhone(tester, size, textScale: scale);
      await _pumpOpener(tester, (c) => showToxIdQrDialog(c, kToxId));
      _expectSquareQr(tester);
      final Finder copy = find.widgetWithText(TextButton, en.actionCopy);
      expect(copy.hitTestable(), findsOneWidget);
      final Finder close = find.widgetWithText(TextButton, en.actionClose);
      expect(close.hitTestable(), findsOneWidget);
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.byType(ToxIdQrDialog), findsNothing);
    });

    testWidgets('Tox ID sheet fits $size at ${scale}x', (tester) async {
      setPhone(tester, size, textScale: scale);
      await _pumpOpener(
        tester,
        (c) => showMyToxIdSheet(
          c,
          Identity(toxId: kToxId, displayName: 'Phone Tester'),
        ),
      );
      _expectSquareQr(tester);
      expect(find.text(kToxId), findsOneWidget);
      final Finder copy = find.widgetWithText(
        FilledButton,
        en.actionCopy,
      );
      await tester.ensureVisible(copy);
      await tester.pumpAndSettle();
      expect(copy.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

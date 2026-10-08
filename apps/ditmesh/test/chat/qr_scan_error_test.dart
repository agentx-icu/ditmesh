import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/contacts/qr_scan_page.dart';

void main() {
  Future<S> pumpError(WidgetTester tester, MobileScannerErrorCode code) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: QrScanErrorView(error: MobileScannerException(errorCode: code)),
        ),
      ),
    );
    return S.of(tester.element(find.byType(QrScanErrorView)));
  }

  testWidgets('permission denied tells the user to allow camera access', (
    tester,
  ) async {
    final S s = await pumpError(
      tester,
      MobileScannerErrorCode.permissionDenied,
    );
    expect(find.text(s.chatScanQrPermissionDenied), findsOneWidget);
    expect(find.text(s.chatScanQrCameraUnavailable), findsNothing);
  });

  testWidgets('any other failure says the camera is unavailable', (
    tester,
  ) async {
    final S s = await pumpError(tester, MobileScannerErrorCode.unsupported);
    expect(find.text(s.chatScanQrCameraUnavailable), findsOneWidget);
    expect(find.text(s.chatScanQrPermissionDenied), findsNothing);
  });

  testWidgets('every error code maps to one of the two messages', (
    tester,
  ) async {
    final S s = await pumpError(tester, MobileScannerErrorCode.genericError);
    for (final MobileScannerErrorCode code in MobileScannerErrorCode.values) {
      expect(
        qrScanErrorMessage(s, code),
        code == MobileScannerErrorCode.permissionDenied
            ? s.chatScanQrPermissionDenied
            : s.chatScanQrCameraUnavailable,
        reason: code.name,
      );
    }
  });

  // A phone in landscape (568x320, the smallest iPhone) with the text at
  // 2x: the permission message runs to ~300 px in de/fr/es/pt/ru, taller
  // than the page, so the view must scroll rather than overflow.
  for (final Locale locale in S.supportedLocales) {
    testWidgets('fits a landscape phone at 2x text in $locale', (tester) async {
      tester.view.physicalSize = const Size(568, 320);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final MobileScannerErrorCode code in <MobileScannerErrorCode>[
        MobileScannerErrorCode.permissionDenied,
        MobileScannerErrorCode.unsupported,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            locale: locale,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              appBar: AppBar(title: const Text('Scan')),
              body: QrScanErrorView(
                error: MobileScannerException(errorCode: code),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$locale ${code.name}');
        final S s = S.of(tester.element(find.byType(QrScanErrorView)));
        await tester.scrollUntilVisible(
          find.text(qrScanErrorMessage(s, code)),
          50,
          scrollable: find.descendant(
            of: find.byType(QrScanErrorView),
            matching: find.byType(Scrollable),
          ),
        );
      }
    });
  }

  testWidgets('a short message stays centred when it fits', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final S s = await pumpError(tester, MobileScannerErrorCode.unsupported);
    final Rect view = tester.getRect(find.byType(QrScanErrorView));
    final Rect text = tester.getRect(find.text(s.chatScanQrCameraUnavailable));
    final Rect icon = tester.getRect(find.byIcon(Icons.videocam_off));
    final double contentCentre = (icon.top + text.bottom) / 2;
    expect(contentCentre, moreOrLessEquals(view.center.dy, epsilon: 1));
    expect(text.center.dx, moreOrLessEquals(view.center.dx, epsilon: 1));
  });
}

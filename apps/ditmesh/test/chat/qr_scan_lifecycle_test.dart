import 'dart:async';

import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/contacts/qr_scan_page.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class _ScannerPlatform extends MobileScannerPlatform {
  int starts = 0;
  int stops = 0;
  final _barcodes = StreamController<BarcodeCapture?>.broadcast();

  void emit(BarcodeCapture capture) => _barcodes.add(capture);
  Future<void> close() => _barcodes.close();

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodes.stream;
  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();
  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();
  @override
  Widget buildCameraView() => const SizedBox.expand();
  @override
  Future<MobileScannerViewAttributes> start(StartOptions options) async {
    starts++;
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      size: Size(640, 480),
    );
  }

  @override
  Future<void> stop() async => stops++;
  @override
  Future<void> updateScanWindow(Rect? window) async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets('scanner releases camera on inactive and resumes once', (
    tester,
  ) async {
    final original = MobileScannerPlatform.instance;
    final platform = _ScannerPlatform();
    MobileScannerPlatform.instance = platform;
    addTearDown(() => MobileScannerPlatform.instance = original);
    addTearDown(platform.close);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: QrScanPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(platform.starts, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(platform.stops, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(platform.starts, 2);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('a covered scanner cannot pop a newer page', (tester) async {
    final original = MobileScannerPlatform.instance;
    final platform = _ScannerPlatform();
    MobileScannerPlatform.instance = platform;
    addTearDown(() => MobileScannerPlatform.instance = original);
    addTearDown(platform.close);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: const Scaffold(body: Text('contacts')),
      ),
    );
    final nav = key.currentState!;
    final scanned = nav.push(
      MaterialPageRoute<String>(builder: (_) => const QrScanPage()),
    );
    await tester.pumpAndSettle();
    unawaited(
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('newer page')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final id = FakeIdentityService.toxIdForSeed(42);
    final capture = BarcodeCapture(
      barcodes: [Barcode(format: BarcodeFormat.qrCode, rawValue: id)],
    );
    platform.emit(capture);
    await tester.pumpAndSettle();
    expect(find.text('newer page'), findsOneWidget);

    nav.pop();
    await tester.pumpAndSettle();
    platform.emit(capture);
    await tester.pumpAndSettle();
    expect(await scanned, id);
    expect(find.text('contacts'), findsOneWidget);
  });
}

import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/contacts/qr_scan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class _ScannerPlatform extends MobileScannerPlatform {
  int starts = 0;
  int stops = 0;

  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();
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
}

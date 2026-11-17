import 'dart:async';

import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/contacts/add_friend_sheet.dart';
import 'package:ditmesh/ui/contacts/qr_scan_page.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class _ScannerPlatform extends MobileScannerPlatform {
  int starts = 0;
  int stops = 0;
  Completer<void>? holdStart;
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
    await holdStart?.future;
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
  testWidgets('a stalled scanner shows an error and can recover', (
    tester,
  ) async {
    final original = MobileScannerPlatform.instance;
    final platform = _ScannerPlatform()..holdStart = Completer<void>();
    MobileScannerPlatform.instance = platform;
    addTearDown(() => MobileScannerPlatform.instance = original);
    addTearDown(platform.close);
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: QrScanPage(),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(seconds: 12));
    expect(find.byType(QrScanErrorView), findsOneWidget);

    platform.holdStart!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(QrScanErrorView), findsNothing);
    expect(platform.starts, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('leaving during startup releases the camera before reopening', (
    tester,
  ) async {
    final original = MobileScannerPlatform.instance;
    final firstStart = Completer<void>();
    final platform = _ScannerPlatform()..holdStart = firstStart;
    MobileScannerPlatform.instance = platform;
    addTearDown(() => MobileScannerPlatform.instance = original);
    addTearDown(platform.close);
    const app = MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: QrScanPage(),
    );
    await tester.pumpWidget(app);
    await tester.pump();
    expect(platform.starts, 1);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app);
    await tester.pump();
    expect(platform.starts, 1);
    expect(platform.stops, 0);

    await tester.pump(const Duration(seconds: 11));
    final secondStart = Completer<void>();
    platform.holdStart = secondStart;
    firstStart.complete();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(QrScanErrorView), findsOneWidget);
    secondStart.complete();
    await tester.pumpAndSettle();
    expect(find.byType(QrScanErrorView), findsNothing);
    expect(platform.stops, 1);
    expect(platform.starts, 2);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(platform.stops, 2);
  });

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

  testWidgets('opening the scanner while inactive waits for focus', (
    tester,
  ) async {
    final original = MobileScannerPlatform.instance;
    final platform = _ScannerPlatform();
    MobileScannerPlatform.instance = platform;
    addTearDown(() => MobileScannerPlatform.instance = original);
    addTearDown(platform.close);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: QrScanPage(),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(platform.starts, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(platform.starts, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('back-to-back scan actions only open one camera route', (
    tester,
  ) async {
    final original = MobileScannerPlatform.instance;
    final platform = _ScannerPlatform();
    final service = FakeChatService();
    MobileScannerPlatform.instance = platform;
    addTearDown(() => MobileScannerPlatform.instance = original);
    addTearDown(platform.close);
    addTearDown(service.dispose);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(body: AddFriendForm(service: service, canScan: true)),
      ),
    );
    final scan = tester.widget<TextButton>(
      find.widgetWithText(TextButton, lookupS(const Locale('en')).chatScanQr),
    );
    scan.onPressed!();
    scan.onPressed!();
    await tester.pump();
    expect(find.byType(QrScanPage, skipOffstage: false), findsOneWidget);
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

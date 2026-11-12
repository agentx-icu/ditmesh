// Platform contracts for the widget host, not evidence of native device I/O.
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_io/testing.dart';
import 'package:provider/provider.dart';
import 'package:ditmesh/ui/keying/key_test_area.dart';
import 'package:ditmesh/ui/listen/workbench/workbench_screen.dart';

import '../listen/workbench_support.dart';

/// Installed once per test, restored only after the widget tree is unmounted.
final class LayoutPluginHost {
  LayoutPluginHost(this.tester)
    : _previousScanner = MobileScannerPlatform.instance,
      _previousPicker = FilePickerPlatform.instance {
    MobileScannerPlatform.instance = scanner;
    FilePickerPlatform.instance = picker;
    // The existing crawl also reaches ListenScreen's recorder lifecycle.
    // No microphone data or permission is claimed by this host.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _record,
      (call) async => switch (call.method) {
        'create' || 'stop' || 'cancel' || 'dispose' => null,
        'hasPermission' || 'isRecording' || 'isPaused' => false,
        'listInputDevices' => <Object>[],
        _ => throw UnsupportedError('Unmodelled recorder call: ${call.method}'),
      },
    );
    addTearDown(close);
  }

  final WidgetTester tester;
  final MobileScannerPlatform _previousScanner;
  final FilePickerPlatform _previousPicker;
  static const _record = MethodChannel('com.llfbandit.record/messages');
  bool _closed = false;
  final scanner = LayoutScanner();
  final picker = LayoutFilePicker();
  final List<RecordingSink> sinks = [];
  final List<FakeClipPlayer> players = [];

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      await tester.pumpWidget(const SizedBox());
      await settleHost();
      await scanner.close();
    } finally {
      MobileScannerPlatform.instance = _previousScanner;
      FilePickerPlatform.instance = _previousPicker;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _record,
        null,
      );
    }
  }

  Future<void> settleHost() async {
    await tester.pump();
    await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }

  Widget wrap(Widget child) => MultiProvider(
    providers: [
      Provider<KeyTestAudioFactory>.value(value: _KeyAudio(this)),
      Provider<WorkbenchPlayerFactory>.value(value: _ClipAudio(this)),
    ],
    child: child,
  );
}

final class _KeyAudio implements KeyTestAudioFactory {
  _KeyAudio(this.host);
  final LayoutPluginHost host;
  @override
  MorseSink create() {
    final sink = RecordingSink(clock: FakeClock());
    host.sinks.add(sink);
    return sink;
  }
}

final class _ClipAudio implements WorkbenchPlayerFactory {
  _ClipAudio(this.host);
  final LayoutPluginHost host;
  @override
  ClipPlayer create() {
    final player = FakeClipPlayer();
    host.players.add(player);
    return player;
  }
}

/// Covers streams and camera-view lifecycle without opening a real camera.
final class LayoutScanner extends MobileScannerPlatform {
  final _barcodes = StreamController<BarcodeCapture?>.broadcast();
  int starts = 0;
  int stops = 0;
  int disposals = 0;

  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodes.stream;
  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();
  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();
  @override
  Widget buildCameraView() =>
      const SizedBox.expand(key: ValueKey('layout-camera-view'));
  @override
  Future<MobileScannerViewAttributes> start(StartOptions options) async {
    starts++;
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      size: Size(640, 480),
    );
  }

  void detect(String value) => _barcodes.add(
    BarcodeCapture(
      barcodes: [Barcode(format: BarcodeFormat.qrCode, rawValue: value)],
    ),
  );

  @override
  Future<void> stop() async => stops++;
  @override
  Future<void> updateScanWindow(Rect? window) async {}
  @override
  Future<void> dispose() async => disposals++;
  Future<void> close() => _barcodes.close();
}

/// A successful selected file exercises the real WAV import and waveform UI.
/// Set [cancel] explicitly to test cancellation without claiming import success.
final class LayoutFilePicker extends FilePickerPlatform {
  int calls = 0;
  bool cancel = false;

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    calls++;
    return cancel ? null : _WavFile(cwWav('SOS TEST'));
  }
}

final class _WavFile extends PlatformFile {
  _WavFile(this.bytes);
  final Uint8List bytes;
  @override
  String get name => 'layout-sos.wav';
  @override
  Uri get uri => Uri.parse('memory:layout-sos.wav');
  // Import consumes the stream, including the no-path/cloud-provider branch.
  // Fail explicitly if a new caller needs a contract this host does not model.
  @override
  Never get xFile =>
      throw UnsupportedError('layout host does not expose XFile');
  @override
  int lengthSync() => bytes.length;
  @override
  Future<int> length() async => bytes.length;
  @override
  Future<Uint8List> readAsBytes() async => bytes;
  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(bytes);
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../i18n/l10n_extension.dart';
import '../common/app_bar_title.dart';
import 'tox_id.dart';

/// Full-screen camera scanner that pops with the first valid Tox ID it sees.
/// The add-friend sheet exposes this on Android, iOS and macOS.
class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  static Future<String?> open(BuildContext context) => Navigator.of(
    context,
  ).push<String>(MaterialPageRoute<String>(builder: (_) => const QrScanPage()));

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> with WidgetsBindingObserver {
  static Future<void>? _previousCameraReleased;

  final _camera = MobileScannerController(autoStart: false);
  final _cameraReleased = Completer<void>();
  late Future<void> _cameraOperation;
  late final Timer _startupTimer;
  bool _scannerMounted = false;
  bool _startupTimedOut = false;
  late bool _foreground;
  bool _done = false;

  /// A QR code was seen that is not a Tox ID; the hint text is resolved in
  /// [build] so it follows the locale.
  bool _sawForeignCode = false;

  @override
  void initState() {
    super.initState();
    _foreground = switch (WidgetsBinding.instance.lifecycleState) {
      null || AppLifecycleState.detached || AppLifecycleState.resumed => true,
      _ => false,
    };
    WidgetsBinding.instance.addObserver(this);
    _startupTimer = Timer(const Duration(seconds: 12), () {
      if (!_camera.value.isInitialized) {
        setState(() => _startupTimedOut = true);
      }
    });
    _cameraOperation = _previousCameraReleased ?? Future<void>.value();
    _previousCameraReleased = _cameraReleased.future;
    _queueCamera(() async {
      if (!mounted) return;
      setState(() => _scannerMounted = true);
      await WidgetsBinding.instance.endOfFrame;
      await _syncCamera();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    _queueCamera(_syncCamera);
  }

  Future<void> _syncCamera() async {
    if (!mounted) return;
    if (!_foreground) {
      await _camera.stop();
    } else if (!_camera.value.isInitialized ||
        _camera.value.hasCameraPermission) {
      await _camera.start();
    }
  }

  void _queueCamera(Future<void> Function() operation) {
    _cameraOperation = _cameraOperation
        .then((_) => operation())
        .onError<Object>(
          (error, stack) => FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'QR scanner',
            ),
          ),
        );
  }

  @override
  void dispose() {
    _startupTimer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    // A native permission prompt or camera start can finish after navigation.
    // Release that session before the next scanner tries to open the camera.
    _queueCamera(() async {
      try {
        try {
          await _camera.stop();
        } finally {
          await _camera.dispose();
        }
      } finally {
        if (identical(_previousCameraReleased, _cameraReleased.future)) {
          _previousCameraReleased = null;
        }
        _cameraReleased.complete();
      }
    });
    super.dispose();
  }

  Widget _startupView() => _startupTimedOut
      ? const QrScanErrorView(
          error: MobileScannerException(
            errorCode: MobileScannerErrorCode.genericError,
          ),
        )
      : const Center(child: CircularProgressIndicator());

  void _onDetect(BarcodeCapture capture) {
    if (_done || !mounted || ModalRoute.isCurrentOf(context) != true) return;
    for (final Barcode code in capture.barcodes) {
      if (code.format != BarcodeFormat.qrCode) continue;
      final String id = normalizeToxId(code.rawValue ?? '');
      if (isValidToxId(id)) {
        _done = true;
        Navigator.of(context).pop(id);
        return;
      }
    }
    if (!_sawForeignCode && mounted) {
      setState(() => _sawForeignCode = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = context.s;
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(s.chatScanQrTitle)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_scannerMounted)
            MobileScanner(
              controller: _camera,
              onDetect: _onDetect,
              placeholderBuilder: (_) => _startupView(),
              errorBuilder: (context, error) => QrScanErrorView(error: error),
            )
          else
            _startupView(),
          if (_sawForeignCode)
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              // The camera runs edge-to-edge; keep the hint above the home
              // indicator and clear of a landscape notch.
              child: SafeArea(
                top: false,
                child: Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      s.chatScanQrNotToxId,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The camera could not start: says why instead of mobile_scanner's bare
/// error icon. Permission denied (the user declined, or restricted it in
/// Settings / by policy) is the one case the user can fix themselves.
class QrScanErrorView extends StatelessWidget {
  const QrScanErrorView({required this.error, super.key});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool denied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    // Centred when it fits; scrolls when it does not (a landscape phone at
    // a large text scale has less height than the localised message).
    return ColoredBox(
      color: scheme.surface,
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      denied
                          ? Icons.no_photography_outlined
                          : Icons.videocam_off,
                      size: 48,
                      color: scheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      qrScanErrorMessage(context.s, error.errorCode),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// User-facing text for a scanner failure [code].
String qrScanErrorMessage(S s, MobileScannerErrorCode code) =>
    code == MobileScannerErrorCode.permissionDenied
    ? s.chatScanQrPermissionDenied
    : s.chatScanQrCameraUnavailable;

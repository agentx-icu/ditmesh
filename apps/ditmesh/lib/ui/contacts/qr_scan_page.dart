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
  // The native scanner is shared. A covered route can remain mounted while a
  // newer scanner needs the camera, and an old start may outlive navigation.
  static Future<void>? _cameraOperations;
  static _QrScanPageState? _cameraOwner;

  MobileScannerController _camera = MobileScannerController(autoStart: false);
  Timer? _startupTimer;
  bool _scannerMounted = false;
  bool _starting = false;
  bool _startupTimedOut = false;
  bool _isCurrentRoute = true;
  late bool _foreground;
  bool _retrying = false;
  bool _done = false;
  bool get _mayScan => mounted && _foreground && _isCurrentRoute && !_done;

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
    _queueCamera(() async {
      if (!mounted) return;
      setState(() => _scannerMounted = true);
      await WidgetsBinding.instance.endOfFrame;
      await _syncCamera();
    });
  }

  void _updateStartupTimer() {
    _startupTimer?.cancel();
    // Count time only during a native start on the foreground route.
    // An in-flight start gets a fresh window when the route becomes visible.
    if (!_mayScan ||
        !_starting ||
        _startupTimedOut ||
        _camera.value.isInitialized) {
      return;
    }
    _startupTimer = Timer(const Duration(seconds: 12), () {
      if (_mayScan && !_camera.value.isInitialized) {
        setState(() => _startupTimedOut = true);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = ModalRoute.isCurrentOf(context) ?? true;
    if (current == _isCurrentRoute) return;
    _isCurrentRoute = current;
    _updateStartupTimer();
    _queueCamera(_syncCamera);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    _updateStartupTimer();
    _queueCamera(_syncCamera);
  }

  Future<void> _syncCamera() async {
    if (!mounted) return;
    if (!_mayScan) {
      await _stopCamera();
      return;
    }
    // A failed permission check stays visible until an explicit retry.
    if (_camera.value.error != null) return;
    final owner = _cameraOwner;
    if (owner != null && !identical(owner, this)) await owner._stopCamera();
    if (!_mayScan) return;
    if (_startupTimedOut) setState(() => _startupTimedOut = false);
    _starting = true;
    _updateStartupTimer();
    try {
      await _camera.start();
    } finally {
      _starting = false;
      _startupTimer?.cancel();
    }
    if (_camera.value.isRunning) _cameraOwner = this;
  }

  Future<void> _stopCamera() async {
    try {
      await _camera.stop();
    } finally {
      if (identical(_cameraOwner, this)) _cameraOwner = null;
    }
  }

  void _retry() {
    if (_retrying || !_mayScan) return;
    _retrying = true;
    _queueCamera(() async {
      try {
        if (!_mayScan) return;
        // A failed start can leave the plugin subscribed to platform events.
        // Recreate the controller so retrying releases those subscriptions.
        final failed = _camera;
        setState(() {
          _camera = MobileScannerController(autoStart: false);
          _startupTimedOut = false;
        });
        await WidgetsBinding.instance.endOfFrame;
        await failed.dispose();
        await _syncCamera();
      } finally {
        _retrying = false;
      }
    });
  }

  void _queueCamera(Future<void> Function() operation) {
    late final Future<void> queued;
    queued = (_cameraOperations ?? Future<void>.value())
        .then((_) => operation())
        .onError<Object>(
          (error, stack) => FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'QR scanner',
            ),
          ),
        )
        .whenComplete(() {
          if (identical(_cameraOperations, queued)) _cameraOperations = null;
        });
    _cameraOperations = queued;
  }

  @override
  void dispose() {
    _startupTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    // A native permission prompt or camera start can finish after navigation.
    // Release that session before the next scanner tries to open the camera.
    _queueCamera(() async {
      try {
        await _stopCamera();
      } finally {
        await _camera.dispose();
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
    if (!_mayScan || ModalRoute.isCurrentOf(context) != true) return;
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
              key: ObjectKey(_camera),
              controller: _camera,
              onDetect: _onDetect,
              placeholderBuilder: (_) => _startupView(),
              errorBuilder: (context, error) =>
                  QrScanErrorView(error: error, onRetry: _retry),
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
  const QrScanErrorView({required this.error, this.onRetry, super.key});

  final MobileScannerException error;
  final VoidCallback? onRetry;

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
                    if (onRetry != null) ...[
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: onRetry,
                        child: Text(context.s.actionRetry),
                      ),
                    ],
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

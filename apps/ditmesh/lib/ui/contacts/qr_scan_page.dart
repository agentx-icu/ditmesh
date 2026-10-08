import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../i18n/l10n_extension.dart';
import 'tox_id.dart';

/// Full-screen camera scanner that pops with the first valid Tox ID it sees.
/// Only reachable on Android / iOS; the add-friend sheet disables the entry
/// point elsewhere (desktop has no `mobile_scanner` implementation).
class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  static Future<String?> open(BuildContext context) => Navigator.of(
    context,
  ).push<String>(MaterialPageRoute<String>(builder: (_) => const QrScanPage()));

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _done = false;

  /// A QR code was seen that is not a Tox ID; the hint text is resolved in
  /// [build] so it follows the locale.
  bool _sawForeignCode = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final Barcode code in capture.barcodes) {
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
      appBar: AppBar(title: Text(s.chatScanQrTitle)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => QrScanErrorView(error: error),
          ),
          if (_sawForeignCode)
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
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

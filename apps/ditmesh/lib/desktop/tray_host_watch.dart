import 'dart:async';

/// Rechecks a desktop tray host only while the app relies on it to reopen.
final class TrayHostWatch {
  TrayHostWatch({required this.isAvailable, required this.onLost});

  final Future<bool> Function() isAvailable;
  final Future<void> Function() onLost;
  Timer? _timer;

  void start() => _timer ??= Timer(const Duration(seconds: 3), _check);

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _check() async {
    final timer = _timer;
    final available = await isAvailable();
    if (!identical(timer, _timer)) return;
    if (!available) await onLost();
    if (!identical(timer, _timer)) return;
    _timer = null;
    start();
  }
}

import 'badge_api.dart';

/// Writes the unread total to the OS badge. Writes are serialised (latest
/// value last) and deduplicated against the last value that reached the OS,
/// so a burst of conversation updates ends with the badge showing the final
/// total exactly once per change.
final class BadgeWriter {
  BadgeWriter(
    this._badge, {
    required bool Function() isDisposed,
    required void Function(Object error, StackTrace stack) onError,
  }) : _isDisposed = isDisposed,
       _onError = onError;

  final BadgeApi _badge;
  final bool Function() _isDisposed;
  final void Function(Object error, StackTrace stack) _onError;

  bool? _supported;
  int? _last;
  Future<void> _chain = Future<void>.value();

  void write(int total) {
    _chain = _chain
        .then((_) => _write(total))
        .catchError((Object error, StackTrace stack) => _onError(error, stack));
  }

  Future<void> _write(int total) async {
    if (_isDisposed()) return;
    _supported ??= await _badge.isSupported();
    if (_supported != true || _last == total) return;
    await _badge.update(total);
    _last = total;
  }
}

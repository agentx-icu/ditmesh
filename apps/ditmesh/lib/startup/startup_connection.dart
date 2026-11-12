import 'dart:async';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

/// Owns initial connection and explicit recovery without restarting the engine.
/// A recovery requested during startup appends one bootstrap refresh to it.
class StartupConnection {
  StartupConnection({
    required IdentityService identity,
    required bool Function() canConnect,
    required void Function() onChanged,
    NetworkBootstrapService? networkBootstrap,
  }) : _identity = identity,
       _canConnect = canConnect,
       _onChanged = onChanged,
       _networkBootstrap = networkBootstrap;

  final IdentityService _identity;
  final bool Function() _canConnect;
  final void Function() _onChanged;
  final NetworkBootstrapService? _networkBootstrap;
  _ConnectionAttempt? _active;
  Object? _error;
  bool _disposed = false;

  Object? get error => _error;

  Future<void> connect({bool refreshBootstrap = false}) {
    final key = _identity.current?.publicKey;
    if (_disposed || !_canConnect() || key == null) return Future<void>.value();
    final active = _active;
    if (active != null && active.key == key) {
      active.refreshBootstrap |= refreshBootstrap;
      return active.done.future;
    }
    final attempt = _ConnectionAttempt(key, refreshBootstrap);
    _active = attempt;
    unawaited(_run(attempt));
    return attempt.done.future;
  }

  bool _isCurrent(_ConnectionAttempt attempt) =>
      !_disposed &&
      _canConnect() &&
      _identity.current?.publicKey == attempt.key;

  Future<void> _run(_ConnectionAttempt attempt) async {
    try {
      await _identity.connect();
      if (!_isCurrent(attempt)) return;
      if (attempt.refreshBootstrap) {
        await _networkBootstrap?.rebootstrap(
          onlyIfDisconnected: true,
          isCurrent: () => _isCurrent(attempt),
        );
      }
      if (_isCurrent(attempt)) _setError(null);
    } on Object catch (error) {
      if (_isCurrent(attempt)) _setError(error);
    } finally {
      if (identical(_active, attempt)) _active = null;
      attempt.done.complete();
    }
  }

  void _setError(Object? error) {
    if (identical(_error, error)) return;
    _error = error;
    _onChanged();
  }

  void dispose() => _disposed = true;
}

class _ConnectionAttempt {
  _ConnectionAttempt(this.key, this.refreshBootstrap);

  final String key;
  bool refreshBootstrap;
  final done = Completer<void>();
}

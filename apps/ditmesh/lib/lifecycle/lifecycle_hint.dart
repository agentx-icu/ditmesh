/// Coarse app-lifecycle events the UI may react to (toasts, chips, logging).
/// Emitted by `AppLifecycleCoordinator.hints`.
enum LifecycleHint {
  /// The app left the foreground (paused / hidden / detached).
  background,

  /// The app has been in the background longer than the platform's expected
  /// budget; the Tox node is probably suspended and messages sent to us are
  /// queued on the peer's side until we come back.
  mayBeDisconnected,

  /// Back in the foreground after a background period.
  foreground,

  /// `IdentityService.connect()` was asked to recover the connection.
  reconnectRequested,

  /// That call threw; the connection chip's retry is the user's fallback.
  reconnectFailed,
}

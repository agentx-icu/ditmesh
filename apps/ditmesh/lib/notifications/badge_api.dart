/// Launcher / dock unread badge. `AppBadgePlusApi` is the production
/// implementation (Android / iOS / macOS); `testing/fake_badge_api.dart`
/// records writes for tests.
///
/// Implementations never throw: an unsupported launcher or platform makes
/// [isSupported] false and [update] a no-op.
abstract interface class BadgeApi {
  Future<bool> isSupported();

  /// Sets the badge to [count]; 0 clears it.
  Future<void> update(int count);
}

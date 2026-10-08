import 'package:flutter/foundation.dart';

/// Which OS the notification stack is running on.
///
/// Resolved from [defaultTargetPlatform] (so `debugDefaultTargetPlatformOverride`
/// works in widget tests) and injectable through every constructor in this
/// module, because `dart:io`'s `Platform` cannot be faked and `flutter test`
/// runs on the host OS (macOS locally, Linux in CI).
///
/// The five shipping targets are listed explicitly; anything else (web,
/// Fuchsia) is [unsupported] and the whole stack degrades to no-ops.
enum NotificationPlatform {
  android,
  ios,
  macos,
  linux,
  windows,
  unsupported;

  static NotificationPlatform detect() {
    if (kIsWeb) return unsupported;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.macOS => macos,
      TargetPlatform.linux => linux,
      TargetPlatform.windows => windows,
      TargetPlatform.fuchsia => unsupported,
    };
  }

  bool get isMobile => this == android || this == ios;

  /// `flutter_local_notifications` has an endorsed implementation here.
  bool get supportsOsNotifications => this != unsupported;

  /// `app_badge_plus` implements Android, iOS and macOS only; elsewhere the
  /// badge writer is a silent no-op.
  bool get supportsBadge => this == android || this == ios || this == macos;

  /// Android 13+ `POST_NOTIFICATIONS` and the UNUserNotificationCenter
  /// authorization prompt on iOS/macOS. Linux (D-Bus) and Windows (toasts)
  /// have no runtime permission.
  bool get needsRuntimePermission =>
      this == android || this == ios || this == macos;

  /// Per-conversation stacking: Android `groupKey` + inbox style, Darwin
  /// `threadIdentifier`. The Linux and Windows backends have no equivalent.
  bool get supportsGrouping => this == android || this == ios || this == macos;

  /// How long a backgrounded app can expect to keep running its Tox loop
  /// before the OS suspends it. Null means "not suspended" (desktop).
  ///
  /// iOS gives ~30 s via `beginBackgroundTask`; ditmesh declares no
  /// background mode that would keep the process alive longer (no `voip`,
  /// and no `audio` since nothing plays in the background). Android is OEM-dependent — Doze and
  /// vendor battery savers freeze processes anywhere from one to several
  /// minutes in; 60 s is a conservative "may be gone" hint, not a guarantee.
  Duration? get backgroundBudget => switch (this) {
    ios => const Duration(seconds: 30),
    android => const Duration(seconds: 60),
    _ => null,
  };
}

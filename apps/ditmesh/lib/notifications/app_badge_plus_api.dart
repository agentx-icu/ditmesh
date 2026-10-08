import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';

import 'badge_api.dart';
import 'notification_platform.dart';

/// Production [BadgeApi] on `app_badge_plus` (1.3.x). The only file in the
/// app that imports the plugin.
///
/// Support: iOS and macOS are exact (UIApplication / NSDockTile). Android is
/// launcher-dependent (Samsung, Xiaomi/HyperOS, Huawei, OPPO, vivo, Sony,
/// HTC ... each via their own broadcast; stock Pixel launcher shows only a
/// dot driven by active notifications) and needs `POST_NOTIFICATIONS` on
/// 13+. Linux and Windows have no implementation, so [isSupported] is false
/// there without touching a platform channel.
final class AppBadgePlusApi implements BadgeApi {
  AppBadgePlusApi({NotificationPlatform? platform})
    : _platform = platform ?? NotificationPlatform.detect();

  final NotificationPlatform _platform;
  bool? _supported;

  @override
  Future<bool> isSupported() async {
    if (!_platform.supportsBadge) return false;
    final bool? cached = _supported;
    if (cached != null) return cached;
    try {
      return _supported = await AppBadgePlus.isSupported();
    } catch (error) {
      // MissingPluginException in unit tests, or an unsupported launcher.
      debugPrint('[AppBadgePlusApi] isSupported failed: $error');
      return false;
    }
  }

  @override
  Future<void> update(int count) async {
    if (!await isSupported()) return;
    try {
      await AppBadgePlus.updateBadge(count < 0 ? 0 : count);
    } catch (error) {
      debugPrint('[AppBadgePlusApi] updateBadge($count) failed: $error');
    }
  }
}

import 'dart:io';

import 'package:ditmesh/notifications/flutter_local_notifications_api.dart';
import 'package:ditmesh/notifications/notification_platform.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

final class _NotificationPlugin implements FlutterLocalNotificationsPlugin {
  late InitializationSettings registeredSettings;

  @override
  Object? noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #resolvePlatformSpecificImplementation) {
      return null;
    }
    return super.noSuchMethod(invocation);
  }

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    registeredSettings = settings;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const String assetPath = 'assets/notification_icon.png';

  test('Linux registers the bundled DitMesh notification icon', () async {
    final plugin = _NotificationPlugin();
    final api = FlutterLocalNotificationsApi(
      plugin: plugin,
      platform: NotificationPlatform.linux,
    );

    expect(await api.initialize(onTap: (_) {}), isTrue);
    expect(
      plugin.registeredSettings.linux?.defaultIcon,
      isA<AssetsLinuxIcon>().having((icon) => icon.content, 'asset', assetPath),
    );
  });

  test(
    'Windows points the existing toast identity to the packaged icon',
    () async {
      final plugin = _NotificationPlugin();
      final api = FlutterLocalNotificationsApi(
        plugin: plugin,
        platform: NotificationPlatform.windows,
      );

      expect(await api.initialize(onTap: (_) {}), isTrue);
      final settings = plugin.registeredSettings.windows!;
      expect(
        settings.appUserModelId,
        FlutterLocalNotificationsApi.windowsAppUserModelId,
      );
      expect(settings.guid, FlutterLocalNotificationsApi.windowsGuid);
      expect(
        settings.iconPath,
        path.join(
          path.dirname(Platform.resolvedExecutable),
          'data',
          'flutter_assets',
          'assets',
          'notification_icon.png',
        ),
      );
    },
  );
}

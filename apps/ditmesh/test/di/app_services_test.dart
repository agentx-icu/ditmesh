import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/app_services.dart';
import 'package:flutter/foundation.dart';
import 'package:ditmesh/desktop/desktop.dart';
import 'package:ditmesh/desktop/testing/testing.dart' as desktop;
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/i18n/locale_controller.dart';
import 'package:ditmesh/notifications/testing/fake_badge_api.dart';
import 'package:ditmesh/notifications/testing/fake_local_notifications_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

/// The cross-cutting wiring `AppScope` builds: a language change must reach
/// the OS-facing surfaces (here the notification API; the tray is covered by
/// the desktop tests).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late FakeIdentityService identity;
  late FakeChatService chat;
  late LocaleController locale;
  late FakeLocalNotificationsApi api;
  late AppServices services;
  var disposed = false;

  setUp(() async {
    disposed = false;
    tempDir = await Directory.systemTemp.createTemp('ditmesh_services_');
    identity = FakeIdentityService(
      connectDelay: Duration.zero,
      dataDirectoryPath: tempDir.path,
    );
    chat = FakeChatService(selfPublicKey: 'F' * 64);
    locale = LocaleController(InMemoryKeyValueStore());
    api = FakeLocalNotificationsApi();
    services = AppServices(
      identity: identity,
      chat: chat,
      locale: locale,
      notificationApis: NotificationApis(
        notifications: api,
        badge: FakeBadgeApi(),
      ),
    );
  });

  tearDown(() async {
    if (!disposed) await services.dispose();
    locale.dispose();
    await identity.dispose();
    await chat.dispose();
    await tempDir.delete(recursive: true);
  });

  test(
    'a language change after start refreshes the notification strings',
    () async {
      services.start();
      await pumpEventQueue();
      expect(api.refreshStringsCalls, 0);

      await locale.setLocale(const Locale('zh'));
      await pumpEventQueue();
      expect(api.refreshStringsCalls, 1);

      await locale.setLocale(null); // back to following the system
      await pumpEventQueue();
      expect(api.refreshStringsCalls, 2);
    },
  );

  test(
    'desktop quit persists and disconnects the identity before destroying',
    () async {
      final persistent = _PersistentIdentity();
      final window = desktop.FakeWindowApi();
      final shell = DesktopShellController(
        config: DesktopShellConfig(
          store: desktop.InMemoryKeyValueStore(),
          platform: TargetPlatform.macOS,
        ),
        window: window,
        tray: desktop.FakeTrayApi(),
        screen: desktop.FakeScreenApi(const [Rect.fromLTWH(0, 0, 1920, 1080)]),
      );
      await shell.initialize();
      final wired = AppServices(
        identity: persistent,
        chat: chat,
        locale: locale,
        desktopShell: shell,
      );
      wired.start();
      await shell.quit();
      expect(persistent.operations, ['persist', 'disconnect']);
      expect(window.calls, contains('destroy'));
      await wired.dispose();
      shell.dispose();
    },
  );

  test('native save failure still flushes unrelated app settings', () async {
    final persistent = _PersistentIdentity()..failPersist = true;
    var settingsFlushed = false;
    final wired = AppServices(
      identity: persistent,
      chat: chat,
      locale: locale,
      onBackground: () async => settingsFlushed = true,
    );
    wired.start();
    wired.lifecycle.didChangeAppLifecycleState(AppLifecycleState.hidden);
    await pumpEventQueue();
    expect(settingsFlushed, isTrue);
    await wired.dispose();
  });

  test('background persists an identity without disconnecting it', () async {
    final persistent = _PersistentIdentity();
    final wired = AppServices(identity: persistent, chat: chat, locale: locale);
    wired.start();
    wired.lifecycle.didChangeAppLifecycleState(AppLifecycleState.hidden);
    await pumpEventQueue();
    expect(persistent.operations, ['persist']);
    await wired.dispose();
  });

  test('after dispose a language change reaches nothing', () async {
    services.start();
    await pumpEventQueue();
    await services.dispose();
    disposed = true;

    await locale.setLocale(const Locale('zh'));
    await pumpEventQueue();
    expect(api.refreshStringsCalls, 0);
  });
}

final class _PersistentIdentity implements PersistentIdentityService {
  final List<String> operations = [];
  bool failPersist = false;
  @override
  Identity? get current => Identity(toxId: 'A' * 76, displayName: 'test');
  @override
  Stream<Identity?> get identityChanges => const Stream.empty();
  @override
  ConnectionStatus get connectionStatus => ConnectionStatus.offline;
  @override
  Stream<ConnectionStatus> get connectionChanges => const Stream.empty();
  @override
  Future<void> persist() async {
    operations.add('persist');
    if (failPersist) throw StateError('native save failed');
  }

  @override
  Future<void> disconnect() async => operations.add('disconnect');
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/desktop/desktop.dart';
import 'package:ditmesh/desktop/real/window_manager_api.dart';
import 'package:ditmesh/desktop/testing/testing.dart';
import 'package:ditmesh/l10n/generated/s.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final windowCalls = <String>[];
  final platformCalls = <String>[];

  setUp(() {
    windowCalls.clear();
    platformCalls.clear();
    messenger.setMockMethodCallHandler(const MethodChannel('window_manager'), (
      call,
    ) async {
      windowCalls.add(call.method);
      if (call.method == 'getBounds') {
        return {'x': 10.0, 'y': 10.0, 'width': 1100.0, 'height': 760.0};
      }
      if (call.method.startsWith('is')) return false;
      return null;
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      platformCalls.add(call.method);
      return null;
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(
      const MethodChannel('window_manager'),
      null,
    );
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final platform in [TargetPlatform.windows, TargetPlatform.macOS]) {
    test('$platform retains its existing window-manager exit', () async {
      debugDefaultTargetPlatformOverride = platform;
      await WindowManagerApi().destroy();
      expect(windowCalls, ['destroy']);
      expect(platformCalls, isEmpty);
    });
  }

  test(
    'Linux final close waits for saved state before the framework exit',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final store = InMemoryKeyValueStore();
      final tray = FakeTrayApi();
      final saved = Completer<void>();
      final savingStarted = Completer<void>();
      final events = <String>[];
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        expect(events, ['saved', 'cleanup']);
        expect(tray.destroyed, isTrue);
        events.add('platform-exit');
        platformCalls.add(call.method);
        return null;
      });
      final controller = DesktopShellController(
        config: DesktopShellConfig(
          store: store,
          platform: TargetPlatform.linux,
          closeToTray: false,
          trayHostAvailable: () async => true,
          onBeforeQuit: () async => events.add('cleanup'),
        ),
        window: WindowManagerApi(),
        tray: tray,
        screen: FakeScreenApi(const [Rect.fromLTWH(0, 0, 1920, 1080)]),
        strings: lookupS(const Locale('en')),
      );
      addTearDown(controller.dispose);
      controller.addBeforeQuitListener(() async {
        expect(store.values[DesktopShellController.boundsKey], isNotNull);
        savingStarted.complete();
        await saved.future;
        events.add('saved');
      });
      await controller.initialize();
      windowCalls.clear();
      final closing = controller.handleCloseRequested();
      await savingStarted.future;
      expect(platformCalls, isEmpty);
      expect(windowCalls, isNot(contains('destroy')));
      expect(tray.destroyed, isFalse);
      saved.complete();
      await closing;
      expect(events, ['saved', 'cleanup', 'platform-exit']);
      expect(tray.destroyed, isTrue);
      expect(platformCalls, ['SystemNavigator.pop']);
      expect(windowCalls, isNot(contains('destroy')));
    },
  );

  test(
    'Linux close-to-tray still hides without requesting process exit',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final controller = DesktopShellController(
        config: DesktopShellConfig(
          store: InMemoryKeyValueStore(),
          platform: TargetPlatform.linux,
          closeToTray: true,
          trayHostAvailable: () async => true,
        ),
        window: WindowManagerApi(),
        tray: FakeTrayApi(),
        screen: FakeScreenApi(const [Rect.fromLTWH(0, 0, 1920, 1080)]),
        strings: lookupS(const Locale('en')),
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      windowCalls.clear();
      await controller.handleCloseRequested();
      expect(windowCalls.last, 'hide');
      expect(windowCalls, isNot(contains('destroy')));
      expect(platformCalls, isEmpty);
    },
  );
}

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/desktop/desktop.dart';
import 'package:ditmesh/desktop/testing/testing.dart';
import 'package:ditmesh/l10n/generated/s.dart';

/// Every label assertion is written against English; the harness pins it so
/// the test host's locale never leaks in.
final S en = lookupS(const Locale('en'));

/// Builds a controller on fakes. [platform] defaults to Linux so the tray
/// tooltip path is exercised without the macOS badge title.
({
  DesktopShellController controller,
  FakeWindowApi window,
  FakeTrayApi tray,
  FakeScreenApi screen,
  InMemoryKeyValueStore store,
  List<String> log,
})
_harness({
  TargetPlatform platform = TargetPlatform.linux,
  Map<String, String>? stored,
  List<Rect> areas = const [Rect.fromLTWH(0, 0, 1920, 1040)],
  bool closeToTray = true,
  FakeTrayApi? tray,
  FakeWindowApi? window,
  Future<void> Function()? onBeforeQuit,
  void Function(bool enabled)? onToggleSound,
  S? strings,
}) {
  final store = InMemoryKeyValueStore(stored);
  final log = <String>[];
  final w = window ?? FakeWindowApi();
  final t = tray ?? FakeTrayApi();
  final s = FakeScreenApi(areas);
  final controller = DesktopShellController(
    config: DesktopShellConfig(
      store: store,
      platform: platform,
      closeToTray: closeToTray,
      onBeforeQuit: onBeforeQuit,
      onToggleSound: onToggleSound,
      persistDebounce: Duration.zero,
      log: log.add,
    ),
    window: w,
    tray: t,
    screen: s,
    strings: strings ?? en,
  );
  return (
    controller: controller,
    window: w,
    tray: t,
    screen: s,
    store: store,
    log: log,
  );
}

Future<void> _drain() => Future<void>.delayed(Duration.zero);

void main() {
  test('tray sound choice survives controller recreation', () async {
    final h = _harness();
    await h.controller.initialize();
    await h.controller.setSoundEnabled(false);
    final again = _harness(stored: h.store.values);
    await again.controller.initialize();
    expect(again.controller.soundEnabled, isFalse);
    h.controller.dispose();
    again.controller.dispose();
  });
  group('startup and bounds restore', () {
    test(
      'first launch: centred default size, minimum 360×640, shown',
      () async {
        final h = _harness();
        await h.controller.initialize();

        expect(h.controller.isActive, isTrue);
        expect(h.window.initialized, isTrue);
        expect(h.window.preventClose, isTrue);
        expect(h.window.minimumSize, const Size(360, 640));
        expect(h.window.bounds, const Rect.fromLTWH(410, 140, 1100, 760));
        expect(h.window.visible, isTrue);
        expect(h.window.focused, isTrue);
        expect(h.window.maximized, isFalse);
        expect(h.window.title, 'DitMesh');
        expect(h.controller.isWindowVisible, isTrue);
      },
    );

    test('restores persisted bounds and re-maximises', () async {
      final saved = const WindowBounds(
        rect: Rect.fromLTWH(300, 120, 900, 700),
        maximized: true,
      ).encode();
      final h = _harness(stored: {DesktopShellController.boundsKey: saved});
      await h.controller.initialize();

      expect(h.window.bounds, const Rect.fromLTWH(300, 120, 900, 700));
      expect(h.window.calls, contains('maximize'));
      expect(h.window.maximized, isTrue);
    });

    test('clamps persisted bounds that are off today\'s display', () async {
      final saved = const WindowBounds(
        rect: Rect.fromLTWH(-4000, -500, 3000, 2000),
      ).encode();
      final h = _harness(stored: {DesktopShellController.boundsKey: saved});
      await h.controller.initialize();

      expect(h.window.bounds, const Rect.fromLTWH(0, 0, 1920, 1040));
    });

    test('corrupt persisted bounds degrade to first launch', () async {
      final h = _harness(stored: {DesktopShellController.boundsKey: '{oops'});
      await h.controller.initialize();
      expect(h.window.bounds, const Rect.fromLTWH(410, 140, 1100, 760));
    });

    test('display lookup failure skips clamping but still shows', () async {
      final h = _harness();
      h.screen.error = StateError('headless');
      await h.controller.initialize();
      expect(h.window.visible, isTrue);
      expect(h.log.single, contains('display lookup failed'));
    });

    test('initialize is idempotent', () async {
      final h = _harness();
      await h.controller.initialize();
      final calls = h.window.calls.length;
      await h.controller.initialize();
      expect(h.window.calls.length, calls);
    });
  });

  group('bounds persistence', () {
    test('persists bounds and maximised flag on close', () async {
      final h = _harness(closeToTray: false);
      await h.controller.initialize();
      h.window.bounds = const Rect.fromLTWH(50, 60, 800, 700);
      h.window.maximized = true;

      await h.controller.handleCloseRequested();

      final stored = WindowBounds.decode(
        h.store.values[DesktopShellController.boundsKey],
      );
      expect(
        stored,
        const WindowBounds(
          rect: Rect.fromLTWH(50, 60, 800, 700),
          maximized: true,
        ),
      );
    });

    test('persists after a move/resize once the debounce elapses', () async {
      final h = _harness();
      await h.controller.initialize();

      h.window.simulateBoundsChanged(const Rect.fromLTWH(10, 20, 700, 900));
      expect(h.store.values, isNot(contains(DesktopShellController.boundsKey)));
      await _drain();
      await _drain();

      final stored = WindowBounds.decode(
        h.store.values[DesktopShellController.boundsKey],
      );
      expect(stored?.rect, const Rect.fromLTWH(10, 20, 700, 900));
    });

    test('persists before hiding to the tray', () async {
      final h = _harness();
      await h.controller.initialize();
      h.window.bounds = const Rect.fromLTWH(5, 5, 640, 900);

      await h.controller.hideToTray();

      expect(
        WindowBounds.decode(
          h.store.values[DesktopShellController.boundsKey],
        )?.rect,
        const Rect.fromLTWH(5, 5, 640, 900),
      );
    });
  });

  group('close-to-tray', () {
    test('close hides instead of quitting when the setting is on', () async {
      var quitHooks = 0;
      final h = _harness(onBeforeQuit: () async => quitHooks++);
      await h.controller.initialize();

      h.window.simulateCloseRequested();
      await _drain();

      expect(h.window.visible, isFalse);
      expect(h.window.destroyed, isFalse);
      expect(quitHooks, 0);
      expect(h.controller.isWindowVisible, isFalse);
      await h.controller.flushTrayUpdates();
      expect(h.tray.menu.first.label, 'Show DitMesh');
    });

    test('close quits when the setting is off', () async {
      var quitHooks = 0;
      final h = _harness(
        closeToTray: false,
        onBeforeQuit: () async => quitHooks++,
      );
      await h.controller.initialize();

      h.window.simulateCloseRequested();
      await _drain();

      expect(h.window.destroyed, isTrue);
      expect(h.tray.destroyed, isTrue);
      expect(quitHooks, 1);
    });

    test('close quits when the tray is unavailable, even if on', () async {
      final h = _harness(tray: FakeTrayApi(failing: true));
      await h.controller.initialize();
      expect(h.controller.isTrayAvailable, isFalse);
      expect(h.log.single, contains('tray unavailable'));

      h.window.simulateCloseRequested();
      await _drain();

      expect(h.window.destroyed, isTrue);
      expect(
        h.window.calls,
        isNot(contains('hide')),
        reason: 'never hidden without a tray',
      );
    });

    test('persisted closeToTray=false overrides the config default', () async {
      final h = _harness(
        stored: {DesktopShellController.closeToTrayKey: 'false'},
      );
      await h.controller.initialize();
      expect(h.controller.closeToTray, isFalse);

      h.window.simulateCloseRequested();
      await _drain();
      expect(h.window.destroyed, isTrue);
    });

    test('setCloseToTray persists and notifies', () async {
      final h = _harness();
      await h.controller.initialize();
      var notified = 0;
      h.controller.addListener(() => notified++);

      await h.controller.setCloseToTray(false);

      expect(h.store.values[DesktopShellController.closeToTrayKey], 'false');
      expect(notified, 1);
    });

    test('Quit from the tray menu exits even with close-to-tray on', () async {
      var quitHooks = 0;
      final h = _harness(onBeforeQuit: () async => quitHooks++);
      await h.controller.initialize();

      h.tray.simulateMenuItem(TrayMenuKeys.quit);
      await _drain();

      expect(h.window.destroyed, isTrue);
      expect(quitHooks, 1);
      // A second close request after quit is ignored.
      h.window.simulateCloseRequested();
      await _drain();
      expect(h.window.calls.where((c) => c == 'destroy').length, 1);
    });

    test('a failing onBeforeQuit still destroys the window', () async {
      final h = _harness(
        closeToTray: false,
        onBeforeQuit: () async => throw StateError('teardown'),
      );
      await h.controller.initialize();
      await h.controller.quit();
      expect(h.window.destroyed, isTrue);
      expect(h.log.single, contains('onBeforeQuit failed'));
    });
  });

  group('tray', () {
    test('uses the platform icon and initial tooltip / menu', () async {
      final h = _harness();
      await h.controller.initialize();

      expect(h.tray.iconAsset, TrayIconAssets.linuxPng);
      expect(h.tray.isTemplate, isFalse);
      expect(h.tray.tooltip, 'DitMesh');
      expect(h.tray.menu.map((e) => e.key), [
        TrayMenuKeys.showHide,
        TrayMenuKeys.sound,
        '',
        TrayMenuKeys.quit,
      ]);
      expect(h.tray.menu.first.label, 'Hide DitMesh');
      expect(h.tray.menu[1].checked, isTrue);
    });

    test('macOS gets a template icon; Windows the .ico', () async {
      final mac = _harness(platform: TargetPlatform.macOS);
      await mac.controller.initialize();
      expect(mac.tray.iconAsset, TrayIconAssets.macTemplate);
      expect(mac.tray.isTemplate, isTrue);

      final win = _harness(platform: TargetPlatform.windows);
      await win.controller.initialize();
      expect(win.tray.iconAsset, TrayIconAssets.windowsIco);
    });

    test('left click toggles the window', () async {
      final h = _harness();
      await h.controller.initialize();

      h.tray.simulateClick();
      await _drain();
      expect(h.window.visible, isFalse);

      h.tray.simulateClick();
      await _drain();
      expect(h.window.visible, isTrue);
      expect(h.window.focused, isTrue);
    });

    test('Show/Hide menu row toggles and relabels', () async {
      final h = _harness();
      await h.controller.initialize();

      h.tray.simulateMenuItem(TrayMenuKeys.showHide);
      await _drain();
      await h.controller.flushTrayUpdates();
      expect(h.window.visible, isFalse);
      expect(h.tray.menu.first.label, 'Show DitMesh');
    });

    test('Sound row flips the checkbox and calls the placeholder', () async {
      final toggles = <bool>[];
      final h = _harness(onToggleSound: toggles.add);
      await h.controller.initialize();

      h.tray.simulateMenuItem(TrayMenuKeys.sound);
      await _drain();
      await h.controller.flushTrayUpdates();

      expect(toggles, [false]);
      expect(h.controller.soundEnabled, isFalse);
      expect(h.tray.menu[1].label, 'Sound off');
      expect(h.tray.menu[1].checked, isFalse);
    });

    test(
      'a per-platform gap (no tooltip) is tolerated and logged once',
      () async {
        final h = _harness(tray: FakeTrayApi(unsupported: {'setToolTip'}));
        await h.controller.initialize();
        expect(h.controller.isTrayAvailable, isTrue);
        expect(h.tray.menu, isNotEmpty);

        h.controller.setUnreadCount(2);
        await h.controller.flushTrayUpdates();

        expect(h.log.where((m) => m.contains('setToolTip')).length, 1);
      },
    );
  });

  group('unread count', () {
    test('updates the window title, tooltip and macOS badge', () async {
      final h = _harness(platform: TargetPlatform.macOS);
      await h.controller.initialize();
      var notified = 0;
      h.controller.addListener(() => notified++);

      h.controller.setUnreadCount(3);
      await h.controller.flushTrayUpdates();

      expect(notified, 1);
      expect(h.controller.windowTitle, '(3) DitMesh');
      expect(h.window.title, '(3) DitMesh');
      expect(h.tray.tooltip, 'DitMesh — 3 unread messages');
      expect(h.tray.title, '3');

      h.controller.setUnreadCount(0);
      await h.controller.flushTrayUpdates();
      expect(h.window.title, 'DitMesh');
      expect(h.tray.tooltip, 'DitMesh');
      expect(h.tray.title, '');
    });

    test('caps the badge at 99+ and clamps negatives to zero', () async {
      final h = _harness();
      await h.controller.initialize();

      h.controller.setUnreadCount(250);
      await h.controller.flushTrayUpdates();
      expect(h.controller.windowTitle, '(99+) DitMesh');
      expect(h.tray.tooltip, 'DitMesh — 250 unread messages');

      h.controller.setUnreadCount(-4);
      expect(h.controller.unreadCount, 0);
    });


    test('does not touch the tray title off macOS', () async {
      final h = _harness(platform: TargetPlatform.windows);
      await h.controller.initialize();
      h.controller.setUnreadCount(1);
      await h.controller.flushTrayUpdates();
      expect(h.tray.title, isNull);
      expect(h.tray.calls, isNot(contains('setTitle')));
    });

    test('unchanged count is a no-op', () async {
      final h = _harness();
      await h.controller.initialize();
      final calls = h.window.calls.length;
      h.controller.setUnreadCount(0);
      expect(h.window.calls.length, calls);
    });
  });

  // Language switching (updateStrings) is covered in
  // desktop_shell_strings_test.dart.

  group('mobile platforms are inert', () {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      test('$platform: initialize, unread, show/hide, close never reach '
          'the plugins or the store', () async {
        final h = _harness(platform: platform);
        await h.controller.initialize();

        h.controller.setUnreadCount(7);
        await h.controller.showWindow();
        await h.controller.hideToTray();
        await h.controller.toggleWindow();
        await h.controller.persistWindowState();
        await h.controller.handleCloseRequested();
        await h.controller.quit();
        await h.controller.setCloseToTray(false);
        await h.controller.flushTrayUpdates();

        expect(h.controller.isActive, isFalse);
        expect(h.controller.isTrayAvailable, isFalse);
        expect(h.window.calls, isEmpty);
        expect(h.tray.calls, isEmpty);
        expect(h.screen.lookups, 0);
        expect(h.store.values, isEmpty);
        // State is still tracked so callers need no platform branches.
        expect(h.controller.unreadCount, 7);
        expect(h.controller.windowTitle, '(7) DitMesh');
        expect(h.controller.closeToTray, isFalse);
      });
    }

    test('DesktopShellConfig.isDesktop follows the platform', () {
      final store = InMemoryKeyValueStore();
      for (final p in TargetPlatform.values) {
        final config = DesktopShellConfig(store: store, platform: p);
        expect(config.isDesktop, isDesktopTarget(p));
      }
      expect(isDesktopTarget(TargetPlatform.macOS), isTrue);
      expect(isDesktopTarget(TargetPlatform.windows), isTrue);
      expect(isDesktopTarget(TargetPlatform.linux), isTrue);
      expect(isDesktopTarget(TargetPlatform.android), isFalse);
      expect(isDesktopTarget(TargetPlatform.iOS), isFalse);
      expect(isDesktopTarget(TargetPlatform.fuchsia), isFalse);
    });
  });

  test('initDesktopShell accepts injected APIs and runs startup', () async {
    final store = InMemoryKeyValueStore();
    final window = FakeWindowApi();
    final controller = await initDesktopShell(
      DesktopShellConfig(store: store, platform: TargetPlatform.linux),
      window: window,
      tray: FakeTrayApi(),
      screen: FakeScreenApi(),
    );
    expect(controller.isActive, isTrue);
    expect(window.visible, isTrue);
    controller.dispose();
    expect(window.handler, isNull);
  });
}

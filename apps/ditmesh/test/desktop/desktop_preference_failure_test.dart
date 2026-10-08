import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/desktop/desktop.dart';
import 'package:ditmesh/desktop/testing/testing.dart' as fake;

class FailingStore implements KeyValueStore {
  final values = <String, String>{};
  String? failingKey;
  Completer<void>? delayed;
  @override
  Future<String?> get(String key) async => values[key];
  @override
  Future<void> set(String key, String value) async {
    if (failingKey == key) throw StateError('disk unavailable');
    if (key == DesktopShellController.soundEnabledKey) await delayed?.future;
    values[key] = value;
  }
}

void main() {
  test('quit waits for an in-flight desktop preference write', () async {
    final store = FailingStore()..delayed = Completer<void>();
    final window = fake.FakeWindowApi();
    final shell = DesktopShellController(
      config: DesktopShellConfig(store: store, platform: TargetPlatform.macOS),
      window: window,
      tray: fake.FakeTrayApi(),
      screen: fake.FakeScreenApi(),
    );
    await shell.initialize();
    final save = shell.setSoundEnabled(false);
    final quit = shell.quit();
    await pumpEventQueue();
    expect(window.destroyed, isFalse);
    store.delayed!.complete();
    await Future.wait([save, quit]);
    expect(store.values[DesktopShellController.soundEnabledKey], 'false');
    expect(window.destroyed, isTrue);
    shell.dispose();
  });
  test('failed desktop sound selection can be retried unchanged', () async {
    final store = FailingStore();
    final shell = DesktopShellController(
      config: DesktopShellConfig(store: store, platform: TargetPlatform.macOS),
      window: fake.FakeWindowApi(),
      tray: fake.FakeTrayApi(),
      screen: fake.FakeScreenApi(),
    );
    await shell.initialize();
    store.failingKey = DesktopShellController.soundEnabledKey;
    await shell.setSoundEnabled(false);
    expect(shell.soundEnabled, isTrue);
    store.failingKey = null;
    await shell.setSoundEnabled(false);
    expect(store.values[DesktopShellController.soundEnabledKey], 'false');
    shell.dispose();
  });
  test('failed close-to-tray selection can be retried unchanged', () async {
    final store = FailingStore();
    final shell = DesktopShellController(
      config: DesktopShellConfig(store: store, platform: TargetPlatform.macOS),
      window: fake.FakeWindowApi(),
      tray: fake.FakeTrayApi(),
      screen: fake.FakeScreenApi(),
    );
    await shell.initialize();
    store.failingKey = DesktopShellController.closeToTrayKey;
    await shell.setCloseToTray(false);
    expect(shell.closeToTray, isTrue);
    store.failingKey = null;
    await shell.setCloseToTray(false);
    expect(store.values[DesktopShellController.closeToTrayKey], 'false');
    shell.dispose();
  });
}

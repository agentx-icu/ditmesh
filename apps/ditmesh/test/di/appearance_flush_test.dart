import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/app_preferences.dart';
import 'package:ditmesh/di/app_settings.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/ui/appearance/ui_style.dart';
import 'package:ditmesh_chat_api/testing.dart';

final class _BlockingAppearanceStore implements KeyValueStore {
  final _delegate = InMemoryKeyValueStore();
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  String? getString(String key) => _delegate.getString(key);
  @override
  Future<void> remove(String key) => _delegate.remove(key);
  @override
  Future<void> setString(String key, String value) async {
    if (key == AppSettings.storageKey) {
      if (!started.isCompleted) started.complete();
      await release.future;
    }
    await _delegate.setString(key, value);
  }
}

void main() {
  test(
    'app flush waits for appearance writes before allowing shutdown',
    () async {
      final identity = FakeIdentityService();
      final store = _BlockingAppearanceStore();
      final prefs = AppPreferences(
        store,
        backendLabel: 'test',
        identity: identity,
      );
      final saving = prefs.settings.applyAppearance(
        style: UiStyle.paper,
        themeMode: ThemeMode.dark,
      );
      await store.started.future;
      prefs.notifications.sound = false;
      var flushed = false;
      final flushing = prefs.flush().then((_) => flushed = true);
      try {
        await pumpEventQueue();
        expect(flushed, isFalse);
        expect(prefs.settings.style, UiStyle.modern);
      } finally {
        store.release.complete();
        await saving;
        await flushing;
        prefs.dispose();
      }
      final reopened = AppPreferences(
        store,
        backendLabel: 'test',
        identity: identity,
      );
      expect(reopened.settings.style, UiStyle.paper);
      expect(reopened.settings.themeMode, ThemeMode.dark);
      expect(reopened.notifications.sound, isFalse);
      reopened.dispose();
      await identity.dispose();
    },
  );
}

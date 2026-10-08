import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/app_settings.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/ui/appearance/ui_style.dart';

void main() {
  test('legacy theme survives absent or damaged appearance preferences', () {
    for (final saved in [null, 'broken', '[]', '{"mode":"unknown"}']) {
      final store = InMemoryKeyValueStore({
        'app.theme': 'dark',
        AppSettings.storageKey: ?saved,
      });
      final settings = AppSettings(backendLabel: 'test', store: store);
      addTearDown(settings.dispose);
      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.style, UiStyle.modern);
    }
  });

  test('saved appearance takes precedence over a legacy theme', () async {
    final store = InMemoryKeyValueStore({
      'app.theme': 'dark',
      AppSettings.storageKey: '{"style":"paper","mode":"light"}',
    });
    final settings = AppSettings(backendLabel: 'test', store: store);
    addTearDown(settings.dispose);
    expect(settings.style, UiStyle.paper);
    expect(settings.themeMode, ThemeMode.light);
    await settings.applyAppearance(
      style: UiStyle.radio,
      themeMode: ThemeMode.system,
    );
    final reopened = AppSettings(backendLabel: 'test', store: store);
    addTearDown(reopened.dispose);
    expect(reopened.style, UiStyle.radio);
    expect(reopened.themeMode, ThemeMode.system);
  });
}

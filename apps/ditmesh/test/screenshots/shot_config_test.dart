import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/app_settings.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/ui/appearance/ui_style.dart';

import '../../integration_test/support/shot_harness.dart';

void main() {
  test('all ten canonical shot locales resolve to shipped locales', () {
    const tags = [
      'en',
      'zh',
      'zh_Hant',
      'ja',
      'ko',
      'de',
      'fr',
      'es',
      'pt',
      'ru',
    ];
    expect(parseShotLocales(tags.join(',')), tags);
    expect(
      parseShotLocale('zh_Hant'),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    );
    for (final tag in tags) {
      expect(parseShotLocale(tag).languageCode, tag.split('_').first);
    }
  });

  test('empty unknown and duplicate shot locales fail before capture', () {
    for (final value in ['', 'en,', 'en,en', 'en,unknown', 'zh_Hans']) {
      expect(() => parseShotLocales(value), throwsArgumentError, reason: value);
    }
    expect(() => parseShotLocale('unknown'), throwsArgumentError);
  });

  test('all five styles parse and unknown or empty styles fail', () {
    for (final style in UiStyle.values) {
      expect(parseShotStyle(style.name), style);
    }
    for (final value in ['', 'future', 'all']) {
      expect(() => parseShotStyle(value), throwsArgumentError);
    }
  });

  test('requested shot appearance is applied and persisted', () async {
    final store = InMemoryKeyValueStore();
    final settings = AppSettings(backendLabel: 'test', store: store);
    addTearDown(settings.dispose);
    for (final style in UiStyle.values) {
      await applyShotAppearance(settings, style: style.name, theme: 'dark');
      expect(settings.style, style);
      expect(settings.themeMode, ThemeMode.dark);
      final reopened = AppSettings(backendLabel: 'test', store: store);
      expect(reopened.style, style);
      expect(reopened.themeMode, ThemeMode.dark);
      reopened.dispose();
    }
  });
}

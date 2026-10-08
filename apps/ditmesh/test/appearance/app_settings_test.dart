import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/app_settings.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/ui/appearance/ui_style.dart';

void main() {
  test('new and corrupt preferences use Modern Calm and system mode', () {
    for (final saved in [
      null,
      'broken',
      '{}',
      '{"style":"future","mode":"unknown"}',
    ]) {
      final settings = AppSettings(
        backendLabel: 'test',
        store: InMemoryKeyValueStore(
          saved == null ? null : {AppSettings.storageKey: saved},
        ),
      );
      addTearDown(settings.dispose);
      expect(settings.style, UiStyle.modern);
      expect(settings.themeMode, ThemeMode.system);
    }
  });

  test(
    'all five styles persist with independent brightness across restart',
    () async {
      final store = InMemoryKeyValueStore();
      final settings = AppSettings(backendLabel: 'test', store: store);
      addTearDown(settings.dispose);
      for (final style in UiStyle.values) {
        for (final mode in ThemeMode.values) {
          await settings.applyAppearance(style: style, themeMode: mode);
          final reopened = AppSettings(
            backendLabel: 'another identity',
            store: store,
          );
          expect(reopened.style, style);
          expect(reopened.themeMode, mode);
          reopened.dispose();
        }
      }
    },
  );

  test('failed saving leaves the visible appearance unchanged', () async {
    final settings = AppSettings(backendLabel: 'test', store: FailingStore());
    addTearDown(settings.dispose);
    var notifications = 0;
    settings.addListener(() => notifications++);
    await expectLater(
      settings.applyAppearance(style: UiStyle.radio, themeMode: ThemeMode.dark),
      throwsA(isA<FileSystemException>()),
    );
    expect(settings.style, UiStyle.modern);
    expect(settings.themeMode, ThemeMode.system);
    expect(notifications, 0);
  });

  test('concurrent saves retain the last chosen appearance', () async {
    final store = InMemoryKeyValueStore();
    final settings = AppSettings(backendLabel: 'test', store: store);
    addTearDown(settings.dispose);
    await Future.wait([
      settings.applyAppearance(style: UiStyle.radio, themeMode: ThemeMode.dark),
      settings.applyAppearance(
        style: UiStyle.cartoon,
        themeMode: ThemeMode.light,
      ),
    ]);
    final reopened = AppSettings(backendLabel: 'test', store: store);
    addTearDown(reopened.dispose);
    expect(reopened.style, UiStyle.cartoon);
    expect(reopened.themeMode, ThemeMode.light);
  });

  test('language and appearance file writes can complete together', () async {
    final dir = await Directory.systemTemp.createTemp('ditmesh_appearance_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/settings.json');
    final store = await JsonFileKeyValueStore.open(file);
    await Future.wait([
      store.setString('i18n.locale', 'zh'),
      store.setString(
        'appearance.preferences',
        '{"style":"cartoon","mode":"dark"}',
      ),
      store.setString('window.bounds', '1280x800'),
    ]);
    final reopened = await JsonFileKeyValueStore.open(file);
    expect(reopened.getString('i18n.locale'), 'zh');
    expect(reopened.getString('window.bounds'), '1280x800');
    final settings = AppSettings(backendLabel: 'test', store: reopened);
    addTearDown(settings.dispose);
    expect(settings.style, UiStyle.cartoon);
    expect(settings.themeMode, ThemeMode.dark);
  });

  test('failed appearance is not persisted by later settings writes', () async {
    final dir = await Directory.systemTemp.createTemp('ditmesh_failed_save_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/settings.json');
    final store = await JsonFileKeyValueStore.open(file);
    final settings = AppSettings(backendLabel: 'test', store: store);
    addTearDown(settings.dispose);
    await settings.applyAppearance(
      style: UiStyle.modern,
      themeMode: ThemeMode.light,
    );
    final saved = store.getString(AppSettings.storageKey);
    // A directory at the temporary-file path makes the real disk write fail.
    final blocked = await Directory('${file.path}.tmp').create();
    await expectLater(
      settings.applyAppearance(
        style: UiStyle.cartoon,
        themeMode: ThemeMode.dark,
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(store.getString(AppSettings.storageKey), saved);
    await blocked.delete();
    await store.setString('i18n.locale', 'zh');
    final reopenedStore = await JsonFileKeyValueStore.open(file);
    final reopened = AppSettings(backendLabel: 'test', store: reopenedStore);
    addTearDown(reopened.dispose);
    expect(reopened.style, UiStyle.modern);
    expect(reopened.themeMode, ThemeMode.light);
    expect(reopenedStore.getString('i18n.locale'), 'zh');
    // Failed writes also leave the queue available for an explicit retry.
    await settings.applyAppearance(
      style: UiStyle.cartoon,
      themeMode: ThemeMode.dark,
    );
    expect(settings.style, UiStyle.cartoon);
  });
}

class FailingStore implements KeyValueStore {
  @override
  String? getString(String key) => null;
  @override
  Future<void> setString(String key, String value) async =>
      throw const FileSystemException('read only');
  @override
  Future<void> remove(String key) async =>
      throw const FileSystemException('read only');
}

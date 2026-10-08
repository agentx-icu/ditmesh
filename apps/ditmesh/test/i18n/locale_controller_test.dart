import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/i18n/locale_controller.dart';

final class _FailingLocaleStore implements KeyValueStore {
  _FailingLocaleStore([
    Map<String, String>? initial,
    this.failuresRemaining = 1,
  ]) : delegate = InMemoryKeyValueStore(initial);

  final InMemoryKeyValueStore delegate;
  int failuresRemaining;

  @override
  String? getString(String key) => delegate.getString(key);

  @override
  Future<void> setString(String key, String value) async {
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw const FileSystemException('preferences disk unavailable');
    }
    await delegate.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw const FileSystemException('preferences disk unavailable');
    }
    await delegate.remove(key);
  }
}

void main() {
  group('LocaleController', () {
    test('defaults to following the system when nothing is stored', () {
      final controller = LocaleController(InMemoryKeyValueStore());
      expect(controller.locale, isNull);
      expect(controller.followsSystem, isTrue);
    });

    test('setLocale notifies and persists the canonical name', () async {
      final store = InMemoryKeyValueStore();
      final controller = LocaleController(store);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setLocale(const Locale('zh'));

      expect(controller.locale, const Locale('zh'));
      expect(store.getString(LocaleController.storageKey), 'zh');
      expect(notifications, 1);
    });

    test('a new controller restores the persisted choice', () async {
      final store = InMemoryKeyValueStore();
      await LocaleController(store).setLocale(const Locale('en'));

      final restored = LocaleController(store);
      expect(restored.locale, const Locale('en'));
      expect(restored.followsSystem, isFalse);
    });

    test('returning to system default removes the stored key', () async {
      final store = InMemoryKeyValueStore({
        LocaleController.storageKey: 'zh_CN',
      });
      final controller = LocaleController(store);
      expect(controller.locale, const Locale('zh'));

      await controller.setLocale(null);

      expect(controller.locale, isNull);
      expect(store.getString(LocaleController.storageKey), isNull);
    });

    test('setting the same locale twice notifies once', () async {
      final controller = LocaleController(InMemoryKeyValueStore());
      var notifications = 0;
      controller.addListener(() => notifications++);
      await controller.setLocale(const Locale('zh'));
      await controller.setLocale(const Locale('zh', 'CN'));
      expect(notifications, 1);
    });

    test(
      'a failed language save restores selection and allows retry',
      () async {
        final store = _FailingLocaleStore();
        final controller = LocaleController(store);
        await expectLater(
          controller.setLocale(const Locale('zh')),
          throwsA(isA<FileSystemException>()),
        );
        expect(controller.locale, isNull);

        await controller.setLocale(const Locale('zh'));

        expect(LocaleController(store).locale, const Locale('zh'));
      },
    );

    test('a failed return to system language can be retried', () async {
      final store = _FailingLocaleStore({LocaleController.storageKey: 'zh'});
      final controller = LocaleController(store);
      await expectLater(
        controller.setLocale(null),
        throwsA(isA<FileSystemException>()),
      );
      expect(controller.locale, const Locale('zh'));

      await controller.setLocale(null);

      expect(LocaleController(store).locale, isNull);
    });

    test(
      'overlapping failed language changes revert to the saved language',
      () async {
        final store = _FailingLocaleStore(null, 2);
        final controller = LocaleController(store);
        await Future.wait(<Future<void>>[
          expectLater(
            controller.setLocale(const Locale('zh')),
            throwsA(isA<FileSystemException>()),
          ),
          expectLater(
            controller.setLocale(const Locale('en')),
            throwsA(isA<FileSystemException>()),
          ),
        ]);

        expect(controller.locale, isNull);
        await controller.setLocale(const Locale('zh'));
        expect(LocaleController(store).locale, const Locale('zh'));
      },
    );

    test(
      'language changes from listeners persist the final selection',
      () async {
        final store = InMemoryKeyValueStore();
        final controller = LocaleController(store);
        Future<void>? later;
        controller.addListener(() {
          if (controller.locale == const Locale('zh')) {
            later = controller.setLocale(const Locale('en'));
          }
        });

        await controller.setLocale(const Locale('zh'));
        await later;

        expect(controller.locale, const Locale('en'));
        expect(LocaleController(store).locale, const Locale('en'));
      },
    );

    test('an unsupported locale is ignored', () async {
      final store = InMemoryKeyValueStore();
      final controller = LocaleController(store);
      await controller.setLocale(const Locale('xx'));
      expect(controller.locale, isNull);
      expect(store.getString(LocaleController.storageKey), isNull);
    });

    test('a corrupt stored value falls back to system default', () {
      final controller = LocaleController(
        InMemoryKeyValueStore({LocaleController.storageKey: 'klingon'}),
      );
      expect(controller.locale, isNull);
    });

    test('localeName / parseLocaleName round-trip and tolerate variants', () {
      expect(LocaleController.localeName(const Locale('zh')), 'zh');
      expect(
        LocaleController.localeName(
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
        ),
        'zh_Hant',
      );
      expect(LocaleController.localeName(const Locale('en')), 'en');
      for (final name in ['zh', 'zh_CN', 'zh-Hans', 'zh_Hans_CN', 'ZH']) {
        expect(
          LocaleController.parseLocaleName(name),
          const Locale('zh'),
          reason: name,
        );
      }
      expect(LocaleController.parseLocaleName('en_US'), const Locale('en'));
      expect(LocaleController.parseLocaleName(''), isNull);
      expect(LocaleController.parseLocaleName(null), isNull);
    });

    test('supportedLocales mirrors the generated S class', () {
      expect(
        LocaleController.supportedLocales.map((l) => l.languageCode),
        containsAll(['en', 'zh']),
      );
    });
  });

  group('JsonFileKeyValueStore', () {
    late Directory dir;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('ditmesh_i18n_store_');
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('persists across instances and survives a missing file', () async {
      final file = File('${dir.path}/prefs/i18n.json');
      final store = await JsonFileKeyValueStore.open(file);
      expect(store.getString('k'), isNull);

      await store.setString('k', 'v');
      final reopened = await JsonFileKeyValueStore.open(file);
      expect(reopened.getString('k'), 'v');

      await reopened.remove('k');
      final again = await JsonFileKeyValueStore.open(file);
      expect(again.getString('k'), isNull);
    });

    test('treats a corrupt file as empty instead of throwing', () async {
      final file = File('${dir.path}/i18n.json')
        ..writeAsStringSync('{not json');
      final store = await JsonFileKeyValueStore.open(file);
      expect(store.getString('anything'), isNull);
    });

    test(
      'failed preferences do not leak into a later successful save',
      () async {
        final file = File('${dir.path}/i18n.json');
        final store = await JsonFileKeyValueStore.open(file);
        await store.setString('locale', 'en');
        final original = await file.rename('${file.path}.original');
        await Directory(file.path).create();
        await expectLater(
          store.setString('locale', 'zh'),
          throwsA(isA<FileSystemException>()),
        );
        await Directory(file.path).delete();
        await original.rename(file.path);

        await store.setString('theme', 'dark');

        expect(
          (await JsonFileKeyValueStore.open(file)).getString('locale'),
          'en',
        );
        expect(store.getString('locale'), 'en');
      },
    );

    test('a failed preference removal can be retried', () async {
      final file = File('${dir.path}/i18n.json');
      final store = await JsonFileKeyValueStore.open(file);
      await store.setString('locale', 'zh');
      final original = await file.rename('${file.path}.original');
      await Directory(file.path).create();
      await expectLater(
        store.remove('locale'),
        throwsA(isA<FileSystemException>()),
      );
      await Directory(file.path).delete();
      await original.rename(file.path);

      await store.remove('locale');

      expect(
        (await JsonFileKeyValueStore.open(file)).getString('locale'),
        isNull,
      );
    });

    test(
      'overlapping preference writes retain every key after restart',
      () async {
        final file = File('${dir.path}/prefs/i18n.json');
        final store = await JsonFileKeyValueStore.open(file);

        await Future.wait(<Future<void>>[
          for (var index = 0; index < 20; index++)
            store.setString('key$index', 'value$index'),
        ]);

        final reopened = await JsonFileKeyValueStore.open(file);
        for (var index = 0; index < 20; index++) {
          expect(reopened.getString('key$index'), 'value$index');
        }
      },
    );

    test(
      'corrupt preferences recover the previous save across reopen',
      () async {
        final file = File('${dir.path}/i18n.json');
        final store = await JsonFileKeyValueStore.open(file);
        await store.setString('locale', 'en');
        await store.setString('locale', 'zh');
        await file.writeAsString('{not json');

        expect(
          (await JsonFileKeyValueStore.open(file)).getString('locale'),
          'en',
        );
        expect(
          (await JsonFileKeyValueStore.open(file)).getString('locale'),
          'en',
        );
      },
    );
  });
}

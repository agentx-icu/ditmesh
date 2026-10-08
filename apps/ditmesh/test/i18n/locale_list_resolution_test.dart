import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/i18n/current_strings.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/i18n/locale_controller.dart';
import 'package:ditmesh/i18n/locale_resolution.dart';
import 'package:ditmesh/l10n/generated/s.dart';

const _en = Locale('en');
const _zh = Locale('zh');
const _zhHans = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
const _zhHant = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
const _zhHantTw = Locale.fromSubtags(
  languageCode: 'zh',
  scriptCode: 'Hant',
  countryCode: 'TW',
);
const _ja = Locale('ja');
// Italian ships no ARB, so it always falls through to the next preference.
const _itIt = Locale('it', 'IT');

void main() {
  group('resolveSystemLocales', () {
    const shippedToday = [_en, _zh];
    const shippedLater = [_en, _zhHans, _zhHant, _ja];

    test('walks the preferred list in order', () {
      expect(
        resolveSystemLocales([_itIt, const Locale('zh', 'CN')], shippedToday),
        _zh,
      );
      expect(
        resolveSystemLocales([const Locale('ko'), _ja, _zh], shippedLater),
        _ja,
      );
      expect(resolveSystemLocales([_zh, _en], shippedToday), _zh);
      expect(
        resolveSystemLocales([const Locale('en', 'GB'), _zh], shippedToday),
        _en,
        reason: 'an earlier supported language wins over a later one',
      );
    });

    test('a list with nothing shipped falls back to English', () {
      expect(
        resolveSystemLocales([
          _itIt,
          const Locale('de'),
          const Locale('ko'),
        ], shippedToday),
        _en,
      );
    });

    test('null or empty list falls back', () {
      expect(resolveSystemLocales(null, shippedToday), _en);
      expect(resolveSystemLocales(const [], shippedToday), _en);
      expect(resolveSystemLocales(const [], shippedToday, fallback: _zh), _zh);
    });

    test('Chinese script/region variants inside a list', () {
      expect(resolveSystemLocales([_itIt, _zhHantTw], shippedToday), _zh);
      expect(
        resolveSystemLocales([_itIt, const Locale('zh', 'HK')], shippedLater),
        _zhHant,
      );
      expect(resolveSystemLocales([_itIt, _zhHantTw], shippedLater), _zhHant);
      expect(
        resolveSystemLocales([_itIt, const Locale('zh', 'CN')], shippedLater),
        _zhHans,
      );
    });
  });

  group('LocaleController with a system locale list', () {
    test('effectiveLocale walks the live list', () {
      var system = [_itIt, const Locale('zh', 'CN')];
      final controller = LocaleController(
        InMemoryKeyValueStore(),
        systemLocales: () => system,
      );
      addTearDown(controller.dispose);
      expect(controller.effectiveLocale, _zh);

      system = [_itIt];
      expect(controller.effectiveLocale, _en, reason: 'read live, not cached');
      system = const [];
      expect(controller.effectiveLocale, _en);
    });

    test('an explicit override wins over the system list', () async {
      final controller = LocaleController(
        InMemoryKeyValueStore(),
        systemLocales: () => const [Locale('zh', 'CN')],
      );
      addTearDown(controller.dispose);
      await controller.setLocale(_en);
      expect(controller.effectiveLocale, _en);
    });

    test('resolve (the MaterialApp callback) uses the same rules', () {
      expect(
        LocaleController.resolve([_itIt, _zhHantTw], S.supportedLocales),
        _zhHant,
      );
      expect(LocaleController.resolve(null, S.supportedLocales), _en);
    });
  });

  testWidgets(
    'MaterialApp, effectiveLocale and currentS agree for [it-IT, zh-CN]',
    (tester) async {
      tester.platformDispatcher.localesTestValue = const [
        _itIt,
        Locale('zh', 'CN'),
      ];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final controller = LocaleController(
        InMemoryKeyValueStore(),
        systemLocales: () => tester.platformDispatcher.locales,
      );
      LocaleController.active = controller;
      addTearDown(() {
        LocaleController.active = null;
        controller.dispose();
      });

      late BuildContext captured;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          locale: controller.locale,
          localeListResolutionCallback: LocaleController.resolve,
          home: Builder(
            builder: (context) {
              captured = context;
              return Text(S.of(context).languageTitle);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final appLocale = Localizations.localeOf(captured);
      expect(appLocale, _zh);
      expect(controller.effectiveLocale, appLocale);
      expect(currentLocale(), appLocale);
      expect(currentS().languageTitle, '语言');
      expect(find.text('语言'), findsOneWidget);
    },
  );
}

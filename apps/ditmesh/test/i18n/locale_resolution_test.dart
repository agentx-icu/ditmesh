import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/i18n/language_catalog.dart';
import 'package:ditmesh/i18n/locale_resolution.dart';

const _en = Locale('en');
const _zh = Locale('zh');
const _zhHans = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
const _zhHant = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
const _ja = Locale('ja');

void main() {
  group('resolveSystemLocale (toxee rules, data-driven)', () {
    const shippedToday = [_en, _zh];
    const shippedLater = [_en, _zhHans, _zhHant, _ja];

    test('unsupported language falls back to English', () {
      expect(resolveSystemLocale(const Locale('fr'), shippedToday), _en);
      expect(resolveSystemLocale(const Locale('ko'), shippedLater), _en);
    });

    test('plain zh maps to the only Chinese file we ship today', () {
      for (final system in [
        _zh,
        const Locale('zh', 'CN'),
        const Locale('zh', 'TW'),
        _zhHant,
      ]) {
        expect(resolveSystemLocale(system, shippedToday), _zh, reason: '$system');
      }
    });

    test('Traditional by script or by TW/HK/MO region once zh_Hant ships', () {
      expect(resolveSystemLocale(_zhHant, shippedLater), _zhHant);
      for (final region in ['TW', 'HK', 'MO']) {
        expect(
          resolveSystemLocale(Locale('zh', region), shippedLater),
          _zhHant,
          reason: region,
        );
      }
      expect(resolveSystemLocale(const Locale('zh', 'CN'), shippedLater), _zhHans);
      expect(resolveSystemLocale(_zh, shippedLater), _zhHans);
      expect(
        resolveSystemLocale(
          const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hans',
            countryCode: 'TW',
          ),
          shippedLater,
        ),
        _zhHans,
        reason: 'an explicit script beats the region',
      );
    });

    test('other languages match exactly on script, else language only', () {
      expect(resolveSystemLocale(const Locale('ja', 'JP'), shippedLater), _ja);
      expect(resolveSystemLocale(const Locale('en', 'GB'), shippedLater), _en);
    });
  });

  group('localeTag / parseLocaleTag', () {
    test('round-trips and prefers script over region', () {
      expect(localeTag(_en), 'en');
      expect(localeTag(_zhHant), 'zh_Hant');
      expect(localeTag(const Locale('pt', 'BR')), 'pt_BR');
      expect(parseLocaleTag('zh-Hans-CN'), _zhHans.withCountry('CN'));
      expect(parseLocaleTag('EN_us'), const Locale('en', 'US'));
      expect(parseLocaleTag(''), isNull);
      expect(parseLocaleTag(null), isNull);
    });
  });

  group('supportedLocaleFor', () {
    test('never changes language', () {
      expect(supportedLocaleFor(const Locale('fr'), [_en, _zh]), isNull);
      expect(supportedLocaleFor(const Locale('zh', 'TW'), [_en, _zh]), _zh);
    });
  });

  group('LanguageCatalog', () {
    test('native names, with tag fallback for unknown locales', () {
      expect(LanguageCatalog.nativeName(_en), 'English');
      expect(LanguageCatalog.nativeName(_zh), '简体中文');
      expect(LanguageCatalog.nativeName(_zhHant), '繁體中文');
      expect(LanguageCatalog.nativeName(const Locale('ja')), '日本語');
      expect(LanguageCatalog.nativeName(const Locale('xx')), 'xx');
      expect(LanguageCatalog.isRtl(const Locale('ar')), isTrue);
      expect(LanguageCatalog.isRtl(_en), isFalse);
    });
  });
}

extension on Locale {
  Locale withCountry(String country) => Locale.fromSubtags(
        languageCode: languageCode,
        scriptCode: scriptCode,
        countryCode: country,
      );
}

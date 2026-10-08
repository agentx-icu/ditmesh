import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/i18n/locale_controller.dart';
import 'package:ditmesh/i18n/locale_resolution.dart';
import 'package:ditmesh/i18n/strings_resolver.dart';
import 'package:ditmesh/l10n/generated/s.dart';

const _newTags = ['zh_Hant', 'ja', 'ko', 'de', 'fr', 'es', 'pt', 'ru'];
const _traditional = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all ten interface locales ship', () {
    expect(
      S.supportedLocales.map(localeTag),
      unorderedEquals(['en', 'zh', ..._newTags]),
    );
  });

  test('Apple language declarations match the shipped interface locales', () {
    final tags = S.supportedLocales.map((locale) {
      final tag = localeTag(locale);
      return tag == 'zh' ? 'zh-Hans' : tag.replaceAll('_', '-');
    });
    for (final platform in ['ios', 'macos']) {
      final text = File('$platform/Runner/Info.plist').readAsStringSync();
      final array = RegExp(
        r'<key>CFBundleLocalizations</key>\s*<array>(.*?)</array>',
        dotAll: true,
      ).firstMatch(text);
      expect(array, isNotNull, reason: platform);
      final declared = RegExp(
        r'<string>([^<]+)</string>',
      ).allMatches(array!.group(1)!).map((match) => match.group(1)!);
      expect(declared, unorderedEquals(tags), reason: platform);
    }
  });

  test('system Chinese script and region select the shipped translation', () {
    for (final region in ['TW', 'HK', 'MO']) {
      final controller = LocaleController(
        InMemoryKeyValueStore(),
        systemLocales: () => [Locale('zh', region)],
      );
      addTearDown(controller.dispose);
      expect(controller.effectiveLocale, _traditional, reason: region);
      expect(lookupS(controller.effectiveLocale).languageTitle, '語言');
    }
    final controller = LocaleController(
      InMemoryKeyValueStore(),
      systemLocales: () => const [
        Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'TW',
        ),
      ],
    );
    addTearDown(controller.dispose);
    expect(controller.effectiveLocale, const Locale('zh'));
  });

  for (final tag in _newTags) {
    test('$tag persists and updates context-free service strings', () async {
      final locale = parseLocaleTag(tag)!;
      final store = InMemoryKeyValueStore();
      final controller = LocaleController(store);
      final strings = StringsResolver(controller);
      addTearDown(controller.dispose);
      addTearDown(strings.dispose);
      var changes = 0;
      strings.addListener(() => changes++);

      await controller.setLocale(locale);

      expect(controller.locale, locale);
      expect(store.getString(LocaleController.storageKey), tag);
      final restored = LocaleController(store);
      addTearDown(restored.dispose);
      expect(restored.locale, locale);
      expect(strings.s.localeName, tag);
      expect(changes, 1);
      expect(strings.s.languageTitle, isNot('Language'));
      expect(strings.s.desktopTrayShow('DitMesh'), contains('DitMesh'));
      expect(
        strings.s.notificationGroupInviteBody('N0CALL'),
        contains('N0CALL'),
      );
      expect(
        strings.s.learnLessonOf(3, 40),
        allOf(contains('3'), contains('40')),
      );
      expect(strings.s.statsDays(22), contains('22'));
      expect(strings.s.chatBytesLeftCount(-2), contains('-2'));
      expect(strings.s.appName, 'DitMesh');
    });
  }

  test('Russian day counts use one, few and many forms', () {
    final ru = lookupS(const Locale('ru'));
    expect(ru.statsDays(0), '0 дней');
    expect(ru.statsDays(1), '1 день');
    expect(ru.statsDays(2), '2 дня');
    expect(ru.statsDays(5), '5 дней');
    expect(ru.statsDays(21), '21 день');
    expect(ru.statsDays(22), '22 дня');
    expect(ru.statsDays(11), '11 дней');
    expect(ru.statsDays(12), '12 дней');
  });

  test('Portuguese zero sessions does not describe a previous session', () {
    final pt = lookupS(const Locale('pt'));
    expect(pt.statsTrendSubtitle(0), 'Nenhuma sessão');
    expect(pt.statsTrendSubtitle(1), 'Última sessão');
    expect(pt.statsTrendSubtitle(2), 'Últimas 2 sessões');
  });
}

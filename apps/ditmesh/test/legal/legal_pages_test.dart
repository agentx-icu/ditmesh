import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ditmesh/i18n/locale_controller.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/legal/legal_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _headings = {
  'de': ('Lokale Daten', 'Lizenz und Gewährleistung'),
  'en': ('Local data', 'Licence and warranty'),
  'es': ('Datos locales', 'Licencia y garantía'),
  'fr': ('Données locales', 'Licence et garantie'),
  'ja': ('端末内のデータ', 'ライセンスと保証'),
  'ko': ('기기에 저장되는 데이터', '라이선스 및 보증'),
  'pt': ('Dados locais', 'Licença e garantia'),
  'ru': ('Локальные данные', 'Лицензия и гарантия'),
  'zh': ('本地数据', '许可与免责'),
  'zh_Hant': ('本地資料', '授權與免責'),
};

const _publicGroups = {
  'de': 'öffentlichen Tox-Gruppen',
  'en': 'public Tox groups',
  'es': 'grupos públicos de Tox',
  'fr': 'groupes Tox publics',
  'ja': '公開 Tox グループ',
  'ko': '공개 Tox 그룹',
  'pt': 'grupos públicos do Tox',
  'ru': 'открытых группах Tox',
  'zh': '公开 Tox 群组',
  'zh_Hant': '公開 Tox 群組',
};

const _documents = [
  ('privacy', PrivacyPolicyPage()),
  ('terms', TermsOfUsePage()),
];

String _asset(String document, String locale) =>
    'assets/legal/${document}_$locale.txt';

class _LocalDocuments extends CachingAssetBundle {
  _LocalDocuments(this.documents, {this.pending = const {}});

  final Map<String, String> documents;
  final Map<String, Future<String>> pending;
  final requests = <String>[];

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    requests.add(key);
    final document = pending[key];
    if (document != null) return document;
    return documents[key] ?? (throw StateError('Missing fixture $key'));
  }

  @override
  Future<ByteData> load(String key) => rootBundle.load(key);
}

Widget _app(Locale locale, AssetBundle bundle, Widget page) => MaterialApp(
  locale: locale,
  supportedLocales: S.supportedLocales,
  localizationsDelegates: S.localizationsDelegates,
  localeListResolutionCallback: LocaleController.resolve,
  home: DefaultAssetBundle(bundle: bundle, child: page),
);

void main() {
  late Map<String, String> documents;
  setUpAll(() {
    final assets = Directory('assets/legal').existsSync()
        ? Directory('assets/legal')
        : Directory('apps/ditmesh/assets/legal');
    documents = {
      for (final file in assets.listSync().whereType<File>())
        if (file.path.endsWith('.txt'))
          'assets/legal/${file.uri.pathSegments.last}': file.readAsStringSync(),
    };
  });

  testWidgets('both documents are bundled for every supported locale', (
    tester,
  ) async {
    final locales = S.supportedLocales.map((locale) => locale.toString());
    expect(_headings.keys, unorderedEquals(locales));
    await tester.runAsync(() async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final locale in locales) {
        for (final (document, _) in _documents) {
          final key = _asset(document, locale);
          expect(manifest.listAssets(), contains(key));
          final data = await rootBundle.load(key);
          final text = utf8.decode(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          );
          expect(text, documents[key], reason: key);
        }
      }
    });
  });

  for (final locale in S.supportedLocales) {
    final language = locale.toString();
    final (privacyHeading, termsHeading) = _headings[language]!;
    test(
      'privacy disclosures include the scanner and public groups in $language',
      () {
        final policy = documents[_asset('privacy', language)]!;
        final strings = lookupS(locale);
        expect(policy, contains('Google ML Kit'));
        expect(strings.thirdPartyShareText, contains('Google ML Kit'));
        for (final text in [
          policy,
          strings.nearbyVisibleDesc,
          strings.nearbyPrivacyBody,
        ]) {
          expect(text, contains(_publicGroups[language]!));
          expect(
            text,
            isNot(matches(RegExp(r'\b5\s*(?:km|км|公里)', caseSensitive: false))),
          );
        }
      },
    );
    for (final (document, page) in _documents) {
      testWidgets('$document loads its $language body without a web link', (
        tester,
      ) async {
        final bundle = _LocalDocuments(documents);
        await tester.pumpWidget(_app(locale, bundle, page));
        await tester.pumpAndSettle();

        final key = _asset(document, language);
        expect(bundle.requests, [key]);
        final text = documents[key]!;
        expect(
          text,
          contains(document == 'privacy' ? privacyHeading : termsHeading),
        );
        expect(find.text(text), findsOneWidget);
        expect(find.byIcon(Icons.open_in_new), findsNothing);
        if (language != 'en') {
          expect(text, isNot(documents[_asset(document, 'en')]));
        }
      });
    }
  }

  for (final (preferred, expected) in [
    (const Locale('pt', 'BR'), 'pt'),
    (const Locale('zh', 'TW'), 'zh_Hant'),
  ]) {
    testWidgets('the $preferred preference loads $expected legal text', (
      tester,
    ) async {
      final bundle = _LocalDocuments(documents);
      await tester.pumpWidget(
        _app(preferred, bundle, const PrivacyPolicyPage()),
      );
      await tester.pumpAndSettle();
      final key = _asset('privacy', expected);
      expect(bundle.requests, [key]);
      expect(find.text(documents[key]!), findsOneWidget);
    });
  }

  testWidgets('switching languages immediately hides the previous body', (
    tester,
  ) async {
    const page = PrivacyPolicyPage();
    final french = Completer<String>();
    final enKey = _asset('privacy', 'en');
    final frKey = _asset('privacy', 'fr');
    final bundle = _LocalDocuments(documents, pending: {frKey: french.future});
    await tester.pumpWidget(_app(const Locale('en'), bundle, page));
    await tester.pumpAndSettle();
    expect(find.text(documents[enKey]!), findsOneWidget);

    await tester.pumpWidget(_app(const Locale('fr'), bundle, page));
    await tester.pump();
    expect(find.text(documents[enKey]!), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    french.complete(documents[frKey]!);
    await tester.pumpAndSettle();
    expect(find.text(documents[frKey]!), findsOneWidget);
    expect(bundle.requests, [enKey, frKey]);
  });

  testWidgets('a missing translation shows the localized error', (
    tester,
  ) async {
    final key = _asset('terms', 'de');
    final bundle = _LocalDocuments({...documents}..remove(key));
    await tester.pumpWidget(
      _app(const Locale('de'), bundle, const TermsOfUsePage()),
    );
    await tester.pumpAndSettle();

    expect(bundle.requests, [key]);
    expect(
      find.text(lookupS(const Locale('de')).legalDocumentUnavailable),
      findsOneWidget,
    );
    expect(find.text(documents[_asset('terms', 'en')]!), findsNothing);
  });
}

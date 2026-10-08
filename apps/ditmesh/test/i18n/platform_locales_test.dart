// Guards the native language declarations against drift from the ARB set in
// lib/l10n/app_*.arb: Android's per-app language list (res/xml/
// locale_config.xml), iOS/macOS CFBundleLocalizations, and the localized
// permission purpose strings (*.lproj/InfoPlist.strings). Adding an ARB
// without the native side (or the reverse) only shows up in OS settings or in
// a permission prompt on a device otherwise.
//
// en.lproj/InfoPlist.strings is required too (not optional): it mirrors
// Info.plist so every declared language has an explicit .lproj, which keeps
// the set equality below exact rather than "ARB set minus English".
//
// Runs with the package root (apps/ditmesh) as the working directory.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Maps an ARB `@@locale` (`en`, `zh`, `zh_Hant`, `pt_BR`, …) to the BCP 47
/// tag the native platforms use. Chinese needs an explicit script because the
/// Apple and Android lists name scripts, not bare `zh`.
String _nativeTag(String arbLocale) {
  final List<String> parts = arbLocale.split(RegExp('[_-]'));
  final String language = parts.first;
  if (language == 'zh' && parts.length == 1) return 'zh-Hans';
  return parts.join('-');
}

Set<String> _arbNativeTags() {
  final List<File> arbs = Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .where((f) => RegExp(r'app_[^/\\]+\.arb$').hasMatch(f.path))
      .toList();
  // Called while declaring tests, so throw rather than expect().
  if (arbs.isEmpty) throw StateError('no lib/l10n/app_*.arb found');
  return {
    for (final File f in arbs)
      _nativeTag(
        (jsonDecode(f.readAsStringSync()) as Map<String, dynamic>)['@@locale']
            as String,
      ),
  };
}

Set<String> _androidLocaleConfig() {
  const String path = 'android/app/src/main/res/xml/locale_config.xml';
  final String xml = File(
    path,
  ).readAsStringSync().replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
  return {
    for (final RegExpMatch m in RegExp(
      r'<locale\s+android:name="([^"]+)"',
    ).allMatches(xml))
      m.group(1)!,
  };
}

String _plist(String platform) =>
    File('$platform/Runner/Info.plist').readAsStringSync();

Set<String> _bundleLocalizations(String platform) {
  final RegExpMatch? m = RegExp(
    r'<key>CFBundleLocalizations</key>\s*<array>(.*?)</array>',
    dotAll: true,
  ).firstMatch(_plist(platform));
  expect(
    m,
    isNotNull,
    reason: '$platform Info.plist lacks CFBundleLocalizations',
  );
  return {
    for (final RegExpMatch s in RegExp(
      r'<string>([^<]+)</string>',
    ).allMatches(m!.group(1)!))
      s.group(1)!.trim(),
  };
}

Map<String, String> _usageDescriptions(String platform) => {
  for (final RegExpMatch m in RegExp(
    r'<key>(NS\w+UsageDescription)</key>\s*<string>([^<]*)</string>',
  ).allMatches(_plist(platform)))
    m.group(1)!: m.group(2)!,
};

/// Languages that ship an `InfoPlist.strings`, by `.lproj` name.
Set<String> _infoPlistStringsLanguages(String platform) => {
  for (final Directory d in Directory(
    '$platform/Runner',
  ).listSync().whereType<Directory>())
    if (d.path.endsWith('.lproj') &&
        File('${d.path}/InfoPlist.strings').existsSync())
      d.uri.pathSegments
          .where((s) => s.isNotEmpty)
          .last
          .replaceAll('.lproj', ''),
};

/// `"key" = "value";` entries of a `.strings` file (comments stripped).
Map<String, String> _strings(String path) {
  final String text = File(path)
      .readAsStringSync()
      .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
      .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '');
  return {
    for (final RegExpMatch m in RegExp(
      r'"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;',
    ).allMatches(text))
      m.group(1)!: m.group(2)!,
  };
}

void main() {
  final Set<String> arbTags = _arbNativeTags();

  test('ARB locales map to the expected native tags', () {
    expect(_nativeTag('en'), 'en');
    expect(_nativeTag('zh'), 'zh-Hans');
    expect(_nativeTag('zh_Hant'), 'zh-Hant');
    expect(_nativeTag('pt_BR'), 'pt-BR');
    expect(_nativeTag('sr_Latn_RS'), 'sr-Latn-RS');
    expect(arbTags, containsAll(<String>['en', 'zh-Hans']));
  });

  test('Android locale_config.xml equals the ARB set', () {
    expect(_androidLocaleConfig(), equals(arbTags));
  });

  test('AndroidManifest references the locale config', () {
    final String manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android:localeConfig="@xml/locale_config"'));
  });

  for (final String platform in <String>['ios', 'macos']) {
    group(platform, () {
      test('LAN connections declare their local network purpose', () {
        expect(
          _usageDescriptions(platform)['NSLocalNetworkUsageDescription'],
          isNotNull,
          reason:
              '$platform LAN bootstrap needs a local network purpose string',
        );
      });

      test('CFBundleLocalizations equals the ARB set', () {
        expect(_bundleLocalizations(platform), equals(arbTags));
      });

      test('InfoPlist.strings languages equal the ARB set', () {
        expect(_infoPlistStringsLanguages(platform), equals(arbTags));
      });

      test('every NS*UsageDescription is localized in every language', () {
        final Map<String, String> usage = _usageDescriptions(platform);
        expect(
          usage,
          isNotEmpty,
          reason: '$platform declares no usage strings',
        );
        for (final String lang in arbTags) {
          final Map<String, String> entries = _strings(
            '$platform/Runner/$lang.lproj/InfoPlist.strings',
          );
          for (final String key in usage.keys) {
            expect(
              entries[key],
              isNotNull,
              reason: '$platform $lang.lproj/InfoPlist.strings lacks $key',
            );
            expect(entries[key]!.trim(), isNotEmpty);
            if (lang == 'en') {
              expect(
                entries[key],
                usage[key]!.replaceAll('&apos;', "'"),
                reason: '$platform en.lproj $key drifted from Info.plist',
              );
            } else {
              expect(
                entries[key],
                isNot(usage[key]),
                reason: '$platform $lang.lproj $key is untranslated',
              );
              expect(entries[key], contains('DitMesh'));
            }
          }
        }
      });

      test('Xcode project registers InfoPlist.strings and its regions', () {
        final String pbx = File(
          '$platform/Runner.xcodeproj/project.pbxproj',
        ).readAsStringSync();
        expect(pbx, contains('/* InfoPlist.strings in Resources */,'));
        final RegExpMatch? regions = RegExp(
          r'knownRegions = \((.*?)\);',
          dotAll: true,
        ).firstMatch(pbx);
        expect(regions, isNotNull);
        for (final String lang in arbTags) {
          expect(pbx, contains('$lang.lproj/InfoPlist.strings'));
          expect(
            regions!.group(1),
            anyOf(contains('\t$lang,'), contains('"$lang",')),
            reason: '$platform knownRegions lacks $lang',
          );
        }
      });
    });
  }
}

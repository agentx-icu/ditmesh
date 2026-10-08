import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/i18n/locale_resolution.dart';
import 'package:ditmesh/ui/reference/reference_catalog.dart';
import 'package:ditmesh/ui/reference/reference_localized_text.dart';
import 'package:ditmesh/ui/reference/reference_mnemonics.dart';
import 'package:ditmesh/ui/reference/reference_qcodes.dart';

const Locale _zhHant = Locale.fromSubtags(
  languageCode: 'zh',
  scriptCode: 'Hant',
);
const Locale _zhHantTw = Locale.fromSubtags(
  languageCode: 'zh',
  scriptCode: 'Hant',
  countryCode: 'TW',
);
const Locale _zhHansSg = Locale.fromSubtags(
  languageCode: 'zh',
  scriptCode: 'Hans',
  countryCode: 'SG',
);

/// Italian ships no reference text.
const Locale _itIt = Locale('it', 'IT');

void main() {
  group('referenceLanguageKeys', () {
    test('most specific first, English last', () {
      expect(referenceLanguageKeys(_zhHantTw), <String>[
        'zh_Hant_TW',
        'zh_Hant',
        'zh_TW',
        'zh',
        'en',
      ]);
      expect(referenceLanguageKeys(const Locale('zh', 'TW')), <String>[
        'zh_TW',
        'zh',
        'en',
      ]);
      expect(referenceLanguageKeys(const Locale('en')), <String>['en']);
    });

    test('referenceLanguageFor picks the shipped column', () {
      expect(referenceLanguageFor(_zhHantTw), 'zh_Hant');
      expect(referenceLanguageFor(_zhHant), 'zh_Hant');
      // No script: the UI resolves zh-HK to zh_Hant before it gets here;
      // the raw tag alone only knows the language.
      expect(referenceLanguageFor(const Locale('zh', 'HK')), 'zh');
      expect(referenceLanguageFor(const Locale('fr', 'FR')), 'fr');
      expect(referenceLanguageFor(_itIt), 'en', reason: 'not shipped');
    });
  });

  group('localizedReferenceText', () {
    const Map<String, String> row = <String, String>{
      'en': 'Hello',
      'zh': '你好',
      'zh_Hant': '妳好',
    };

    test('prefers script, then language, then English', () {
      expect(localizedReferenceText(row, _zhHantTw), '妳好');
      expect(localizedReferenceText(row, _zhHant), '妳好');
      expect(localizedReferenceText(row, const Locale('zh', 'CN')), '你好');
      expect(localizedReferenceText(row, const Locale('de')), 'Hello');
      expect(localizedReferenceText(const <String, String>{}, _zhHant), isNull);
    });

    test('each UI reads its own language, unshipped ones fall back', () {
      for (final String tag in kReferenceTexts.keys) {
        expect(
          ReferenceQCodes.meaning('QRZ', parseLocaleTag(tag)!),
          kReferenceTexts[tag]!.qCodes['QRZ'],
          reason: tag,
        );
      }
      expect(
        ReferenceQCodes.meaning('QRZ', _zhHantTw),
        kReferenceTexts['zh_Hant']!.qCodes['QRZ'],
      );
      // A Chinese variant nobody ships still reads Chinese, not English.
      expect(
        ReferenceQCodes.meaning('QRZ', _zhHansSg),
        kReferenceTexts['zh']!.qCodes['QRZ'],
      );
      expect(ReferenceQCodes.meaning('QRZ', _itIt), 'Who is calling me?');
      final ReferenceEntry a = ReferenceCatalog.alphabet.first;
      expect(a.mnemonic(_zhHant), startsWith('A：'));
      expect(a.mnemonic(_zhHantTw), a.mnemonic(_zhHant));
      expect(a.mnemonic(_itIt), startsWith('A: di-DAH'));
    });
  });

  group('separator and rhythm by language code', () {
    test('full-width colon for zh and ja tags', () {
      expect(referenceLabelSeparator('zh'), '：');
      expect(referenceLabelSeparator('zh_Hant'), '：');
      expect(referenceLabelSeparator('zh-Hant-TW'), '：');
      expect(referenceLabelSeparator('ja'), '：');
      expect(referenceLabelSeparator('en'), ': ');
      expect(referenceLabelSeparator('fr_FR'), ': ');
    });

    test('the rhythm follows the most specific shipped language', () {
      final String zhHant = kReferenceTexts['zh_Hant']!.rhythm.voice('.-');
      expect(
        ReferenceMnemonics.spokenRhythm('.-', language: 'zh_Hant'),
        zhHant,
      );
      expect(
        ReferenceMnemonics.spokenRhythm(
          '.-',
          language: referenceLanguageFor(_zhHantTw),
        ),
        zhHant,
      );
      expect(ReferenceMnemonics.spokenRhythm('.-', language: 'zh'), '嘀嗒');
      expect(ReferenceMnemonics.spokenRhythm('.-', language: 'it'), 'di-DAH');
    });

    test('forCharacter accepts tiered tags for phrases and notes', () {
      expect(
        ReferenceMnemonics.forCharacter('1', '.----', language: 'zh_Hant_TW'),
        ReferenceMnemonics.forCharacter('1', '.----', language: 'zh_Hant'),
      );
      expect(
        ReferenceMnemonics.forCharacter('A', '.-', language: 'zh_Hans_SG'),
        'A：嘀嗒 — "a-PART"（英文口诀中重读音节为划）',
      );
      expect(
        ReferenceMnemonics.forCharacter('A', '.-', language: 'it'),
        'A: di-DAH — "a-PART"',
      );
    });
  });
}

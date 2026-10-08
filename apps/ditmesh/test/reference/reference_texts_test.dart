import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/i18n/locale_resolution.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/reference/reference_mnemonics.dart';
import 'package:ditmesh/ui/reference/text/reference_texts.dart';

/// Every shipped UI language must also ship complete reference content:
/// the same rows as English, nothing blank, and translated digit
/// mnemonics plus the note for the English phonetic letter phrases.
void main() {
  final ReferenceText en = kReferenceTexts['en']!;

  Map<String, Map<String, String>> tablesOf(ReferenceText t) =>
      <String, Map<String, String>>{
        'qCodes': t.qCodes,
        'abbreviations': t.abbreviations,
        'prosigns': t.prosigns,
        'punctuation': t.punctuation,
      };

  test('one reference text per shipped ARB locale, English first', () {
    expect(kReferenceTexts.keys.first, 'en');
    expect(
      kReferenceTexts.keys.toSet(),
      S.supportedLocales.map(localeTag).toSet(),
    );
  });

  for (final MapEntry<String, ReferenceText> language
      in kReferenceTexts.entries) {
    final String tag = language.key;
    final ReferenceText text = language.value;

    test('$tag carries exactly the English rows, none blank', () {
      final Map<String, Map<String, String>> ours = tablesOf(text);
      tablesOf(en).forEach((String table, Map<String, String> rows) {
        expect(
          ours[table]!.keys.toList(),
          rows.keys.toList(),
          reason: '$tag.$table: same rows, same order as English',
        );
        ours[table]!.forEach((String row, String value) {
          expect(value.trim(), isNotEmpty, reason: '$tag.$table[$row]');
        });
      });
    });

    if (tag == 'en') continue;

    test('$tag translates the digit mnemonics and the phrase note', () {
      expect(
        text.digitPhrases.keys.toSet(),
        <String>{for (int d = 0; d <= 9; d++) '$d'},
        reason: '$tag.digitPhrases',
      );
      for (final String phrase in text.digitPhrases.values) {
        expect(phrase.trim(), isNotEmpty, reason: '$tag.digitPhrases');
      }
      expect(text.phraseNote.trim(), isNotEmpty, reason: '$tag.phraseNote');
    });

    test('$tag is actually translated', () {
      // Codes, signs and units may coincide with English; whole meanings
      // should not. Allow a few identical rows (`QRP`-style shorthands).
      int same = 0;
      int total = 0;
      tablesOf(en).forEach((String table, Map<String, String> rows) {
        rows.forEach((String row, String english) {
          total++;
          if (tablesOf(text)[table]![row] == english) same++;
        });
      });
      expect(same, lessThan(total ~/ 10), reason: '$tag: $same/$total rows');
    });
  }

  test('the voiced rhythm never comes out empty', () {
    for (final String tag in kReferenceTexts.keys) {
      expect(
        ReferenceMnemonics.spokenRhythm('.-', language: tag).trim(),
        isNotEmpty,
        reason: tag,
      );
    }
  });
}

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/ui/reference/reference_abbreviations.dart';
import 'package:ditmesh/ui/reference/reference_catalog.dart';
import 'package:ditmesh/ui/reference/reference_localized_text.dart';
import 'package:ditmesh/ui/reference/reference_mnemonics.dart';
import 'package:ditmesh/ui/reference/reference_qcodes.dart';

const Locale en = Locale('en');
const Locale zh = Locale('zh');
// Italian ships no reference text, so it falls back to English.
const Locale it = Locale('it');

void main() {
  group('ReferenceCatalog', () {
    test('alphabet has A-Z and 0-9 in that order', () {
      final labels = ReferenceCatalog.alphabet.map((e) => e.label).toList();
      expect(labels.length, 36);
      expect(labels.first, 'A');
      expect(labels[25], 'Z');
      expect(labels[26], '0');
      expect(labels.last, '9');
    });

    test('punctuation is everything else in the international table', () {
      final int total = MorseAlphabet.international.length;
      expect(
        ReferenceCatalog.alphabet.length + ReferenceCatalog.punctuation.length,
        total,
      );
      expect(ReferenceCatalog.punctuation.any((e) => e.label == '?'), isTrue);
      expect(ReferenceCatalog.punctuation.any((e) => e.label == 'A'), isFalse);
    });

    test('every alphabet entry has a mnemonic with its spoken rhythm', () {
      for (final entry in ReferenceCatalog.alphabet) {
        expect(entry.hasMnemonic, isTrue, reason: entry.label);
        expect(
          entry.mnemonic(en),
          contains(ReferenceMnemonics.spokenRhythm(entry.pattern)),
          reason: entry.label,
        );
        expect(
          entry.mnemonic(zh),
          contains(
            ReferenceMnemonics.spokenRhythm(entry.pattern, language: 'zh'),
          ),
          reason: entry.label,
        );
      }
      final a = ReferenceCatalog.alphabet.first;
      expect(a.mnemonic(en), startsWith('A: di-DAH'));
      // The phonetic phrase stays English in Chinese, with a note.
      expect(a.mnemonic(zh), startsWith('A：嘀嗒'));
      expect(a.mnemonic(zh), contains('"a-PART"'));
      // Digit phrases are descriptive, so they are translated.
      final one = ReferenceCatalog.alphabet.firstWhere((e) => e.label == '1');
      expect(one.mnemonic(zh), isNot(contains('one dit')));
      expect(one.mnemonic(it), one.mnemonic(en), reason: 'falls back to en');
    });

    test('prosigns are bracketed, playable and explained', () {
      for (final entry in ReferenceCatalog.prosigns) {
        expect(entry.label, matches(RegExp(r'^<[A-Z]+>$')));
        expect(MorseEncoder.toPattern(entry.playText), entry.pattern);
        for (final locale in <Locale>[en, zh]) {
          expect(entry.meaning(locale), isNotEmpty, reason: entry.label);
        }
        expect(entry.meaning(zh), isNot(entry.meaning(en)), reason: entry.label);
      }
    });

    test('Q-codes carry the standard set with meanings', () {
      final labels = ReferenceCatalog.qCodes.map((e) => e.label).toSet();
      for (final code in <String>[
        'QRL', 'QRM', 'QRN', 'QRO', 'QRP', 'QRQ', 'QRS', 'QRT', 'QRU', //
        'QRV', 'QRX', 'QRZ', 'QSB', 'QSL', 'QSO', 'QSY', 'QTH',
      ]) {
        expect(labels, contains(code));
      }
      for (final entry in ReferenceCatalog.qCodes) {
        expect(entry.meaning(en), isNotEmpty, reason: entry.label);
        expect(entry.meaning(zh), isNotEmpty, reason: entry.label);
        expect(entry.meaning(it), entry.meaning(en), reason: entry.label);
        expect(entry.pattern, MorseEncoder.toPattern(entry.label));
      }
      expect(ReferenceQCodes.meaning('QRZ', en), 'Who is calling me?');
      expect(ReferenceQCodes.meaning('QRZ', zh), '谁在呼叫我？');
      expect(ReferenceQCodes.meaning('QZZ', en), isNull);
    });

    test('every content row carries every supported language', () {
      for (final entry in ReferenceCatalog.all) {
        if (entry.meanings.isNotEmpty) {
          expect(
            entry.meanings.keys,
            containsAll(kReferenceLanguages),
            reason: '${entry.id} meanings',
          );
        }
        if (entry.hasMnemonic) {
          expect(
            entry.mnemonics.keys,
            containsAll(kReferenceLanguages),
            reason: '${entry.id} mnemonics',
          );
        }
      }
    });

    test('every trainer CW abbreviation has a meaning', () {
      final labels = ReferenceCatalog.abbreviations.map((e) => e.label).toList();
      for (final name in WordLists.cwAbbreviations) {
        expect(labels, contains(name));
        expect(ReferenceAbbreviations.meaningOf(name, en), isNotEmpty, reason: name);
        expect(ReferenceAbbreviations.meaningOf(name, zh), isNotEmpty, reason: name);
      }
      expect(ReferenceAbbreviations.meaningOf('ZZZ', en), isEmpty);
      expect(labels.toSet().length, labels.length, reason: 'no duplicates');
    });

    test('Koch order carries 1-based positions matching MorseAlphabet', () {
      final koch = ReferenceCatalog.koch;
      expect(koch.length, MorseAlphabet.kochOrder.length);
      for (int i = 0; i < koch.length; i++) {
        expect(koch[i].position, i + 1);
        expect(koch[i].label, MorseAlphabet.kochOrder[i]);
      }
      expect(koch.first.label, 'K');
      expect(koch.last.label, '<AR>');
      expect(koch.last.pattern, MorseAlphabet.prosigns['AR']);
    });

    test('ids are unique across the whole catalog', () {
      final ids = ReferenceCatalog.all.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('ReferenceCatalog.search', () {
    test('empty query returns every section', () {
      expect(ReferenceCatalog.search('').keys, ReferenceSection.values);
    });

    test('matches labels case-insensitively across sections', () {
      final hits = ReferenceCatalog.search('qrl');
      expect(hits.keys, <ReferenceSection>[ReferenceSection.qCodes]);
      expect(hits[ReferenceSection.qCodes]!.single.label, 'QRL');
    });

    test('matches meanings in every language', () {
      final hits = ReferenceCatalog.search('who is calling');
      expect(hits[ReferenceSection.qCodes]!.single.label, 'QRZ');
      final zhHits = ReferenceCatalog.search('谁在呼叫');
      expect(zhHits[ReferenceSection.qCodes]!.single.label, 'QRZ');
    });

    test('matches raw and display patterns', () {
      expect(
        ReferenceCatalog.search('.-.-.')[ReferenceSection.prosigns]!.single.label,
        '<AR>',
      );
      expect(
        ReferenceCatalog.search('−−−')[ReferenceSection.alphabet]!
            .any((e) => e.label == 'O'),
        isTrue,
      );
    });

    test('a character shows up in alphabet and Koch order', () {
      final hits = ReferenceCatalog.search('K');
      expect(hits[ReferenceSection.alphabet]!.any((e) => e.label == 'K'), isTrue);
      expect(hits[ReferenceSection.koch]!.first.label, 'K');
      expect(hits[ReferenceSection.koch]!.first.position, 1);
    });

    test('no hits gives an empty map', () {
      expect(ReferenceCatalog.search('zzzzzz'), isEmpty);
    });
  });

  group('ReferenceMnemonics.spokenRhythm', () {
    test('voices dits and dahs the way operators do', () {
      expect(ReferenceMnemonics.spokenRhythm('.-'), 'di-DAH');
      expect(ReferenceMnemonics.spokenRhythm('-...'), 'DAH-di-di-dit');
      expect(ReferenceMnemonics.spokenRhythm('.'), 'dit');
      expect(ReferenceMnemonics.spokenRhythm('---'), 'DAH-DAH-DAH');
    });

    test('reads 嘀 / 嗒 in Chinese', () {
      expect(ReferenceMnemonics.spokenRhythm('.-', language: 'zh'), '嘀嗒');
      expect(ReferenceMnemonics.spokenRhythm('-...', language: 'zh'), '嗒嘀嘀嘀');
    });
  });
}

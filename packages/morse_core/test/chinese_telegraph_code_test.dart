import 'package:morse_core/morse_core.dart';
import 'package:morse_core/src/telegraph/telegraph_table.g.dart';
import 'package:test/test.dart';

void main() {
  group('ChineseTelegraphCode', () {
    test('tables come from a known Unihan version and are non-trivial', () {
      expect(ChineseTelegraphCode.unicodeVersion, isNot('unknown'));
      expect(ChineseTelegraphCode.codeOf('中'), '0022');
      expect(ChineseTelegraphCode.codeOf('文'), '2429');
      expect(ChineseTelegraphCode.codeOf('信'), '0207');
      expect(ChineseTelegraphCode.codeOf('息'), '1873');
    });

    test('codes are zero-padded to four digits', () {
      expect(ChineseTelegraphCode.codeOf('一'), '0001');
      expect(ChineseTelegraphCode.format(7), '0007');
    });

    test('simplified and traditional forms share a code across codebooks', () {
      // Unihan lists the simplified form in the mainland book and the
      // traditional one in the Taiwan book, both at 0948.
      expect(ChineseTelegraphCode.codeOf('国'), '0948');
      expect(
        ChineseTelegraphCode.codeOf('國', codebook: TelegraphCodebook.taiwan),
        '0948',
      );
      expect(ChineseTelegraphCode.charsOf('0948'), contains('国'));
      expect(
        ChineseTelegraphCode.charsOf('0948', codebook: TelegraphCodebook.taiwan),
        contains('國'),
      );
    });

    test('the two codebooks diverge for some characters', () {
      expect(ChineseTelegraphCode.codeOf('仉'), '8022');
      expect(
        ChineseTelegraphCode.codeOf('仉', codebook: TelegraphCodebook.taiwan),
        '0097',
      );
    });

    test('characters outside the codebook have no code', () {
      expect(ChineseTelegraphCode.codeOf('A'), isNull);
      expect(ChineseTelegraphCode.codeOf(' '), isNull);
      expect(ChineseTelegraphCode.charsOf('12345'), isEmpty);
      expect(ChineseTelegraphCode.charsOf('abcd'), isEmpty);
    });

    test('encode keeps every input character with its code or null', () {
      final units = ChineseTelegraphCode.encode('中A');
      expect(units.map((u) => u.char), ['中', 'A']);
      expect(units.first.code, '0022');
      expect(units.last.hasCode, isFalse);
      expect(units.first.toString(), '中(0022)');
    });

    test('containsCodedChars', () {
      expect(ChineseTelegraphCode.containsCodedChars('CQ DE 中'), isTrue);
      expect(ChineseTelegraphCode.containsCodedChars('CQ DE'), isFalse);
    });

    test('transliterate turns coded characters into spaced digit groups', () {
      expect(ChineseTelegraphCode.transliterate('中文'), '0022 2429');
      expect(ChineseTelegraphCode.transliterate('CQ 中文 K'), 'CQ 0022 2429 K');
      expect(ChineseTelegraphCode.transliterate('中,文'), '0022 , 2429');
      expect(ChineseTelegraphCode.transliterate('CQ DE'), 'CQ DE');
      expect(ChineseTelegraphCode.transliterate(''), '');
    });

    test('decode reads four-digit groups with any separators', () {
      expect(ChineseTelegraphCode.decode('0022 2429 0207 1873'), '中文信息');
      expect(ChineseTelegraphCode.decode('0022/2429'), '中文');
      expect(ChineseTelegraphCode.decode('00222429'), '中文');
      // Trailing partial group is ignored, unassigned code is marked.
      expect(ChineseTelegraphCode.decode('0022 99'), '中');
      expect(ChineseTelegraphCode.decode('0022 0000', unknown: '?'), '中?');
    });

    test('a character with several codes decodes from each of them', () {
      // Unihan lists a few Taiwan-book characters with two codes; the
      // secondary code must still decode to the character while encoding
      // uses the primary one.
      final aliases = taiwanTelegraphAliases;
      expect(aliases, isNotEmpty);
      for (final entry in aliases.entries) {
        final code = ChineseTelegraphCode.format(entry.key);
        expect(
          ChineseTelegraphCode.charsOf(code, codebook: TelegraphCodebook.taiwan),
          contains(entry.value),
        );
        expect(
          ChineseTelegraphCode.codeOf(entry.value,
              codebook: TelegraphCodebook.taiwan),
          isNot(code),
        );
      }
    });

    test('the Morse side is plain digits', () {
      final pattern = MorseEncoder.toPattern(
        ChineseTelegraphCode.transliterate('中'),
      );
      expect(pattern, MorseEncoder.toPattern('0022'));
    });
  });
}

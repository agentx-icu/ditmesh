import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/reference/morse_pattern_text.dart';
import 'package:ditmesh/ui/reference/pattern_decoder.dart';

void main() {
  group('PatternDecoder.decode', () {
    test('decodes letters separated by spaces', () {
      expect(PatternDecoder.decode('.- -...'), 'AB');
    });

    test('slash separates words', () {
      expect(PatternDecoder.decode('... --- ... / ... --- ...'), 'SOS SOS');
    });

    test('tolerates leading, trailing and repeated separators', () {
      expect(PatternDecoder.decode('  .-   /  -...  //'), 'A B');
    });

    test('decodes prosign patterns as <NAME>', () {
      expect(PatternDecoder.decode('...-.-'), '<SK>');
      // AR and + share a pattern: the character table wins.
      expect(PatternDecoder.decode('.-.-.'), '+');
    });

    test('renders unknown patterns as <pattern>', () {
      expect(PatternDecoder.decode('......'), '<......>');
      expect(PatternDecoder.decode('.- ......'), 'A<......>');
      expect(PatternDecoder.hasUnknown('.- ......'), isTrue);
      expect(PatternDecoder.hasUnknown('.- -...'), isFalse);
    });

    test('accepts display glyphs and lookalikes', () {
      expect(PatternDecoder.decode('$kDitGlyph$kDahGlyph'), 'A');
      // `_` is a dah lookalike: -...- is `=` in the character table.
      expect(PatternDecoder.decode('_..._'), '=');
      expect(PatternDecoder.decode('•–'), 'A');
      expect(PatternDecoder.decode('.- | -...'), 'A B');
    });

    test('empty input decodes to empty text', () {
      expect(PatternDecoder.decode(''), '');
      expect(PatternDecoder.decode('   /  '), '');
    });
  });

  group('displayMorsePattern', () {
    test('maps marks to glyphs and keeps gaps', () {
      expect(displayMorsePattern('... --- ... / .-'),
          '$kDitGlyph$kDitGlyph$kDitGlyph $kDahGlyph$kDahGlyph$kDahGlyph '
          '$kDitGlyph$kDitGlyph$kDitGlyph / $kDitGlyph$kDahGlyph');
    });
  });
}

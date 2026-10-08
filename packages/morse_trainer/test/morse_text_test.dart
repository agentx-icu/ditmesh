import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

void main() {
  group('MorseText.tokenize', () {
    test('upper-cases and collapses whitespace', () {
      expect(MorseText.tokenize('  cq  de\n k '), [
        'C',
        'Q',
        ' ',
        'D',
        'E',
        ' ',
        'K',
      ]);
    });

    test('keeps prosigns as one token', () {
      expect(MorseText.tokenize('a<bt>b <sk>'), [
        'A',
        '<BT>',
        'B',
        ' ',
        '<SK>',
      ]);
    });

    test('unterminated bracket is a plain symbol', () {
      expect(MorseText.tokenize('a<b'), ['A', '<', 'B']);
    });

    test('symbols drops spaces, charSet is distinct', () {
      expect(MorseText.symbols('KM MK'), ['K', 'M', 'M', 'K']);
      expect(MorseText.charSet('KM MK <BT>'), {'K', 'M', '<BT>'});
    });

    test('usesOnly', () {
      expect(MorseText.usesOnly('kmk m', {'K', 'M'}), isTrue);
      expect(MorseText.usesOnly('kmr', {'K', 'M'}), isFalse);
      expect(MorseText.usesOnly('', {'K'}), isTrue);
    });
  });
}

import 'package:morse_core/morse_core.dart';
import 'package:test/test.dart';

void main() {
  group('MorseAlphabet.international', () {
    test('covers A-Z, 0-9 and the ITU punctuation set', () {
      for (int c = 'A'.codeUnitAt(0); c <= 'Z'.codeUnitAt(0); c++) {
        expect(MorseAlphabet.international, contains(String.fromCharCode(c)));
      }
      for (int d = 0; d <= 9; d++) {
        expect(MorseAlphabet.international, contains('$d'));
      }
      for (final String p in r""". , ? ' ! / ( ) & : ; = + - _ " $ @""".split(' ')) {
        expect(MorseAlphabet.international, contains(p), reason: 'punct $p');
      }
      expect(MorseAlphabet.international.length, 26 + 10 + 18);
    });

    test('well-known patterns', () {
      expect(MorseAlphabet.international['E'], '.');
      expect(MorseAlphabet.international['T'], '-');
      expect(MorseAlphabet.international['S'], '...');
      expect(MorseAlphabet.international['O'], '---');
      expect(MorseAlphabet.international['0'], '-----');
      expect(MorseAlphabet.international['5'], '.....');
      expect(MorseAlphabet.international['?'], '..--..');
      expect(MorseAlphabet.international['@'], '.--.-.');
    });

    test('patterns are well-formed and unique', () {
      final Set<String> seen = <String>{};
      for (final MapEntry<String, String> e
          in MorseAlphabet.international.entries) {
        expect(e.key.length, 1, reason: 'key ${e.key}');
        expect(e.value, matches(RegExp(r'^[.-]+$')), reason: 'pattern ${e.key}');
        expect(seen.add(e.value), isTrue, reason: 'duplicate ${e.value}');
      }
    });

    test('full round trip for every entry', () {
      for (final MapEntry<String, String> e
          in MorseAlphabet.international.entries) {
        expect(MorseAlphabet.encodeChar(e.key), e.value);
        expect(MorseAlphabet.decodePattern(e.value), e.key);
      }
    });

    test('encodeChar is case-insensitive and null for unsupported', () {
      expect(MorseAlphabet.encodeChar('a'), '.-');
      expect(MorseAlphabet.encodeChar('A'), '.-');
      expect(MorseAlphabet.encodeChar('z'), '--..');
      expect(MorseAlphabet.encodeChar('#'), isNull);
      expect(MorseAlphabet.encodeChar(' '), isNull);
      expect(MorseAlphabet.encodeChar(''), isNull);
      expect(MorseAlphabet.encodeChar('é'), isNull);
    });

    test('decodePattern never returns a prosign', () {
      expect(MorseAlphabet.decodePattern('...-.-'), isNull); // SK
      expect(MorseAlphabet.decodePattern('...---...'), isNull); // SOS
      expect(MorseAlphabet.decodePattern('.-.-.'), '+'); // AR shares +
      expect(MorseAlphabet.decodePattern('-...-'), '='); // BT shares =
      expect(MorseAlphabet.decodePattern(''), isNull);
      expect(MorseAlphabet.decodePattern('.........'), isNull);
    });
  });

  group('MorseAlphabet.prosigns', () {
    test('contains the standard set with correct patterns', () {
      expect(MorseAlphabet.prosigns['AR'], '.-.-.');
      expect(MorseAlphabet.prosigns['SK'], '...-.-');
      expect(MorseAlphabet.prosigns['BT'], '-...-');
      expect(MorseAlphabet.prosigns['KN'], '-.--.');
      expect(MorseAlphabet.prosigns['AS'], '.-...');
      expect(MorseAlphabet.prosigns['SN'], '...-.');
      expect(MorseAlphabet.prosigns['SOS'], '...---...');
      expect(MorseAlphabet.prosigns['CT'], '-.-.-');
      expect(MorseAlphabet.prosigns['HH'], '........');
    });

    test('round trip for every prosign', () {
      for (final MapEntry<String, String> e in MorseAlphabet.prosigns.entries) {
        expect(MorseAlphabet.encodeProsign(e.key), e.value);
        expect(MorseAlphabet.encodeProsign('<${e.key}>'), e.value);
        expect(MorseAlphabet.encodeProsign(e.key.toLowerCase()), e.value);
        expect(MorseAlphabet.decodeProsignPattern(e.value), e.key);
      }
    });

    test('prosign is one run of elements, equal to its letters concatenated',
        () {
      // AR = A + R, SK = S + K, SOS = S + O + S, etc.
      for (final MapEntry<String, String> e in MorseAlphabet.prosigns.entries) {
        final String concatenated =
            e.key.split('').map((String c) => MorseAlphabet.encodeChar(c)!).join();
        expect(e.value, concatenated, reason: e.key);
      }
    });

    test('unknown prosign returns null', () {
      expect(MorseAlphabet.encodeProsign('XYZ'), isNull);
      expect(MorseAlphabet.encodeProsign(''), isNull);
      expect(MorseAlphabet.encodeProsign('<>'), isNull);
      expect(MorseAlphabet.decodeProsignPattern('.-'), isNull);
    });
  });

  group('MorseAlphabet.kochOrder', () {
    test('has 43 entries, starts K M and ends with the three prosigns', () {
      expect(MorseAlphabet.kochOrder.length, 43);
      expect(MorseAlphabet.kochOrder.take(4), <String>['K', 'M', 'R', 'S']);
      expect(MorseAlphabet.kochOrder.skip(40), <String>['<BT>', '<SK>', '<AR>']);
    });

    test('has no duplicates', () {
      expect(MorseAlphabet.kochOrder.toSet().length,
          MorseAlphabet.kochOrder.length);
    });

    test('every entry is encodable', () {
      for (final String entry in MorseAlphabet.kochOrder) {
        final String pattern = MorseEncoder.toPattern(entry);
        expect(pattern, isNotEmpty, reason: entry);
        expect(pattern, isNot(contains(' ')), reason: '$entry is one symbol');
        if (entry.startsWith('<')) {
          expect(MorseAlphabet.encodeProsign(entry), pattern);
        } else {
          expect(MorseAlphabet.encodeChar(entry), pattern);
        }
      }
    });
  });
}

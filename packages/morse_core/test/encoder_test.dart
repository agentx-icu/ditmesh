import 'package:morse_core/morse_core.dart';
import 'package:test/test.dart';

void main() {
  group('MorseEncoder.toPattern', () {
    test('exact patterns for plain text', () {
      expect(MorseEncoder.toPattern('SOS'), '... --- ...');
      expect(MorseEncoder.toPattern('sos'), '... --- ...');
      expect(MorseEncoder.toPattern('PARIS'), '.--. .- .-. .. ...');
      expect(MorseEncoder.toPattern('E'), '.');
      expect(MorseEncoder.toPattern('CQ DE'), '-.-. --.- / -.. .');
      expect(MorseEncoder.toPattern('73'), '--... ...--');
    });

    test('punctuation', () {
      expect(MorseEncoder.toPattern('R U OK?'), '.-. / ..- / --- -.- ..--..');
      expect(MorseEncoder.toPattern('A.B,C'), '.- .-.-.- -... --..-- -.-.');
      expect(MorseEncoder.toPattern(r'$@'), '...-..- .--.-.');
      expect(MorseEncoder.toPattern('1+1=2'), '.---- .-.-. .---- -...- ..---');
    });

    test('prosigns become one pattern without inner spaces', () {
      expect(MorseEncoder.toPattern('<AR>'), '.-.-.');
      expect(MorseEncoder.toPattern('<SOS>'), '...---...');
      expect(MorseEncoder.toPattern('<sk>'), '...-.-');
      expect(MorseEncoder.toPattern('CQ <AR>'), '-.-. --.- / .-.-.');
      expect(MorseEncoder.toPattern('A<BT>B'), '.- -...- -...');
      expect(MorseEncoder.toPattern('<HH>'), '........');
    });

    test('unknown bracketed tokens fall back to per-character encoding', () {
      // '<' and '>' are unsupported and dropped; X Y Z encode normally.
      expect(MorseEncoder.toPattern('<XYZ>'), '-..- -.-- --..');
      expect(MorseEncoder.toPattern('A<B'), '.- -...');
    });

    test('whitespace collapses; leading / trailing whitespace ignored', () {
      expect(MorseEncoder.toPattern('  A    B  '), '.- / -...');
      expect(MorseEncoder.toPattern('A\tB\nC'), '.- / -... / -.-.');
      expect(MorseEncoder.toPattern(''), '');
      expect(MorseEncoder.toPattern('   '), '');
    });

    test('unsupported characters are skipped by default', () {
      expect(MorseEncoder.toPattern('A#B'), '.- -...');
      expect(MorseEncoder.toPattern('#'), '');
      expect(MorseEncoder.toPattern('# #'), '');
      expect(MorseEncoder.toPattern('A # B'), '.- / -...');
      expect(MorseEncoder.toPattern('A😀B'), '.- -...');
    });

    test('onUnsupported maps characters; its result is re-encoded', () {
      final List<String> seen = <String>[];
      String map(String c) {
        seen.add(c);
        switch (c) {
          case 'é':
            return 'E';
          case 'ü':
            return 'UE';
          case '#':
            return '<HH>';
          default:
            return '';
        }
      }

      expect(
        MorseEncoder.toPattern('éüx#~', onUnsupported: map),
        '. ..- . -..- ........',
      );
      expect(seen, <String>['é', 'ü', '#', '~']);
    });

    test('onUnsupported result that is still unsupported is dropped', () {
      expect(MorseEncoder.toPattern('A~B', onUnsupported: (_) => '%'), '.- -...');
    });
  });

  group('MorseEncoder.encode', () {
    const MorseTiming t20 = MorseTiming(wpm: 20);

    List<MorseElementKind> kinds(String text, [MorseTiming t = t20]) =>
        MorseEncoder.encode(text, t).map((MorseElement e) => e.kind).toList();

    test('SOS element sequence: 9 marks, 6 intra gaps, 2 char gaps', () {
      // S O S = 3 + 3 + 3 marks (O is ---), 2 intra gaps per letter.
      final List<MorseElement> els = MorseEncoder.encode('SOS', t20);
      expect(els.length, 17);
      final int marks = els.where((MorseElement e) => e.on).length;
      final int intra = els
          .where((MorseElement e) => e.kind == MorseElementKind.intraGap)
          .length;
      final int chars = els
          .where((MorseElement e) => e.kind == MorseElementKind.charGap)
          .length;
      expect(marks, 9);
      expect(intra, 6);
      expect(chars, 2);
      expect(els.any((MorseElement e) => e.kind == MorseElementKind.wordGap),
          isFalse);
      expect(kinds('SOS'), <MorseElementKind>[
        MorseElementKind.dit,
        MorseElementKind.intraGap,
        MorseElementKind.dit,
        MorseElementKind.intraGap,
        MorseElementKind.dit,
        MorseElementKind.charGap,
        MorseElementKind.dah,
        MorseElementKind.intraGap,
        MorseElementKind.dah,
        MorseElementKind.intraGap,
        MorseElementKind.dah,
        MorseElementKind.charGap,
        MorseElementKind.dit,
        MorseElementKind.intraGap,
        MorseElementKind.dit,
        MorseElementKind.intraGap,
        MorseElementKind.dit,
      ]);
    });

    test('durations follow the timing', () {
      final List<MorseElement> els = MorseEncoder.encode('SOS', t20);
      for (final MorseElement e in els) {
        switch (e.kind) {
          case MorseElementKind.dit:
            expect(e.duration, t20.dit);
          case MorseElementKind.dah:
            expect(e.duration, t20.dah);
          case MorseElementKind.intraGap:
            expect(e.duration, t20.intraGap);
          case MorseElementKind.charGap:
            expect(e.duration, t20.charGap);
          case MorseElementKind.wordGap:
            expect(e.duration, t20.wordGap);
        }
      }
    });

    test('"A B" has exactly one wordGap, replacing (not adding to) the charGap',
        () {
      final List<MorseElementKind> k = kinds('A B');
      expect(k, <MorseElementKind>[
        MorseElementKind.dit,
        MorseElementKind.intraGap,
        MorseElementKind.dah,
        MorseElementKind.wordGap,
        MorseElementKind.dah,
        MorseElementKind.intraGap,
        MorseElementKind.dit,
        MorseElementKind.intraGap,
        MorseElementKind.dit,
        MorseElementKind.intraGap,
        MorseElementKind.dit,
      ]);
      final int wordIdx = k.indexOf(MorseElementKind.wordGap);
      expect(k.where((MorseElementKind x) => x == MorseElementKind.wordGap).length,
          1);
      expect(k[wordIdx - 1].isGap, isFalse);
      expect(k[wordIdx + 1].isGap, isFalse);
      expect(k, isNot(contains(MorseElementKind.charGap)));
    });

    test('never starts or ends with a gap; whitespace collapses', () {
      for (final String text in <String>[
        '  A B  ',
        'A     B',
        'A # B',
        '\nCQ\tDE\n',
        '<AR>',
        'E',
      ]) {
        final List<MorseElement> els = MorseEncoder.encode(text, t20);
        expect(els, isNotEmpty, reason: text);
        expect(els.first.on, isTrue, reason: 'start of "$text"');
        expect(els.last.on, isTrue, reason: 'end of "$text"');
        // No two consecutive gaps anywhere.
        for (int i = 1; i < els.length; i++) {
          expect(!els[i - 1].on || !els[i].on, isTrue,
              reason: 'marks must alternate with gaps in "$text"');
          expect(els[i - 1].on || els[i].on, isTrue,
              reason: 'gaps must not repeat in "$text"');
        }
      }
      expect(kinds('A     B'), kinds('A B'));
      expect(kinds('A # B'), kinds('A B'));
    });

    test('empty or fully unsupported text yields an empty timeline', () {
      expect(MorseEncoder.encode('', t20), isEmpty);
      expect(MorseEncoder.encode('   ', t20), isEmpty);
      expect(MorseEncoder.encode('#~', t20), isEmpty);
    });

    test('prosign uses intraGap only inside', () {
      final List<MorseElementKind> k = kinds('<SOS>');
      expect(k.length, 17);
      expect(k.where((MorseElementKind x) => x == MorseElementKind.intraGap).length,
          8);
      expect(k, isNot(contains(MorseElementKind.charGap)));
      // Same run as the letters S O S but without the char gaps.
      expect(kinds('<SOS>').where((MorseElementKind x) => !x.isGap),
          kinds('SOS').where((MorseElementKind x) => !x.isGap));
    });

    test('Farnsworth timing stretches only char/word gaps', () {
      const MorseTiming fw = MorseTiming(wpm: 18, farnsworthWpm: 8);
      final List<MorseElement> els = MorseEncoder.encode('AB CD', fw);
      for (final MorseElement e in els) {
        switch (e.kind) {
          case MorseElementKind.dit:
          case MorseElementKind.intraGap:
            expect(e.duration, fw.dit);
          case MorseElementKind.dah:
            expect(e.duration, fw.dah);
          case MorseElementKind.charGap:
            expect(e.duration, fw.charGap);
            expect(e.duration, greaterThan(fw.dah * 2));
          case MorseElementKind.wordGap:
            expect(e.duration, fw.wordGap);
        }
      }
    });
  });

  group('MorseEncoder.totalDuration', () {
    test('PARIS alone is 43 dit (50 dit including the trailing word gap)', () {
      const MorseTiming t20 = MorseTiming(wpm: 20);
      final List<MorseElement> paris = MorseEncoder.encode('PARIS', t20);
      // The timeline never ends with a gap, so the canonical 50-dit PARIS
      // word is 43 dit of elements plus the 7-dit word gap that follows it.
      expect(MorseEncoder.totalDuration(paris), const Duration(milliseconds: 2580));
      expect(MorseEncoder.totalDuration(paris) + t20.wordGap,
          const Duration(milliseconds: 3000));
      // Two words: 50 + 43 dit.
      expect(MorseEncoder.totalDuration(MorseEncoder.encode('PARIS PARIS', t20)),
          const Duration(milliseconds: 5580));
    });

    test('empty timeline is zero; sums arbitrary iterables', () {
      expect(MorseEncoder.totalDuration(const <MorseElement>[]), Duration.zero);
      expect(
        MorseEncoder.totalDuration(<MorseElement>[
          const MorseElement(MorseElementKind.dit, Duration(milliseconds: 60)),
          const MorseElement(MorseElementKind.charGap, Duration(milliseconds: 180)),
        ]),
        const Duration(milliseconds: 240),
      );
    });
  });
}

extension on MorseElementKind {
  bool get isGap =>
      this == MorseElementKind.intraGap ||
      this == MorseElementKind.charGap ||
      this == MorseElementKind.wordGap;
}

import 'dart:math';

import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

void main() {
  group('NumberGroupsDrill', () {
    test('only allowed digits, grouped, deterministic', () {
      final gen = NumberGroupsDrill(
        groupCount: 4,
        allowedChars: const <String>{'K', '0', '5', '9'},
      );
      expect(gen.digits, <String>['0', '5', '9']);
      expect(gen.canGenerate, isTrue);
      final drill = gen.generate(Random(3));
      expect(drill.kind, 'numbers');
      expect(drill.text.split(' '), hasLength(4));
      expect(drill.chars, everyElement(isIn(<String>{'0', '5', '9'})));
      expect(drill.charCount, 20);
      expect(gen.generate(Random(3)).text, drill.text);
    });

    test('needs two digits; unfiltered uses all ten', () {
      final one = NumberGroupsDrill(allowedChars: const <String>{'5', 'K'});
      expect(one.canGenerate, isFalse);
      expect(() => one.generate(Random(1)), throwsStateError);
      expect(NumberGroupsDrill().digits, hasLength(10));
    });
  });

  group('ConfusableDrill', () {
    test('pattern neighbours are one element apart', () {
      expect(ConfusableDrill.areNeighbours('S', 'H'), isTrue); // ... ....
      expect(ConfusableDrill.areNeighbours('U', 'V'), isTrue); // ..- ...-
      expect(ConfusableDrill.areNeighbours('K', 'M'), isTrue); // -.- --
      expect(ConfusableDrill.areNeighbours('A', 'N'), isFalse); // .- -.
      expect(ConfusableDrill.areNeighbours('E', 'E'), isFalse);
      expect(ConfusableDrill.areNeighbours('<AR>', 'R'), isFalse);
      expect(ConfusableDrill.areNeighbours('<BT>', 'B'), isTrue); // -...- -...
      expect(ConfusableDrill.areNeighbours('#', 'E'), isFalse);
    });

    test('recorded mistakes outrank plain neighbours', () {
      final confusion = ConfusionMatrix()
        ..record('A', 'N', times: 3)
        ..record('N', 'A')
        ..record('S', 'S', times: 9)
        ..record('S', null, times: 5);
      final pairs = ConfusableDrill.rankPairs(const <String>[
        'S',
        'H',
        'A',
        'N',
        'E',
      ], confusion);
      expect(pairs.first, const ConfusablePair('A', 'N', mistakes: 4));
      expect(
        pairs.skip(1),
        everyElement(
          predicate<ConfusablePair>(
            (p) => p.mistakes == 0 && ConfusableDrill.areNeighbours(p.a, p.b),
          ),
        ),
      );
      expect(pairs, contains(const ConfusablePair('S', 'H')));
    });

    test('mistakes outside the allowed set are ignored', () {
      final confusion = ConfusionMatrix()..record('X', 'Y', times: 10);
      expect(
        ConfusableDrill.rankPairs(const <String>['A', 'N'], confusion),
        isEmpty,
      );
    });

    test('every group contrasts the two symbols of one pair', () {
      final gen = ConfusableDrill(
        chars: const <String>['K', 'M', 'R', 'S', 'U', 'A', 'P', 'T'],
        groupCount: 20,
      );
      expect(gen.canGenerate, isTrue);
      expect(gen.pairs.length, lessThanOrEqualTo(4));
      final drill = gen.generate(Random(11));
      expect(drill.kind, 'confusables');
      for (final group in drill.text.split(' ')) {
        final used = MorseText.charSet(group);
        expect(used, hasLength(2), reason: group);
        expect(
          gen.pairs.any((p) => used.containsAll(<String>[p.a, p.b])),
          isTrue,
          reason: group,
        );
      }
    });

    test('cannot generate without a pair', () {
      final gen = ConfusableDrill(chars: const <String>['A', 'N']);
      expect(gen.canGenerate, isFalse);
      expect(() => gen.generate(Random(1)), throwsStateError);
    });
  });

  group('ContestExchangeDrill', () {
    test('cut numbers replace 0 and 9 only', () {
      expect(ContestExchangeDrill.cut('599'), '5NN');
      expect(ContestExchangeDrill.cut('1907'), '1NT7');
    });

    test('exchanges are call, report, number', () {
      final gen = ContestExchangeDrill(cutNumberChance: 0);
      final random = Random(5);
      for (var i = 0; i < 50; i++) {
        final parts = gen.nextExchange(random).split(' ');
        expect(parts, hasLength(3));
        expect(parts[1], '599');
        expect(parts[2], matches(RegExp(r'^[0-9]{2,3}$')));
      }
    });

    test('always-cut exchanges carry no 0 or 9', () {
      final gen = ContestExchangeDrill(cutNumberChance: 1);
      final random = Random(9);
      for (var i = 0; i < 50; i++) {
        final parts = gen.nextExchange(random).split(' ');
        expect(parts[1], '5NN');
        expect(parts[2], isNot(matches(RegExp('[09]'))));
      }
      expect(gen.generate(Random(1)).kind, 'contest');
    });

    test('a restricted exchange uses only allowed symbols', () {
      // A late-lesson set without 1, 2, 4, 6, 7, 8, B, C, D or X.
      final allowed = MorseText.charSet('KMRSUAPTLOWI.NJEF0Y,VG5/Q9ZH3');
      final gen = ContestExchangeDrill(allowedChars: allowed);
      expect(gen.canGenerate, isTrue);
      final random = Random(2);
      for (var i = 0; i < 200; i++) {
        final text = gen.nextExchange(random);
        expect(MorseText.usesOnly(text, allowed), isTrue, reason: text);
      }
    });

    test('cannot generate without a spellable report', () {
      final gen = ContestExchangeDrill(allowedChars: MorseText.charSet('KMRS'));
      expect(gen.canGenerate, isFalse);
      expect(() => gen.generate(Random(1)), throwsStateError);
    });
  });

  group('WordDrill.radioShorthand', () {
    test('mixes abbreviations and Q-codes under the filter', () {
      final all = WordDrill.radioShorthand();
      expect(all.kind, 'abbreviations');
      expect(all.candidates, containsAll(<String>['TNX', 'QTH', 'QSL']));
      final narrow = WordDrill.radioShorthand(
        allowedChars: const <String>{'Q', 'R', 'S', 'T', 'H', 'L', 'O'},
      );
      expect(narrow.candidates, containsAll(<String>['QRS', 'QTH', 'QSL']));
      expect(narrow.candidates, isNot(contains('TNX')));
    });
  });
}

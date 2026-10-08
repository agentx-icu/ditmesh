import 'dart:math';

import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

void main() {
  const allowed = <String>{'K', 'M', 'R', 'S', 'U', 'A', 'P', 'T'};

  group('Drill', () {
    test('fromText derives chars and counts', () {
      final d = Drill.fromText('km<bt> rs', kind: 'x');
      expect(d.chars, {'K', 'M', '<BT>', 'R', 'S'});
      expect(d.charCount, 5);
      expect(d.tokens, ['K', 'M', '<BT>', ' ', 'R', 'S']);
      final back = Drill.fromJson(d.toJson());
      expect(back.text, d.text);
      expect(back.chars, d.chars);
      expect(back.kind, 'x');
    });
  });

  group('RandomGroupsDrill', () {
    test('deterministic for a seed', () {
      final gen = RandomGroupsDrill(chars: allowed);
      final a = gen.generate(Random(7)).text;
      final b = gen.generate(Random(7)).text;
      expect(a, b);
      expect(a, isNot(gen.generate(Random(8)).text));
    });

    test('groups of 5, only allowed chars', () {
      final gen = RandomGroupsDrill(chars: allowed, groupCount: 6);
      final drill = gen.generate(Random(1));
      final groups = drill.text.split(' ');
      expect(groups, hasLength(6));
      for (final g in groups) {
        expect(g.length, 5);
      }
      expect(drill.chars, everyElement(isIn(allowed)));
      expect(drill.charCount, 30);
      expect(drill.kind, 'groups');
      expect(gen.totalChars, 30);
    });

    test('handles prosign symbols as single units', () {
      final gen = RandomGroupsDrill(chars: const {'K', '<BT>'}, groupCount: 2);
      final drill = gen.generate(Random(3));
      expect(drill.charCount, 10);
      expect(drill.chars, everyElement(isIn({'K', '<BT>'})));
    });

    test('weights bias selection', () {
      final weights = CharWeights.explicit({'K': 100, 'M': 1});
      final gen = RandomGroupsDrill(
        chars: const {'K', 'M'},
        groupCount: 20,
        weights: weights,
      );
      final text = gen.generate(Random(5)).text.replaceAll(' ', '');
      final ks = text.split('').where((c) => c == 'K').length;
      expect(ks, greaterThan(85));
    });

    test('forLength rounds up to whole groups; empty set rejected', () {
      final gen = RandomGroupsDrill.forLength(chars: allowed, totalChars: 52);
      expect(gen.groupCount, 11);
      expect(
        () => RandomGroupsDrill(chars: const <String>{}),
        throwsArgumentError,
      );
    });
  });

  group('WordDrill', () {
    test('filters to allowed chars and de-duplicates', () {
      final gen = WordDrill(
        words: const ['ART', 'arm', 'ART', 'MAP', 'ZOO', 'RUST', ''],
        allowedChars: allowed,
      );
      expect(gen.candidates, ['ART', 'ARM', 'MAP', 'RUST']);
      expect(gen.hasCandidates, isTrue);
    });

    test('generate uses only candidates and is deterministic', () {
      final gen = WordDrill.commonWords(allowedChars: allowed, wordCount: 8);
      expect(gen.hasCandidates, isTrue);
      final a = gen.generate(Random(11));
      final b = gen.generate(Random(11));
      expect(a.text, b.text);
      final words = a.text.split(' ');
      expect(words, hasLength(8));
      expect(words, everyElement(isIn(gen.candidates)));
      expect(a.chars, everyElement(isIn(allowed)));
    });

    test('no candidates -> StateError', () {
      final gen = WordDrill(words: const ['ZOO'], allowedChars: const {'K'});
      expect(gen.hasCandidates, isFalse);
      expect(() => gen.generate(Random(1)), throwsStateError);
    });

    test('cw abbreviations list is complete and has kind', () {
      final gen = WordDrill.cwAbbreviations();
      expect(gen.kind, 'abbreviations');
      expect(gen.candidates, containsAll(['CQ', 'DE', '73', 'XYL', 'TNX']));
      expect(gen.candidates.length, WordLists.cwAbbreviations.length);
    });

    test('built-in word lists are clean', () {
      expect(WordLists.commonWords.length, greaterThanOrEqualTo(300));
      expect(
        WordLists.commonWords.toSet().length,
        WordLists.commonWords.length,
      );
      final alnum = RegExp(r'^[A-Z0-9]+$');
      for (final w in [
        ...WordLists.commonWords,
        ...WordLists.cwAbbreviations,
      ]) {
        expect(alnum.hasMatch(w), isTrue, reason: w);
      }
    });
  });

  group('CallsignDrill', () {
    final callsignShape = RegExp(r'^[A-Z]{1,2}[0-9][A-Z]{1,3}$');

    test('produces prefix+digit+suffix shapes, deterministic', () {
      final gen = CallsignDrill(count: 20);
      final a = gen.generate(Random(2));
      expect(a.text, gen.generate(Random(2)).text);
      final calls = a.text.split(' ');
      expect(calls, hasLength(20));
      for (final c in calls) {
        expect(callsignShape.hasMatch(c), isTrue, reason: c);
      }
      expect(a.kind, 'callsigns');
    });

    test('restricts to allowed chars', () {
      const set = <String>{'K', 'M', 'R', 'S', '5', '0'};
      final gen = CallsignDrill(count: 30, allowedChars: set);
      expect(gen.canGenerate, isTrue);
      final drill = gen.generate(Random(9));
      expect(drill.chars, everyElement(isIn(set)));
      for (final c in drill.text.split(' ')) {
        expect(callsignShape.hasMatch(c), isTrue, reason: c);
      }
    });

    test('cannot generate without a digit', () {
      final gen = CallsignDrill(allowedChars: const {'K', 'M'});
      expect(gen.canGenerate, isFalse);
      expect(() => gen.generate(Random(1)), throwsStateError);
    });
  });

  group('QsoDrill', () {
    test('single template resolves every placeholder, deterministic', () {
      final gen = QsoDrill();
      final a = gen.generate(Random(4));
      expect(a.text, gen.generate(Random(4)).text);
      expect(a.text, isNot(contains('{')));
      expect(a.kind, 'qso');
    });

    test('full QSO keeps calls consistent and uses prosign tokens', () {
      final gen = QsoDrill(full: true);
      final drill = gen.generate(Random(6));
      expect(drill.text, startsWith('CQ CQ CQ DE '));
      expect(drill.text, contains('<SK>'));
      expect(drill.chars, contains('<BT>'));
      expect(drill.chars, isNot(contains('<')));
      final call = drill.text.split(' ')[3];
      expect(
        drill.text.split(' ').where((w) => w == call).length,
        greaterThanOrEqualTo(6),
      );
    });

    test('custom templates', () {
      final gen = QsoDrill(templates: const ['{CALL1} DE {CALL2} K']);
      final text = gen.generate(Random(1)).text;
      expect(text.split(' '), hasLength(4));
      expect(text, endsWith(' K'));
    });
  });
}

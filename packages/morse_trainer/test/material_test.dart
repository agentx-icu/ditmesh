import 'dart:convert';

import 'dart:math';

import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 3);

  TrainingMaterial make(String text, {MaterialKind kind = MaterialKind.text}) {
    final a = MaterialImport.analyze(text, kind);
    return MaterialImport.create(
      id: 'm1',
      title: 'T',
      kind: kind,
      text: text,
      analysis: a,
      now: now,
      source: const MaterialSource(
        description: 'chat',
        localRef: 'chat:me/c2c_X/42',
      ),
    );
  }

  group('analysis', () {
    test('unsupported characters are listed, never silently replaced', () {
      final a = MaterialImport.analyze(
        'CQ 你好 DE café <BT> K',
        MaterialKind.text,
      );
      expect(a.unsupported, ['你', '好', 'É']);
      expect(a.items.single, 'CQ DE CAF <BT> K');
      expect(a.prosigns, 1);
      expect(a.ok, isTrue);
    });

    test('word lists dedupe and report duplicates', () {
      final a = MaterialImport.analyze(
        'k1abc\nK1ABC\n\nDL2XY',
        MaterialKind.callsigns,
      );
      expect(a.items, ['K1ABC', 'DL2XY']);
      expect(a.duplicates, ['K1ABC']);
    });

    test('limits reject explicitly', () {
      final many = List.generate(1001, (i) => 'W$i').join('\n');
      expect(
        MaterialImport.analyze(many, MaterialKind.wordList).problems,
        contains(MaterialProblem.tooManyEntries),
      );
      final long = 'E' * 201;
      expect(
        MaterialImport.analyze(long, MaterialKind.wordList).problems,
        contains(MaterialProblem.entryTooLong),
      );
      expect(MaterialImport.analyze('你好', MaterialKind.text).problems, [
        MaterialProblem.nothingTrainable,
      ]);
      expect(
        () => MaterialImport.create(
          id: 'x',
          title: 'x',
          kind: MaterialKind.text,
          text: '你好',
          analysis: MaterialImport.analyze('你好', MaterialKind.text),
          now: now,
        ),
        throwsStateError,
      );
    });

    test('an over-long word is cut so every item round-trips', () {
      final a = MaterialImport.analyze('E' * 201, MaterialKind.text);
      expect(a.ok, isTrue);
      for (final item in a.items) {
        expect(
          MorseText.symbols(item).length,
          lessThanOrEqualTo(MaterialLimits.maxSymbolsPerEntry),
        );
      }
      final m = MaterialImport.create(
        id: 'x',
        title: 'x',
        kind: MaterialKind.text,
        text: 'E' * 201,
        analysis: a,
        now: now,
      );
      expect(
        MaterialLibraryCodec.decode(MaterialLibraryCodec.encode([m])),
        hasLength(1),
      );
    });

    test('long text is segmented at word boundaries', () {
      final text = List.filled(30, 'PARIS').join(' ');
      final a = MaterialImport.analyze(text, MaterialKind.text);
      expect(a.items.length, greaterThan(1));
      for (final item in a.items) {
        expect(MorseText.symbols(item).length, lessThanOrEqualTo(40));
        expect(item.split(' '), everyElement('PARIS'));
      }
      expect(a.symbolCount, 150);
    });
  });

  group('library codec', () {
    test('round trip keeps entries; exports drop private references', () {
      final m = make('CQ CQ DE K1ABC K');
      final raw = MaterialLibraryCodec.encode([m]);
      expect(raw, isNot(contains('chat:me')));
      final back = MaterialLibraryCodec.decode(raw).single;
      expect(back.normalizedItems, m.normalizedItems);
      expect(back.originalText, m.originalText);
      expect(back.source!.localRef, isNull);
      expect(back.source!.description, 'chat');
    });

    test('invalid input is rejected whole', () {
      expect(() => MaterialLibraryCodec.decode('{'), throwsFormatException);
      expect(
        () => MaterialLibraryCodec.decode('{"format":"other","version":1}'),
        throwsFormatException,
      );
      Map<String, Object?> lib() =>
          jsonDecode(MaterialLibraryCodec.encode([make('K')]))
              as Map<String, Object?>;
      final bad = lib();
      ((bad['materials']! as List).single as Map)['normalizedItems'] = ['你'];
      expect(
        () => MaterialLibraryCodec.decode(jsonEncode(bad)),
        throwsFormatException,
      );
      final wrongType = lib()..['version'] = 'bad';
      expect(
        () => MaterialLibraryCodec.decode(jsonEncode(wrongType)),
        throwsFormatException,
      );
      final newer = lib()..['version'] = 9;
      expect(
        () => MaterialLibraryCodec.decode(jsonEncode(newer)),
        throwsFormatException,
      );
    });

    test('duplicate ids follow the chosen policy', () {
      final a = make('K');
      final b = make('M');
      var n = 0;
      String id() => 'copy${n++}';
      expect(
        MaterialLibraryCodec.merge(
          [a],
          [b],
          policy: DuplicatePolicy.overwrite,
          newId: id,
        ).single.normalizedItems,
        ['M'],
      );
      final kept = MaterialLibraryCodec.merge(
        [a],
        [b],
        policy: DuplicatePolicy.keepCopy,
        newId: id,
      );
      expect(kept.map((m) => m.id), ['m1', 'copy0']);
      expect(
        MaterialLibraryCodec.merge(
          [a],
          [b],
          policy: DuplicatePolicy.skip,
          newId: id,
        ),
        hasLength(1),
      );
    });
  });

  group('drill', () {
    test('text goes in order; learned-only filters items', () {
      final m = make(List.filled(20, 'KM RS').join(' '));
      final d = MaterialDrill(m);
      final r = Random(1);
      expect(d.generate(r).text, m.normalizedItems[0]);
      expect(
        d.generate(r).text,
        m.normalizedItems[1 % m.normalizedItems.length],
      );
      expect(MaterialDrill(m, allowed: {'K', 'M'}).canGenerate, isFalse);
      expect(
        MaterialDrill(m, allowed: {'K', 'M', 'R', 'S'}).canGenerate,
        isTrue,
      );
    });
  });
}

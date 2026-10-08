import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

void main() {
  group('SequenceAligner', () {
    test('identical sequences align as matches', () {
      final pairs = SequenceAligner.align(['A', 'B', 'C'], ['A', 'B', 'C']);
      expect(pairs.map((p) => p.op), everyElement(AlignmentOp.match));
    });

    test('deletion does not shift later symbols', () {
      final pairs = SequenceAligner.align(
        ['K', 'M', 'R', 'S', 'U'],
        ['K', 'R', 'S', 'U'],
      );
      expect(pairs.map((p) => p.op).toList(), [
        AlignmentOp.match,
        AlignmentOp.deletion,
        AlignmentOp.match,
        AlignmentOp.match,
        AlignmentOp.match,
      ]);
      expect(pairs[1].target, 'M');
      expect(pairs[1].answer, isNull);
    });

    test('insertion is isolated', () {
      final pairs = SequenceAligner.align(
        ['K', 'M', 'R'],
        ['K', 'X', 'M', 'R'],
      );
      expect(
        pairs.where((p) => p.op == AlignmentOp.insertion).single.answer,
        'X',
      );
      expect(pairs.where((p) => p.op == AlignmentOp.match).length, 3);
    });

    test('empty sides', () {
      expect(SequenceAligner.align([], []), isEmpty);
      expect(SequenceAligner.align(['A'], []).single.op, AlignmentOp.deletion);
      expect(SequenceAligner.align([], ['A']).single.op, AlignmentOp.insertion);
    });
  });

  group('SessionScore', () {
    test('perfect copy', () {
      final s = SessionScore.evaluate('KMRS UAPT', 'kmrs uapt');
      expect(s.totalChars, 8);
      expect(s.correctChars, 8);
      expect(s.accuracy, 1.0);
      expect(s.isPerfect, isTrue);
      expect(s.errors, 0);
    });

    test('spaces are not scored', () {
      final s = SessionScore.evaluate('KM RS', 'KMRS');
      expect(s.accuracy, 1.0);
    });

    test('one missed char keeps the rest aligned', () {
      final s = SessionScore.evaluate('KMRSU', 'KRSU');
      expect(s.deletions, 1);
      expect(s.substitutions, 0);
      expect(s.correctChars, 4);
      expect(s.accuracy, closeTo(0.8, 1e-9));
      expect(s.charStats['M'], const CharStats(attempts: 1, correct: 0));
      expect(s.confusion.count('M', null), 1);
    });

    test('one inserted char does not hurt headline accuracy', () {
      final s = SessionScore.evaluate('KMR', 'KMXR');
      expect(s.insertions, 1);
      expect(s.accuracy, 1.0);
      expect(s.strictAccuracy, closeTo(0.75, 1e-9));
      expect(s.confusion.count(ConfusionMatrix.missed, 'X'), 1);
    });

    test('substitutions land in the confusion matrix and per-char map', () {
      final s = SessionScore.evaluate('KKKMM', 'KKRMR');
      expect(s.substitutions, 2);
      expect(s.confusion.count('K', 'R'), 1);
      expect(s.confusion.count('M', 'R'), 1);
      expect(s.confusion.mostConfusedWith('K'), 'R');
      expect(s.confusion.mostConfusedWith('R'), isNull);
      expect(s.perCharAccuracy['K'], closeTo(2 / 3, 1e-9));
      expect(s.perCharAccuracy['M'], closeTo(0.5, 1e-9));
      expect(s.weakChars(), ['M', 'K']);
    });

    test('prosigns are one symbol', () {
      final s = SessionScore.evaluate('K <BT> M', 'K <SK> M');
      expect(s.totalChars, 3);
      expect(s.substitutions, 1);
      expect(s.confusion.count('<BT>', '<SK>'), 1);
    });

    test('empty target', () {
      final s = SessionScore.evaluate('', 'ABC');
      expect(s.totalChars, 0);
      expect(s.accuracy, 0);
      expect(s.insertions, 3);
    });

    test('JSON round trip preserves scoring and metadata', () {
      final at = DateTime.utc(2026, 9, 30, 12);
      final s = SessionScore.evaluate(
        'KMRS UAPT',
        'KMRX UPT',
        at: at,
        elapsed: const Duration(seconds: 42),
        lesson: 7,
        drillKind: 'groups',
      );
      final back = SessionScore.fromJson(s.toJson());
      expect(back.accuracy, s.accuracy);
      expect(back.correctChars, s.correctChars);
      expect(back.substitutions, s.substitutions);
      expect(back.deletions, s.deletions);
      expect(back.at, at);
      expect(back.elapsed, const Duration(seconds: 42));
      expect(back.lesson, 7);
      expect(back.drillKind, 'groups');
      expect(back.alignment, s.alignment);
    });
  });

  group('ConfusionMatrix', () {
    test('records, merges, round-trips', () {
      final m = ConfusionMatrix()
        ..record('K', 'K')
        ..record('K', 'R', times: 2)
        ..record('K', null)
        ..recordInsertion('X');
      expect(m.totalFor('K'), 4);
      expect(m.errorsFor('K'), 3);
      expect(m.mostConfusedWith('K'), 'R');
      expect(m.rowFor('K'), {'K': 1, 'R': 2, '': 1});

      final other = ConfusionMatrix()..record('K', 'R');
      m.merge(other);
      expect(m.count('K', 'R'), 3);

      final back = ConfusionMatrix.fromJson(m.toJson());
      expect(back.count('K', 'R'), 3);
      expect(back.count('K', null), 1);
      expect(back.count(ConfusionMatrix.missed, 'X'), 1);
      expect(back.targets.toSet(), m.targets.toSet());
      expect(ConfusionMatrix.fromJson(null).isEmpty, isTrue);
    });

    test('mostConfusedWith ties resolve lexically', () {
      final m = ConfusionMatrix()
        ..record('K', 'R')
        ..record('K', 'M');
      expect(m.mostConfusedWith('K'), 'M');
    });
  });

  group('CharStats', () {
    test('accumulates and round trips', () {
      var s = CharStats.empty;
      s = s.withResult(correct: true).withResult(correct: false);
      expect(s.attempts, 2);
      expect(s.correct, 1);
      expect(s.misses, 1);
      expect(s.accuracy, 0.5);
      expect(CharStats.fromJson(s.toJson()), s);
      final merged = CharStats.merge({'K': s}, {'K': s, 'M': s});
      expect(merged['K'], const CharStats(attempts: 4, correct: 2));
      expect(merged['M'], s);
      expect(CharStats.mapFromJson(CharStats.mapToJson(merged)), merged);
    });
  });

  test('combine never lets a copy borrow symbols across rounds', () {
    // Answer 1 holds rounds 1+2, answer 2 is blank: per-round scoring.
    final parts = [
      SessionScore.evaluate('KMRSU', 'KMRSUAPTLO'),
      SessionScore.evaluate('APTLO', ''),
    ];
    final c = SessionScore.combine(parts);
    expect(c.totalChars, 10);
    expect(c.correctChars, 5);
    expect(c.insertions, 5);
    expect(c.alignment, hasLength(15));
    expect(SessionScore.evaluate('KMRSU APTLO', 'KMRSUAPTLO').correctChars, 10);
  });
}

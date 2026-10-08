import 'dart:math';

import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1);

  group('SrsScheduler', () {
    test('introduce puts symbols in box 0 due now, idempotent', () {
      final s = SrsScheduler().introduce(['K', 'M'], t0);
      expect(s.boxOf('K'), 0);
      expect(s.boxOf('M'), 0);
      expect(s.boxOf('R'), isNull);
      expect(s.dueChars(t0), ['K', 'M']);
      final again = s.record('K', correct: true, now: t0).introduce(['K'], t0);
      expect(again.boxOf('K'), 1);
    });

    test('promotion caps at maxBox, demotion floors at 0', () {
      var s = SrsScheduler().introduce(['K'], t0);
      for (var i = 0; i < 10; i++) {
        s = s.record('K', correct: true, now: t0);
      }
      expect(s.boxOf('K'), 4);
      expect(s.maxBox, 4);
      s = s.record('K', correct: false, now: t0);
      expect(s.boxOf('K'), 3);
      for (var i = 0; i < 10; i++) {
        s = s.record('K', correct: false, now: t0);
      }
      expect(s.boxOf('K'), 0);
    });

    test('due time follows the interval of the new box', () {
      final s = SrsScheduler()
          .introduce(['K'], t0)
          .record('K', correct: true, now: t0);
      expect(s.cardFor('K')!.dueAt, t0.add(const Duration(days: 1)));
      expect(s.dueChars(t0), isEmpty);
      expect(s.dueChars(t0.add(const Duration(hours: 23))), isEmpty);
      expect(s.dueChars(t0.add(const Duration(days: 1))), ['K']);
    });

    test('recording an unknown symbol introduces it first', () {
      final s = SrsScheduler().record('Z', correct: false, now: t0);
      expect(s.boxOf('Z'), 0);
      expect(s.dueChars(t0), ['Z']);
    });

    test('dueChars sorts by due time then symbol; shuffle is seeded', () {
      final s =
          SrsScheduler(
                intervals: const [
                  Duration.zero,
                  Duration(hours: 1),
                  Duration(hours: 2),
                ],
              )
              .introduce(['R', 'K', 'M'], t0)
              .record('R', correct: true, now: t0) // due t0+1h
              .record('M', correct: true, now: t0) // box1 due t0+1h
              .record('M', correct: true, now: t0); // box2 due t0+2h
      final later = t0.add(const Duration(hours: 3));
      expect(s.dueChars(later), ['K', 'R', 'M']);
      final a = s.dueChars(later, shuffle: Random(5));
      final b = s.dueChars(later, shuffle: Random(5));
      expect(a, b);
      expect(a.toSet(), {'K', 'R', 'M'});
    });

    test('dueOrNew adds untracked symbols', () {
      final s = SrsScheduler()
          .introduce(['K'], t0)
          .record('K', correct: true, now: t0);
      expect(s.dueOrNew(['K', 'M'], t0), ['M']);
      expect(s.dueOrNew(['K', 'M'], t0.add(const Duration(days: 2))), [
        'K',
        'M',
      ]);
    });

    test('applyScore promotes accurate symbols and demotes weak ones', () {
      final score = SessionScore.evaluate('KKKKKMMMMM', 'KKKKKMMRRR');
      final s = SrsScheduler()
          .introduce(['K', 'M'], t0)
          .record('M', correct: true, now: t0)
          .applyScore(score, now: t0);
      expect(s.boxOf('K'), 1);
      expect(s.boxOf('M'), 0);
      expect(s.boxCounts, {1: 1, 0: 1});
    });

    test('JSON round trip including custom intervals', () {
      final s = SrsScheduler(
        intervals: const [Duration.zero, Duration(minutes: 5)],
      ).introduce(['K', 'M'], t0).record('K', correct: true, now: t0);
      final back = SrsScheduler.fromJson(s.toJson());
      expect(back.intervals, s.intervals);
      expect(back.cards, s.cards);
      expect(back.cardFor('K'), s.cardFor('K'));
    });

    test('fromJson without intervals uses defaults', () {
      final back = SrsScheduler.fromJson(<String, Object?>{
        'cards': <String, Object?>{},
      });
      expect(back.intervals, SrsScheduler.defaultIntervals);
    });
  });
}

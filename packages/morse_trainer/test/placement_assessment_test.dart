import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

void main() {
  final course = KochCourse();

  PlacementAssessment fresh([int seed = 1]) =>
      PlacementAssessment(course: course, seed: seed);

  test('tiers follow the actual Koch order, each symbol twice', () {
    final p = fresh();
    expect(p.tiers, hasLength(5));
    expect(p.tiers[0].symbols, course.order.sublist(0, 10));
    expect(p.tiers[3].symbols, course.order.sublist(30));
    expect(p.tiers[3].symbolCount, 26);
    for (final tier in p.tiers.take(4)) {
      expect(tier.symbolCount, greaterThanOrEqualTo(20));
      final counts = <String, int>{};
      for (final r in tier.rounds) {
        for (final s in MorseText.symbols(r)) {
          counts[s] = (counts[s] ?? 0) + 1;
        }
      }
      expect(counts.values, everyElement(2));
    }
    expect(p.tiers[4].symbols, isEmpty);
    expect(p.tiers[4].symbolCount, greaterThanOrEqualTo(20));
    expect(p.tiers.map((t) => t.effectiveWpm), [5, 8, 12, 16, 20]);
    // Seeded and replayable.
    expect(fresh().tiers[1].rounds, p.tiers[1].rounds);
    expect(fresh(2).tiers[1].rounds, isNot(p.tiers[1].rounds));
  });

  test(
    'a perfect first tier suggests the lesson after the verified prefix',
    () {
      final p = fresh();
      expect(p.recordTier(p.currentTier!.rounds), isTrue);
      // Tier two all wrong: stop.
      expect(p.recordTier(['', '', '', '']), isFalse);
      expect(p.isFinished, isTrue);
      final r = p.result();
      expect(r.verifiedPrefix, 10);
      expect(r.suggestedLesson, course.lessonFor(course.order[10]));
      expect(r.tiersPassed, 1);
    },
  );

  test('one wrong copy blocks verification and the prefix', () {
    final p = fresh();
    final rounds = p.currentTier!.rounds;
    final answers = [...rounds];
    // Corrupt the first occurrence of M (order[1]).
    final i = answers.indexWhere((a) => a.contains('M'));
    answers[i] = answers[i].replaceFirst('M', 'K');
    p.recordTier(answers);
    final r = p.result();
    expect(r.evidence['M']!.verified, isFalse);
    expect(r.verifiedPrefix, 1);
    expect(r.suggestedLesson, 1);
  });

  test('replayed rounds never verify symbols', () {
    final p = fresh();
    final rounds = p.currentTier!.rounds;
    p.recordTier(rounds, assisted: {for (var i = 0; i < rounds.length; i++) i});
    expect(p.result().verifiedPrefix, 0);
    expect(p.result().suggestedLesson, 1);
  });

  test('isolated later successes cannot skip an untested prerequisite', () {
    final p = fresh();
    // Skip tier one by answering nothing: stops at once.
    p.recordTier(const []);
    expect(p.result().suggestedLesson, 1);
    expect(p.result().evidence.values.any((e) => e.verified), isFalse);
  });

  test('all tiers perfect suggests the last lesson', () {
    final p = fresh();
    while (!p.isFinished) {
      p.recordTier(p.currentTier!.rounds);
    }
    final r = p.result();
    expect(r.verifiedPrefix, course.order.length);
    expect(r.suggestedLesson, course.lessonCount);
    expect(r.tiersPassed, 5);
  });
}

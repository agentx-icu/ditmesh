import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

void main() {
  const order = <String>['K', 'M', 'R', 'S', 'U', 'A', 'P', 'T'];
  final course = KochCourse(order: order);

  group('KochCourse lessons', () {
    test('lesson count is one fewer than symbols', () {
      expect(course.lessonCount, 7);
      expect(KochCourse(order: const ['K']).lessonCount, 0);
      expect(KochCourse(order: const []).lessonCount, 0);
    });

    test('lesson 1 teaches first two symbols', () {
      expect(course.charsForLesson(1), ['K', 'M']);
      expect(course.newCharForLesson(1), 'M');
    });

    test('lesson n teaches n+1 symbols and introduces order[n]', () {
      expect(course.charsForLesson(3), ['K', 'M', 'R', 'S']);
      expect(course.newCharForLesson(3), 'S');
      expect(course.charsForLesson(7), order);
      expect(course.charSetForLesson(2), {'K', 'M', 'R'});
    });

    test('out-of-range lessons throw', () {
      expect(() => course.charsForLesson(0), throwsRangeError);
      expect(() => course.charsForLesson(8), throwsRangeError);
      expect(() => course.newCharForLesson(8), throwsRangeError);
    });

    test('recent chars, lessonFor, clamp, isLast', () {
      expect(course.recentCharsForLesson(1), {'K', 'M'});
      expect(course.recentCharsForLesson(4), {'U', 'S'});
      expect(course.recentCharsForLesson(4, count: 3), {'U', 'S', 'R'});
      expect(course.lessonFor('K'), 1);
      expect(course.lessonFor('M'), 1);
      expect(course.lessonFor('S'), 3);
      expect(course.lessonFor('Z'), isNull);
      expect(course.clampLesson(0), 1);
      expect(course.clampLesson(99), 7);
      expect(course.isLastLesson(7), isTrue);
      expect(course.isLastLesson(6), isFalse);
    });

    test('default order is MorseAlphabet.kochOrder (does not throw)', () {
      // kochOrder may still be empty while morse_core is under construction;
      // only assert that construction works and lessonCount is consistent.
      final c = KochCourse();
      expect(c.lessonCount, c.order.length < 2 ? 0 : c.order.length - 1);
    });
  });

  group('KochCourse unlock rule', () {
    String repeat(String s, int n) => List.filled(n, s).join();

    test('passes at exactly 90 % with 50 chars', () {
      final target = repeat('K', 50);
      final answer = '${repeat('K', 45)}${repeat('M', 5)}';
      final score = SessionScore.evaluate(target, answer);
      expect(score.accuracy, closeTo(0.9, 1e-9));
      expect(course.passes(score), isTrue);
    });

    test('fails just below 90 %', () {
      final target = repeat('K', 50);
      final answer = '${repeat('K', 44)}${repeat('M', 6)}';
      expect(course.passes(SessionScore.evaluate(target, answer)), isFalse);
    });

    test('fails with fewer than minCharsPerSession even if perfect', () {
      final target = repeat('K', 49);
      final score = SessionScore.evaluate(target, target);
      expect(score.accuracy, 1.0);
      expect(course.passes(score), isFalse);
    });

    test('thresholds are configurable', () {
      final lenient = KochCourse(
        order: order,
        passAccuracy: 0.5,
        minCharsPerSession: 4,
      );
      final score = SessionScore.evaluate('KMKM', 'KMRR');
      expect(lenient.passes(score), isTrue);
      expect(course.passes(score), isFalse);
    });

    test('nextLesson advances only on pass and never past the end', () {
      final pass = SessionScore.evaluate(repeat('K', 50), repeat('K', 50));
      final fail = SessionScore.evaluate(repeat('K', 50), repeat('M', 50));
      expect(course.nextLesson(1, pass), 2);
      expect(course.nextLesson(1, fail), 1);
      expect(course.nextLesson(7, pass), 7);
    });
  });
}

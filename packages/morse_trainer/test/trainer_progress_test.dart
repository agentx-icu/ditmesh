import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

void main() {
  final day1 = DateTime(2026, 3, 10, 9);
  final day2 = DateTime(2026, 3, 11, 21);
  final day4 = DateTime(2026, 3, 13, 8);
  String repeat(String s, int n) => List.filled(n, s).join();

  group('TrainerProgress', () {
    test('initial state', () {
      final p = TrainerProgress();
      expect(p.currentLesson, 1);
      expect(p.streakDays, 0);
      expect(p.streakAsOf(day1), 0);
      expect(p.history, isEmpty);
      expect(p.overallAccuracy, 0);
      expect(p.dailyGoalMet(day1), isFalse);
    });

    test('recordSession merges stats, history, confusion and SRS', () {
      final score = SessionScore.evaluate('KKMM', 'KKMR', drillKind: 'groups');
      final p = TrainerProgress().recordSession(score, now: day1);
      expect(p.charStats['K'], const CharStats(attempts: 2, correct: 2));
      expect(p.charStats['M'], const CharStats(attempts: 2, correct: 1));
      expect(p.history.single.totalChars, 4);
      expect(p.history.single.lesson, 1);
      expect(p.history.single.drillKind, 'groups');
      expect(p.history.single.at, day1);
      expect(p.confusion.count('M', 'R'), 1);
      expect(p.srs.boxOf('K'), 1);
      expect(p.srs.boxOf('M'), 0);
      expect(p.overallAccuracy, closeTo(0.75, 1e-9));
      expect(p.charsOn(day1), 4);
      expect(p.totalCharsPracticed, 4);
    });

    test('streak counts consecutive days and resets after a gap', () {
      final score = SessionScore.evaluate('K', 'K');
      var p = TrainerProgress().recordSession(score, now: day1);
      expect(p.streakDays, 1);
      p = p.recordSession(score, now: day1.add(const Duration(hours: 5)));
      expect(p.streakDays, 1);
      p = p.recordSession(score, now: day2);
      expect(p.streakDays, 2);
      expect(p.streakAsOf(day2), 2);
      expect(p.streakAsOf(day2.add(const Duration(days: 1))), 2);
      expect(p.streakAsOf(day4), 0);
      p = p.recordSession(score, now: day4);
      expect(p.streakDays, 1);
      expect(p.lastPracticeDay, DateTime(2026, 3, 13));
    });

    test('daily goal', () {
      final p = TrainerProgress(dailyGoalChars: 10)
          .recordSession(
            SessionScore.evaluate(repeat('K', 6), repeat('K', 6)),
            now: day1,
          )
          .recordSession(
            SessionScore.evaluate(repeat('M', 4), repeat('M', 4)),
            now: day1.add(const Duration(hours: 1)),
          );
      expect(p.charsOn(day1), 10);
      expect(p.dailyGoalMet(day1), isTrue);
      expect(p.dailyGoalMet(day2), isFalse);
    });

    test('history is trimmed to maxHistory keeping newest', () {
      var p = TrainerProgress(maxHistory: 2);
      for (var i = 1; i <= 3; i++) {
        p = p.recordSession(
          SessionScore.evaluate(repeat('K', i), repeat('K', i)),
          now: day1.add(Duration(minutes: i)),
        );
      }
      expect(p.history.map((s) => s.totalChars), [2, 3]);
    });

    test('advanceIfPassed uses the course rule', () {
      final course = KochCourse(
        order: const ['K', 'M', 'R'],
        minCharsPerSession: 4,
      );
      final pass = SessionScore.evaluate('KMKM', 'KMKM');
      final fail = SessionScore.evaluate('KMKM', 'RRRR');
      var p = TrainerProgress();
      expect(p.advanceIfPassed(course, fail).currentLesson, 1);
      p = p.advanceIfPassed(course, pass);
      expect(p.currentLesson, 2);
      expect(p.advanceIfPassed(course, pass).currentLesson, 2);
      expect(p.withLesson(5).currentLesson, 5);
    });

    test('JSON round trip', () {
      final p = TrainerProgress(dailyGoalChars: 42, maxHistory: 7)
          .recordSession(
            SessionScore.evaluate(
              'KMRS',
              'KMRX',
              elapsed: const Duration(seconds: 30),
              lesson: 3,
            ),
            now: day1,
          )
          .recordSession(SessionScore.evaluate('K', 'K'), now: day2)
          .withLesson(4);
      final back = TrainerProgress.fromJson(p.toJson());
      expect(back.currentLesson, 4);
      expect(back.charStats, p.charStats);
      expect(back.streakDays, 2);
      expect(back.lastPracticeDay, p.lastPracticeDay);
      expect(back.dailyGoalChars, 42);
      expect(back.maxHistory, 7);
      expect(back.history, p.history);
      expect(back.srs.cards, p.srs.cards);
      expect(back.confusion.count('S', 'X'), 1);
    });

    test('fromJson tolerates a minimal document', () {
      final p = TrainerProgress.fromJson(<String, Object?>{'currentLesson': 3});
      expect(p.currentLesson, 3);
      expect(p.history, isEmpty);
      expect(p.srs.cards, isEmpty);
      expect(p.confusion.isEmpty, isTrue);
    });
  });

  group('SessionSummary', () {
    test('fromScore and JSON', () {
      final score = SessionScore.evaluate('KMR', 'KMX', at: day1, lesson: 2);
      final s = SessionSummary.fromScore(score);
      expect(s.at, day1);
      expect(s.lesson, 2);
      expect(s.accuracy, closeTo(2 / 3, 1e-9));
      expect(SessionSummary.fromJson(s.toJson()), s);
    });
  });

  group('InMemoryTrainerStore', () {
    test('load returns null when empty, then the saved progress', () async {
      final store = InMemoryTrainerStore();
      expect(await store.load(), isNull);
      final p = TrainerProgress().recordSession(
        SessionScore.evaluate('KM', 'KM'),
        now: day1,
      );
      await store.save(p);
      expect(store.saveCount, 1);
      final loaded = await store.load();
      expect(loaded, isNotNull);
      expect(loaded!.history, p.history);
      expect(loaded.charStats, p.charStats);
      await store.clear();
      expect(await store.load(), isNull);
    });

    test('seeded store', () async {
      final store = InMemoryTrainerStore(TrainerProgress(currentLesson: 9));
      expect((await store.load())!.currentLesson, 9);
    });
  });
}

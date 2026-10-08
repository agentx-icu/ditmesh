// Regression tests for the 2026-10-03 Learn review of morse_trainer.
//
// The daylight-saving cases only bite in a DST zone; run this file with
// `TZ=America/New_York dart test` to exercise them against real 23 h / 25 h
// local midnights. In any other zone they still pin the calendar-day rule.
import 'package:morse_core/morse_core.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

void main() {
  String repeat(String s, int n) => List.filled(n, s).join();

  group('Koch unlock rule', () {
    final course = KochCourse();

    test('typing both candidates for every symbol does not pass', () {
      final score = SessionScore.evaluate(repeat('SH', 25), repeat('SHSH', 25));
      expect(score.accuracy, 1.0);
      expect(score.strictAccuracy, closeTo(0.5, 1e-9));
      expect(course.passes(score), isFalse);
    });

    test('a clean session at the minimum length passes', () {
      final target = repeat('KM', KochCourse.defaultMinCharsPerSession ~/ 2);
      expect(course.passes(SessionScore.evaluate(target, target)), isTrue);
    });

    test('default session length satisfies the course minimum', () {
      expect(
        TrainerSettings.defaults.sessionLengthChars,
        greaterThanOrEqualTo(course.minCharsPerSession),
      );
    });

    test('recentCharsForLesson reaches back to the first symbol', () {
      final c = KochCourse(order: const ['K', 'M', 'R', 'S']);
      expect(c.recentCharsForLesson(2, count: 3), {'R', 'M', 'K'});
      // Two lessons back from lesson 2 is lesson 1, which taught K and M.
      expect(c.recentCharsForLesson(2), {'R', 'M', 'K'});
      expect(c.recentCharsForLesson(3), {'S', 'R'});
      expect(c.recentCharsForLesson(1, count: 1), {'M', 'K'});
    });

    test('default course has every lesson encodable', () {
      expect(course.lessonCount, greaterThan(40));
      for (final symbol in course.order) {
        expect(
          MorseAlphabet.encodeChar(symbol) ??
              MorseAlphabet.encodeProsign(symbol),
          isNotNull,
          reason: symbol,
        );
      }
    });
  });

  group('streak across daylight-saving changes', () {
    // US spring-forward 2026-03-08, fall-back 2026-11-01.
    test('consecutive calendar days extend the streak', () {
      for (final (a, b) in [
        (DateTime(2026, 3, 7, 20), DateTime(2026, 3, 8, 20)),
        (DateTime(2026, 3, 8, 20), DateTime(2026, 3, 9, 8)),
        (DateTime(2026, 10, 31, 20), DateTime(2026, 11, 1, 20)),
        (DateTime(2026, 11, 1, 20), DateTime(2026, 11, 2, 8)),
      ]) {
        final p = TrainerProgress(streakDays: 3, lastPracticeDay: a);
        expect(TrainerProgress.daysBetween(a, b), 1, reason: '$a -> $b');
        expect(p.streakAfterPracticeOn(b), 4, reason: '$a -> $b');
        expect(p.streakAsOf(b), 3, reason: '$a -> $b');
      }
    });

    test('a skipped day resets the streak across a change', () {
      final last = DateTime(2026, 3, 7, 20);
      final p = TrainerProgress(streakDays: 3, lastPracticeDay: last);
      expect(p.streakAsOf(DateTime(2026, 3, 9, 8)), 0);
      expect(p.streakAfterPracticeOn(DateTime(2026, 3, 9, 8)), 1);
    });

    test('recordPractice credits streak and lifetime only', () {
      final now = DateTime(2026, 3, 9, 8);
      final p = TrainerProgress(
        streakDays: 2,
        lastPracticeDay: DateTime(2026, 3, 8, 9),
      );
      final score = SessionScore.evaluate('PARIS', 'PARIS', at: now);
      final next = p.recordPractice(
        SessionSummary.fromScore(score, at: now),
        now: now,
      );
      expect(next.streakDays, 3);
      expect(next.sessionCount, 1);
      expect(next.totalCharsPracticed, 5);
      expect(next.charStats, isEmpty);
    });
  });

  group('lifetime counters', () {
    test('survive history trimming and a JSON round trip', () {
      var p = TrainerProgress(maxHistory: 2);
      final at = DateTime(2026, 3, 10, 9);
      for (var i = 0; i < 3; i++) {
        p = p.recordSession(
          SessionScore.evaluate('KMKM', 'KMKM', at: at),
          now: at,
        );
      }
      expect(p.history, hasLength(2));
      expect(p.sessionCount, 3);
      expect(p.totalCharsPracticed, 12);
      final back = TrainerProgress.fromJson(p.toJson());
      expect(back.sessionCount, 3);
      expect(back.totalCharsPracticed, 12);
    });

    test('older files without counters fall back to the history', () {
      final at = DateTime(2026, 3, 10, 9);
      final p = TrainerProgress().recordSession(
        SessionScore.evaluate('KMKM', 'KMKM', at: at),
        now: at,
      );
      final json = p.toJson()
        ..remove('lifetimeSessions')
        ..remove('lifetimeChars');
      final back = TrainerProgress.fromJson(json);
      expect(back.sessionCount, 1);
      expect(back.totalCharsPracticed, 4);
    });
  });

  group('SRS', () {
    final t0 = DateTime.utc(2026, 1, 1);

    test('record() treats a box beyond maxBox as the top box', () {
      // Stores reject such files; record() must still not index past the
      // interval list when a caller builds one directly.
      final srs = SrsScheduler(
        cards: <String, SrsCard>{'K': SrsCard(box: 7, dueAt: t0)},
      );
      final next = srs.record('K', correct: false, now: t0);
      expect(next.cards['K']!.box, srs.maxBox - 1);
    });

    test('a good result promotes only symbols that are due', () {
      final score = SessionScore.evaluate('KMKM', 'KMKM', at: t0);
      final once = SrsScheduler().applyScore(score, now: t0);
      final twice = once.applyScore(score, now: t0);
      expect(once.cards['K']!.box, 1);
      expect(twice.cards['K']!.box, 1);
    });

    test('a bad result demotes even when not due', () {
      final good = SessionScore.evaluate('KMKM', 'KMKM', at: t0);
      final bad = SessionScore.evaluate('KMKM', 'TTTT', at: t0);
      final srs = SrsScheduler()
          .applyScore(good, now: t0)
          .applyScore(bad, now: t0);
      expect(srs.cards['K']!.box, 0);
    });
  });

  test('CharWeights rejects infinite weights', () {
    expect(
      () => CharWeights.explicit(<String, double>{'K': double.infinity}),
      throwsArgumentError,
    );
    expect(
      () => CharWeights.explicit(
        const <String, double>{},
        defaultWeight: double.nan,
      ),
      throwsArgumentError,
    );
  });
}

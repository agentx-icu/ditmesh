import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/ui/stats/stats_math.dart';
import 'package:ditmesh/ui/stats/stats_model.dart';

/// Fixed "today" for every snapshot: Wednesday 2026-09-30 at noon.
final DateTime kNow = DateTime(2026, 9, 30, 12);

/// Builds progress through the public API: one receive session per day for
/// [days] consecutive days ending [endOffsetDays] days before [kNow], then an
/// optional send session today.
TrainerProgress buildProgress({
  int days = 3,
  int endOffsetDays = 0,
  bool withSendToday = false,
  int lesson = 3,
}) {
  var progress = TrainerProgress(currentLesson: lesson, dailyGoalChars: 20);
  for (var i = days - 1; i >= 0; i--) {
    final at = kNow.subtract(Duration(days: i + endOffsetDays));
    final score = SessionScore.evaluate(
      'KMRS KMRS KMRS',
      i == 0 ? 'KMRS KMRS KMRS' : 'KMRS KMRR KMRS',
      at: at,
      elapsed: const Duration(minutes: 2),
      lesson: lesson,
      drillKind: 'groups',
    );
    progress = progress.recordSession(score, now: at);
  }
  if (withSendToday) {
    final score = SessionScore.evaluate(
      'KMRS KMRS',
      'KMRS KMRS',
      at: kNow,
      elapsed: const Duration(minutes: 1),
      lesson: lesson,
      drillKind: kSendDrillKind,
    );
    progress = progress.recordSession(score, now: kNow);
  }
  return progress;
}

void main() {
  group('StatsSnapshot.from', () {
    test('fresh progress is empty with sane defaults', () {
      final s = StatsSnapshot.from(TrainerProgress(), now: kNow);
      expect(s.isEmpty, isTrue);
      expect(s.currentLesson, 1);
      expect(s.lessonCount, 42);
      expect(s.learnedChars, <String>['K', 'M']);
      expect(s.accuracyAllTime, isNull);
      expect(s.accuracyLast7Days, isNull);
      expect(s.currentStreak, 0);
      expect(s.bestStreak, 0);
      expect(s.totalPracticeTime, Duration.zero);
      expect(s.trend, isEmpty);
      expect(s.calendar.length, 7 * StatsSnapshot.kCalendarWeeks);
      expect(s.activeDays, 0);
      expect(s.confusedTargets, isEmpty);
    });

    test('aggregates totals, streak and practice time', () {
      final s = StatsSnapshot.from(buildProgress(days: 3), now: kNow);
      expect(s.isEmpty, isFalse);
      expect(s.sessionCount, 3);
      expect(s.totalChars, 36);
      expect(s.totalPracticeTime, const Duration(minutes: 6));
      expect(s.currentStreak, 3);
      expect(s.bestStreak, 3);
      expect(s.charsToday, 12);
      expect(s.dailyGoal, 20);
      expect(s.dailyGoalMet, isFalse);
      expect(s.learnedChars, <String>['K', 'M', 'R', 'S']);
      // 2 misses over 36 chars lifetime.
      expect(s.accuracyAllTime, closeTo(34 / 36, 1e-9));
      expect(s.accuracyLast7Days, closeTo(34 / 36, 1e-9));
    });

    test('7-day accuracy excludes older sessions; streak lapses', () {
      final s = StatsSnapshot.from(
        buildProgress(days: 2, endOffsetDays: 10),
        now: kNow,
      );
      expect(s.accuracyLast7Days, isNull);
      expect(s.accuracyAllTime, isNotNull);
      expect(s.currentStreak, 0);
      expect(s.bestStreak, 2);
    });

    test('trend keeps the newest sessions and flags send drills', () {
      final s = StatsSnapshot.from(
        buildProgress(days: 2, withSendToday: true),
        now: kNow,
      );
      expect(s.trend.length, 3);
      expect(s.trend.map((p) => p.index), <int>[1, 2, 3]);
      expect(s.trend.last.isSend, isTrue);
      expect(s.trend.first.isSend, isFalse);
      expect(s.trendHasBothKinds, isTrue);
      expect(s.trend.last.accuracy, 1);
    });

    test('trend window is capped', () {
      final s = StatsSnapshot.from(
        buildProgress(days: 40),
        now: kNow,
        trendWindow: 5,
      );
      expect(s.trend.length, 5);
      expect(s.trend.last.summary.at, kNow);
    });

    test('single-kind history draws one series', () {
      final s = StatsSnapshot.from(buildProgress(days: 2), now: kNow);
      expect(s.trendHasBothKinds, isFalse);
    });

    test('calendar ends on the current ISO week and sums chars per day', () {
      final s = StatsSnapshot.from(buildProgress(days: 3), now: kNow);
      final last = s.calendar.last.day;
      expect(last.weekday, DateTime.sunday);
      expect(last, DateTime(2026, 10, 4));
      expect(s.calendar.first.day, DateTime(2026, 7, 13));
      expect(s.calendar.first.day.weekday, DateTime.monday);
      final today = s.calendar.firstWhere((d) => d.day == dayOf(kNow));
      expect(today.chars, 12);
      expect(s.activeDays, 3);
      expect(s.calendarMaxChars, 12);
    });

    test('per-character buckets and confusions', () {
      final s = StatsSnapshot.from(buildProgress(days: 3), now: kNow);
      expect(s.statsFor('K').attempts, 9);
      expect(s.bucketOf('K'), AccuracyBucket.strong);
      expect(s.statsFor('S').attempts, 9);
      // S was answered as R twice (two imperfect sessions).
      expect(s.statsFor('S').correct, 7);
      expect(s.bucketOf('S'), AccuracyBucket.fair);
      expect(s.bucketOf('U'), AccuracyBucket.none);
      final confusions = s.confusionsFor('S');
      expect(confusions.length, 1);
      expect(confusions.single.answered, 'R');
      expect(confusions.single.count, 2);
      expect(s.confusionsFor('K'), isEmpty);
    });

    test('heatmap rows/columns hide characters without data', () {
      final s = StatsSnapshot.from(buildProgress(days: 3), now: kNow);
      expect(s.confusedTargets, <String>['S']);
      expect(s.confusedAnswers, <String>['R']);
      expect(s.confusionCount('S', 'R'), 2);
      expect(s.confusionCount('S', 'S'), 0);
      expect(s.confusionMax, 2);
    });

    test('missed answers sort last among heatmap columns', () {
      final matrix = ConfusionMatrix()
        ..record('K', null, times: 3)
        ..record('K', 'M')
        ..record('M', 'K', times: 2);
      final progress = TrainerProgress(
        currentLesson: 2,
        history: <SessionSummary>[
          SessionSummary(at: kNow, totalChars: 10, correctChars: 4),
        ],
        confusion: matrix,
      );
      final s = StatsSnapshot.from(progress, now: kNow);
      expect(s.confusedTargets, <String>['K', 'M']);
      expect(s.confusedAnswers, <String>['K', 'M', ConfusionMatrix.missed]);
      final k = s.confusionsFor('K');
      expect(k.first.isMissed, isTrue);
      expect(k.first.count, 3);
    });

    test('lesson beyond the course is clamped', () {
      final s = StatsSnapshot.from(
        TrainerProgress(currentLesson: 99),
        now: kNow,
      );
      expect(s.currentLesson, 42);
      expect(s.learnedChars.length, 43);
    });

    test('round-trips through JSON without changing the snapshot', () {
      final progress = buildProgress(days: 3, withSendToday: true);
      final copy = TrainerProgress.fromJson(progress.toJson());
      final a = StatsSnapshot.from(progress, now: kNow);
      final b = StatsSnapshot.from(copy, now: kNow);
      expect(b.totalChars, a.totalChars);
      expect(b.accuracyAllTime, a.accuracyAllTime);
      expect(b.trend.length, a.trend.length);
      expect(b.confusedTargets, a.confusedTargets);
      expect(b.bestStreak, a.bestStreak);
    });
  });

  test('QSO and placement records never enter accuracy figures', () {
    final now = DateTime(2026, 10, 3, 12);
    SessionSummary rec(ExerciseSource source, int correct) => SessionSummary(
      at: now,
      totalChars: 10,
      correctChars: correct,
      id: 'ex${source.name}',
      source: source,
      assistance: const {},
    );
    final snap = StatsSnapshot.from(
      TrainerProgress(
        history: [
          rec(ExerciseSource.course, 5),
          rec(ExerciseSource.qso, 10),
          rec(ExerciseSource.placement, 10),
        ],
      ),
      now: now,
    );
    expect(snap.accuracyLast7Days, 0.5);
    expect(snap.trend, hasLength(1));
  });
}

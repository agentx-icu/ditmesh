import 'dart:math' as math;

import 'package:morse_trainer/morse_trainer.dart';

import 'stats_math.dart';

/// `SessionSummary.drillKind` the send-practice flow records
/// (`lib/training/send_session.dart`). Anything else is a receive drill.
const String kSendDrillKind = 'send';

/// One point on the accuracy trend chart.
final class TrendPoint {
  const TrendPoint({
    required this.index,
    required this.summary,
    required this.isSend,
  });

  /// 1-based position in the plotted window (oldest = 1).
  final int index;
  final SessionSummary summary;
  final bool isSend;

  double get accuracy => summary.accuracy;
}

/// One heat square in the practice calendar.
final class CalendarDay {
  const CalendarDay({required this.day, required this.chars});

  final DateTime day;
  final int chars;
}

/// One wrong answer for a character, ordered most frequent first.
final class ConfusionEntry {
  const ConfusionEntry({required this.answered, required this.count});

  /// Empty string means the character was missed entirely.
  final String answered;
  final int count;

  bool get isMissed => answered == ConfusionMatrix.missed;
}

/// Everything the dashboard renders, derived once from [TrainerProgress] so
/// widgets stay declarative and tests can assert on numbers directly.
final class StatsSnapshot {
  StatsSnapshot._({
    required this.progress,
    required this.course,
    required this.now,
    required this.learnedChars,
    required this.accuracyLast7Days,
    required this.bestStreak,
    required this.totalPracticeTime,
    required this.trend,
    required this.calendar,
  });

  /// Whether [s] is a copy/send accuracy record (legacy records are).
  static bool countsAsCopying(SessionSummary s) => switch (s.source) {
    ExerciseSource.qso ||
    ExerciseSource.placement ||
    ExerciseSource.recording ||
    // Radio-condition results stay out of the clean accuracy trend (F11).
    ExerciseSource.conditions => false,
    _ => true,
  };

  factory StatsSnapshot.from(
    TrainerProgress progress, {
    KochCourse? course,
    DateTime? now,
    int trendWindow = kTrendWindow,
    int calendarWeeks = kCalendarWeeks,
  }) {
    final resolvedCourse = course ?? KochCourse();
    final clock = now ?? DateTime.now();
    final lesson = resolvedCourse.clampLesson(progress.currentLesson);
    final learned = resolvedCourse.lessonCount == 0
        ? const <String>[]
        : resolvedCourse.charsForLesson(lesson);

    final since = dayOf(clock).subtract(const Duration(days: 6));
    var recentTotal = 0;
    var recentCorrect = 0;
    var elapsed = Duration.zero;
    for (final s in progress.history) {
      elapsed += s.elapsed ?? Duration.zero;
      // QSO, placement and recording records carry activity, not copying
      // accuracy: they never enter accuracy figures.
      if (!s.at.isBefore(since) && countsAsCopying(s)) {
        recentTotal += s.totalChars;
        recentCorrect += s.correctChars;
      }
    }

    final windowStart = math.max(0, progress.history.length - trendWindow);
    final window = progress.history
        .sublist(windowStart)
        .where(countsAsCopying)
        .toList();
    final trend = <TrendPoint>[
      for (var i = 0; i < window.length; i++)
        TrendPoint(
          index: i + 1,
          summary: window[i],
          isSend: window[i].drillKind == kSendDrillKind,
        ),
    ];

    return StatsSnapshot._(
      progress: progress,
      course: resolvedCourse,
      now: clock,
      learnedChars: learned,
      accuracyLast7Days: recentTotal == 0 ? null : recentCorrect / recentTotal,
      bestStreak: math.max(
        progress.streakDays,
        longestDailyRun(progress.history.map((s) => s.at)),
      ),
      totalPracticeTime: elapsed,
      trend: trend,
      calendar: _buildCalendar(progress, clock, calendarWeeks),
    );
  }

  /// Sessions plotted on the trend chart.
  static const int kTrendWindow = 30;

  /// Weeks shown by the practice calendar.
  static const int kCalendarWeeks = 12;

  final TrainerProgress progress;
  final KochCourse course;
  final DateTime now;

  /// Symbols known at the current lesson, in Koch order.
  final List<String> learnedChars;

  /// Correct / attempted over sessions in the last 7 calendar days, or null
  /// when there were none.
  final double? accuracyLast7Days;

  /// Longest run of consecutive practice days seen in history (or the stored
  /// streak, whichever is larger).
  final int bestStreak;

  /// Sum of recorded session durations.
  final Duration totalPracticeTime;

  /// Oldest first, at most [kTrendWindow] points.
  final List<TrendPoint> trend;

  /// Oldest first, `7 * kCalendarWeeks` days ending today.
  final List<CalendarDay> calendar;

  bool get isEmpty => progress.history.isEmpty;

  int get currentLesson => course.clampLesson(progress.currentLesson);

  int get lessonCount => course.lessonCount;

  double? get accuracyAllTime =>
      progress.charStats.isEmpty ? null : progress.overallAccuracy;

  int get totalChars => progress.totalCharsPracticed;

  int get sessionCount => progress.sessionCount;

  int get currentStreak => progress.streakAsOf(now);

  int get charsToday => progress.charsOn(now);

  int get dailyGoal => progress.dailyGoalChars;

  bool get dailyGoalMet => progress.dailyGoalMet(now);

  /// True when both send and receive sessions appear in the trend window, so
  /// the chart draws two series.
  bool get trendHasBothKinds {
    var send = false;
    var receive = false;
    for (final p in trend) {
      if (p.isSend) {
        send = true;
      } else {
        receive = true;
      }
    }
    return send && receive;
  }

  int get activeDays => calendar.where((d) => d.chars > 0).length;

  int get calendarMaxChars =>
      calendar.fold<int>(0, (m, d) => math.max(m, d.chars));

  CharStats statsFor(String char) =>
      progress.charStats[char] ?? CharStats.empty;

  AccuracyBucket bucketOf(String char) {
    final s = statsFor(char);
    return bucketFor(s.accuracy, attempts: s.attempts);
  }

  /// Wrong answers for [char], most frequent first (ties by symbol).
  List<ConfusionEntry> confusionsFor(String char, {int limit = 3}) {
    final row = progress.confusion.rowFor(char);
    final entries =
        <ConfusionEntry>[
          for (final e in row.entries)
            if (e.key != char && e.value > 0)
              ConfusionEntry(answered: e.key, count: e.value),
        ]..sort((a, b) {
          final byCount = b.count.compareTo(a.count);
          return byCount != 0 ? byCount : a.answered.compareTo(b.answered);
        });
    return entries.length > limit ? entries.sublist(0, limit) : entries;
  }

  /// Learned characters that have at least one recorded wrong answer, in Koch
  /// order. Rows of the confusion heatmap.
  List<String> get confusedTargets => <String>[
    for (final c in learnedChars)
      if (progress.confusion.errorsFor(c) > 0) c,
  ];

  /// Columns of the confusion heatmap: every answered symbol that appears in
  /// a [confusedTargets] row (excluding the correct answer), Koch order first,
  /// then unknown symbols alphabetically, then "missed" last.
  List<String> get confusedAnswers {
    final seen = <String>{};
    for (final target in confusedTargets) {
      for (final e in progress.confusion.rowFor(target).entries) {
        if (e.key != target && e.value > 0) {
          seen.add(e.key);
        }
      }
    }
    final ordered = <String>[
      for (final c in course.order)
        if (seen.remove(c)) c,
    ];
    final hasMissed = seen.remove(ConfusionMatrix.missed);
    ordered.addAll(seen.toList()..sort());
    if (hasMissed) {
      ordered.add(ConfusionMatrix.missed);
    }
    return ordered;
  }

  int confusionCount(String target, String answered) =>
      target == answered ? 0 : progress.confusion.count(target, answered);

  int get confusionMax {
    var max = 0;
    for (final t in confusedTargets) {
      for (final e in progress.confusion.rowFor(t).entries) {
        if (e.key != t) {
          max = math.max(max, e.value);
        }
      }
    }
    return max;
  }

  static List<CalendarDay> _buildCalendar(
    TrainerProgress progress,
    DateTime now,
    int weeks,
  ) {
    final today = dayOf(now);
    final totalDays = weeks * 7;
    // End the grid on today's ISO week so columns are whole weeks.
    final end = weekStartOf(today).add(const Duration(days: 6));
    final start = end.subtract(Duration(days: totalDays - 1));
    final perDay = <DateTime, int>{};
    for (final s in progress.history) {
      final day = dayOf(s.at);
      if (!day.isBefore(start) && !day.isAfter(end)) {
        perDay[day] = (perDay[day] ?? 0) + s.totalChars;
      }
    }
    return <CalendarDay>[
      for (var i = 0; i < totalDays; i++)
        () {
          final day = DateTime(start.year, start.month, start.day + i);
          return CalendarDay(day: day, chars: perDay[day] ?? 0);
        }(),
    ];
  }
}

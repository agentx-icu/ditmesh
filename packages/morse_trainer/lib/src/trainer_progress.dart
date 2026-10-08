import 'char_stats.dart';
import 'confusion_matrix.dart';
import 'daily_plan.dart';
import 'exercise.dart';
import 'koch_course.dart';
import 'session_score.dart';
import 'session_summary.dart';
import 'srs_scheduler.dart';

/// Everything the trainer remembers about a learner.
///
/// Immutable; [recordSession] returns the updated progress. Persist it with a
/// `TrainerStore` (the app supplies the file-backed implementation).
final class TrainerProgress {
  TrainerProgress({
    this.currentLesson = 1,
    Map<String, CharStats> charStats = const <String, CharStats>{},
    this.streakDays = 0,
    DateTime? lastPracticeDay,
    this.dailyGoalChars = 100,
    List<SessionSummary> history = const <SessionSummary>[],
    SrsScheduler? srs,
    ConfusionMatrix? confusion,
    this.maxHistory = 500,
    int? lifetimeSessions,
    int? lifetimeChars,
    List<String> committedIds = const <String>[],
    this.dailyPlan,
    this.previousPlan,
    this.speedAdviceKey,
  }) : assert(currentLesson >= 1, 'currentLesson must be >= 1'),
       assert(streakDays >= 0, 'streakDays must be >= 0'),
       assert(dailyGoalChars >= 0, 'dailyGoalChars must be >= 0'),
       assert(maxHistory > 0, 'maxHistory must be positive'),
       charStats = Map<String, CharStats>.unmodifiable(charStats),
       lastPracticeDay = lastPracticeDay == null
           ? null
           : dayOf(lastPracticeDay),
       history = List<SessionSummary>.unmodifiable(history),
       // Files written before the lifetime counters existed: the retained
       // history is the best available lower bound.
       lifetimeSessions = lifetimeSessions ?? history.length,
       lifetimeChars =
           lifetimeChars ??
           history.fold<int>(0, (sum, s) => sum + s.totalChars),
       srs = srs ?? SrsScheduler(),
       confusion = confusion ?? ConfusionMatrix(),
       committedIds = List<String>.unmodifiable(committedIds);

  /// How many committed exercise ids are remembered for de-duplication.
  ///
  /// Far more than [maxHistory], so trimming history never forgets an id a
  /// retry could still submit. Retries outlive a restart only through
  /// unfinished drafts (a finished QSO awaiting its save), which are
  /// committed the next time their screen opens; ten thousand later
  /// exercises before that happens is not a reachable state.
  static const int maxCommittedIds = 10000;

  /// 1-based Koch lesson the learner is working on.
  final int currentLesson;

  /// Lifetime per-symbol counters.
  final Map<String, CharStats> charStats;

  /// Consecutive days with at least one session, as of [lastPracticeDay].
  final int streakDays;

  /// Local calendar day (midnight) of the most recent session, or null.
  final DateTime? lastPracticeDay;

  /// Symbols per day the learner aims for.
  final int dailyGoalChars;

  /// Newest last; trimmed to [maxHistory].
  final List<SessionSummary> history;

  final SrsScheduler srs;

  /// Lifetime confusion counts.
  final ConfusionMatrix confusion;

  final int maxHistory;

  /// Sessions ever recorded; unlike [history] never trimmed.
  final int lifetimeSessions;

  /// Symbols ever practised; unlike [history] never trimmed.
  final int lifetimeChars;

  /// Exercise ids already credited, oldest first (see [recordExercise]).
  final List<String> committedIds;

  /// Today's (or the latest) daily plan, committed with the progress so a
  /// step's completion and its exercise land in one write.
  final DailyPlan? dailyPlan;

  /// The plan of an earlier day, kept for inspection only.
  final DailyPlan? previousPlan;

  /// Evidence batch the last speed recommendation was shown or applied for.
  final String? speedAdviceKey;

  bool hasCommitted(String id) => committedIds.contains(id);

  /// Local midnight of [when].
  static DateTime dayOf(DateTime when) =>
      DateTime(when.year, when.month, when.day);

  /// Calendar days from the local day of [from] to the local day of [to].
  ///
  /// Compares dates, not durations: across a daylight-saving change two
  /// local midnights are 23 h or 25 h apart, which `Duration.inDays` would
  /// truncate to 0 or 1.
  static int daysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  int get totalCharsPracticed => lifetimeChars;

  int get sessionCount => lifetimeSessions;

  /// Lifetime correct / attempted over every symbol; 0 with no data.
  double get overallAccuracy {
    var attempts = 0;
    var correct = 0;
    for (final s in charStats.values) {
      attempts += s.attempts;
      correct += s.correct;
    }
    return attempts == 0 ? 0 : correct / attempts;
  }

  /// Symbols practised on the calendar day of [when].
  int charsOn(DateTime when) {
    final day = dayOf(when);
    return history
        .where((s) => dayOf(s.at) == day)
        .fold<int>(0, (sum, s) => sum + s.totalChars);
  }

  bool dailyGoalMet(DateTime now) => charsOn(now) >= dailyGoalChars;

  /// The streak as seen from [now]: 0 once a full day has been skipped.
  int streakAsOf(DateTime now) {
    final last = lastPracticeDay;
    if (last == null) {
      return 0;
    }
    return daysBetween(last, now) > 1 ? 0 : streakDays;
  }

  /// The streak after practising at [now]: same day keeps it, the next day
  /// extends it, anything later (or an unknown last day) restarts at 1.
  int streakAfterPracticeOn(DateTime now) {
    final last = lastPracticeDay;
    if (last == null) {
      return 1;
    }
    final gap = daysBetween(last, now);
    if (gap == 0) {
      return streakDays;
    }
    return gap == 1 ? streakDays + 1 : 1;
  }

  /// Appends [summary] to history and credits the streak and lifetime
  /// counters, leaving per-symbol statistics, SRS and confusion untouched.
  /// For practice that is not a copy of sent symbols (sending drills).
  TrainerProgress recordPractice(
    SessionSummary summary, {
    required DateTime now,
  }) => copyWith(
    history: _appendHistory(summary),
    streakDays: streakAfterPracticeOn(now),
    lastPracticeDay: dayOf(now),
    lifetimeSessions: lifetimeSessions + 1,
    lifetimeChars: lifetimeChars + summary.totalChars,
  );

  List<SessionSummary> _appendHistory(SessionSummary summary) {
    final next = <SessionSummary>[...history, summary];
    if (next.length > maxHistory) {
      next.removeRange(0, next.length - maxHistory);
    }
    return next;
  }

  /// Folds a finished session into the progress.
  ///
  /// [lesson] defaults to the score's lesson, then to [currentLesson].
  /// [now] must be supplied so callers (and tests) control the clock.
  TrainerProgress recordSession(
    SessionScore score, {
    required DateTime now,
    int? lesson,
    bool updateSrs = true,
    double srsPassAccuracy = 0.9,
  }) {
    final summary = SessionSummary.fromScore(
      score,
      at: score.at ?? now,
      lesson: lesson ?? score.lesson ?? currentLesson,
    );
    final mergedConfusion = confusion.copy()..merge(score.confusion);

    return recordPractice(summary, now: now).copyWith(
      charStats: CharStats.merge(charStats, score.charStats),
      srs: updateSrs
          ? srs.applyScore(score, now: now, passAccuracy: srsPassAccuracy)
          : srs,
      confusion: mergedConfusion,
    );
  }

  /// Moves to [course]'s next lesson when [score] passes, otherwise unchanged.
  TrainerProgress advanceIfPassed(KochCourse course, SessionScore score) {
    if (!course.isValidLesson(currentLesson)) {
      return this;
    }
    final next = course.nextLesson(currentLesson, score);
    return next == currentLesson ? this : copyWith(currentLesson: next);
  }

  TrainerProgress withLesson(int lesson) => copyWith(currentLesson: lesson);

  /// Credits one exercise according to [credit] (spec §3.3), exactly once
  /// per [SessionSummary.id]: a repeated submission of the same id returns
  /// this progress unchanged, also after a restart.
  ///
  /// Receive statistics, confusions and SRS only take symbols in [learned]
  /// (all symbols when null): unknown-to-the-course symbols may be practised
  /// but never enter the learned-symbol SRS. Lesson unlocks are the caller's
  /// decision ([advanceIfPassed]) and only when [ExerciseCredit.unlock].
  TrainerProgress recordExercise(
    SessionScore score,
    SessionSummary summary, {
    required ExerciseCredit credit,
    required DateTime now,
    Set<String>? learned,
    double srsPassAccuracy = 0.9,
  }) {
    final id = summary.id;
    if (id != null && hasCommitted(id)) return this;
    if (!credit.activity) {
      return id == null ? this : copyWith(committedIds: _withId(id));
    }
    var next = recordPractice(summary, now: now);
    if (id != null) next = next.copyWith(committedIds: _withId(id));
    if (!credit.receiveStats) return next;
    bool keep(String c) => learned == null || learned.contains(c);
    final stats = <String, CharStats>{
      for (final e in score.charStats.entries)
        if (keep(e.key)) e.key: e.value,
    };
    final filtered = ConfusionMatrix();
    for (final target in score.confusion.targets) {
      if (target != ConfusionMatrix.missed && !keep(target)) continue;
      for (final e in score.confusion.rowFor(target).entries) {
        filtered.record(target, e.key, times: e.value);
      }
    }
    return next.copyWith(
      charStats: CharStats.merge(charStats, stats),
      srs: srs.applyCharStats(stats, now: now, passAccuracy: srsPassAccuracy),
      confusion: confusion.copy()..merge(filtered),
    );
  }

  List<String> _withId(String id) {
    final ids = <String>[...committedIds, id];
    // Evict the oldest ordinary ids. Ids of results that can be parked
    // across launches (prefix `qso_`, one per finished QSO) are never
    // evicted, so a parked result can never be credited twice.
    var excess = ids.length - maxCommittedIds;
    if (excess > 0) {
      ids.removeWhere((x) => excess-- > 0 && !x.startsWith(protectedIdPrefix));
    }
    return ids;
  }

  /// See [_withId].
  static const String protectedIdPrefix = 'qso_';

  /// Installs [plan] as today's plan; an older plan moves to [previousPlan].
  TrainerProgress withDailyPlan(DailyPlan plan) {
    final current = dailyPlan;
    if (current != null && current.id == plan.id) {
      return copyWith(dailyPlan: plan);
    }
    return copyWith(
      dailyPlan: plan,
      previousPlan: current == null || current.date == plan.date
          ? previousPlan
          : current,
    );
  }

  TrainerProgress copyWith({
    int? currentLesson,
    Map<String, CharStats>? charStats,
    int? streakDays,
    DateTime? lastPracticeDay,
    int? dailyGoalChars,
    List<SessionSummary>? history,
    SrsScheduler? srs,
    ConfusionMatrix? confusion,
    int? maxHistory,
    int? lifetimeSessions,
    int? lifetimeChars,
    List<String>? committedIds,
    DailyPlan? dailyPlan,
    DailyPlan? previousPlan,
    String? speedAdviceKey,
  }) => TrainerProgress(
    currentLesson: currentLesson ?? this.currentLesson,
    charStats: charStats ?? this.charStats,
    streakDays: streakDays ?? this.streakDays,
    lastPracticeDay: lastPracticeDay ?? this.lastPracticeDay,
    dailyGoalChars: dailyGoalChars ?? this.dailyGoalChars,
    history: history ?? this.history,
    srs: srs ?? this.srs,
    confusion: confusion ?? this.confusion,
    maxHistory: maxHistory ?? this.maxHistory,
    lifetimeSessions: lifetimeSessions ?? this.lifetimeSessions,
    lifetimeChars: lifetimeChars ?? this.lifetimeChars,
    committedIds: committedIds ?? this.committedIds,
    dailyPlan: dailyPlan ?? this.dailyPlan,
    previousPlan: previousPlan ?? this.previousPlan,
    speedAdviceKey: speedAdviceKey ?? this.speedAdviceKey,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'version': 1,
    'currentLesson': currentLesson,
    'charStats': CharStats.mapToJson(charStats),
    'streakDays': streakDays,
    'lastPracticeDay': lastPracticeDay?.toIso8601String().substring(0, 10),
    'dailyGoalChars': dailyGoalChars,
    'history': history.map((s) => s.toJson()).toList(),
    'srs': srs.toJson(),
    'confusion': confusion.toJson(),
    'maxHistory': maxHistory,
    'lifetimeSessions': lifetimeSessions,
    'lifetimeChars': lifetimeChars,
    if (committedIds.isNotEmpty) 'committedIds': committedIds,
    if (dailyPlan != null) 'dailyPlan': dailyPlan!.toJson(),
    if (previousPlan != null) 'previousPlan': previousPlan!.toJson(),
    if (speedAdviceKey != null) 'speedAdviceKey': speedAdviceKey,
  };

  /// Reads [toJson] output. Values are taken as stored, so a store can
  /// validate them and fall back to a backup (the app's `FileTrainerStore`
  /// does).
  factory TrainerProgress.fromJson(Map<String, Object?> json) {
    final lastDay = json['lastPracticeDay'] as String?;
    final rawHistory = json['history'] as List<Object?>? ?? const <Object?>[];
    final rawSrs = json['srs'] as Map<String, Object?>?;

    final history = rawHistory
        .map((e) => SessionSummary.fromJson(e! as Map<String, Object?>))
        .toList();
    final lifetimeSessions = (json['lifetimeSessions'] as num?)?.toInt();
    final lifetimeChars = (json['lifetimeChars'] as num?)?.toInt();
    final rawPlan = json['dailyPlan'];
    final rawPrevious = json['previousPlan'];
    return TrainerProgress(
      currentLesson: (json['currentLesson'] as num?)?.toInt() ?? 1,
      charStats: CharStats.mapFromJson(
        json['charStats'] as Map<String, Object?>?,
      ),
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      lastPracticeDay: lastDay == null ? null : DateTime.parse(lastDay),
      dailyGoalChars: (json['dailyGoalChars'] as num?)?.toInt() ?? 100,
      history: history,
      srs: rawSrs == null ? null : SrsScheduler.fromJson(rawSrs),
      confusion: ConfusionMatrix.fromJson(
        json['confusion'] as Map<String, Object?>?,
      ),
      maxHistory: (json['maxHistory'] as num?)?.toInt() ?? 500,
      // Absent in files written before the counters existed: the
      // constructor derives them from the history. Present values are
      // taken as stored so a store can reject inconsistent ones.
      lifetimeSessions: lifetimeSessions,
      lifetimeChars: lifetimeChars,
      committedIds:
          (json['committedIds'] as List<Object?>?)?.cast<String>() ??
          const <String>[],
      dailyPlan: rawPlan is Map<String, Object?>
          ? DailyPlan.fromJson(rawPlan)
          : null,
      previousPlan: rawPrevious is Map<String, Object?>
          ? DailyPlan.fromJson(rawPrevious)
          : null,
      speedAdviceKey: json['speedAdviceKey'] as String?,
    );
  }

  @override
  String toString() =>
      'TrainerProgress(lesson $currentLesson, ${history.length} sessions, '
      'streak $streakDays, ${(overallAccuracy * 100).toStringAsFixed(1)}%)';
}

/// What a daily-plan step practises.
enum PlanStepKind {
  /// SRS review of due symbols.
  review,

  /// Focused drill on confused / weak learned symbols.
  focus,

  /// Koch course copying of the step's lesson.
  course,

  /// Short sending practice.
  send;

  static PlanStepKind parse(String? name) => values.firstWhere(
    (v) => v.name == name,
    orElse: () => PlanStepKind.course,
  );
}

enum PlanStepState {
  pending,

  /// Started; its content is frozen.
  active,
  done;

  static PlanStepState parse(String? name) => values.firstWhere(
    (v) => v.name == name,
    orElse: () => PlanStepState.pending,
  );
}

/// Localisable reason a step is in the plan. The app maps each to an ARB
/// string; the plan itself carries no prose.
enum PlanReason {
  dueReview,
  confusions,
  weakSymbols,

  /// Long enough (>= the course minimum) to unlock the next lesson.
  courseChallenge,

  /// Extended beyond its time share so it can still unlock a lesson.
  courseExtended,

  /// Too short to unlock; consolidates the lesson.
  courseConsolidate,

  /// The course moved on after the plan was made: this step practises the
  /// old lesson and cannot unlock the new one.
  courseOutdated,
  sendRhythm;

  static PlanReason parse(String? name) => values.firstWhere(
    (v) => v.name == name,
    orElse: () => PlanReason.courseConsolidate,
  );
}

/// The speeds a plan was frozen with.
final class PlanSettings {
  const PlanSettings({
    required this.characterWpm,
    required this.effectiveWpm,
    required this.toneHz,
    required this.groupSize,
  });

  final double characterWpm;
  final double effectiveWpm;
  final double toneHz;
  final int groupSize;

  Map<String, Object?> toJson() => <String, Object?>{
    'characterWpm': characterWpm,
    'effectiveWpm': effectiveWpm,
    'toneHz': toneHz,
    'groupSize': groupSize,
  };

  factory PlanSettings.fromJson(Map<String, Object?> json) => PlanSettings(
    characterWpm: (json['characterWpm'] as num).toDouble(),
    effectiveWpm: (json['effectiveWpm'] as num).toDouble(),
    toneHz: (json['toneHz'] as num).toDouble(),
    groupSize: (json['groupSize'] as num).toInt(),
  );

  @override
  bool operator ==(Object other) =>
      other is PlanSettings &&
      other.characterWpm == characterWpm &&
      other.effectiveWpm == effectiveWpm &&
      other.toneHz == toneHz &&
      other.groupSize == groupSize;

  @override
  int get hashCode =>
      Object.hash(characterWpm, effectiveWpm, toneHz, groupSize);
}

/// One step of a [DailyPlan].
final class PlanStep {
  PlanStep({
    required this.id,
    required this.kind,
    required List<String> pool,
    required this.minutes,
    required this.charBudget,
    required this.lesson,
    required this.reason,
    this.unlockEligible = false,
    this.state = PlanStepState.pending,
    this.resultRef,
    this.accuracy,
    this.stale = false,
    this.seed = 0,
    this.settings,
  }) : pool = List<String>.unmodifiable(pool);

  /// Stable per-step seed: reopening the step plays the same content even
  /// after other steps were refreshed or reordered.
  final int seed;

  /// Speeds frozen when the step started (null until then: the plan's
  /// current settings apply).
  final PlanSettings? settings;

  /// Stable within the plan (`<planId>/<index>`).
  final String id;
  final PlanStepKind kind;

  /// Symbols the step drills (send steps: symbols a target may use).
  final List<String> pool;

  /// Time share of the plan budget, in minutes.
  final double minutes;

  /// Symbols to copy (receive steps) or targets to key (send steps).
  final int charBudget;

  /// Koch lesson the step was made for.
  final int lesson;
  final PlanReason reason;

  /// Whether passing this step may unlock the next lesson.
  final bool unlockEligible;
  final PlanStepState state;

  /// Exercise id of the attempt that completed the step.
  final String? resultRef;

  /// Strict accuracy of that attempt (null for sending).
  final double? accuracy;

  /// Lesson or speed changed after planning; the step should be refreshed
  /// before it starts.
  final bool stale;

  bool get isDone => state == PlanStepState.done;

  PlanStep copyWith({
    PlanStepState? state,
    String? resultRef,
    double? accuracy,
    bool? stale,
    PlanReason? reason,
    bool? unlockEligible,
    PlanSettings? settings,
  }) => PlanStep(
    id: id,
    kind: kind,
    pool: pool,
    minutes: minutes,
    charBudget: charBudget,
    lesson: lesson,
    reason: reason ?? this.reason,
    unlockEligible: unlockEligible ?? this.unlockEligible,
    state: state ?? this.state,
    resultRef: resultRef ?? this.resultRef,
    accuracy: accuracy ?? this.accuracy,
    stale: stale ?? this.stale,
    seed: seed,
    settings: settings ?? this.settings,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'kind': kind.name,
    'pool': pool,
    'minutes': minutes,
    'charBudget': charBudget,
    'lesson': lesson,
    'reason': reason.name,
    'unlockEligible': unlockEligible,
    'state': state.name,
    'resultRef': resultRef,
    'accuracy': accuracy,
    'stale': stale,
    'seed': seed,
    if (settings != null) 'settings': settings!.toJson(),
  };

  factory PlanStep.fromJson(Map<String, Object?> json) => PlanStep(
    id: json['id'] as String,
    kind: PlanStepKind.parse(json['kind'] as String?),
    pool: (json['pool'] as List<Object?>).cast<String>(),
    minutes: (json['minutes'] as num).toDouble(),
    charBudget: (json['charBudget'] as num).toInt(),
    lesson: (json['lesson'] as num).toInt(),
    reason: PlanReason.parse(json['reason'] as String?),
    unlockEligible: json['unlockEligible'] as bool? ?? false,
    state: PlanStepState.parse(json['state'] as String?),
    resultRef: json['resultRef'] as String?,
    accuracy: (json['accuracy'] as num?)?.toDouble(),
    stale: json['stale'] as bool? ?? false,
    seed: (json['seed'] as num?)?.toInt() ?? 0,
    settings: json['settings'] is Map<String, Object?>
        ? PlanSettings.fromJson(json['settings']! as Map<String, Object?>)
        : null,
  );
}

/// A day's practice plan. Content, speeds and seed are frozen when it is
/// made; completing steps never regenerates it.
final class DailyPlan {
  DailyPlan({
    required this.id,
    required this.date,
    required this.profileKey,
    required this.seed,
    required this.budgetMinutes,
    required this.settings,
    required List<PlanStep> steps,
  }) : steps = List<PlanStep>.unmodifiable(steps);

  final String id;

  /// Local calendar day, `yyyy-mm-dd`.
  final String date;
  final String profileKey;
  final int seed;
  final int budgetMinutes;
  final PlanSettings settings;
  final List<PlanStep> steps;

  static String dateKey(DateTime local) =>
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';

  bool isFor(DateTime now) => date == dateKey(now);

  bool get isComplete => steps.every((s) => s.isDone);

  int get doneCount => steps.where((s) => s.isDone).length;

  double get estimatedMinutes => steps.fold(0.0, (a, s) => a + s.minutes);

  /// The first step not done yet, or null when complete.
  PlanStep? get nextStep {
    for (final step in steps) {
      if (!step.isDone) return step;
    }
    return null;
  }

  PlanStep? stepById(String id) {
    for (final step in steps) {
      if (step.id == id) return step;
    }
    return null;
  }

  DailyPlan _replace(String stepId, PlanStep Function(PlanStep) update) =>
      DailyPlan(
        id: id,
        date: date,
        profileKey: profileKey,
        seed: seed,
        budgetMinutes: budgetMinutes,
        settings: settings,
        steps: [for (final s in steps) s.id == stepId ? update(s) : s],
      );

  DailyPlan withSteps(List<PlanStep> next) => DailyPlan(
    id: id,
    date: date,
    profileKey: profileKey,
    seed: seed,
    budgetMinutes: budgetMinutes,
    settings: settings,
    steps: next,
  );

  /// Marks [stepId] started: its content (seed, pool) and speeds are now
  /// frozen on the step itself.
  DailyPlan start(String stepId) => _replace(
    stepId,
    (s) => s.isDone || s.state == PlanStepState.active
        ? s
        : s.copyWith(state: PlanStepState.active, settings: settings),
  );

  /// The speeds [step] runs at: its frozen snapshot once started.
  PlanSettings settingsOf(PlanStep step) => step.settings ?? settings;

  /// The plan with new current speeds and budget (for steps not started).
  DailyPlan withSettings(PlanSettings next, int budget) => DailyPlan(
    id: id,
    date: date,
    profileKey: profileKey,
    seed: seed,
    budgetMinutes: budget,
    settings: next,
    steps: steps,
  );

  /// Marks [stepId] done with the exercise that completed it. Completing an
  /// already done step changes nothing (no double credit).
  DailyPlan complete(
    String stepId, {
    required String exerciseId,
    double? accuracy,
  }) => _replace(
    stepId,
    (s) => s.isDone
        ? s
        : s.copyWith(
            state: PlanStepState.done,
            resultRef: exerciseId,
            accuracy: accuracy,
          ),
  );

  /// Flags steps that have not started yet as stale (lesson or speed changed).
  DailyPlan markPendingStale() => withSteps([
    for (final s in steps)
      s.state == PlanStepState.pending ? s.copyWith(stale: true) : s,
  ]);

  bool get hasStaleSteps => steps.any((s) => s.stale && !s.isDone);

  Map<String, Object?> toJson() => <String, Object?>{
    'v': 1,
    'id': id,
    'date': date,
    'profileKey': profileKey,
    'seed': seed,
    'budgetMinutes': budgetMinutes,
    'settings': settings.toJson(),
    'steps': steps.map((s) => s.toJson()).toList(),
  };

  factory DailyPlan.fromJson(Map<String, Object?> json) {
    final settings = PlanSettings.fromJson(
      json['settings']! as Map<String, Object?>,
    );
    return DailyPlan(
      id: json['id'] as String,
      date: json['date'] as String,
      profileKey: json['profileKey'] as String? ?? '',
      seed: (json['seed'] as num).toInt(),
      budgetMinutes: (json['budgetMinutes'] as num).toInt(),
      settings: settings,
      steps: [
        for (final raw in json['steps']! as List<Object?>)
          _withSnapshot(
            PlanStep.fromJson(raw! as Map<String, Object?>),
            settings,
          ),
      ],
    );
  }

  /// Plans saved before steps carried their own speeds: an already started
  /// step ran at the plan's speeds, which were never refreshed back then.
  static PlanStep _withSnapshot(PlanStep step, PlanSettings planSettings) =>
      step.state != PlanStepState.pending && step.settings == null
      ? step.copyWith(settings: planSettings)
      : step;
}

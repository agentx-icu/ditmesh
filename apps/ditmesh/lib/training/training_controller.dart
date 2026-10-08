import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_trainer/morse_trainer.dart';

import 'drill_catalog.dart';
import 'exercise_outcome.dart';
import 'receive_session.dart';
import 'send_session.dart';
import 'training_settings.dart';
import 'training_doc_store.dart';
import 'training_settings_store.dart';

export 'exercise_outcome.dart';
export 'receive_recording.dart';
export 'send_practice_start.dart';

/// Learner state for the Learn tab: loads progress and settings, exposes the
/// Koch position, SRS due list and streak, starts sessions and records their
/// results. Pure logic on top of the stores; time and randomness are
/// injected so tests replay deterministically.
final class TrainingController extends ChangeNotifier {
  TrainingController({
    required TrainerStore progressStore,
    required TrainingSettingsStore settingsStore,
    KochCourse? course,
    DateTime Function()? now,
    Random? random,
    this.profileKey = '',
    TrainingDocStore? docs,
  }) : _docs = docs ?? InMemoryTrainingDocStore(),
       _progressStore = progressStore,
       _settingsStore = settingsStore,
       course = course ?? KochCourse(),
       _now = now ?? DateTime.now,
       _random = random ?? Random();

  /// Symbols one send-practice target contains.
  static const int sendTargetChars = 5;

  /// Lesson from which QSO drills are offered (they need most letters).
  static const int qsoFromLesson = DrillCatalog.qsoFromLesson;

  /// Abbreviations / Q-codes needed before that drill is offered.
  static const int minShorthandWords = DrillCatalog.minShorthandWords;

  final TrainerStore _progressStore;
  final TrainingSettingsStore _settingsStore;
  final TrainingDocStore _docs;
  final KochCourse course;

  /// The learning profile this controller belongs to (identity public key,
  /// or `guest`); plans are only executed by their own profile.
  final String profileKey;
  final DateTime Function() _now;
  final Random _random;

  TrainerProgress _progress = TrainerProgress();
  TrainingSettings _settings = TrainingSettings.defaults;
  TrainingSettings _savedSettings = TrainingSettings.defaults;
  bool _loaded = false;
  bool _disposed = false;
  Object? _loadError;
  Future<void> _writes = Future<void>.value();
  final Map<Object, (Object, StackTrace)> _writeErrors = {};

  bool get isLoaded => _loaded;

  /// Disposed: its profile was switched or replaced.
  bool get isDisposed => _disposed;

  /// Set when [load] could not read the stores; the controller then runs on
  /// defaults and the next save overwrites whatever was unreadable.
  Object? get loadError => _loadError;

  TrainerProgress get progress => _progress;
  TrainingSettings get settings => _settings;
  TrainerSettings get trainerSettings => _settings.trainer;

  DateTime now() => _now();

  /// The injected randomness (plans and simulators seed from it).
  Random get random => _random;

  DrillCatalog get _catalog => DrillCatalog(
    course: course,
    progress: _progress,
    settings: trainerSettings,
  );

  // ---------------------------------------------------------------------------
  // Lifecycle

  Future<void> load() async {
    _ensureActive();
    try {
      final progress = await _progressStore.load();
      final settings = await _settingsStore.load();
      if (_disposed) return;
      _progress = _clampLesson(progress ?? TrainerProgress());
      _settings = settings ?? TrainingSettings.defaults;
      _savedSettings = _settings;
      _loadError = null;
    } on Object catch (error) {
      if (_disposed) return;
      _loadError = error;
      _progress = TrainerProgress();
      _settings = TrainingSettings.defaults;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> updateSettings(TrainingSettings settings) async {
    _ensureActive();
    if (settings == _settings) {
      return;
    }
    final speedChanged =
        settings.trainer.characterWpm != _settings.trainer.characterWpm ||
        settings.trainer.farnsworthWpm != _settings.trainer.farnsworthWpm;
    _settings = settings;
    if (speedChanged) _markPlanStale();
    final save = _persist(_settingsStore, () async {
      await _settingsStore.save(settings);
      _savedSettings = settings;
    });
    notifyListeners();
    try {
      await save;
    } on Object {
      if (!_disposed && identical(_settings, settings)) {
        _settings = _savedSettings;
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> setDailyGoal(int chars) =>
      _commit(_progress.copyWith(dailyGoalChars: chars));

  /// Jumps to [lesson] (clamped); for the lesson picker.
  Future<void> setLesson(int lesson) {
    final clamped = course.clampLesson(lesson);
    var next = _progress.withLesson(clamped);
    final plan = next.dailyPlan;
    if (clamped != _progress.currentLesson && plan != null) {
      next = next.copyWith(dailyPlan: plan.markPendingStale());
    }
    return _commit(next);
  }

  /// Commits [update] of the current progress (plans, advice keys).
  Future<void> commitProgress(
    TrainerProgress Function(TrainerProgress progress) update,
  ) => _commit(update(_progress));

  Future<void> resetProgress() async {
    _ensureActive();
    _progress = TrainerProgress();
    final clear = _persist(_progressStore, _progressStore.clear);
    notifyListeners();
    await clear;
  }

  /// Reads a training document (drafts, materials, details).
  Future<Map<String, Object?>?> readDoc(String name) async {
    await _writes;
    return _docs.read(name);
  }

  /// Writes a document in order with every other training write, so
  /// [flush] covers it.
  Future<void> writeDoc(String name, Map<String, Object?> json) {
    _ensureActiveOrInTxn();
    return _persist(_docs, () => _docs.write(name, json));
  }

  Future<void> deleteDoc(String name) {
    _ensureActiveOrInTxn();
    return _persist(_docs, () => _docs.delete(name));
  }

  Future<void> _docTxn = Future<void>.value();

  /// Runs a read-modify-write of training documents with no other
  /// transaction in between (concurrent saves would otherwise both read
  /// the same snapshot and the last write would drop the other change).
  Future<T> docTransaction<T>(Future<T> Function() body) {
    _ensureActive();
    // A transaction accepted before disposal may still finish its writes
    // (flush waits for it); the zone marks calls made from inside it.
    final result = _docTxn.then(
      (_) => runZoned(body, zoneValues: <Object, Object>{_txnKey: this}),
    );
    _docTxn = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<List<String>> docNames() async {
    await _writes;
    return _docs.names();
  }

  /// Durability barrier used before backgrounding, backup or replacement.
  Future<void> flush() async {
    // Document transactions enqueue their writes when they run: wait for
    // them first, then for every queued write.
    await _docTxn;
    await _writes;
    if (_writeErrors.isNotEmpty) {
      final (error, stack) = _writeErrors.values.first;
      Error.throwWithStackTrace(error, stack);
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Lesson view

  int get currentLesson => _progress.currentLesson;
  int get lessonCount => course.lessonCount;
  bool get isCourseComplete => course.isLastLesson(currentLesson);

  /// Every symbol taught up to and including the current lesson.
  List<String> get learnedChars => course.charsForLesson(currentLesson);

  /// The symbol the current lesson introduces.
  String get newestChar => course.newCharForLesson(currentLesson);

  /// Symbols the SRS wants drilled now, plus learned symbols never tracked.
  List<String> get dueChars => _progress.srs.dueOrNew(learnedChars, _now());

  int get streak => _progress.streakAsOf(_now());
  int get charsToday => _progress.charsOn(_now());
  int get dailyGoal => _progress.dailyGoalChars;
  double get dailyGoalFraction =>
      dailyGoal == 0 ? 1 : (charsToday / dailyGoal).clamp(0.0, 1.0);
  bool get dailyGoalMet => _progress.dailyGoalMet(_now());

  /// Accuracy of [char] over all recorded sessions, or null if never drilled.
  double? accuracyOf(String char) => _progress.charStats[char]?.accuracy;

  /// Drill kinds the learned set can support right now.
  List<ReceiveDrillKind> get availableReceiveKinds {
    final chars = learnedChars;
    final catalog = _catalog;
    return <ReceiveDrillKind>[
      for (final kind in ReceiveDrillKind.values)
        if (kind != ReceiveDrillKind.review &&
            catalog.drillFor(kind, chars) != null)
          kind,
    ];
  }

  // ---------------------------------------------------------------------------
  // Sessions

  /// The Koch lesson drill: weighted random groups over the learned set.
  ReceiveSession startLessonSession() =>
      startReceiveSession(ReceiveDrillKind.groups);

  /// [preset] other than clear plays every round under simulated radio
  /// conditions (F11) at the learner's own speeds; such a session never
  /// counts toward the lesson.
  ReceiveSession startReceiveSession(
    ReceiveDrillKind kind, {
    RadioPreset preset = RadioPreset.clear,
  }) {
    if (kind == ReceiveDrillKind.review) {
      return startReviewSession();
    }
    final chars = learnedChars;
    final t = trainerSettings;
    final generator = _catalog.generatorFor(kind, chars);
    final timing = t.toTiming();
    final conditions = preset == RadioPreset.clear
        ? null
        : RadioScenario.preset(
            preset,
            seed: _random.nextInt(1 << 31),
            characterWpm: timing.wpm,
            effectiveWpm: timing.farnsworthWpm ?? timing.wpm,
            toneHz: t.toneHz,
          );
    return ReceiveSession(
      kind: kind,
      generator: generator,
      // QSO scripts are fixed text (names, rigs, <BT>, <SK>), not filtered
      // to the lesson, so their keypad offers every symbol of the course.
      chars: generator is QsoDrill ? course.order : chars,
      timing: timing,
      charBudget: t.sessionLengthChars,
      timeBudget: t.sessionLengthSeconds == null
          ? null
          : Duration(seconds: t.sessionLengthSeconds!),
      lesson: currentLesson,
      countsTowardLesson: conditions == null,
      conditions: conditions,
      random: _random,
      now: _now,
    );
  }

  /// SRS review: due symbols only (falls back to the whole learned set when
  /// nothing is due), weighted by weakness. Never advances the lesson.
  ReceiveSession startReviewSession() {
    final due = dueChars;
    final pool = due.length >= 2 ? due : learnedChars;
    final t = trainerSettings;
    return ReceiveSession(
      kind: ReceiveDrillKind.review,
      generator: RandomGroupsDrill(
        chars: pool,
        groupCount: 1,
        groupSize: t.groupSize,
        weights: _catalog.weights(),
      ),
      chars: pool,
      timing: t.toTiming(),
      charBudget: t.sessionLengthChars,
      timeBudget: t.sessionLengthSeconds == null
          ? null
          : Duration(seconds: t.sessionLengthSeconds!),
      lesson: currentLesson,
      random: _random,
      now: _now,
    );
  }

  /// The one commit path for every scored exercise (spec §3): builds the
  /// exercise record, applies [CreditPolicy], completes the daily-plan step
  /// in the same write and, for course sessions with unlock credit, the
  /// Koch rule. A repeated [id] credits nothing (`duplicate`).
  Future<ReceiveOutcome> recordExercise({
    required SessionScore score,
    required String id,
    required ExerciseSource source,
    required Set<Assistance> assistance,
    bool answered = true,
    bool completed = true,
    int? lesson,
    MorseTiming? timing,
    Duration? active,
    String? planStepId,
    String? sourceRef,
    String? detailRef,
    Set<String>? learned,
    bool countsTowardLesson = false,
    RadioScenario? conditions,
  }) async {
    final (next, outcome) = applyExercise(
      _progress,
      course: course,
      now: _now(),
      score: score,
      id: id,
      source: source,
      assistance: assistance,
      answered: answered,
      completed: completed,
      lesson: lesson,
      timing: timing ?? trainerSettings.toTiming(),
      toneHz: _settings.trainer.toneHz,
      active: active,
      planStepId: planStepId,
      sourceRef: sourceRef,
      detailRef: detailRef,
      learned: learned ?? learnedChars.toSet(),
      countsTowardLesson: countsTowardLesson,
      conditions: conditions,
    );
    if (outcome.duplicate) {
      // Already credited in memory; "saved" only when it is on disk too.
      final unsaved = _writeErrors.containsKey(_progressStore);
      return outcome.withSaved(!unsaved || await retryProgressSave());
    }
    final saved = await _commitKeepingResult(next);
    return outcome.withSaved(saved);
  }

  void _markPlanStale() {
    final plan = _progress.dailyPlan;
    if (plan == null || !plan.isFor(_now())) return;
    _progress = _progress.copyWith(dailyPlan: plan.markPendingStale());
    final next = _progress;
    unawaited(
      _persist(
        _progressStore,
        () => _progressStore.save(next),
      ).then((_) {}, onError: (Object _) {}),
    );
  }

  /// Credits a finished send session to history, streak and the daily goal.
  ///
  /// Sending accuracy is a different skill from copying, so the per-symbol
  /// receive statistics, SRS boxes and confusion matrix are left untouched;
  /// only the history entry (and the streak derived from it) is added.
  Future<SendOutcome> recordSendSession(
    SendSession session, {
    String? detailRef,
  }) async {
    final score = session.scoreForHistory();
    final outcome = await recordExercise(
      score: score,
      id: session.id,
      source: ExerciseSource.send,
      assistance: const <Assistance>{},
      answered: session.hasInput,
      lesson: session.lesson,
      timing: session.nominalTiming,
      active: session.activeElapsed,
      planStepId: session.planStepId,
      detailRef: detailRef,
    );
    return SendOutcome(score: score, saved: outcome.saved);
  }

  /// Writes the current in-memory progress again after a failed save. Never
  /// re-applies a session, so retrying cannot credit one twice. Returns
  /// whether the write succeeded.
  Future<bool> retryProgressSave() async {
    _ensureActive();
    final progress = _progress;
    try {
      await _persist(_progressStore, () => _progressStore.save(progress));
      return true;
    } on Object {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Internals

  TrainerProgress _clampLesson(TrainerProgress progress) {
    final clamped = course.clampLesson(progress.currentLesson);
    return clamped == progress.currentLesson
        ? progress
        : progress.withLesson(clamped);
  }

  /// [_commit] for a finished session: the in-memory progress keeps the
  /// session even when the write fails, so the screen can still show the
  /// result and offer [retryProgressSave]. Returns whether it was saved.
  Future<bool> _commitKeepingResult(TrainerProgress next) async {
    _ensureActive();
    try {
      await _commit(next);
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> _commit(TrainerProgress next) async {
    _ensureActive();
    _progress = next;
    // Enqueue before notification: a listener can reset or record another
    // session synchronously, and that later operation must stay later.
    final save = _persist(_progressStore, () => _progressStore.save(next));
    notifyListeners();
    await save;
  }

  static final Object _txnKey = Object();

  void _ensureActiveOrInTxn() {
    if (identical(Zone.current[_txnKey], this)) return;
    _ensureActive();
  }

  void _ensureActive() {
    if (_disposed) throw StateError('training controller disposed');
  }

  Future<void> _persist(Object store, Future<void> Function() operation) {
    final result = _writes.then((_) => operation());
    _writes = result.then<void>(
      (_) {
        _writeErrors.remove(store);
      },
      onError: (Object error, StackTrace stack) {
        _writeErrors[store] = (error, stack);
      },
    );
    return result;
  }
}

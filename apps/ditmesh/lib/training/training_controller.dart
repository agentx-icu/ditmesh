import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_trainer/morse_trainer.dart';

import 'exercise_outcome.dart';
import 'training_settings.dart';
import 'training_doc_store.dart';
import 'training_settings_store.dart';

export 'exercise_outcome.dart';
export 'receive_recording.dart';

/// Learner state behind chat copy, group practice and the recording
/// workbench: loads progress and settings, exposes the learned symbol set
/// and records scored exercises. Pure logic on top of the stores; time and
/// randomness are injected so tests replay deterministically.
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

  final TrainerStore _progressStore;
  final TrainingSettingsStore _settingsStore;
  final TrainingDocStore _docs;
  final KochCourse course;

  /// The learning profile this controller belongs to (identity public key,
  /// or `guest`).
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

  /// The injected randomness (focused drills seed from it).
  Random get random => _random;

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
    _settings = settings;
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

  /// Reads a training document (group practice, audio materials).
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
  // Learned set

  int get currentLesson => _progress.currentLesson;

  /// Every symbol taught up to and including the current lesson.
  List<String> get learnedChars => course.charsForLesson(currentLesson);

  // ---------------------------------------------------------------------------
  // Recording

  /// The one commit path for every scored exercise (spec §3): builds the
  /// exercise record and applies [CreditPolicy]. A repeated [id] credits
  /// nothing (`duplicate`).
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
    String? sourceRef,
    Set<String>? learned,
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
      sourceRef: sourceRef,
      learned: learned ?? learnedChars.toSet(),
    );
    if (outcome.duplicate) {
      // Already credited in memory; "saved" only when it is on disk too.
      final unsaved = _writeErrors.containsKey(_progressStore);
      return outcome.withSaved(!unsaved || await retryProgressSave());
    }
    final saved = await _commitKeepingResult(next);
    return outcome.withSaved(saved);
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

  /// Commits a finished exercise: the in-memory progress keeps it even when
  /// the write fails, so the screen can still show the result and offer
  /// [retryProgressSave]. Returns whether it was saved.
  Future<bool> _commitKeepingResult(TrainerProgress next) async {
    _ensureActive();
    _progress = next;
    // Enqueue before notification: a listener can record another exercise
    // synchronously, and that later operation must stay later.
    final save = _persist(_progressStore, () => _progressStore.save(next));
    notifyListeners();
    try {
      await save;
      return true;
    } on Object {
      return false;
    }
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

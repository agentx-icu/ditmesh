import 'dart:math';

import 'package:morse_core/morse_core.dart';
import 'package:morse_trainer/morse_trainer.dart';

/// What a receive (copy) session drills.
enum ReceiveDrillKind {
  /// Koch random groups from the learned set (the lesson drill).
  groups,

  /// One symbol per round: instant character recognition.
  characters,

  /// Common words that fit the learned set.
  words,

  /// CW abbreviations and Q-codes that fit the learned set.
  abbreviations,

  /// Digit groups from the learned digits.
  numbers,

  /// Amateur callsigns built from the learned set.
  callsigns,

  /// Minimal pairs: the trainee's most confused symbols and pattern
  /// neighbours (S/H, U/V) drilled against each other.
  confusables,

  /// Templated QSO lines (needs most of the alphabet).
  qso,

  /// Contest exchanges with cut numbers (needs most of the alphabet).
  contest,

  /// SRS review: symbols that are due, weighted by weakness.
  review;

  /// Label stored as `Drill.kind` / `SessionScore.drillKind`.
  String get label => name;

  static ReceiveDrillKind parse(String? name) {
    for (final kind in values) {
      if (kind.name == name) {
        return kind;
      }
    }
    return ReceiveDrillKind.groups;
  }
}

/// One played-and-answered chunk of a [ReceiveSession].
final class ReceiveRound {
  const ReceiveRound({
    required this.index,
    required this.drill,
    required this.answer,
    required this.score,
  });

  /// 0-based position in the session.
  final int index;
  final Drill drill;
  final String answer;

  /// Alignment-based score of this round alone.
  final SessionScore score;
}

/// A receive drill in progress: a sequence of short rounds (one group, one
/// word, one callsign ...) until the character or time budget is spent.
///
/// Pure logic, no timers: the UI plays [currentTimeline], collects the copy,
/// calls [submit], and when [isComplete] calls [finish] to get the session
/// [SessionScore] the controller records. Time only moves through [now].
final class ReceiveSession {
  ReceiveSession({
    required this.kind,
    required DrillGenerator generator,
    required Iterable<String> chars,
    required this.timing,
    required this.charBudget,
    required Random random,
    required DateTime Function() now,
    this.lesson,
    this.countsTowardLesson = false,
    this.timeBudget,
    ExerciseSource? source,
    this.planStepId,
    this.sourceRef,
    this.learnedChars,
    this.conditions,
    String? id,
  }) : assert(charBudget > 0, 'charBudget must be positive'),
       assert(
         conditions == null || !conditions.isClear,
         'clear playback is ordinary practice: pass no conditions',
       ),
       _generator = generator,
       _random = random,
       _now = now,
       chars = List<String>.unmodifiable(chars),
       source =
           source ??
           (conditions != null
               ? ExerciseSource.conditions
               : countsTowardLesson
               ? ExerciseSource.course
               : kind == ReceiveDrillKind.review
               ? ExerciseSource.review
               : ExerciseSource.focus),
       startedAt = now() {
    // Not from the drill random: ids must not shift a seeded drill.
    this.id = id ?? ExerciseIds.next(startedAt, Random());
    _current = _generator.generate(_random);
  }

  /// Stable exercise id: saving again (retry) keeps it, a new session gets
  /// a new one.
  late final String id;

  final ExerciseSource source;

  /// Daily-plan step this session executes, if any.
  final String? planStepId;

  /// Local origin reference (chat message, material entry).
  final String? sourceRef;

  /// Symbols that may enter learned-symbol statistics; null = the
  /// controller's learned set.
  final Set<String>? learnedChars;

  /// Simulated radio conditions every round is played under (F11); null
  /// for ordinary clean playback. Round `i` uses `conditions.forRound(i)`.
  final RadioScenario? conditions;

  /// The scenario of the round waiting to be answered.
  RadioScenario? get currentConditions => conditions?.forRound(_rounds.length);

  final Set<Assistance> _assistance = <Assistance>{};
  Duration _paused = Duration.zero;
  DateTime? _pausedAt;

  /// Help used so far. Revealing can never be taken back: once assisted,
  /// the attempt stays assisted.
  Set<Assistance> get assistance => Set<Assistance>.unmodifiable(_assistance);

  bool get isAssisted => _assistance.isNotEmpty;

  void markAssistance(Assistance kind) {
    if (!isFinished) _assistance.add(kind);
  }

  /// A replay of the current round after its first playback.
  void markReplay() => markAssistance(Assistance.replay);

  /// Background / pause: excluded from [activeElapsed].
  void pause() => _pausedAt ??= _now();

  void resume() {
    final at = _pausedAt;
    if (at == null) return;
    _paused += _now().difference(at);
    _pausedAt = null;
  }

  /// Time spent practising (pauses and background excluded).
  Duration get activeElapsed {
    final pausedNow = _pausedAt == null
        ? Duration.zero
        : _now().difference(_pausedAt!);
    final active = elapsed - _paused - pausedNow;
    return active.isNegative ? Duration.zero : active;
  }

  final ReceiveDrillKind kind;
  final DrillGenerator _generator;
  final Random _random;
  final DateTime Function() _now;

  /// Symbols the trainee may answer with (the on-screen keypad set).
  final List<String> chars;

  /// Timing every round is played at.
  final MorseTiming timing;

  /// Symbols to play before the session ends (whole rounds; the last round
  /// may overshoot).
  final int charBudget;

  /// Optional wall-clock cap; the session ends after the round in progress.
  final Duration? timeBudget;

  /// Koch lesson this session belongs to, if any (review sessions have none).
  final int? lesson;

  /// Whether a pass on this session may unlock the next Koch lesson.
  final bool countsTowardLesson;

  final DateTime startedAt;

  final List<ReceiveRound> _rounds = <ReceiveRound>[];
  Drill _current = Drill.fromText('');
  SessionScore? _final;

  List<ReceiveRound> get rounds => List<ReceiveRound>.unmodifiable(_rounds);

  /// The round waiting to be answered.
  Drill get currentDrill => _current;

  /// Playable timeline of [currentDrill] at [timing].
  List<MorseElement> get currentTimeline =>
      MorseEncoder.encode(_current.text, timing);

  int get roundCount => _rounds.length;

  /// Whether any round was answered with at least one Morse symbol. Blank
  /// submissions are not answers: they earn no credit (spec §3.3).
  bool get hasAnswers => _rounds.any((r) => MorseSupport.hasSymbols(r.answer));

  /// Symbols sent so far (answered rounds only).
  int get charsAnswered =>
      _rounds.fold<int>(0, (sum, r) => sum + r.score.totalChars);

  /// 0..1 progress towards [charBudget].
  double get progress => (charsAnswered / charBudget).clamp(0.0, 1.0);

  Duration get elapsed => _now().difference(startedAt);

  bool get isFinished => _final != null;

  /// True once the budget is spent; the UI should call [finish].
  bool get isComplete {
    if (isFinished) {
      return true;
    }
    if (charsAnswered >= charBudget) {
      return true;
    }
    final cap = timeBudget;
    return cap != null && elapsed >= cap;
  }

  /// Running accuracy over answered rounds (0 before the first answer).
  double get runningAccuracy {
    var total = 0;
    var correct = 0;
    for (final r in _rounds) {
      total += r.score.totalChars;
      correct += r.score.correctChars;
    }
    return total == 0 ? 0 : correct / total;
  }

  /// Scores [answer] against the current round and, unless the budget is now
  /// spent, generates the next round.
  ReceiveRound submit(String answer) {
    if (isFinished) {
      throw StateError('session already finished');
    }
    final score = SessionScore.evaluate(
      _current.text,
      answer,
      at: _now(),
      lesson: lesson,
      drillKind: kind.label,
    );
    final round = ReceiveRound(
      index: _rounds.length,
      drill: _current,
      answer: answer,
      score: score,
    );
    _rounds.add(round);
    if (!isComplete) {
      _current = _generator.generate(_random);
    }
    return round;
  }

  /// Aggregates every round into one [SessionScore]. Idempotent.
  ///
  /// Rounds are joined with word gaps so the alignment works over the whole
  /// session; a dropped or extra symbol in one round can only shift that
  /// round's neighbours, never the whole copy.
  SessionScore finish() {
    final existing = _final;
    if (existing != null) {
      return existing;
    }
    final target = _rounds.map((r) => r.drill.text).join(' ');
    final answer = _rounds.map((r) => r.answer).join(' ');
    final score = SessionScore.evaluate(
      target,
      answer,
      at: _now(),
      elapsed: elapsed,
      lesson: lesson,
      drillKind: kind.label,
    );
    _final = score;
    return score;
  }

  /// Symbols copied below 100 % in this session, worst first.
  List<String> weakChars() => (_final ?? finish()).weakChars();

  /// Confusions observed so far as `(target, answered)` pairs with counts,
  /// most frequent first. The answered side is `''` for a missed symbol.
  List<(String, String, int)> confusionPairs({int limit = 5}) {
    final counts = <(String, String), int>{};
    for (final r in _rounds) {
      final m = r.score.confusion;
      for (final target in m.targets) {
        for (final entry in m.rowFor(target).entries) {
          if (entry.key == target || target == ConfusionMatrix.missed) {
            continue;
          }
          final key = (target, entry.key);
          counts[key] = (counts[key] ?? 0) + entry.value;
        }
      }
    }
    final pairs = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) {
          return byCount;
        }
        final byTarget = a.key.$1.compareTo(b.key.$1);
        return byTarget != 0 ? byTarget : a.key.$2.compareTo(b.key.$2);
      });
    return pairs
        .take(limit)
        .map((e) => (e.key.$1, e.key.$2, e.value))
        .toList(growable: false);
  }
}

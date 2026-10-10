import 'dart:math';

import 'package:morse_core/morse_core.dart';
import 'package:morse_trainer/morse_trainer.dart';

/// Label stored as `Drill.kind` / `SessionScore.drillKind` for receive
/// rounds (random groups over a symbol pool).
const String kReceiveDrillKind = 'groups';

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

/// A receive drill in progress: a sequence of short rounds (one group per
/// round) until the character budget is spent.
///
/// Pure logic, no timers: the UI plays [currentTimeline], collects the copy,
/// calls [submit], and when [isComplete] calls [finish] to get the session
/// [SessionScore] the controller records. Time only moves through [now].
final class ReceiveSession {
  ReceiveSession({
    required DrillGenerator generator,
    required Iterable<String> chars,
    required this.timing,
    required this.charBudget,
    required Random random,
    required DateTime Function() now,
    this.lesson,
    this.source = ExerciseSource.focus,
    String? id,
  }) : assert(charBudget > 0, 'charBudget must be positive'),
       _generator = generator,
       _random = random,
       _now = now,
       chars = List<String>.unmodifiable(chars),
       startedAt = now() {
    // Not from the drill random: ids must not shift a seeded drill.
    this.id = id ?? ExerciseIds.next(startedAt, Random());
    _current = _generator.generate(_random);
  }

  /// Stable exercise id: saving again (retry) keeps it, a new session gets
  /// a new one.
  late final String id;

  final ExerciseSource source;

  final Set<Assistance> _assistance = <Assistance>{};
  Duration _paused = Duration.zero;
  DateTime? _pausedAt;

  /// Help used so far. Revealing can never be taken back: once assisted,
  /// the attempt stays assisted.
  Set<Assistance> get assistance => Set<Assistance>.unmodifiable(_assistance);

  bool get isAssisted => _assistance.isNotEmpty;

  /// A replay of the current round after its first playback.
  void markReplay() {
    if (!isFinished) _assistance.add(Assistance.replay);
  }

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

  /// Koch lesson this session belongs to, if any.
  final int? lesson;

  final DateTime startedAt;

  final List<ReceiveRound> _rounds = <ReceiveRound>[];
  Drill _current = Drill.fromText('');
  SessionScore? _final;

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
  bool get isComplete => isFinished || charsAnswered >= charBudget;

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
      drillKind: kReceiveDrillKind,
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
      drillKind: kReceiveDrillKind,
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

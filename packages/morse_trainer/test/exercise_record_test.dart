import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime(2026, 10, 3, 9);

  SessionSummary record(
    SessionScore score, {
    String id = 'ex1',
    ExerciseSource source = ExerciseSource.review,
    Set<Assistance> assistance = const <Assistance>{},
  }) => SessionSummary.exercise(
    score,
    id: id,
    source: source,
    at: now,
    assistance: assistance,
    characterWpm: 20,
    effectiveWpm: 8,
    toneHz: 700,
  );

  group('CreditPolicy', () {
    test('course unassisted gets everything', () {
      final c = CreditPolicy.decide(
        source: ExerciseSource.course,
        completed: true,
        answered: true,
        assistance: const {},
      );
      expect(
        [c.activity, c.receiveStats, c.unlock, c.speedSample],
        [true, true, true, true],
      );
    });

    test('assisted practice is activity only', () {
      for (final source in ExerciseSource.values) {
        final c = CreditPolicy.decide(
          source: source,
          completed: true,
          answered: true,
          assistance: const {Assistance.replay},
        );
        expect(c.activity, isTrue, reason: source.name);
        expect(c.receiveStats || c.unlock || c.speedSample, isFalse);
      }
    });

    test('review/chat/material never unlock but feed stats', () {
      for (final source in [
        ExerciseSource.review,
        ExerciseSource.focus,
        ExerciseSource.chat,
        ExerciseSource.material,
      ]) {
        final c = CreditPolicy.decide(
          source: source,
          completed: true,
          answered: true,
          assistance: const {},
        );
        expect(c.unlock, isFalse);
        expect(c.receiveStats, isTrue);
      }
    });

    test('send, qso, placement, recording never touch receive stats', () {
      for (final source in [
        ExerciseSource.send,
        ExerciseSource.qso,
        ExerciseSource.placement,
        ExerciseSource.recording,
      ]) {
        final c = CreditPolicy.decide(
          source: source,
          completed: true,
          answered: true,
          assistance: const {},
        );
        expect(c.activity, isTrue);
        expect(c.receiveStats || c.unlock || c.speedSample, isFalse);
      }
    });

    test('unanswered or unfinished earns nothing', () {
      expect(
        CreditPolicy.decide(
          source: ExerciseSource.course,
          completed: true,
          answered: false,
          assistance: const {},
        ).activity,
        isFalse,
      );
      expect(
        CreditPolicy.decide(
          source: ExerciseSource.course,
          completed: false,
          answered: true,
          assistance: const {},
        ).activity,
        isFalse,
      );
    });
  });

  group('TrainerProgress.recordExercise', () {
    final score = SessionScore.evaluate('KMR XYZ', 'KMR XYQ');
    const credit = ExerciseCredit(
      activity: true,
      receiveStats: true,
      unlock: false,
      speedSample: true,
    );

    test('the same id is credited once, also after a JSON round trip', () {
      var p = TrainerProgress();
      p = p.recordExercise(score, record(score), credit: credit, now: now);
      final reloaded = TrainerProgress.fromJson(p.toJson());
      final again = reloaded.recordExercise(
        score,
        record(score),
        credit: credit,
        now: now,
      );
      expect(again.lifetimeSessions, 1);
      expect(again.history, hasLength(1));
      expect(again.charStats['K']!.attempts, 1);
    });

    test('a new id is a new attempt', () {
      var p = TrainerProgress();
      p = p.recordExercise(score, record(score), credit: credit, now: now);
      p = p.recordExercise(
        score,
        record(score, id: 'ex2'),
        credit: credit,
        now: now,
      );
      expect(p.lifetimeSessions, 2);
    });

    test('only learned symbols enter stats, confusion and SRS', () {
      final p = TrainerProgress().recordExercise(
        score,
        record(score),
        credit: credit,
        now: now,
        learned: {'K', 'M', 'R'},
      );
      expect(p.charStats.keys, unorderedEquals(['K', 'M', 'R']));
      expect(p.srs.contains('X'), isFalse);
      expect(p.confusion.targets, isNot(contains('Z')));
      // Activity still counts every symbol practised.
      expect(p.lifetimeChars, 6);
    });

    test('activity-only credit leaves receive statistics alone', () {
      final p = TrainerProgress().recordExercise(
        score,
        record(score, assistance: {Assistance.reveal}),
        credit: const ExerciseCredit(
          activity: true,
          receiveStats: false,
          unlock: false,
          speedSample: false,
        ),
        now: now,
      );
      expect(p.lifetimeSessions, 1);
      expect(p.charStats, isEmpty);
      expect(p.srs.cards, isEmpty);
    });

    test('trimming history keeps lifetime totals and the dedupe ids', () {
      var p = TrainerProgress(maxHistory: 2);
      for (var i = 0; i < 4; i++) {
        p = p.recordExercise(
          score,
          record(score, id: 'ex$i'),
          credit: credit,
          now: now,
        );
      }
      expect(p.history, hasLength(2));
      expect(p.lifetimeSessions, 4);
      final replay = p.recordExercise(
        score,
        record(score, id: 'ex0'),
        credit: credit,
        now: now,
      );
      expect(replay.lifetimeSessions, 4);
    });
  });

  test('parkable QSO ids survive de-duplication eviction', () {
    final score = SessionScore.evaluate('K', 'K');
    const credit = ExerciseCredit(
      activity: true,
      receiveStats: false,
      unlock: false,
      speedSample: false,
    );
    SessionSummary r(String id) => record(score, id: id);
    var p = TrainerProgress().recordExercise(
      score,
      r('qso_callCq_1'),
      credit: credit,
      now: now,
    );
    for (var i = 0; i < TrainerProgress.maxCommittedIds + 5; i++) {
      p = p.recordExercise(score, r('ex$i'), credit: credit, now: now);
    }
    expect(p.hasCommitted('qso_callCq_1'), isTrue);
    expect(p.hasCommitted('ex0'), isFalse);
  });

  group('SessionSummary exercise metadata', () {
    test('round-trips every field', () {
      final score = SessionScore.evaluate('PARIS', 'PARIIS');
      final s = SessionSummary.exercise(
        score,
        id: 'ex9',
        source: ExerciseSource.chat,
        at: now,
        assistance: {Assistance.hint},
        characterWpm: 20,
        effectiveWpm: 10,
        toneHz: 650,
        active: const Duration(seconds: 42),
        planStepId: 'p/1',
        sourceRef: 'chat:a/b/c',
      );
      final back = SessionSummary.fromJson(s.toJson());
      expect(back.id, 'ex9');
      expect(back.source, ExerciseSource.chat);
      expect(back.assistance, {Assistance.hint});
      expect(back.insertions, 1);
      expect(back.strictAccuracy, closeTo(5 / 6, 1e-9));
      expect(back.active, const Duration(seconds: 42));
      expect(back.perChar!['I']!.attempts, 1);
      expect(back.sourceRef, 'chat:a/b/c');
    });

    test('legacy summaries load with unknown metadata', () {
      final legacy = SessionSummary.fromJson({
        'at': now.toIso8601String(),
        'totalChars': 10,
        'correctChars': 9,
        'elapsedMs': 60000,
      });
      expect(legacy.id, isNull);
      expect(legacy.assistance, isNull);
      expect(legacy.isKnownUnassisted, isFalse);
      // Wall-clock elapsed is never relabelled as active time.
      expect(legacy.active, isNull);
      expect(legacy.toJson().containsKey('v'), isFalse);
    });
  });
}

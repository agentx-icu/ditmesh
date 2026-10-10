import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/chat_copy_session.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/training/training_settings.dart';

import 'helpers/test_controller.dart';

void main() {
  test('loads defaults when nothing is stored', () async {
    final t = await TestTraining.create();
    final c = t.controller;
    expect(c.isLoaded, isTrue);
    expect(c.loadError, isNull);
    expect(c.currentLesson, 1);
    expect(c.learnedChars, <String>['K', 'M']);
    expect(c.settings, TrainingSettings.defaults);
  });

  test('clamps an out-of-range stored lesson', () async {
    final t = await TestTraining.create(
      progress: TrainerProgress(currentLesson: 999),
    );
    expect(t.controller.currentLesson, 42);
  });

  test('a focus session drills only learned symbols from the list', () async {
    final t = await TestTraining.create(
      progress: TrainerProgress(currentLesson: 3),
    );
    final session = t.controller.startFocusSession(<String>['R', 'Z'])!;
    // Z is not learned; the pool is topped up to two learned symbols.
    expect(session.chars, <String>['R', 'S']);
    expect(session.source, ExerciseSource.focus);
    expect(session.lesson, 3);
    expect(session.currentDrill.chars, everyElement(isIn(session.chars)));
    expect(t.controller.startFocusSession(<String>['Z']), isNull);
  });

  test('seeded random makes focus sessions replayable', () async {
    final a = await TestTraining.create(seed: 7);
    final b = await TestTraining.create(seed: 7);
    expect(
      a.controller.startFocusSession(<String>['K'])!.currentDrill.text,
      b.controller.startFocusSession(<String>['K'])!.currentDrill.text,
    );
  });

  test('a perfect focus session records stats and saves', () async {
    final t = await TestTraining.create();
    final c = t.controller;
    final session = c.startFocusSession(<String>['K', 'M'])!;
    while (!session.isComplete) {
      session.submit(session.currentDrill.text);
    }
    final outcome = await c.recordReceiveSession(session);
    expect(outcome.passed, isTrue);
    expect(outcome.saved, isTrue);
    expect(c.currentLesson, 1, reason: 'focus practice never unlocks');
    expect(t.progressStore.saveCount, 1);
    final saved = await t.progressStore.load();
    expect(saved!.history.single.drillKind, 'groups');
    expect(saved.history.single.source, ExerciseSource.focus);
  });

  test('a failed focus session records confusions', () async {
    final t = await TestTraining.create(settings: kShortSettings);
    final c = t.controller;
    final session = c.startFocusSession(<String>['K', 'M'])!;
    while (!session.isComplete) {
      // Answer the wrong symbol every time.
      final wrong = session.currentDrill.text
          .split('')
          .map((ch) => ch == 'K' ? 'M' : (ch == 'M' ? 'K' : ch))
          .join();
      session.submit(wrong);
    }
    final outcome = await c.recordReceiveSession(session);
    expect(outcome.passed, isFalse);
    expect(
      c.progress.confusion.count('K', 'M') +
          c.progress.confusion.count('M', 'K'),
      greaterThan(0),
    );
    expect(c.progress.charStats.keys, containsAll(<String>['K', 'M']));
    expect(c.progress.sessionCount, 1);
  });

  test('a repeated exercise id credits nothing', () async {
    final t = await TestTraining.create();
    final c = t.controller;
    final score = SessionScore.evaluate('KM', 'KM', drillKind: 'chat');
    Future<ReceiveOutcome> record() => c.recordExercise(
      score: score,
      id: 'ex-1',
      source: ExerciseSource.chat,
      assistance: const <Assistance>{},
    );
    expect((await record()).duplicate, isFalse);
    final again = await record();
    expect(again.duplicate, isTrue);
    expect(again.saved, isTrue);
    expect(c.progress.sessionCount, 1);
  });

  test('updateSettings persists and notifies once per change', () async {
    final t = await TestTraining.create();
    final c = t.controller;
    var notifications = 0;
    c.addListener(() => notifications++);
    const next = TrainingSettings(soundEnabled: false, flashEnabled: true);
    await c.updateSettings(next);
    await c.updateSettings(next);
    expect(notifications, 1);
    expect(t.settingsStore.saveCount, 1);
    expect(await t.settingsStore.load(), next);
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/file_trainer_store.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/training/training_settings.dart';
import 'package:ditmesh/training/training_settings_store.dart';

final class _RetrySettingsStore implements TrainingSettingsStore {
  _RetrySettingsStore({this.failuresRemaining = 1});

  int failuresRemaining;
  int attempts = 0;
  TrainingSettings? saved;

  @override
  Future<TrainingSettings?> load() async => saved;

  @override
  Future<void> save(TrainingSettings settings) async {
    attempts++;
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw const FileSystemException('disk unavailable');
    }
    saved = settings;
  }

  @override
  Future<void> clear() async => saved = null;
}

final class _RetryProgressStore implements TrainerStore {
  int attempts = 0;
  TrainerProgress? saved;

  @override
  Future<TrainerProgress?> load() async => saved;

  @override
  Future<void> save(TrainerProgress progress) async {
    attempts++;
    if (attempts == 1) {
      throw const FileSystemException('progress disk unavailable');
    }
    saved = progress;
  }

  @override
  Future<void> clear() async => saved = null;
}

void main() {
  late Directory directory;
  late FileTrainerStore progressStore;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ditmesh_controller_');
    progressStore = FileTrainerStore.inDataDirectory(directory.path);
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  TrainingController controller({TrainingSettingsStore? settingsStore}) =>
      TrainingController(
        progressStore: progressStore,
        settingsStore: settingsStore ?? InMemoryTrainingSettingsStore(),
      );

  test(
    'a reset triggered by notification cannot be overwritten by its save',
    () async {
      final c = controller();
      await c.load();
      Future<void>? reset;
      c.addListener(() {
        if (reset == null) {
          // Set the marker before reset itself notifies.
          reset = Future<void>.value();
          reset = c.resetProgress();
        }
      });

      await c.setLesson(5);
      await reset;

      expect(c.currentLesson, 1);
      expect(
        await FileTrainerStore.inDataDirectory(directory.path).load(),
        isNull,
      );
      c.dispose();
    },
  );

  test('failed training settings save can retry the same selection', () async {
    final settings = _RetrySettingsStore();
    final c = controller(settingsStore: settings);
    const selection = TrainingSettings(flashEnabled: true);

    await expectLater(
      c.updateSettings(selection),
      throwsA(isA<FileSystemException>()),
    );
    await c.updateSettings(selection);

    expect(settings.attempts, 2);
    expect(settings.saved, selection);
    c.dispose();
  });

  test('disposed controller rejects late writes explicitly', () async {
    final c = controller();
    c.dispose();

    await expectLater(c.setLesson(5), throwsStateError);
    await expectLater(
      c.updateSettings(const TrainingSettings(flashEnabled: true)),
      throwsStateError,
    );
    expect(await progressStore.load(), isNull);
  });

  test(
    'overlapping failed settings changes revert to the saved selection',
    () async {
      final settings = _RetrySettingsStore(failuresRemaining: 2);
      final c = controller(settingsStore: settings);
      const first = TrainingSettings(flashEnabled: true);
      const second = TrainingSettings(hapticEnabled: true);

      await Future.wait(<Future<void>>[
        expectLater(
          c.updateSettings(first),
          throwsA(isA<FileSystemException>()),
        ),
        expectLater(
          c.updateSettings(second),
          throwsA(isA<FileSystemException>()),
        ),
      ]);

      expect(c.settings, TrainingSettings.defaults);
      await c.updateSettings(first);
      expect(settings.saved, first);
      c.dispose();
    },
  );

  test(
    'saving settings cannot hide an unsaved progress failure from flush',
    () async {
      final progress = _RetryProgressStore();
      final c = TrainingController(
        progressStore: progress,
        settingsStore: InMemoryTrainingSettingsStore(),
      );
      await expectLater(c.setLesson(5), throwsA(isA<FileSystemException>()));
      await c.updateSettings(const TrainingSettings(flashEnabled: true));

      await expectLater(c.flush(), throwsA(isA<FileSystemException>()));

      await c.setLesson(5);
      await c.flush();
      expect(progress.saved?.currentLesson, 5);
      c.dispose();
    },
  );
}

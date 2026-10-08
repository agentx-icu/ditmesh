import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/training_settings.dart';
import 'package:ditmesh/training/training_settings_store.dart';
import 'package:path/path.dart' as p;

void main() {
  group('TrainingSettings JSON', () {
    test('round-trips every field', () {
      const settings = TrainingSettings(
        trainer: TrainerSettings(
          characterWpm: 25,
          farnsworthWpm: 10,
          toneHz: 650,
          sessionLengthChars: 75,
          sessionLengthSeconds: 120,
          groupSize: 4,
        ),
        soundEnabled: false,
        flashEnabled: true,
        hapticEnabled: true,
        keyerMode: KeyerMode.straight,
      );
      expect(TrainingSettings.fromJson(settings.toJson()), settings);
    });

    test('missing keys and unknown keyer fall back to defaults', () {
      final parsed = TrainingSettings.fromJson(<String, Object?>{
        'keyerMode': 'sideswiper',
        'trainer': <String, Object?>{'characterWpm': 15},
      });
      expect(parsed.keyerMode, KeyerMode.iambicB);
      expect(parsed.soundEnabled, isTrue);
      expect(parsed.trainer.characterWpm, 15);
      expect(parsed.trainer.toneHz, TrainerSettings.defaults.toneHz);
    });


    test('hasFeedback is false only when every modality is off', () {
      const off = TrainingSettings(soundEnabled: false);
      expect(off.hasFeedback, isFalse);
      expect(off.copyWith(flashEnabled: true).hasFeedback, isTrue);
      expect(TrainingSettings.defaults.hasFeedback, isTrue);
    });
  });

  group('InMemoryTrainingSettingsStore', () {
    test('round-trips and counts saves', () async {
      final store = InMemoryTrainingSettingsStore();
      expect(await store.load(), isNull);
      const s = TrainingSettings(keyerMode: KeyerMode.iambicA);
      await store.save(s);
      expect(store.saveCount, 1);
      expect(await store.load(), s);
      await store.clear();
      expect(await store.load(), isNull);
    });
  });

  group('FileTrainingSettingsStore', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('ditmesh_settings_');
    });

    tearDown(() async {
      if (await tmp.exists()) {
        await tmp.delete(recursive: true);
      }
    });

    test('a stored session shorter than the Koch minimum is lifted', () async {
      // Older builds allowed 20-symbol sessions, which could never pass a
      // lesson: KochCourse needs at least minCharsPerSession symbols.
      final file = File(p.join(tmp.path, 'settings.json'));
      final store = FileTrainingSettingsStore(file);
      await store.save(
        const TrainingSettings(
          trainer: TrainerSettings(sessionLengthChars: 20),
        ),
      );
      final back = await store.load();
      expect(back!.trainer.sessionLengthChars, KochCourse().minCharsPerSession);
      expect(TrainingSettings.minSessionChars, KochCourse().minCharsPerSession);
    });

    test('writes settings.json next to progress and reloads it', () async {
      final store = FileTrainingSettingsStore.inDataDirectory(tmp.path);
      const s = TrainingSettings(
        trainer: TrainerSettings(characterWpm: 18),
        flashEnabled: true,
      );
      await store.save(s);
      expect(store.file.path, p.join(tmp.path, 'training', 'settings.json'));
      expect(
        await FileTrainingSettingsStore.inDataDirectory(tmp.path).load(),
        s,
      );
    });

    test('corrupt file falls back to the previous save', () async {
      final store = FileTrainingSettingsStore.inDataDirectory(tmp.path);
      await store.save(const TrainingSettings(soundEnabled: false));
      await store.save(const TrainingSettings(flashEnabled: true));
      await store.file.writeAsString('garbage');
      final loaded = await store.load();
      expect(loaded, const TrainingSettings(soundEnabled: false));
    });

    test(
      'invalid settings structure falls back to the previous save',
      () async {
        final store = FileTrainingSettingsStore.inDataDirectory(tmp.path);
        await store.save(const TrainingSettings(soundEnabled: false));
        await store.save(const TrainingSettings(flashEnabled: true));
        await store.file.writeAsString('{"soundEnabled":"invalid"}');

        expect(
          await FileTrainingSettingsStore.inDataDirectory(tmp.path).load(),
          const TrainingSettings(soundEnabled: false),
        );
      },
    );
  });
}

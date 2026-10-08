import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/file_trainer_store.dart';
import 'package:ditmesh/training/training_settings.dart';
import 'package:ditmesh/training/training_settings_store.dart';

void main() {
  test(
    'invalid domain values recover backups with assertions disabled',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'ditmesh_release_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final progress = TrainerProgress(currentLesson: 4);
      final invalidBase = progress.withLesson(5).toJson();
      final invalidProgress = <String, Map<String, Object?>>{
        'progress-lesson': {...invalidBase, 'currentLesson': 0},
        'progress-goal': {...invalidBase, 'dailyGoalChars': -1},
        'progress-stats': {
          ...invalidBase,
          'charStats': {
            'K': {'attempts': 1, 'correct': 2},
          },
        },
        'progress-srs': {
          ...invalidBase,
          'srs': {
            'cards': {
              'K': {'box': 999, 'dueAt': '2026-10-01T00:00:00Z'},
            },
          },
        },
      };
      for (final entry in invalidProgress.entries) {
        final file = File('${directory.path}/${entry.key}.json');
        final store = FileTrainerStore(file);
        await store.save(progress);
        await store.save(progress.withLesson(5));
        await file.writeAsString(jsonEncode(entry.value));
      }
      final settings = FileTrainingSettingsStore(
        File('${directory.path}/settings-tone.json'),
      );
      await settings.save(
        const TrainingSettings(trainer: TrainerSettings(toneHz: 650)),
      );
      await settings.save(TrainingSettings.defaults);
      await settings.file.writeAsString('{"trainer":{"toneHz":0}}');

      final result = await Process.run('dart', [
        '--packages=${File('../../.dart_tool/package_config.json').absolute.path}',
        'test/training/fixtures/load_training_files.dart',
        directory.path,
      ], runInShell: Platform.isWindows);

      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(jsonDecode(result.stdout as String), {
        for (final name in invalidProgress.keys) '$name.json': 4,
        'settings-tone.json': 650,
      });
    },
  );
}

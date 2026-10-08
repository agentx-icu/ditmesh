import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/file_trainer_store.dart';

/// Regression tests for the persisted lifetime counters (Codex finding R2):
/// a file whose counters are below what its own history shows is invalid and
/// must fall back to the `.bak` of the previous save, never reach the trainer
/// and never be rotated over the good backup.
void main() {
  late Directory directory;
  late File file;
  late FileTrainerStore store;

  File backupFileOf(File f) => File('${f.path}.bak');
  File corruptFileOf(File f) => File('${f.path}.corrupt');

  final history = <SessionSummary>[
    SessionSummary(
      at: DateTime.utc(2026, 9, 30, 8),
      totalChars: 40,
      correctChars: 36,
      lesson: 3,
    ),
    SessionSummary(
      at: DateTime.utc(2026, 10, 1, 8),
      totalChars: 60,
      correctChars: 50,
      lesson: 3,
    ),
  ];

  TrainerProgress progress({int lesson = 3}) => TrainerProgress(
    currentLesson: lesson,
    history: history,
    lifetimeSessions: 1000,
    lifetimeChars: 50000,
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ditmesh_lifetime_');
    file = File('${directory.path}/progress.json');
    store = FileTrainerStore(file);
  });

  tearDown(() => directory.delete(recursive: true));

  Future<void> overwritePrimary(Map<String, Object?> changes) async {
    final json = jsonDecode(await file.readAsString()) as Map<String, Object?>;
    await file.writeAsString(jsonEncode({...json, ...changes}));
  }

  Future<Map<String, Object?>> readPrimary() async =>
      jsonDecode(await file.readAsString()) as Map<String, Object?>;

  test('runs with assertions enabled', () {
    var asserted = false;
    assert(asserted = true, 'unreachable');
    expect(asserted, isTrue);
  });

  group('negative counters', () {
    setUp(() async {
      await store.save(progress());
      await store.save(progress(lesson: 4));
      expect(await backupFileOf(file).exists(), isTrue);
      await overwritePrimary({'lifetimeSessions': -1, 'lifetimeChars': -1});
    });

    test('load recovers the backup and keeps it on the next save', () async {
      final loaded = await store.load();
      expect(loaded, isNotNull);
      expect(loaded!.currentLesson, 3, reason: 'served from the .bak');
      expect(loaded.lifetimeSessions, 1000);
      expect(loaded.lifetimeChars, 50000);
      expect(loaded.history, hasLength(2));
      expect(await corruptFileOf(file).exists(), isTrue);

      await store.save(loaded.withLesson(5));
      final reloaded = await FileTrainerStore(file).load();
      expect(reloaded!.currentLesson, 5);
      expect(reloaded.lifetimeSessions, 1000);
      expect(reloaded.lifetimeChars, 50000);
      final onDisk = await readPrimary();
      expect(onDisk['lifetimeSessions'], 1000);
      expect(onDisk['lifetimeChars'], 50000);
    });

    test('a save without a load does not rotate the corrupt file', () async {
      await store.save(progress(lesson: 6));

      // The corrupt primary is set aside, not moved over the good backup.
      final backup =
          jsonDecode(await backupFileOf(file).readAsString())
              as Map<String, Object?>;
      expect(backup['lifetimeSessions'], 1000);
      expect(backup['lifetimeChars'], 50000);
      expect(await corruptFileOf(file).exists(), isTrue);

      final reloaded = await FileTrainerStore(file).load();
      expect(reloaded!.currentLesson, 6);
      expect(reloaded.lifetimeSessions, 1000);
      expect(reloaded.lifetimeChars, 50000);
    });
  });

  group('counters below the kept history', () {
    for (final entry in <String, Map<String, Object?>>{
      'sessions below history length': {'lifetimeSessions': 0},
      'sessions one below history length': {'lifetimeSessions': 1},
      'chars below history total': {'lifetimeChars': 99},
      'both zero': {'lifetimeSessions': 0, 'lifetimeChars': 0},
    }.entries) {
      test('${entry.key} falls back to the backup', () async {
        await store.save(progress());
        await store.save(progress(lesson: 4));
        await overwritePrimary(entry.value);

        final loaded = await store.load();
        expect(loaded, isNotNull);
        expect(loaded!.currentLesson, 3, reason: 'served from the .bak');
        expect(loaded.lifetimeSessions, 1000);
        expect(loaded.lifetimeChars, 50000);
        expect(await corruptFileOf(file).exists(), isTrue);
      });
    }

    test('counters exactly equal to the history are accepted', () async {
      await store.save(
        TrainerProgress(
          currentLesson: 4,
          history: history,
          lifetimeSessions: 2,
          lifetimeChars: 100,
        ),
      );

      final loaded = await store.load();
      expect(loaded!.currentLesson, 4);
      expect(loaded.lifetimeSessions, 2);
      expect(loaded.lifetimeChars, 100);
      expect(await corruptFileOf(file).exists(), isFalse);
    });

    test('with no backup there is nothing to load', () async {
      await store.save(progress());
      await overwritePrimary({'lifetimeSessions': 0});

      expect(await store.load(), isNull);
      expect(await corruptFileOf(file).exists(), isTrue);
    });
  });

  test('a file without the counter keys derives them from history', () async {
    final legacy = progress(lesson: 4).toJson()
      ..remove('lifetimeSessions')
      ..remove('lifetimeChars');
    await file.writeAsString(jsonEncode(legacy));

    final loaded = await store.load();
    expect(loaded, isNotNull);
    expect(loaded!.currentLesson, 4);
    expect(loaded.lifetimeSessions, 2);
    expect(loaded.lifetimeChars, 100);
    expect(await corruptFileOf(file).exists(), isFalse);
  });

  test('valid counters above the history round-trip exactly', () async {
    await store.save(progress(lesson: 7));

    final onDisk = await readPrimary();
    expect(onDisk['lifetimeSessions'], 1000);
    expect(onDisk['lifetimeChars'], 50000);

    final loaded = await FileTrainerStore(file).load();
    expect(loaded!.currentLesson, 7);
    expect(loaded.lifetimeSessions, 1000);
    expect(loaded.lifetimeChars, 50000);
    expect(loaded.totalCharsPracticed, 50000);
    expect(loaded.sessionCount, 1000);
    expect(loaded.history, hasLength(2));

    // Saving the loaded value again is lossless.
    await store.save(loaded);
    final again = await store.load();
    expect(again!.lifetimeSessions, 1000);
    expect(again.lifetimeChars, 50000);
  });
}

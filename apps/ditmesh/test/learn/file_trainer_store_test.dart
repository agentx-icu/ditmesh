import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/file_trainer_store.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('ditmesh_store_');
  });

  tearDown(() async {
    if (await tmp.exists()) {
      await tmp.delete(recursive: true);
    }
  });

  FileTrainerStore store() => FileTrainerStore.inDataDirectory(tmp.path);

  test('empty directory loads null', () async {
    expect(await store().load(), isNull);
  });

  test('lives at <dataDirectory>/training/progress.json', () async {
    final s = store();
    await s.save(TrainerProgress(currentLesson: 3));
    expect(s.file.path, p.join(tmp.path, 'training', 'progress.json'));
    expect(await s.file.exists(), isTrue);
    expect(await File('${s.file.path}.tmp').exists(), isFalse);
  });

  test('round-trips progress through JSON', () async {
    final s = store();
    final score = SessionScore.evaluate('KMKM MKMK', 'KMKM MKKK');
    final progress = TrainerProgress(
      currentLesson: 2,
      dailyGoalChars: 80,
    ).recordSession(score, now: DateTime(2026, 9, 30, 12));
    await s.save(progress);

    final loaded = await store().load();
    expect(loaded, isNotNull);
    expect(loaded!.currentLesson, 2);
    expect(loaded.dailyGoalChars, 80);
    expect(loaded.history.length, 1);
    expect(loaded.streakDays, 1);
    expect(loaded.charStats['K']!.attempts, progress.charStats['K']!.attempts);
    expect(loaded.srs.cards.keys, containsAll(<String>['K', 'M']));
  });

  test('second save keeps the previous document as .bak', () async {
    final s = store();
    await s.save(TrainerProgress(currentLesson: 1));
    await s.save(TrainerProgress(currentLesson: 2));
    final bak = File('${s.file.path}.bak');
    expect(await bak.exists(), isTrue);
    expect(await bak.readAsString(), contains('"currentLesson": 1'));
    expect((await s.load())!.currentLesson, 2);
  });

  test('corrupt primary falls back to .bak and is set aside', () async {
    final s = store();
    await s.save(TrainerProgress(currentLesson: 4));
    await s.save(TrainerProgress(currentLesson: 5));
    await s.file.writeAsString('{ this is not json');

    final loaded = await store().load();
    expect(loaded, isNotNull);
    expect(loaded!.currentLesson, 4);
    expect(await File('${s.file.path}.corrupt').exists(), isTrue);
    expect(await s.file.exists(), isFalse);
  });

  test('corrupt primary with no backup loads null', () async {
    final s = store();
    await s.file.parent.create(recursive: true);
    await s.file.writeAsString('[]');
    expect(await store().load(), isNull);
  });

  test('invalid progress structure falls back to a valid backup', () async {
    final s = store();
    await s.save(TrainerProgress(currentLesson: 4));
    await s.save(TrainerProgress(currentLesson: 5));
    await s.file.writeAsString('{"currentLesson":"invalid"}');

    expect((await store().load())?.currentLesson, 4);
    expect(await File('${s.file.path}.corrupt').exists(), isTrue);
    expect((await store().load())?.currentLesson, 4);
  });

  test('recovered backup survives repeated loads and the next save', () async {
    final s = store();
    await s.save(TrainerProgress(currentLesson: 4));
    await s.save(TrainerProgress(currentLesson: 5));
    await s.file.writeAsString('not json');
    expect((await store().load())?.currentLesson, 4);
    expect((await store().load())?.currentLesson, 4);

    await store().save(TrainerProgress(currentLesson: 6));
    await s.file.writeAsString('not json again');
    expect((await store().load())?.currentLesson, 4);
  });

  test(
    'saving over invalid progress preserves the last valid backup',
    () async {
      final s = store();
      await s.save(TrainerProgress(currentLesson: 4));
      await s.save(TrainerProgress(currentLesson: 5));
      await s.file.writeAsString('{"currentLesson":"invalid"}');

      await store().save(TrainerProgress(currentLesson: 6));
      await s.file.writeAsString('corrupt after the new save');

      expect((await store().load())?.currentLesson, 4);
    },
  );

  test(
    'missing primary but present .bak (crash mid-rename) loads .bak',
    () async {
      final s = store();
      await s.save(TrainerProgress(currentLesson: 7));
      await s.file.rename('${s.file.path}.bak');
      expect((await store().load())!.currentLesson, 7);
    },
  );

  test('clear removes every companion file', () async {
    final s = store();
    await s.save(TrainerProgress(currentLesson: 1));
    await s.save(TrainerProgress(currentLesson: 2));
    await s.clear();
    expect(await s.file.exists(), isFalse);
    expect(await File('${s.file.path}.bak').exists(), isFalse);
    expect(await store().load(), isNull);
  });
}

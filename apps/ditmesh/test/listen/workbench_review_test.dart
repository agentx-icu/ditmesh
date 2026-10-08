import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/training/audio_material_store.dart';
import 'package:ditmesh/training/training_controller.dart';
import 'package:ditmesh/training/training_settings_store.dart';
import 'package:ditmesh/ui/listen/listen_screen.dart';
import 'package:ditmesh/ui/listen/workbench/recording_files.dart';
import 'package:ditmesh/ui/listen/workbench/workbench_controller.dart';
import 'package:ditmesh/ui/listen/workbench/workbench_screen.dart';
import 'package:path/path.dart' as p;

import '../learn/helpers/l10n.dart';
import '../learn/helpers/test_controller.dart';
import 'fake_pcm_source.dart';
import 'workbench_support.dart';

/// Progress that can never be written (save-failure path).
final class _FailingStore implements TrainerStore {
  @override
  Future<TrainerProgress?> load() async => null;

  @override
  Future<void> save(TrainerProgress progress) async =>
      throw const FileSystemException('disk full');

  @override
  Future<void> clear() async {}
}

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('wbr_');
  });
  tearDown(() => root.delete(recursive: true));

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 250; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 2)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<FakeClipPlayer> pumpScreen(
    WidgetTester tester,
    TrainingController training,
  ) async {
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final player = FakeClipPlayer();
    await tester.pumpWidget(
      l10nApp(
        home: WorkbenchScreen(
          picker: FakePicker(
            PickedRecording(name: 'sos.wav', bytes: cwWav('SOS TEST')),
          ),
          player: player,
          profileRoot: () async => root.path,
          training: () async => training,
        ),
      ),
    );
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('workbench-import-empty')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('workbench-decode')));
    await settle(tester);
    return player;
  }

  testWidgets('viewing the decoder output makes the copy assisted', (
    tester,
  ) async {
    final t = await TestTraining.create();
    await pumpScreen(tester, t.controller);
    await tester.tap(find.text(en.workbenchModeDecoder));
    await tester.pump();
    expect(find.text('SOS TEST'), findsOneWidget);
    await tester.tap(find.text(en.workbenchModeCopy));
    await tester.pump();
    // Once exposed, the answer stays visible for this attempt.
    expect(find.text('SOS TEST'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('workbench-answer')),
      'SOS TEST',
    );
    await tester.tap(find.byKey(const ValueKey('workbench-submit')));
    await settle(tester);
    final record = t.controller.progress.history.single;
    expect(record.assistance, contains(Assistance.decoder));
  });

  testWidgets('decoding the same selection again keeps it assisted', (
    tester,
  ) async {
    final t = await TestTraining.create();
    await pumpScreen(tester, t.controller);
    await tester.tap(find.text(en.workbenchModeDecoder));
    await tester.pump();
    await tester.tap(find.text(en.workbenchModeCopy));
    await tester.pump();
    // A fresh result for the unchanged selection and tuning.
    await tester.tap(find.byKey(const ValueKey('workbench-decode')));
    await settle(tester);
    await tester.enterText(
      find.byKey(const ValueKey('workbench-answer')),
      'SOS TEST',
    );
    await tester.tap(find.byKey(const ValueKey('workbench-submit')));
    await settle(tester);
    final record = t.controller.progress.history.single;
    expect(record.assistance, contains(Assistance.decoder));
  });

  testWidgets('the keypad never reveals the hidden decoder output', (
    tester,
  ) async {
    final t = await TestTraining.create();
    await pumpScreen(tester, t.controller);
    expect(find.text(en.workbenchDecoderHidden), findsOneWidget);
    // Symbols that are not in "SOS TEST" are offered too.
    for (final symbol in <String>['K', 'Q', '7']) {
      expect(find.text(symbol), findsWidgets, reason: symbol);
    }
  });

  testWidgets('a failed save keeps the score and offers a retry', (
    tester,
  ) async {
    final c = TrainingController(
      progressStore: _FailingStore(),
      settingsStore: InMemoryTrainingSettingsStore(),
    );
    await c.load();
    addTearDown(c.dispose);
    await pumpScreen(tester, c);
    await tester.enterText(
      find.byKey(const ValueKey('workbench-answer')),
      'SOS TEST',
    );
    await tester.tap(find.byKey(const ValueKey('workbench-submit')));
    await settle(tester);
    expect(find.text(en.learnAccuracyPercent(100)), findsOneWidget);
    expect(find.text(en.learnProgressSaveFailed), findsOneWidget);
    expect(find.text(en.actionRetry), findsOneWidget);
  });

  test('a stop while PCM is still being read prevents playback', () async {
    final player = FakeClipPlayer();
    final c = WorkbenchController(
      library: RecordingLibrary(root.path),
      player: player,
    );
    addTearDown(c.dispose);
    expect(
      await c.importRecording(
        PickedRecording(name: 'cq.wav', bytes: cwWav('SOS')),
      ),
      isTrue,
    );
    final play = c.togglePlay();
    await c.stopPlayback();
    await play;
    expect(player.plays, isEmpty);
    // A selection change also invalidates a pending play.
    final again = c.togglePlay();
    c.setSelection(0, 100);
    await again;
    expect(player.plays, isEmpty);
  });

  group('media paths', () {
    test('only plain names under media/recordings are accepted', () {
      for (final bad in <String>[
        r'C:\Windows\x.wav',
        r'\\server\share\x.wav',
        'media/recordings/../../x.wav',
        '/etc/passwd',
        r'media\recordings\x.wav',
        'media/recordings/sub/x.wav',
      ]) {
        expect(
          () => AudioMaterial.fromJson(<String, Object?>{
            'id': 'a',
            'file': bad,
            'startUs': 0,
            'endUs': 1,
            'sampleRate': 8000,
            'channels': 1,
            'createdAt': '2026-10-03T00:00:00Z',
          }),
          throwsFormatException,
          reason: bad,
        );
        expect(
          () => RecordingLibrary(root.path).fileFor(bad),
          throwsArgumentError,
          reason: bad,
        );
      }
      final ok = RecordingLibrary(
        root.path,
      ).fileFor('media/recordings/rec_1.wav');
      expect(p.isWithin(root.path, ok.path), isTrue);
    });

    test('concurrent deletions never resurrect an entry', () async {
      final t = await TestTraining.create();
      final c = t.controller;
      AudioMaterial m(String id) => AudioMaterial(
        id: id,
        title: id,
        file: 'media/recordings/$id.wav',
        originalName: '$id.wav',
        start: Duration.zero,
        end: const Duration(seconds: 1),
        sampleRate: 8000,
        channels: 1,
        createdAt: c.now(),
      );
      await Future.wait([
        c.upsertAudioMaterial(m('a')),
        c.upsertAudioMaterial(m('b')),
        c.upsertAudioMaterial(m('c')),
      ]);
      expect(await c.loadAudioMaterials(), hasLength(3));
      await Future.wait([
        c.deleteAudioMaterial('a'),
        c.deleteAudioMaterial('b'),
      ]);
      final left = await c.loadAudioMaterials();
      expect(left.map((e) => e.id), ['c']);
    });

    test('unreferenced recordings are pruned; the working one stays', () async {
      final lib = RecordingLibrary(root.path);
      for (final name in <String>['current.wav', 'rec_a.wav', 'rec_b.wav']) {
        await lib.fileFor('media/recordings/$name').create(recursive: true);
      }
      await lib.pruneUnreferenced({'media/recordings/rec_a.wav'});
      expect(await lib.exists('media/recordings/current.wav'), isTrue);
      expect(await lib.exists('media/recordings/rec_a.wav'), isTrue);
      expect(await lib.exists('media/recordings/rec_b.wav'), isFalse);
    });
  });

  testWidgets('opening the workbench stops the microphone first', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final source = FakePcmSource();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: ListenScreen(source: source),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.listenStart));
    await tester.pumpAndSettle();
    expect(source.isStreaming, isTrue);
    await tester.tap(find.byKey(const ValueKey('listen-open-workbench')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(source.isStreaming, isFalse);
    expect(find.byType(WorkbenchScreen), findsOneWidget);
  });
}

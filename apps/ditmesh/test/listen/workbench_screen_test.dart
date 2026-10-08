import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/audio_material_store.dart';
import 'package:ditmesh/ui/listen/workbench/recording_files.dart';
import 'package:ditmesh/ui/listen/workbench/workbench_screen.dart';
import 'package:path/path.dart' as p;

import '../learn/helpers/l10n.dart';
import '../learn/helpers/test_controller.dart';
import 'workbench_support.dart';

void main() {
  late Directory root;
  late String dataDir;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('wbs_');
    dataDir = p.join(root.path, 'training');
    await Directory(dataDir).create();
  });
  tearDown(() => root.delete(recursive: true));

  /// Lets real file I/O and decoding finish: every I/O step completes on
  /// the real event loop and continues in the test's fake-async zone, so
  /// alternate the two many times.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 250; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 2)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<(TestTraining, FakePicker, FakeClipPlayer)> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(390, 2200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final t = await TestTraining.create();
    final picker = FakePicker(
      PickedRecording(name: 'sos.wav', bytes: cwWav('SOS TEST')),
    );
    final player = FakeClipPlayer();
    await tester.pumpWidget(
      l10nApp(
        home: WorkbenchScreen(
          picker: picker,
          player: player,
          profileRoot: () async => dataDir,
          training: () async => t.controller,
        ),
      ),
    );
    await settle(tester);
    return (t, picker, player);
  }

  testWidgets('import, decode, then copy it myself records activity only', (
    tester,
  ) async {
    final (t, _, player) = await pumpScreen(tester);
    expect(find.text(en.workbenchBackupNote), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('workbench-import-empty')));
    await settle(tester);
    expect(find.byKey(const ValueKey('workbench-info')), findsOneWidget);
    expect(find.byKey(const ValueKey('workbench-waveform')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('workbench-play')));
    await settle(tester);
    expect(player.plays, hasLength(1));

    await tester.tap(find.byKey(const ValueKey('workbench-decode')));
    await settle(tester);
    // Copy-it-myself is the default: the decoder text stays hidden.
    expect(find.text('SOS TEST'), findsNothing);
    expect(find.text(en.workbenchDecoderHidden), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('workbench-answer')),
      'SOS TEST',
    );
    await tester.tap(find.byKey(const ValueKey('workbench-submit')));
    await settle(tester);
    expect(find.text(en.learnAccuracyPercent(100)), findsOneWidget);
    expect(find.text(en.workbenchAgainstDecoder), findsOneWidget);
    final record = t.controller.progress.history.single;
    expect(record.source, ExerciseSource.recording);
    expect(record.isKnownUnassisted, isTrue);
    expect(t.controller.progress.srs.cards, isEmpty);
    expect(t.controller.progress.charStats, isEmpty);
  });

  testWidgets('a rejected file reports why and keeps the screen usable', (
    tester,
  ) async {
    final (_, picker, _) = await pumpScreen(tester);
    picker.next = PickedRecording(
      name: 'x.wav',
      bytes: cwWav('E', sampleRate: 22050),
    );
    await tester.tap(find.byKey(const ValueKey('workbench-import-empty')));
    await settle(tester);
    expect(find.text(en.workbenchErrorRate), findsOneWidget);
    expect(
      find.byKey(const ValueKey('workbench-import-empty')),
      findsOneWidget,
    );
  });

  testWidgets('a saved selection with missing media offers relink', (
    tester,
  ) async {
    final (t, _, _) = await pumpScreen(tester);
    // In-memory training docs: no real I/O, so no runAsync.
    unawaited(
      t.controller.upsertAudioMaterial(
        AudioMaterial(
          id: 'rec_1',
          title: 'Old net',
          file: 'media/recordings/rec_1.wav',
          originalName: 'net.wav',
          start: Duration.zero,
          end: const Duration(seconds: 2),
          sampleRate: 8000,
          channels: 1,
          createdAt: DateTime.utc(2026, 10, 3),
        ),
      ),
    );
    await settle(tester);
    await tester.tap(find.byTooltip(en.workbenchLibrary));
    await settle(tester);
    expect(find.text('Old net'), findsOneWidget);
    expect(find.text(en.workbenchMissing), findsOneWidget);
    await tester.tap(find.byTooltip(en.workbenchRelink));
    await settle(tester);
    expect(find.text(en.workbenchMissing), findsNothing);
    expect(
      await tester.runAsync(
        () => RecordingLibrary(dataDir).exists('media/recordings/rec_1.wav'),
      ),
      isTrue,
    );
  });

  testWidgets('save a selection, then restore it from the list', (
    tester,
  ) async {
    final (t, _, _) = await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('workbench-import-empty')));
    await settle(tester);
    await tester.enterText(find.byKey(const ValueKey('workbench-end')), '1.5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('workbench-save')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('workbench-save-title')),
      'First call',
    );
    await tester.tap(find.byKey(const ValueKey('workbench-save-confirm')));
    await settle(tester);
    late List<AudioMaterial> saved;
    unawaited(t.controller.loadAudioMaterials().then((v) => saved = v));
    await tester.pump();
    expect(saved.single.title, 'First call');
    expect(saved.single.end.inMilliseconds, closeTo(1500, 1));
    expect(saved.single.file, startsWith('media/recordings/rec_'));

    await tester.tap(find.byTooltip(en.workbenchLibrary));
    await settle(tester);
    await tester.tap(find.text('First call'));
    await settle(tester);
    expect(find.text('First call'), findsOneWidget);
  });

  testWidgets('fits a 320 px phone with large text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpScreen(tester, size: const Size(320, 2600));
    await tester.tap(find.byKey(const ValueKey('workbench-import-empty')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('workbench-decode')));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });
}

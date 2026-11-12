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
import 'workbench_wait.dart';

void main() {
  late Directory root;
  late String dataDir;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('wbs_');
    dataDir = p.join(root.path, 'training');
    await Directory(dataDir).create();
  });
  tearDown(() => root.delete(recursive: true));

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
    await waitForWorkbench(
      tester,
      find.byKey(const ValueKey('workbench-import-empty')),
    );
    return (t, picker, player);
  }

  testWidgets('import, decode, then copy it myself records activity only', (
    tester,
  ) async {
    final (t, _, player) = await pumpScreen(tester);
    expect(find.text(en.workbenchBackupNote), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('workbench-import-empty')));
    await waitForWorkbench(
      tester,
      find.byKey(const ValueKey('workbench-decode')),
    );
    expect(find.byKey(const ValueKey('workbench-info')), findsOneWidget);
    expect(find.byKey(const ValueKey('workbench-waveform')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('workbench-play')));
    await waitForWorkbench(tester, find.text(en.workbenchStop));
    expect(player.plays, hasLength(1));

    await tester.tap(find.byKey(const ValueKey('workbench-decode')));
    await waitForWorkbench(tester, find.text(en.workbenchDecoderHidden));
    // Copy-it-myself is the default: the decoder text stays hidden.
    expect(find.text('SOS TEST'), findsNothing);
    expect(find.text(en.workbenchDecoderHidden), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('workbench-answer')),
      'SOS TEST',
    );
    await tester.tap(find.byKey(const ValueKey('workbench-submit')));
    await waitForWorkbenchCondition(
      tester,
      () => t.controller.progress.history.isNotEmpty,
      description: 'record the copy attempt',
    );
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
    // Observe the transient error before the four-second SnackBar expires.
    await waitForWorkbench(tester, find.text(en.workbenchErrorRate));
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
    var seeded = false;
    unawaited(
      t.controller
          .upsertAudioMaterial(
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
          )
          .then((_) => seeded = true),
    );
    await waitForWorkbenchCondition(
      tester,
      () => seeded,
      description: 'save the library fixture',
    );
    await tester.tap(find.byTooltip(en.workbenchLibrary));
    await waitForWorkbench(tester, find.text('Old net'));
    expect(find.text('Old net'), findsOneWidget);
    expect(find.text(en.workbenchMissing), findsOneWidget);
    await tester.tap(find.byTooltip(en.workbenchRelink));
    await waitForWorkbench(
      tester,
      find.text(en.workbenchMissing),
      absent: true,
    );
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
    await waitForWorkbench(
      tester,
      find.byKey(const ValueKey('workbench-decode')),
    );
    await tester.enterText(find.byKey(const ValueKey('workbench-end')), '1.5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await waitForWorkbench(
      tester,
      find.byKey(const ValueKey('workbench-save')),
      enabled: true,
    );
    await tester.tap(find.byKey(const ValueKey('workbench-save')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('workbench-save-title')),
      'First call',
    );
    await tester.tap(find.byKey(const ValueKey('workbench-save-confirm')));
    await waitForWorkbench(tester, find.text(en.workbenchSaved));
    final saved = await tester.runAsync(t.controller.loadAudioMaterials);
    expect(saved!.single.title, 'First call');
    expect(saved.single.end.inMilliseconds, closeTo(1500, 1));
    expect(saved.single.file, startsWith('media/recordings/rec_'));

    await tester.tap(find.byTooltip(en.workbenchLibrary));
    await waitForWorkbench(tester, find.text('First call'));
    await tester.tap(find.text('First call'));
    await waitForWorkbench(tester, find.byType(BottomSheet), absent: true);
    expect(find.text('First call'), findsOneWidget);
  });

  testWidgets('fits a 320 px phone with large text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpScreen(tester, size: const Size(320, 2600));
    await tester.tap(find.byKey(const ValueKey('workbench-import-empty')));
    await waitForWorkbench(
      tester,
      find.byKey(const ValueKey('workbench-decode')),
    );
    await tester.tap(find.byKey(const ValueKey('workbench-decode')));
    await waitForWorkbench(tester, find.text(en.workbenchDecoderHidden));
    expect(tester.takeException(), isNull);
  });
}

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/audio_material_store.dart';
import 'package:ditmesh/training/training_doc_store.dart';
import 'package:ditmesh/ui/listen/workbench/recording_files.dart';
import 'package:ditmesh/ui/listen/workbench/workbench_screen.dart';
import 'package:ditmesh/ui/listen/workbench/workbench_controller.dart';
import 'package:ditmesh/ui/listen/workbench/workbench_waveform.dart';
import 'package:path/path.dart' as p;

import '../learn/helpers/l10n.dart';
import '../learn/helpers/test_controller.dart';
import 'workbench_support.dart';
import 'workbench_wait.dart';

final class _FallibleMaterials implements TrainingDocStore {
  final _store = InMemoryTrainingDocStore();
  Exception? readError;

  @override
  Future<Map<String, Object?>?> read(String name) async {
    if (readError case final error? when name == AudioMaterialStore.doc) {
      throw error;
    }
    return _store.read(name);
  }

  @override
  Future<void> write(String name, Map<String, Object?> json) =>
      _store.write(name, json);
}

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
    TrainingDocStore? docs,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final t = await TestTraining.create(docs: docs);
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

  Future<WorkbenchController> importForSelection(WidgetTester tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('workbench-import-empty')));
    final view = find.byType(WorkbenchWaveform);
    await waitForWorkbench(tester, view);
    return tester.widget<WorkbenchWaveform>(view).controller;
  }

  testWidgets('dragging across the selection retains the opposite endpoint', (
    tester,
  ) async {
    final c = await importForSelection(tester);
    final total = c.info!.frameCount;
    final anchor = total ~/ 2;
    c.setSelection(total ~/ 4, anchor);
    await tester.pump();
    final bounds = tester.getRect(
      find.byKey(const ValueKey('workbench-waveform')),
    );
    Offset point(double fraction) =>
        Offset(bounds.left + bounds.width * fraction, bounds.center.dy);
    final drag = await tester.startGesture(point(.25));
    await drag.moveTo(point(.31));
    await drag.moveTo(point(.65));
    await drag.moveTo(point(.80));
    await drag.up();
    await tester.pump();

    expect(c.start, anchor);
    expect(c.end, closeTo(total * .8, 1));
  });

  testWidgets('playback notifications preserve a pending time edit', (
    tester,
  ) async {
    final c = await importForSelection(tester);
    final end = find.byKey(const ValueKey('workbench-end'));
    await tester.enterText(end, '1.23');
    c.setLoop(true);
    await tester.pump();

    expect(tester.widget<TextField>(end).controller!.text, '1.23');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(c.end, 9840);
  });

  testWidgets('leaving an unchanged time field keeps the exact frame', (
    tester,
  ) async {
    final c = await importForSelection(tester);
    final start = find.byKey(const ValueKey('workbench-start'));
    c.setSelection(1001, c.end);
    await tester.pump();
    await tester.tap(start);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('workbench-waveform')));
    await tester.pump();

    expect(c.start, 1001);
  });

  testWidgets('invalid time input restores the previous value', (tester) async {
    final c = await importForSelection(tester);
    final start = find.byKey(const ValueKey('workbench-start'));
    c.setSelection(1001, c.end);
    await tester.pump();
    final previous = tester.widget<TextField>(start).controller!.text;
    await tester.enterText(start, '1,,2');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(tester.widget<TextField>(start).controller!.text, previous);
    expect(c.start, 1001);
  });

  testWidgets('replacing the recording discards its pending time edit', (
    tester,
  ) async {
    final (_, picker, _) = await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('workbench-import-empty')));
    final end = find.byKey(const ValueKey('workbench-end'));
    await waitForWorkbench(tester, end);
    final pending = Completer<void>();
    picker.holdPick = pending;
    await tester.tap(find.byKey(const ValueKey('workbench-import')));
    await tester.enterText(end, '1.23');
    picker.next = PickedRecording(name: 'next.wav', bytes: cwWav('E'));
    pending.complete();
    await waitForWorkbench(tester, find.text('next.wav'));

    final c = tester
        .widget<WorkbenchWaveform>(find.byType(WorkbenchWaveform))
        .controller;
    final seconds = (c.positionOf(c.end).inMilliseconds / 1000).toStringAsFixed(
      2,
    );
    expect(tester.widget<TextField>(end).controller!.text, seconds);
  });

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
    await waitForWorkbenchCondition(
      tester,
      () => player.isPlaying,
      description: 'start playback',
    );
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

  testWidgets('a covering page stops playback and restores the Loop control', (
    tester,
  ) async {
    final (_, _, player) = await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('workbench-import-empty')));
    await waitForWorkbench(tester, find.text('sos.wav'));
    final loop = find.widgetWithText(FilterChip, en.workbenchLoop);
    expect(tester.widget<FilterChip>(loop).onSelected, isNotNull);
    await tester.tap(loop);
    await tester.pump();
    final nativeStart = Completer<void>();
    player.holdPlay = nativeStart;
    await tester.tap(find.byKey(const ValueKey('workbench-play')));
    await waitForWorkbenchCondition(
      tester,
      () => player.playRequested.isCompleted,
      description: 'prepare playback',
    );
    expect(tester.widget<FilterChip>(loop).onSelected, isNull);
    nativeStart.complete();
    await waitForWorkbenchCondition(
      tester,
      () => player.isPlaying,
      description: 'start looping playback',
    );
    expect(player.plays.single.$2, isTrue);
    expect(tester.widget<FilterChip>(loop).onSelected, isNull);

    final navigator = Navigator.of(
      tester.element(find.byType(WorkbenchScreen)),
    );
    unawaited(
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Conversation')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(player.isPlaying, isFalse);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(player.plays, hasLength(1));
    expect(tester.widget<FilterChip>(loop).onSelected, isNotNull);
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

  testWidgets('a picker error can be retried without losing the open WAV', (
    tester,
  ) async {
    final (_, picker, _) = await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('workbench-import-empty')));
    await waitForWorkbench(tester, find.text('sos.wav'));
    picker.error = const FileSystemException('provider unavailable');
    await tester.tap(find.byKey(const ValueKey('workbench-import')));
    await waitForWorkbench(tester, find.text(en.workbenchErrorIo));
    expect(find.text('sos.wav'), findsOneWidget);

    picker.error = null;
    picker.next = PickedRecording(name: 'cq.wav', bytes: cwWav('CQ'));
    await tester.tap(find.byKey(const ValueKey('workbench-import')));
    await waitForWorkbench(tester, find.text('cq.wav'));
  });

  testWidgets('the selection cannot be saved while another WAV is picked', (
    tester,
  ) async {
    final (_, picker, _) = await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('workbench-import-empty')));
    final save = find.byKey(const ValueKey('workbench-save'));
    await waitForWorkbench(tester, save, enabled: true);
    final pending = Completer<void>();
    picker.holdPick = pending;
    picker.next = PickedRecording(name: 'cq.wav', bytes: cwWav('CQ'));
    await tester.tap(find.byKey(const ValueKey('workbench-import')));
    await tester.pump();

    expect(tester.widget<ButtonStyleButton>(save).onPressed, isNull);
    pending.complete();
    await waitForWorkbench(tester, find.text('cq.wav'));
    await waitForWorkbench(tester, save, enabled: true);
  });

  testWidgets('missing media keeps the note and offers relink', (tester) async {
    final (t, picker, _) = await pumpScreen(tester);
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
              note: 'Operator changed after the first call',
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
    final missing = find.text(
      '${en.workbenchMissing}\nOperator changed after the first call',
    );
    expect(missing, findsOneWidget);
    picker.error = const FileSystemException('provider unavailable');
    await tester.tap(find.byTooltip(en.workbenchRelink));
    await tester.pump();
    expect(find.text(en.workbenchErrorIo), findsOneWidget);
    expect(missing, findsOneWidget);

    picker.error = null;
    picker.next = PickedRecording(
      name: 'too-short.wav',
      bytes: wavOf(Int16List(8000), sampleRate: 8000),
    );
    await tester.tap(find.byTooltip(en.workbenchRelink));
    await waitForWorkbench(
      tester,
      find.text(en.workbenchRelinkTooShort('0:01.00', '0:02.00')),
    );
    expect(missing, findsOneWidget);
    expect(
      await tester.runAsync(
        () => RecordingLibrary(dataDir).exists('media/recordings/rec_1.wav'),
      ),
      isFalse,
    );

    picker.next = PickedRecording(name: 'valid.wav', bytes: cwWav('SOS TEST'));
    await tester.tap(find.byTooltip(en.workbenchRelink));
    await waitForWorkbench(tester, missing, absent: true);
    expect(missing, findsNothing);
    expect(find.text(en.workbenchErrorIo), findsNothing);
    expect(
      await tester.runAsync(
        () => RecordingLibrary(dataDir).exists('media/recordings/rec_1.wav'),
      ),
      isTrue,
    );
  });

  testWidgets('cancelling clip deletion preserves the entry and audio', (
    tester,
  ) async {
    final (t, _, _) = await pumpScreen(tester);
    final audio = File(p.join(dataDir, 'media/recordings/rec_confirm.wav'));
    await tester.runAsync(() async {
      await audio.parent.create(recursive: true);
      await audio.writeAsBytes(cwWav('E'));
    });
    var seeded = false;
    unawaited(
      t.controller
          .upsertAudioMaterial(
            AudioMaterial(
              id: 'rec_confirm',
              title: 'Friday net',
              file: 'media/recordings/rec_confirm.wav',
              originalName: 'friday.wav',
              start: Duration.zero,
              end: const Duration(milliseconds: 60),
              sampleRate: 8000,
              channels: 1,
              createdAt: DateTime.utc(2026),
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
    await waitForWorkbench(tester, find.text('Friday net'));
    await tester.tap(find.byTooltip(en.workbenchDelete));
    final confirm = find.byType(AlertDialog);
    await waitForWorkbench(tester, confirm);
    expect(confirm, findsOneWidget);
    expect(
      find.descendant(of: confirm, matching: find.textContaining('Friday net')),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: confirm,
        matching: find.textContaining('local recording'),
      ),
      findsWidgets,
    );
    await tester.tap(
      find.descendant(of: confirm, matching: find.text(en.actionCancel)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Friday net'), findsOneWidget);
    expect(await tester.runAsync(audio.exists), isTrue);
    await waitForWorkbench(tester, find.byTooltip(en.workbenchDelete));
    await tester.tap(find.byTooltip(en.workbenchDelete));
    await waitForWorkbench(tester, confirm);
    await tester.tap(find.byKey(const ValueKey('workbench-confirm-delete')));
    await waitForWorkbench(tester, find.text(en.workbenchRemovedClipAndFile));
    expect(find.text('Friday net'), findsNothing);
    expect(await tester.runAsync(audio.exists), isFalse);
  });

  testWidgets('recovering an older index keeps its missing WAVs on disk', (
    tester,
  ) async {
    final docsDir = Directory(p.join(dataDir, 'docs'));
    final docs = FileTrainingDocStore(docsDir);
    final audio = RecordingLibrary(dataDir).fileFor('media/recordings/new.wav');
    await tester.runAsync(() async {
      await audio.parent.create(recursive: true);
      await audio.writeAsBytes(cwWav('E'));
      final newMaterial = AudioMaterial(
        id: 'new',
        title: 'New recording',
        file: 'media/recordings/new.wav',
        originalName: 'new.wav',
        start: Duration.zero,
        end: const Duration(milliseconds: 500),
        sampleRate: 8000,
        channels: 1,
        createdAt: DateTime.utc(2026),
      );
      await docs.write(AudioMaterialStore.doc, {'v': 1, 'materials': []});
      await docs.write(AudioMaterialStore.doc, {
        'v': 1,
        'materials': [newMaterial.toJson()],
      });
      await File(
        p.join(docsDir.path, '${AudioMaterialStore.doc}.json'),
      ).writeAsString('{');
    });

    await pumpScreen(tester, docs: docs);
    final library = find.widgetWithIcon(
      IconButton,
      Icons.library_music_outlined,
    );
    await waitForWorkbenchCondition(
      tester,
      () => tester.widget<IconButton>(library).onPressed != null,
      description: 'enable the library',
    );
    await tester.tap(library);
    await waitForWorkbench(
      tester,
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text(en.workbenchLibraryEmpty),
      ),
    );
    expect(await tester.runAsync(audio.exists), isTrue);
  });

  testWidgets('a failed library load offers a retry', (tester) async {
    final docs = _FallibleMaterials();
    await pumpScreen(tester, docs: docs);
    await waitForWorkbenchCondition(
      tester,
      () =>
          tester
              .widget<IconButton>(
                find.widgetWithIcon(IconButton, Icons.library_music_outlined),
              )
              .onPressed !=
          null,
      description: 'enable the library',
    );
    docs.readError = const FileSystemException('training storage unavailable');
    await tester.tap(find.byTooltip(en.workbenchLibrary));
    await waitForWorkbench(tester, find.text(en.workbenchErrorIo));

    docs.readError = null;
    await tester.tap(find.text(en.actionRetry));
    await waitForWorkbench(tester, find.text(en.workbenchLibraryEmpty));
    expect(find.text(en.workbenchErrorIo), findsNothing);
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
    final savedClip = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text('First call'),
    );
    await waitForWorkbench(tester, savedClip);
    await tester.tap(savedClip);
    await waitForWorkbench(tester, find.byType(BottomSheet), absent: true);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('workbench-loaded-name')))
          .data,
      'First call',
    );
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

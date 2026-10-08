import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/training/material_store.dart';
import 'package:ditmesh/training/training_doc_store.dart';
import 'package:ditmesh/ui/learn/materials/material_file_gateway.dart';
import 'package:ditmesh/ui/learn/materials/materials_screen.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_playback.dart';
import 'helpers/l10n.dart';
import 'helpers/test_controller.dart';

Future<(TestTraining, FakeMaterialFileGateway)> _pump(
  WidgetTester tester, {
  PickedFile? pick,
  int lesson = 10,
}) async {
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final t = await TestTraining.create(
    progress: TrainerProgress(currentLesson: lesson),
  );
  final gateway = FakeMaterialFileGateway(pickResult: pick);
  await tester.pumpWidget(
    Provider<MaterialFileGateway>.value(
      value: gateway,
      child: l10nApp(
        home: MaterialsScreen(
          controller: t.controller,
          playback: FakeLearnPlaybackFactory(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (t, gateway);
}

PickedFile _file(String name, String text) =>
    PickedFile(name, Uint8List.fromList(utf8.encode(text)));

Future<void> _menu(WidgetTester tester, String item) async {
  await tester.tap(find.byTooltip(en.materialsActions).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the editor previews unsupported characters before saving', (
    tester,
  ) async {
    final (t, _) = await _pump(tester);
    expect(find.text(en.materialsEmpty), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('material-new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Contest');
    await tester.enterText(
      find.byKey(const ValueKey('material-text')),
      'CQ TEST 你好 <BT> K',
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(en.materialsPreviewUnsupported('你 好')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('material-save')));
    await tester.pumpAndSettle();
    final saved = (await t.controller.loadMaterials()).single;
    expect(saved.originalText, 'CQ TEST 你好 <BT> K');
    expect(saved.normalizedItems.single, 'CQ TEST <BT> K');
    expect(find.text('Contest'), findsOneWidget);
  });

  testWidgets('TXT import opens the editor; invalid JSON changes nothing', (
    tester,
  ) async {
    final (t, gateway) = await _pump(
      tester,
      pick: _file('calls.txt', 'K1ABC\nDL2XY'),
    );
    await tester.tap(find.byTooltip(en.materialsImport));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.materialsKindCallsigns));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const ValueKey('material-save')));
    await tester.pumpAndSettle();
    final first = await t.controller.loadMaterials();
    expect(first.single.title, 'calls');
    expect(first.single.normalizedItems, ['K1ABC', 'DL2XY']);

    gateway.pickResult = _file('bad.json', '{"format":"nope"}');
    await tester.tap(find.byTooltip(en.materialsImport));
    await tester.pumpAndSettle();
    expect(find.text(en.materialsImportInvalid), findsOneWidget);
    expect(await t.controller.loadMaterials(), hasLength(1));
  });

  testWidgets('JSON round trip with a duplicate kept as a copy', (
    tester,
  ) async {
    final (t, gateway) = await _pump(tester);
    final c = t.controller;
    final m = MaterialImport.create(
      id: 'm1',
      title: 'Words',
      kind: MaterialKind.wordList,
      text: 'CQ\nDE',
      analysis: MaterialImport.analyze('CQ\nDE', MaterialKind.wordList),
      now: c.now(),
      source: const MaterialSource(description: 'x', localRef: 'chat:p/c/1'),
    );
    await c.upsertMaterial(m);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      Provider<MaterialFileGateway>.value(
        value: gateway,
        child: l10nApp(
          home: MaterialsScreen(
            controller: t.controller,
            playback: FakeLearnPlaybackFactory(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(en.materialsExportJson));
    await tester.pumpAndSettle();
    final (name, bytes) = gateway.saved.single;
    expect(name, endsWith('.json'));
    final raw = utf8.decode(bytes);
    expect(raw, isNot(contains('chat:p/c/1')));

    gateway.pickResult = PickedFile('lib.json', bytes);
    await tester.tap(find.byTooltip(en.materialsImport));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.materialsDuplicateKeepCopy));
    await tester.pumpAndSettle();
    final all = await c.loadMaterials();
    expect(all, hasLength(2));
    expect(all.map((e) => e.normalizedItems), everyElement(['CQ', 'DE']));
  });

  testWidgets('WAV export writes a playable file and optional answer', (
    tester,
  ) async {
    final (t, gateway) = await _pump(tester);
    await t.controller.upsertMaterial(
      MaterialImport.create(
        id: 'w',
        title: 'Mein/Text',
        kind: MaterialKind.text,
        text: 'PARIS',
        analysis: MaterialImport.analyze('PARIS', MaterialKind.text),
        now: t.controller.now(),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      Provider<MaterialFileGateway>.value(
        value: gateway,
        child: l10nApp(
          home: MaterialsScreen(
            controller: t.controller,
            playback: FakeLearnPlaybackFactory(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _menu(tester, en.materialsExportWav);
    await tester.tap(find.text(en.materialsWavWithAnswer));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('wav-export')));
    await tester.pumpAndSettle();
    expect(gateway.saved, hasLength(2));
    final (wavName, wav) = gateway.saved.first;
    expect(wavName, endsWith('.wav'));
    expect(wavName, isNot(contains('/')));
    expect(ascii.decode(wav.sublist(0, 4)), 'RIFF');
    expect(ascii.decode(wav.sublist(8, 12)), 'WAVE');
    expect(wav.length, greaterThan(44));
    expect(utf8.decode(gateway.saved.last.$2), 'PARIS');
    expect(find.text(en.materialsWavExported(1)), findsOneWidget);
  });

  testWidgets('learned-only practice explains unavailable entries', (
    tester,
  ) async {
    final (t, _) = await _pump(tester, lesson: 3);
    await t.controller.upsertMaterial(
      MaterialImport.create(
        id: 'p',
        title: 'Mix',
        kind: MaterialKind.wordList,
        text: 'KMR\nXYZ',
        analysis: MaterialImport.analyze('KMR\nXYZ', MaterialKind.wordList),
        now: t.controller.now(),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      l10nApp(
        home: MaterialsScreen(
          controller: t.controller,
          playback: FakeLearnPlaybackFactory(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mix'));
    await tester.pumpAndSettle();
    expect(find.text(en.materialsPracticeLearnedPartial(1)), findsOneWidget);
    await tester.tap(find.text(en.materialsPracticeLearnedPartial(1)));
    await tester.pumpAndSettle();
    expect(find.text('Mix'), findsOneWidget, reason: 'drill title');
  });

  testWidgets('every JSON import is confirmed; TXT export is lossless', (
    tester,
  ) async {
    final (t, gateway) = await _pump(tester);
    final c = t.controller;
    final list = MaterialImport.create(
      id: 'l1',
      title: 'Calls',
      kind: MaterialKind.callsigns,
      text: 'K1ABC\nDL2XY',
      analysis: MaterialImport.analyze('K1ABC\nDL2XY', MaterialKind.callsigns),
      now: c.now(),
    );
    gateway.pickResult = PickedFile(
      'lib.json',
      Uint8List.fromList(utf8.encode(MaterialLibraryCodec.encode([list]))),
    );
    await tester.tap(find.byTooltip(en.materialsImport));
    await tester.pumpAndSettle();
    expect(find.text(en.materialsImportConfirm(1)), findsOneWidget);
    await tester.tap(find.text(en.actionCancel));
    await tester.pumpAndSettle();
    expect(await c.loadMaterials(), isEmpty, reason: 'cancel imports nothing');
    await tester.tap(find.byTooltip(en.materialsImport));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('import-keepCopy')));
    await tester.pumpAndSettle();
    expect(await c.loadMaterials(), hasLength(1));

    await _menu(tester, en.materialsExportTxt);
    final (name, bytes) = gateway.saved.single;
    expect(name, 'Calls.txt');
    expect(utf8.decode(bytes), 'K1ABC\nDL2XY');
  });

  test('materials live under the training directory (in backups)', () {
    final store = FileTrainingDocStore.inDataDirectory('/data/id');
    expect(
      store.directory.path,
      '/data/id${Platform.pathSeparator}training${Platform.pathSeparator}docs',
    );
  });
}

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:morse_dsp/morse_dsp.dart';
import 'package:ditmesh/training/audio_material_store.dart';
import 'package:ditmesh/ui/listen/workbench/recording_files.dart';
import 'package:ditmesh/ui/listen/workbench/workbench_controller.dart';
import 'package:path/path.dart' as p;

import '../learn/helpers/test_controller.dart';
import 'workbench_support.dart';

void main() {
  late Directory root;
  late String dataDir;
  late FakeClipPlayer player;
  late WorkbenchController c;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('wb_');
    dataDir = p.join(root.path, 'training');
    await Directory(dataDir).create();
    player = FakeClipPlayer();
    // Media live in the profile root, beside its backed-up training tree.
    c = WorkbenchController(
      library: RecordingLibrary(root.path),
      player: player,
    );
  });

  tearDown(() async {
    c.dispose();
    await root.delete(recursive: true);
  });

  Future<void> waveform() async {
    for (var i = 0; i < 200 && c.waveform == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  test(
    'imports into managed storage outside the backed-up training dir',
    () async {
      final ok = await c.importRecording(
        PickedRecording(name: 'cq.wav', bytes: cwWav('SOS TEST')),
      );
      expect(ok, isTrue);
      expect(c.info!.sampleRate, 8000);
      expect(c.name, 'cq.wav');
      final copied = File(
        p.join(root.path, 'media', 'recordings', 'current.wav'),
      );
      expect(await copied.exists(), isTrue);
      expect(p.isWithin(dataDir, copied.path), isFalse);
      await waveform();
      expect(c.waveform!.length, greaterThan(0));
    },
  );

  test('every rate and stereo open by header', () async {
    for (final rate in WavPcmReader.supportedRates) {
      for (final ch in <int>[1, 2]) {
        final ok = await c.importRecording(
          PickedRecording(
            name: 'x.dat',
            bytes: cwWav('E', sampleRate: rate, channels: ch),
          ),
        );
        expect(ok, isTrue, reason: '$rate/$ch');
        expect(c.info!.channels, ch);
      }
    }
  });

  test('a rejected import keeps the open session', () async {
    await c.importRecording(PickedRecording(name: 'a.wav', bytes: cwWav('E')));
    final frames = c.info!.frameCount;
    final bad = await c.importRecording(
      PickedRecording(
        name: 'b.mp3',
        bytes: Uint8List.fromList(List.filled(64, 7)),
      ),
    );
    expect(bad, isFalse);
    expect(c.wavError, WavError.notRiff);
    expect(c.info!.frameCount, frames);
    expect(c.name, 'a.wav');
    final huge = await c.importRecording(
      const PickedRecording(
        name: 'h.wav',
        path: '/nonexistent',
        size: 60 << 20,
      ),
    );
    expect(huge, isFalse);
    expect(c.wavError, WavError.tooLarge);
    expect(c.name, 'a.wav');
  });

  test('decodes a selection; changing it invalidates the result', () async {
    await c.importRecording(
      PickedRecording(name: 'a.wav', bytes: cwWav('SOS TEST')),
    );
    await c.decode();
    expect(c.result!.text.trim(), 'SOS TEST');
    c.setSelection(0, c.info!.frameCount ~/ 2);
    expect(c.result, isNull);
    c.setTuning(auto: false, hz: 700);
    expect(c.result, isNull);
  });

  test('cancel stops updates of a decode in flight', () async {
    await c.importRecording(
      PickedRecording(name: 'a.wav', bytes: cwWav('SOS TEST')),
    );
    final running = c.decode();
    c.cancelDecode();
    await running;
    expect(c.result, isNull);
    expect(c.decoding, isFalse);
  });

  test('plays the selection as a mono WAV clip, optionally looping', () async {
    await c.importRecording(
      PickedRecording(name: 'a.wav', bytes: cwWav('E', channels: 2)),
    );
    c.setLoop(true);
    await c.togglePlay();
    final (wav, loop) = player.plays.single;
    expect(loop, isTrue);
    final info = await WavPcmReader.parse(BytesSource(wav));
    expect(info.channels, 1);
    expect(info.frameCount, c.end - c.start);
    await c.togglePlay();
    expect(player.isPlaying, isFalse);
  });

  test('audio materials round trip; missing media and bad entries', () async {
    final t = await TestTraining.create();
    final ctl = t.controller;
    final m = AudioMaterial(
      id: ctl.newAudioMaterialId(),
      title: 'Net',
      file: 'media/recordings/x.wav',
      originalName: 'net.wav',
      start: const Duration(seconds: 1),
      end: const Duration(seconds: 3),
      sampleRate: 8000,
      channels: 1,
      createdAt: DateTime.utc(2026, 10, 3),
      note: 'fast',
    );
    await ctl.upsertAudioMaterial(m);
    await ctl.writeDoc(AudioMaterialStore.doc, <String, Object?>{
      'materials': [
        m.toJson(),
        {'id': 'bad', 'file': '../escape.wav'},
      ],
    });
    final loaded = await ctl.loadAudioMaterials();
    expect(loaded.single.note, 'fast');
    expect(loaded.single.end, const Duration(seconds: 3));
    expect(await RecordingLibrary(root.path).exists(m.file), isFalse);
    expect(await c.openSaved(m.file, m.title), isFalse);
    expect(c.failure, WorkbenchFailure.missingFile);
    await ctl.deleteAudioMaterial(m.id);
    expect(await ctl.loadAudioMaterials(), isEmpty);
  });
}

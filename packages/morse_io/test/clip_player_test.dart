import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';

final class _FakeSource implements AudioSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ControlledEngine implements SoLoud {
  final firstLoad = Completer<AudioSource>();
  final loadingFirst = Completer<void>();
  final secondSource = _FakeSource();
  final loadedNames = <String>[];
  final played = <AudioSource>[];
  final released = <AudioSource>[];
  bool deinitialized = false;

  @override
  bool isInitialized = false;

  @override
  Future<void> init({
    PlaybackDevice? device,
    bool automaticCleanup = false,
    int sampleRate = 44100,
    int bufferSize = 2048,
    Channels channels = Channels.stereo,
    bool lowLatency = true,
    AndroidAAudioAttributes androidAAudioAttributes =
        AndroidAAudioAttributes.mediaMusic,
  }) async => isInitialized = true;

  @override
  void deinit() {
    deinitialized = true;
    isInitialized = false;
  }

  @override
  Future<AudioSource> loadMem(
    String path,
    Uint8List buffer, {
    LoadMode mode = LoadMode.memory,
    bool autoDispose = false,
  }) async {
    loadedNames.add(path);
    if (loadedNames.length == 1) {
      loadingFirst.complete();
      return firstLoad.future;
    }
    return secondSource;
  }

  @override
  SoundHandle play(
    AudioSource sound, {
    int busId = 0,
    double volume = 1,
    double pan = 0,
    bool paused = false,
    bool looping = false,
    Duration loopingStartAt = Duration.zero,
    Duration? loopingEndAt,
  }) {
    played.add(sound);
    return const SoundHandle(1);
  }

  @override
  bool getIsValidVoiceHandle(SoundHandle handle) => isInitialized;

  @override
  Future<void> stop(SoundHandle handle) async {}

  @override
  Future<void> disposeSource(AudioSource source) async {
    expect(isInitialized, isTrue);
    released.add(source);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const length = Duration(seconds: 1);
  test(
    'stop immediately after play cancels startup before SoLoud init',
    () async {
      var engineAccesses = 0;
      final player = SoloudClipPlayer(
        lease: FlutterSoloudApi(
          resolveEngine: () {
            engineAccesses++;
            throw StateError('engine unavailable');
          },
        ),
      );
      addTearDown(player.dispose);

      final playback = player.play(Uint8List(0), length: length);
      await Future.wait([playback, player.stop()]);

      expect(engineAccesses, 0);
      expect(player.isPlaying, isFalse);
    },
  );

  test(
    'disposing during a load releases its source before the engine',
    () async {
      final engine = _ControlledEngine();
      final player = SoloudClipPlayer(lease: FlutterSoloudApi(engine: engine));
      final playback = player.play(Uint8List(0), length: length);
      await engine.loadingFirst.future;

      final disposal = player.dispose();
      expect(engine.deinitialized, isFalse);
      final source = _FakeSource();
      engine.firstLoad.complete(source);
      await Future.wait([playback, disposal]);

      expect(engine.played, isEmpty);
      expect(engine.released, [source]);
      expect(engine.deinitialized, isTrue);
    },
  );

  test('a new play during loading starts only the newer clip', () async {
    final engine = _ControlledEngine();
    final player = SoloudClipPlayer(lease: FlutterSoloudApi(engine: engine));
    addTearDown(player.dispose);
    final first = player.play(Uint8List(0), length: length, loop: true);
    await engine.loadingFirst.future;

    final second = player.play(Uint8List(0), length: length, loop: true);
    final firstSource = _FakeSource();
    engine.firstLoad.complete(firstSource);
    await Future.wait([first, second]);

    expect(engine.released, [firstSource]);
    expect(engine.loadedNames.toSet(), hasLength(2));
    expect(engine.played, [engine.secondSource]);
    expect(player.isPlaying, isTrue);

    await player.stop();
    expect(player.isPlaying, isFalse);
    expect(engine.released, [firstSource, engine.secondSource]);
  });
}

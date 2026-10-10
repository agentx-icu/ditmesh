import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';

final class _FakeSoloudApi implements SoloudApi {
  final List<String> calls = <String>[];
  bool initialized = false;
  int nextId = 1;
  int nextVoice = 101;
  Completer<void>? initGate;
  Completer<void>? loadGate;
  Object? loadError;
  Object? playError;
  Object? stopError;
  Object? resumeError;
  Completer<void>? disposeSourceGate;
  Object? disposeSourceError;

  @override
  bool get isInitialized => initialized;

  @override
  Future<void> init() async {
    calls.add('init');
    final gate = initGate;
    if (gate != null) await gate.future;
    initialized = true;
  }

  @override
  Future<SidetoneSource> loadSineWaveform() async {
    calls.add('loadSineWaveform');
    final gate = loadGate;
    if (gate != null) await gate.future;
    final error = loadError;
    if (error != null) throw error;
    return SidetoneSource(nextId++);
  }

  @override
  void setWaveformFrequency(SidetoneSource source, double hz) =>
      calls.add('freq(${source.id}, $hz)');

  @override
  SidetoneVoice playLooping(SidetoneSource source, {required double volume}) {
    calls.add('playLooping(${source.id}, $volume)');
    final error = playError;
    if (error != null) throw error;
    return SidetoneVoice(nextVoice++);
  }

  @override
  void setVolume(SidetoneVoice voice, double volume) =>
      calls.add('setVolume(${voice.id}, $volume)');

  @override
  void fadeVolume(SidetoneVoice voice, double to, Duration over) =>
      calls.add('fade(${voice.id}, $to, ${over.inMilliseconds})');

  @override
  void resumeVoice(SidetoneVoice voice) {
    calls.add('resume(${voice.id})');
    final error = resumeError;
    if (error != null) throw error;
  }

  @override
  Future<void> stop(SidetoneVoice voice) async {
    calls.add('stop(${voice.id})');
    final error = stopError;
    if (error != null) throw error;
  }

  @override
  Future<void> disposeSource(SidetoneSource source) async {
    calls.add('disposeSource(${source.id})');
    final gate = disposeSourceGate;
    if (gate != null) await gate.future;
    final error = disposeSourceError;
    if (error != null) throw error;
  }

  @override
  Future<void> deinit() async {
    calls.add('deinit');
    initialized = false;
  }
}

final class _FakeForeground implements AppForeground {
  @override
  bool isForeground = true;
  void Function(bool)? listener;
  int cancelled = 0;

  @override
  VoidCallback listen(void Function(bool foreground) onChange) {
    listener = onChange;
    return () => cancelled++;
  }

  void set(bool foreground) {
    isForeground = foreground;
    listener?.call(foreground);
  }
}

final class _FakeSession implements AudioSessionApi {
  _FakeSession(this.log);

  final List<String> log;

  @override
  Future<void> configureForPlayback() async => log.add('session');
}

/// Only what [FlutterSoloudApi.init] / [FlutterSoloudApi.resumeVoice] touch.
final class _FakeSoLoud implements SoLoud {
  _FakeSoLoud(this.log);

  final List<String> log;
  bool running = false;

  @override
  bool get isInitialized => running;

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
  }) async {
    log.add('engine.init');
    running = true;
  }

  @override
  void deinit() {
    log.add('engine.deinit');
    running = false;
  }

  @override
  void setPause(SoundHandle handle, bool pause) =>
      log.add('setPause(${handle.id}, $pause)');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeSoloudApi api;
  late SidetoneSink sink;

  setUp(() {
    api = _FakeSoloudApi();
    sink = SidetoneSink(api: api, frequencyHz: 600, volume: 0.5);
  });

  test('prepare initialises exactly once and starts a silent loop', () async {
    await Future.wait(<Future<void>>[sink.prepare(), sink.prepare()]);
    await sink.prepare();
    expect(sink.isPrepared, isTrue);
    expect(api.calls, <String>[
      'init',
      'loadSineWaveform',
      'freq(1, 600.0)',
      'playLooping(1, 0.0)',
    ]);
  });

  test(
    'on / off ramp the running voice with the configured envelope',
    () async {
      await sink.prepare();
      api.calls.clear();
      sink.on();
      expect(sink.isOn, isTrue);
      sink.on(); // ignored
      sink.off();
      sink.off(); // ignored
      expect(api.calls, <String>[
        'resume(101)',
        'fade(101, 0.5, 5)',
        'fade(101, 0.0, 5)',
      ]);
    },
  );

  test('on / off before prepare are ignored (no engine access)', () {
    sink.on();
    sink.off();
    expect(api.calls, isEmpty);
    expect(sink.isOn, isFalse);
  });

  test('frequency and volume can be changed live', () async {
    await sink.prepare();
    api.calls.clear();
    sink.frequencyHz = 800;
    sink.volume = 2; // clamped
    sink.on();
    sink.volume = 0.25; // applied immediately while on
    expect(api.calls, <String>[
      'freq(1, 800.0)',
      'resume(101)',
      'fade(101, 1.0, 5)',
      'setVolume(101, 0.25)',
    ]);
    expect(sink.volume, 0.25);
  });

  test('dispose stops the voice, frees the source and deinits', () async {
    await sink.prepare();
    sink.on();
    api.calls.clear();
    await sink.dispose();
    expect(api.calls, <String>['stop(101)', 'disposeSource(1)', 'deinit']);
    expect(sink.isPrepared, isFalse);
    expect(sink.isOn, isFalse);
    sink.on(); // safe after dispose
    expect(api.calls.length, 3);
  });

  test(
    'dispose while init is pending creates no voice and deinits once',
    () async {
      api.initGate = Completer<void>();
      final prepare = sink.prepare();
      await pumpEventQueue();
      final dispose = sink.dispose();
      api.initGate!.complete();
      await Future.wait(<Future<void>>[prepare, dispose]);
      expect(api.calls, <String>['init', 'deinit']);
      expect(sink.isPrepared, isFalse);
    },
  );

  test(
    'dispose while the source loads frees it without starting a voice',
    () async {
      api.loadGate = Completer<void>();
      final prepare = sink.prepare();
      await pumpEventQueue();
      final dispose = sink.dispose();
      api.loadGate!.complete();
      await Future.wait(<Future<void>>[prepare, dispose]);
      expect(api.calls, <String>[
        'init',
        'loadSineWaveform',
        'disposeSource(1)',
        'deinit',
      ]);
    },
  );

  test('dispose is single-flight and prepare after it fails', () async {
    await sink.prepare();
    api.calls.clear();
    await Future.wait(<Future<void>>[sink.dispose(), sink.dispose()]);
    await sink.dispose();
    expect(api.calls, <String>['stop(101)', 'disposeSource(1)', 'deinit']);
    await expectLater(sink.prepare(), throwsStateError);
  });

  test('a failed prepare gives the engine back and can be retried', () async {
    api.loadError = StateError('no waveform');
    await expectLater(sink.prepare(), throwsStateError);
    expect(api.calls, <String>['init', 'loadSineWaveform', 'deinit']);
    api.loadError = null;
    api.calls.clear();
    await sink.prepare();
    expect(sink.isPrepared, isTrue);
    expect(api.calls.first, 'init');
  });

  test('dispose during a failed prepare\'s cleanup waits for it', () async {
    api.playError = StateError('no voice');
    api.disposeSourceGate = Completer<void>();
    final prepare = expectLater(sink.prepare(), throwsStateError);
    await pumpEventQueue();
    expect(api.calls.last, 'disposeSource(1)', reason: 'cleanup is running');
    var disposed = false;
    final dispose = sink.dispose().then((_) => disposed = true);
    await pumpEventQueue();
    expect(disposed, isFalse);
    api.disposeSourceGate!.complete();
    await prepare;
    await dispose;
    expect(api.calls.where((c) => c.startsWith('disposeSource')), hasLength(1));
    expect(api.calls.last, 'deinit');
  });

  test('prepare during a failed prepare\'s cleanup joins it', () async {
    api.playError = StateError('no voice');
    api.disposeSourceGate = Completer<void>();
    final first = expectLater(sink.prepare(), throwsStateError);
    await pumpEventQueue();
    final second = expectLater(sink.prepare(), throwsStateError);
    api.disposeSourceGate!.complete();
    await first;
    await second;
    expect(api.calls.where((c) => c == 'loadSineWaveform'), hasLength(1));
    expect(api.calls.last, 'deinit');
    api.playError = null;
    await sink.prepare();
    expect(sink.isPrepared, isTrue);
  });

  test('a prepare whose cleanup also fails reports the first error and '
      'can be retried', () async {
    api.playError = StateError('no voice');
    api.disposeSourceError = ArgumentError('engine gone');
    await expectLater(sink.prepare(), throwsStateError);
    expect(api.calls.last, 'deinit');
    api.playError = null;
    api.disposeSourceError = null;
    await sink.prepare();
    expect(sink.isPrepared, isTrue);
  });

  test('dispose still frees the source and deinits when stop throws', () async {
    await sink.prepare();
    api.calls.clear();
    api.stopError = StateError('engine gone');
    await expectLater(sink.dispose(), throwsStateError);
    expect(api.calls, <String>['stop(101)', 'disposeSource(1)', 'deinit']);
  });

  test('an engine whose native library cannot load fails in prepare, not '
      'in a constructor', () async {
    // SoLoud.instance loads the native plugin and throws when it cannot
    // (seen on Ubuntu 24.04: a bundled libopus needing glibc 2.43). That
    // must surface from prepare(), which callers guard, never from the
    // constructors they call unguarded.
    var resolved = 0;
    SoLoud unloadable() {
      resolved++;
      throw ArgumentError('Failed to load dynamic library');
    }

    late FlutterSoloudApi api;
    expect(
      () => api = FlutterSoloudApi(resolveEngine: unloadable),
      returnsNormally,
    );
    final broken = SidetoneSink(api: api);
    expect(resolved, 0);
    expect(api.isInitialized, isFalse);
    await expectLater(broken.prepare(), throwsArgumentError);
    expect(broken.isPrepared, isFalse);
    // A later prepare tries the engine again rather than replaying the
    // first failure.
    final attempts = resolved;
    await expectLater(broken.prepare(), throwsArgumentError);
    expect(resolved, attempts + 1);
    await broken.dispose();
  });

  test('custom ramp is honoured', () async {
    final custom = SidetoneSink(
      api: api,
      ramp: const Duration(milliseconds: 12),
    );
    await custom.prepare();
    custom.on();
    expect(api.calls.last, 'fade(101, 0.8, 12)');
  });

  group('mobile robustness', () {
    late _FakeForeground foreground;

    setUp(() {
      foreground = _FakeForeground();
      sink = SidetoneSink(api: api, foreground: foreground, volume: 0.5);
    });

    test('a voice the engine lost is replaced on the next key-down', () async {
      // An iOS interruption that never reports its end (or an engine that
      // dropped the handle) used to leave every later on() fading a dead
      // voice: silence until the screen was rebuilt.
      await sink.prepare();
      api.calls.clear();
      api.resumeError = StateError('device failed to start / handle gone');
      sink.on();
      api.resumeError = null;
      expect(api.calls, <String>[
        'resume(101)',
        'stop(101)',
        'playLooping(1, 0.0)',
        'fade(102, 0.5, 5)',
      ]);
      expect(sink.isOn, isTrue);
      sink.off();
      expect(api.calls.last, 'fade(102, 0.0, 5)');
    });

    test(
      'output refused (call in progress) is retried on the next on()',
      () async {
        await sink.prepare();
        api.resumeError = StateError('session not active');
        api.playError = StateError('session not active');
        sink.on();
        expect(sink.isOn, isFalse);
        api.resumeError = null;
        api.playError = null;
        api.calls.clear();
        sink.on();
        expect(sink.isOn, isTrue);
        expect(api.calls, <String>['playLooping(1, 0.0)', 'fade(102, 0.5, 5)']);
      },
    );

    test('backgrounding stops the idle voice and mutes keying until the '
        'app returns', () async {
      await sink.prepare();
      sink.on();
      api.calls.clear();
      foreground.set(false);
      expect(sink.isOn, isFalse);
      await pumpEventQueue();
      expect(api.calls, <String>['stop(101)']);
      sink.on();
      sink.off();
      expect(api.calls, <String>['stop(101)'], reason: 'muted in background');
      foreground.set(true);
      expect(api.calls.last, 'playLooping(1, 0.0)');
      sink.on();
      expect(api.calls.last, 'fade(102, 0.5, 5)');
    });

    test('inactive-style repeats of the same state change nothing', () async {
      await sink.prepare();
      api.calls.clear();
      foreground.set(true);
      foreground.set(true);
      expect(api.calls, isEmpty);
    });

    test(
      'prepared in the background starts no voice until foreground',
      () async {
        foreground.isForeground = false;
        await sink.prepare();
        expect(api.calls.where((c) => c.startsWith('playLooping')), isEmpty);
        expect(sink.isPrepared, isTrue);
        foreground.set(true);
        expect(api.calls.last, 'playLooping(1, 0.0)');
      },
    );

    test('dispose stops listening to the lifecycle', () async {
      await sink.prepare();
      await sink.dispose();
      expect(foreground.cancelled, 1);
      api.calls.clear();
      foreground.set(false);
      foreground.set(true);
      expect(api.calls, isEmpty);
    });
  });

  group('FlutterSoloudApi', () {
    test('configures the audio session before starting the engine, and '
        'only when it starts it', () async {
      final log = <String>[];
      final engine = _FakeSoLoud(log);
      final first = FlutterSoloudApi(
        engine: engine,
        session: _FakeSession(log),
      );
      final second = FlutterSoloudApi(
        engine: engine,
        session: _FakeSession(log),
      );
      await first.init();
      await second.init();
      expect(log, <String>['session', 'engine.init']);
      await first.deinit();
      await second.deinit();
      expect(log.last, 'engine.deinit');
    });

    test(
      'resumeVoice unpauses the handle, which restarts the device',
      () async {
        final log = <String>[];
        final api = FlutterSoloudApi(
          engine: _FakeSoLoud(log),
          session: _FakeSession(log),
        );
        api.resumeVoice(const SidetoneVoice(7));
        expect(log, <String>['setPause(7, false)']);
      },
    );
  });
}

import 'dart:async';

import 'package:flutter_soloud/flutter_soloud.dart';

import 'audio_session_api.dart';
import 'engine_leases.dart';

/// Opaque id of a loaded waveform source (a `flutter_soloud` `AudioSource`).
extension type const SidetoneSource(int id) {}

/// Opaque id of a playing voice (a `flutter_soloud` `SoundHandle`).
extension type const SidetoneVoice(int id) {}

/// The slice of the `flutter_soloud` API that [SidetoneSink] needs.
///
/// Exists so tests inject [FakeSoloudApi]-style doubles and CI never loads
/// the native SoLoud library. Keep it minimal: one method per engine call.
abstract interface class SoloudApi {
  bool get isInitialized;

  /// Starts the engine. Must be idempotent.
  Future<void> init();

  /// Loads a plain (non-super) sine waveform source.
  Future<SidetoneSource> loadSineWaveform();

  void setWaveformFrequency(SidetoneSource source, double hz);

  /// Starts [source] looping forever at [volume] and returns its voice.
  SidetoneVoice playLooping(SidetoneSource source, {required double volume});

  void setVolume(SidetoneVoice voice, double volume);

  /// Ramps the voice volume to [to] over [over] (linear, done by the mixer).
  void fadeVolume(SidetoneVoice voice, double to, Duration over);

  /// Makes sure [voice] is audible: restarts the output device when the OS
  /// stopped it behind the engine's back (an iOS interruption whose end was
  /// never signalled, Control Center, a lost route). Cheap when it runs.
  /// Throws when the device cannot start or [voice] no longer exists.
  void resumeVoice(SidetoneVoice voice);

  Future<void> stop(SidetoneVoice voice);

  Future<void> disposeSource(SidetoneSource source);

  /// Releases what [init] took: the engine stops once no adapter needs it.
  /// Idempotent, and safe to call while [init] is still running.
  Future<void> deinit();
}

/// Production [SoloudApi] on top of `flutter_soloud`.
///
/// Latency notes (needs on-device verification, see README):
/// * [bufferSize] 512 frames at 48 kHz is ~10.7 ms per buffer; SoLoud adds
///   one extra buffer of output latency, so ~21 ms before OS/driver latency.
///   256 frames halves that but underruns on weaker Android devices.
/// * `lowLatency: true` selects AAudio MMAP on Android (the default).
/// * Mono output halves mixer work; the sidetone is a single sine anyway.
final class FlutterSoloudApi implements SoloudApi {
  FlutterSoloudApi({
    SoLoud? engine,
    SoLoud Function()? resolveEngine,
    this.sampleRate = 48000,
    this.bufferSize = 512,
    this.channels = Channels.mono,
    AudioSessionApi session = const PlatformAudioSessionApi(),
  }) : _injected = engine,
       _resolveEngine = resolveEngine ?? _sharedEngine,
       _session = session;

  static SoLoud _sharedEngine() => SoLoud.instance;

  final SoLoud? _injected;

  /// Configured right before this adapter starts the engine (iOS category).
  final AudioSessionApi _session;

  /// How [_engine] is found when no `engine` was injected; tests pass one
  /// that throws to stand in for a native library that cannot be loaded.
  final SoLoud Function() _resolveEngine;

  /// Resolved on first use, not in the constructor: `SoLoud.instance` loads
  /// the native plugin library and throws when it cannot (missing or
  /// incompatible `.so`/`.dll`, no plugin in a unit test). Deferred, that
  /// failure surfaces from [init] -- inside the caller's `prepare` -- where
  /// it is handled (the Learn screens fall back to the screen flash), instead
  /// of from a constructor nobody guards.
  SoLoud get _engine => _injected ?? _resolveEngine();
  final int sampleRate;
  final int bufferSize;
  final Channels channels;

  /// One lease table per engine, shared by every adapter in this isolate
  /// (the engine is an isolate-wide singleton).
  static final Expando<EngineLeases> _leasesByEngine = Expando<EngineLeases>(
    'SoLoud engine leases',
  );

  final Map<int, AudioSource> _sources = <int, AudioSource>{};
  Future<void>? _acquiring;
  bool _holdsLease = false;

  EngineLeases get _leases => _leasesByEngine[_engine] ??= EngineLeases(
    isInitialized: () => _engine.isInitialized,
    deinit: _engine.deinit,
  );

  /// False as well when the native library cannot be loaded at all.
  @override
  bool get isInitialized {
    try {
      return _engine.isInitialized;
    } on Object catch (_) {
      return false;
    }
  }

  /// Takes this adapter's lease on the shared engine, starting it when no
  /// one runs it yet. An engine somebody else started (e.g. a music player
  /// elsewhere in the app) is shared and never shut down by us.
  @override
  Future<void> init() {
    if (_holdsLease) {
      return Future<void>.value();
    }
    final pending = _acquiring;
    if (pending != null) {
      return pending;
    }
    // Published before _acquire runs: it can fail synchronously (an engine
    // whose library cannot load), and its `finally` must then clear the
    // future it belongs to, or every later init() would replay that failure
    // instead of retrying.
    final done = Completer<void>();
    _acquiring = done.future;
    unawaited(_acquire().then(done.complete, onError: done.completeError));
    return done.future;
  }

  Future<void> _acquire() async {
    try {
      await _leases.acquire(() async {
        await _session.configureForPlayback();
        await _engine.init(
          sampleRate: sampleRate,
          bufferSize: bufferSize,
          channels: channels,
        );
      });
      _holdsLease = true;
    } finally {
      _acquiring = null;
    }
  }

  @override
  Future<SidetoneSource> loadSineWaveform() async {
    final source = await _engine.loadWaveform(WaveForm.sin, false, 1, 0);
    _sources[source.soundHash.hash] = source;
    return SidetoneSource(source.soundHash.hash);
  }

  @override
  void setWaveformFrequency(SidetoneSource source, double hz) {
    _engine.setWaveformFreq(_source(source), hz);
  }

  @override
  SidetoneVoice playLooping(SidetoneSource source, {required double volume}) {
    final handle = _engine.play(_source(source), volume: volume, looping: true);
    // Never let voice culling steal the sidetone voice when the app plays
    // other sounds at the same time.
    _engine.setProtectVoice(handle, true);
    return SidetoneVoice(handle.id);
  }

  @override
  void setVolume(SidetoneVoice voice, double volume) {
    _engine.setVolume(SoundHandle(voice.id), volume);
  }

  @override
  void fadeVolume(SidetoneVoice voice, double to, Duration over) {
    _engine.fadeVolume(SoundHandle(voice.id), to, over);
  }

  /// `setPause(false)` on a running voice changes nothing but first runs
  /// the engine's `ensureAudioDeviceStarted`; plain volume changes never do.
  @override
  void resumeVoice(SidetoneVoice voice) {
    _engine.setPause(SoundHandle(voice.id), false);
  }

  @override
  Future<void> stop(SidetoneVoice voice) => _engine.stop(SoundHandle(voice.id));

  @override
  Future<void> disposeSource(SidetoneSource source) async {
    final audioSource = _sources.remove(source.id);
    if (audioSource != null) {
      await _engine.disposeSource(audioSource);
    }
  }

  @override
  Future<void> deinit() async {
    final acquiring = _acquiring;
    if (acquiring != null) {
      try {
        await acquiring;
      } on Object catch (_) {
        // The failed init took no lease; nothing to give back.
      }
    }
    _sources.clear();
    if (!_holdsLease) {
      return;
    }
    _holdsLease = false;
    await _leases.release();
  }

  AudioSource _source(SidetoneSource id) {
    final source = _sources[id.id];
    if (source == null) {
      throw StateError('Unknown sidetone source ${id.id}');
    }
    return source;
  }
}

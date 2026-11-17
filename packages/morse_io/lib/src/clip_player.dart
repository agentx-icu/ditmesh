import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

import 'soloud_api.dart';

/// Plays a short in-memory WAV clip (a recording selection), optionally
/// looping. Used by the recorded-audio workbench; the live sidetone keeps
/// using `SidetoneSink`.
abstract interface class ClipPlayer {
  bool get isPlaying;

  /// Fires `true` when a clip starts and `false` when it stops or ends.
  Stream<bool> get playing;

  /// Stops anything playing, then plays [wav] (RIFF/WAVE bytes).
  Future<void> play(
    Uint8List wav, {
    required Duration length,
    bool loop = false,
  });

  Future<void> stop();

  /// Releases the engine lease. The player cannot be used afterwards.
  Future<void> dispose();
}

/// [ClipPlayer] on the shared SoLoud engine. The engine lease is taken via
/// [FlutterSoloudApi] so the engine is shared with every sidetone sink and
/// shut down only by the last holder (see `EngineLeases`).
final class SoloudClipPlayer implements ClipPlayer {
  SoloudClipPlayer({FlutterSoloudApi? lease})
    : _lease = lease ?? FlutterSoloudApi();

  static int _nextSourceId = 0;

  final FlutterSoloudApi _lease;
  final StreamController<bool> _playing = StreamController<bool>.broadcast();
  Future<void> _operations = Future<void>.value();
  Future<void>? _disposal;
  AudioSource? _source;
  SoundHandle? _handle;
  Timer? _end;
  int _generation = 0;

  @override
  bool get isPlaying => _handle != null;

  @override
  Stream<bool> get playing => _playing.stream;

  @override
  Future<void> play(
    Uint8List wav, {
    required Duration length,
    bool loop = false,
  }) async {
    if (_disposal != null) throw StateError('clip player disposed');
    final generation = ++_generation;
    return _enqueue(() async {
      if (generation != _generation) return;
      await _stopCurrent();
      if (generation != _generation) return;
      try {
        await _lease.init();
        if (generation != _generation) return;
        final engine = _lease.engine;
        // SoLoud identifies loaded audio by name on its shared engine.
        final source = await engine.loadMem(
          'workbench_clip_${_nextSourceId++}.wav',
          wav,
        );
        if (generation != _generation) {
          await engine.disposeSource(source);
          return;
        }
        _source = source;
        _handle = engine.play(source, looping: loop);
      } on Object {
        await _stopCurrent();
        if (generation == _generation) rethrow;
        return;
      }
      _playing.add(true);
      if (!loop) {
        _end = Timer(length + const Duration(milliseconds: 50), () {
          if (generation == _generation) unawaited(stop());
        });
      }
    });
  }

  @override
  Future<void> stop() {
    _generation++;
    return _enqueue(_stopCurrent);
  }

  // Invalidation happens when requested. Resource operations settle in
  // order, including discarding a cancelled load before releasing its lease.
  Future<void> _enqueue(Future<void> Function() action) {
    final result = _operations.then((_) => action());
    _operations = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<void> _stopCurrent() async {
    _end?.cancel();
    _end = null;
    final handle = _handle;
    final source = _source;
    _handle = null;
    _source = null;
    if (handle == null && source == null) return;
    try {
      final engine = _lease.engine;
      try {
        if (handle != null && engine.getIsValidVoiceHandle(handle)) {
          await engine.stop(handle);
        }
      } finally {
        if (source != null) await engine.disposeSource(source);
      }
    } on Object catch (_) {
      // An invalid or already retired voice cannot keep playing.
    }
    if (handle != null) _playing.add(false);
  }

  @override
  Future<void> dispose() {
    final disposal = _disposal;
    if (disposal != null) return disposal;
    _generation++;
    return _disposal = _enqueue(() async {
      await _stopCurrent();
      try {
        await _lease.deinit();
      } finally {
        await _playing.close();
      }
    });
  }
}

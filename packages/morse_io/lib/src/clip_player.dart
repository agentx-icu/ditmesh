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

  final FlutterSoloudApi _lease;
  final StreamController<bool> _playing = StreamController<bool>.broadcast();
  AudioSource? _source;
  SoundHandle? _handle;
  Timer? _end;
  bool _disposed = false;
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
    if (_disposed) throw StateError('clip player disposed');
    await stop();
    final generation = _generation;
    await _lease.init();
    final engine = SoLoud.instance;
    final source = await engine.loadMem('workbench_clip.wav', wav);
    if (_disposed || generation != _generation) {
      await engine.disposeSource(source);
      return;
    }
    _source = source;
    _handle = engine.play(source, looping: loop);
    _playing.add(true);
    if (!loop) {
      _end = Timer(length + const Duration(milliseconds: 50), () {
        if (generation == _generation) unawaited(stop());
      });
    }
  }

  @override
  Future<void> stop() async {
    // A play still loading its clip must not start after this stop.
    _generation++;
    _end?.cancel();
    _end = null;
    final handle = _handle;
    final source = _source;
    _handle = null;
    _source = null;
    if (handle == null && source == null) return;
    final engine = SoLoud.instance;
    try {
      if (handle != null && engine.getIsValidVoiceHandle(handle)) {
        await engine.stop(handle);
      }
      if (source != null) await engine.disposeSource(source);
    } on Object catch (_) {
      // The engine went away (lease released elsewhere): nothing to stop.
    }
    if (!_playing.isClosed) _playing.add(false);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    await stop();
    _disposed = true;
    _generation++;
    await _lease.deinit();
    await _playing.close();
  }
}

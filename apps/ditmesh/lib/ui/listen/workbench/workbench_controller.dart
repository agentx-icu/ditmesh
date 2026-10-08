import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:morse_dsp/morse_dsp.dart';
import 'package:morse_io/morse_io.dart';

import 'recording_files.dart';

/// Why an import or open failed; the UI localises each.
enum WorkbenchFailure { format, missingFile, io }

/// State of the recorded-audio workbench (functional spec §11): one open
/// recording, its waveform, a selection, tuning, decoding and playback.
///
/// Positions are frames on the recording's own sample clock. Changing the
/// selection or the tuning invalidates the decode result and cancels a
/// decode in flight, so no stale text is ever shown for a new selection.
class WorkbenchController extends ChangeNotifier {
  WorkbenchController({required this.library, required this.player}) {
    _playerSub = player.playing.listen((on) {
      if (_disposed) return;
      _playing = on;
      notifyListeners();
    });
  }

  static const int waveformBuckets = 400;

  /// Longest selection played at once (memory bound for the clip).
  static const Duration maxPlay = Duration(minutes: 5);

  final RecordingLibrary library;
  final ClipPlayer player;
  StreamSubscription<bool>? _playerSub;

  WavPcmReader? _reader;
  String? _name;
  String _file = RecordingLibrary.workingFile;
  WaveformEnvelope? _waveform;
  int _waveGen = 0;
  int _start = 0;
  int _end = 0;
  bool _autoTune = true;
  double _manualHz = 700;
  DecodeCancelToken? _token;
  double? _progress;
  SegmentDecodeResult? _result;
  bool _playing = false;
  bool _loop = false;
  bool _busy = false;
  bool _disposed = false;
  WorkbenchFailure? _failure;
  WavError? _wavError;

  WavPcmReader? get reader => _reader;
  WavInfo? get info => _reader?.info;
  String? get name => _name;

  /// Managed media path of the open recording (relative to the profile).
  String get file => _file;
  WaveformEnvelope? get waveform => _waveform;
  int get start => _start;
  int get end => _end;
  bool get autoTune => _autoTune;
  double get manualHz => _manualHz;
  bool get decoding => _token != null;
  double? get progress => _progress;
  SegmentDecodeResult? get result => _result;
  bool get playing => _playing;
  bool get loop => _loop;
  bool get busy => _busy;
  WorkbenchFailure? get failure => _failure;
  WavError? get wavError => _wavError;

  Duration positionOf(int frame) =>
      info == null ? Duration.zero : info!.durationOf(frame);

  /// Imports [picked]; on failure the open recording stays as it was.
  Future<bool> importRecording(PickedRecording picked) => _guard(() async {
    final reader = await library.importTo(
      picked,
      beforeReplace: () async {
        await stopPlayback();
        _cancelDecode();
        await closeReader(_reader);
        _reader = null;
      },
    );
    _install(reader, picked.name, RecordingLibrary.workingFile);
  });

  /// Opens a saved recording; [selection] restores a saved range.
  Future<bool> openSaved(
    String file,
    String name, {
    (Duration, Duration)? selection,
  }) => _guard(() async {
    if (!await library.exists(file)) {
      throw const FileSystemException('missing');
    }
    final reader = await library.open(file);
    await stopPlayback();
    _cancelDecode();
    await closeReader(_reader);
    _install(reader, name, file);
    if (selection != null) {
      setSelection(
        reader.info.frameAt(selection.$1),
        reader.info.frameAt(selection.$2),
      );
    }
  });

  Future<bool> _guard(Future<void> Function() body) async {
    _busy = true;
    _failure = null;
    _wavError = null;
    notifyListeners();
    try {
      await body();
      return true;
    } on WavFormatException catch (e) {
      _failure = WorkbenchFailure.format;
      _wavError = e.error;
      return false;
    } on FileSystemException {
      _failure = WorkbenchFailure.missingFile;
      return false;
    } on Object {
      _failure = WorkbenchFailure.io;
      return false;
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  void _install(WavPcmReader reader, String name, String file) {
    _reader = reader;
    _name = name;
    _file = file;
    _start = 0;
    _end = reader.info.frameCount;
    _result = null;
    _waveform = null;
    unawaited(_buildWaveform(reader));
  }

  Future<void> _buildWaveform(WavPcmReader reader) async {
    final gen = ++_waveGen;
    final envelope = await WaveformEnvelope.build(
      reader,
      math.max(1, math.min(waveformBuckets, reader.info.frameCount)),
      isCancelled: () => _disposed || gen != _waveGen,
    );
    if (_disposed || gen != _waveGen || envelope == null) return;
    _waveform = envelope;
    notifyListeners();
  }

  /// Sets the selection (frames, clamped and ordered).
  void setSelection(int start, int end) {
    final total = info?.frameCount ?? 0;
    var a = start.clamp(0, total);
    var b = end.clamp(0, total);
    if (b < a) (a, b) = (b, a);
    if (a == _start && b == _end) return;
    _start = a;
    _end = b;
    _invalidate();
  }

  void setTuning({bool? auto, double? hz}) {
    _autoTune = auto ?? _autoTune;
    _manualHz = hz ?? _manualHz;
    _invalidate();
  }

  void setLoop(bool loop) {
    _loop = loop;
    notifyListeners();
  }

  void _invalidate() {
    _cancelDecode();
    // Playback of the old selection or tuning is stale too.
    if (_playing) unawaited(stopPlayback());
    _playGen++;
    _result = null;
    notifyListeners();
  }

  void _cancelDecode() {
    _token?.cancel();
    _token = null;
    _progress = null;
  }

  /// Decodes the selection. A cancel (or a selection/tuning change) stops
  /// every later update of this run.
  Future<void> decode() async {
    final reader = _reader;
    if (reader == null || _end <= _start) return;
    _cancelDecode();
    final token = DecodeCancelToken();
    _token = token;
    _result = null;
    _progress = 0;
    notifyListeners();
    final result = await decodeSegment(
      reader,
      startFrame: _start,
      endFrame: _end,
      autoTune: _autoTune,
      manualToneHz: _manualHz,
      cancel: token,
      onProgress: (p) {
        if (identical(_token, token) && !_disposed) {
          _progress = p;
          notifyListeners();
        }
      },
    );
    if (_disposed || !identical(_token, token) || token.isCancelled) return;
    _token = null;
    _progress = null;
    _result = result;
    notifyListeners();
  }

  void cancelDecode() {
    _cancelDecode();
    notifyListeners();
  }

  /// Bumped by every stop / background / selection or tuning change: a
  /// play request still reading PCM must not start sound afterwards.
  int _playGen = 0;

  Future<void> togglePlay() async {
    if (_playing) {
      await stopPlayback();
      return;
    }
    final reader = _reader;
    if (reader == null || _end <= _start) return;
    final gen = ++_playGen;
    final frames = math.min(_end - _start, reader.info.frameAt(maxPlay));
    final mono = await reader.readMono(_start, frames);
    if (_disposed || gen != _playGen || !identical(reader, _reader)) return;
    await player.play(
      monoWav(mono, reader.info.sampleRate),
      length: reader.info.durationOf(frames),
      loop: _loop,
    );
  }

  /// Background / leaving: stop sound (also one still being prepared);
  /// resuming is up to the learner.
  Future<void> stopPlayback() {
    _playGen++;
    return player.stop();
  }

  /// PCM16 mono WAV bytes of [samples] (-1..1) at [sampleRate].
  static Uint8List monoWav(Float64List samples, int sampleRate) {
    final data = samples.length * 2;
    final b = ByteData(44 + data);
    void tag(int at, String s) {
      for (var i = 0; i < 4; i++) {
        b.setUint8(at + i, s.codeUnitAt(i));
      }
    }

    tag(0, 'RIFF');
    b.setUint32(4, 36 + data, Endian.little);
    tag(8, 'WAVE');
    tag(12, 'fmt ');
    b.setUint32(16, 16, Endian.little);
    b.setUint16(20, 1, Endian.little);
    b.setUint16(22, 1, Endian.little);
    b.setUint32(24, sampleRate, Endian.little);
    b.setUint32(28, sampleRate * 2, Endian.little);
    b.setUint16(32, 2, Endian.little);
    b.setUint16(34, 16, Endian.little);
    tag(36, 'data');
    b.setUint32(40, data, Endian.little);
    for (var i = 0; i < samples.length; i++) {
      final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
      b.setInt16(44 + i * 2, v, Endian.little);
    }
    return b.buffer.asUint8List();
  }

  @override
  void dispose() {
    _disposed = true;
    _waveGen++;
    _playGen++;
    _cancelDecode();
    unawaited(_playerSub?.cancel());
    unawaited(player.stop());
    unawaited(closeReader(_reader));
    super.dispose();
  }
}

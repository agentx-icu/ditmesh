import 'dart:async';
import 'dart:typed_data';

import 'package:morse_dsp/testing.dart';
import 'package:morse_io/morse_io.dart';
import 'package:ditmesh/ui/listen/workbench/recording_files.dart';

/// RIFF/WAVE bytes for interleaved PCM16 [samples].
Uint8List wavOf(Int16List samples, {int sampleRate = 48000, int channels = 1}) {
  final data = samples.lengthInBytes;
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
  b.setUint16(22, channels, Endian.little);
  b.setUint32(24, sampleRate, Endian.little);
  b.setUint32(28, sampleRate * channels * 2, Endian.little);
  b.setUint16(32, channels * 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  b.setUint32(40, data, Endian.little);
  final out = b.buffer.asUint8List();
  out.setRange(
    44,
    44 + data,
    samples.buffer.asUint8List(samples.offsetInBytes, data),
  );
  return out;
}

/// A CW recording of [text] at 20 WPM.
Uint8List cwWav(String text, {int sampleRate = 8000, int channels = 1}) =>
    wavOf(
      SyntheticMorse(
        sampleRate: sampleRate,
        channels: channels,
      ).renderText(text),
      sampleRate: sampleRate,
      channels: channels,
    );

final class FakePicker implements RecordingPicker {
  FakePicker([this.next]);

  PickedRecording? next;
  int calls = 0;

  @override
  Future<PickedRecording?> pick() async {
    calls++;
    return next;
  }
}

final class FakeClipPlayer implements ClipPlayer {
  final StreamController<bool> _c = StreamController<bool>.broadcast();
  final List<(Uint8List, bool)> plays = [];
  bool _on = false;
  bool disposed = false;

  @override
  bool get isPlaying => _on;

  @override
  Stream<bool> get playing => _c.stream;

  @override
  Future<void> play(
    Uint8List wav, {
    required Duration length,
    bool loop = false,
  }) async {
    plays.add((wav, loop));
    _on = true;
    _c.add(true);
  }

  @override
  Future<void> stop() async {
    if (!_on) return;
    _on = false;
    _c.add(false);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _c.close();
  }

  /// The clip played to its end (the real player reports that as a stop).
  void end() {
    if (!_on) return;
    _on = false;
    _c.add(false);
  }
}

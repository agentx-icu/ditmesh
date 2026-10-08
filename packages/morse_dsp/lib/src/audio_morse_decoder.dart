import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:morse_core/morse_core.dart';

import 'envelope_gate.dart';
import 'goertzel.dart';
import 'pcm.dart';
import 'tone_finder.dart';

/// Microphone PCM -> decoded text.
///
/// ```text
/// feed(pcm16) -> downmix -> blocks of [blockSize] -> GoertzelDetector.power
///             -> EnvelopeGate -> keyDown/keyUp(sampleClock) -> MorseDecoder
///                          \-> ToneFinder (auto-tune, retunes the Goertzel)
/// ```
///
/// Time never comes from the wall clock: every timestamp handed to the
/// [MorseDecoder] is `samples / sampleRate`, so feeding the same PCM always
/// yields the same text, regardless of how it is chunked or how fast it
/// arrives.
final class AudioMorseDecoder {
  AudioMorseDecoder({
    this.sampleRate = 48000,
    this.blockSize = 256,
    DecoderConfig decoderConfig = const DecoderConfig(),
    EnvelopeGateConfig gateConfig = const EnvelopeGateConfig(),
    ToneFinderConfig toneFinderConfig = const ToneFinderConfig(),
    bool autoTune = true,
    double manualFrequencyHz = defaultFrequencyHz,
  })  : assert(sampleRate > 0, 'sampleRate must be positive'),
        assert(blockSize > 0, 'blockSize must be positive'),
        _autoTune = autoTune,
        _manualFrequencyHz = manualFrequencyHz,
        _decoder = MorseDecoder(config: decoderConfig),
        _gate = EnvelopeGate(
          sampleRate: sampleRate,
          blockSize: blockSize,
          config: gateConfig,
        ),
        _finder = ToneFinder(sampleRate: sampleRate, config: toneFinderConfig),
        _goertzel = GoertzelDetector(
          frequencyHz: manualFrequencyHz,
          sampleRate: sampleRate,
          blockSize: blockSize,
        ) {
    _applyTuning();
  }

  /// Frequency used when auto-tune has not found a tone yet.
  static const double defaultFrequencyHz = 700;

  final int sampleRate;
  final int blockSize;

  final MorseDecoder _decoder;
  final EnvelopeGate _gate;
  final ToneFinder _finder;
  final GoertzelDetector _goertzel;
  final SampleBuffer _samples = SampleBuffer();
  final StreamController<double> _level = StreamController<double>.broadcast();

  bool _autoTune;
  double _manualFrequencyHz;

  /// Called synchronously for every gate transition, with its time on the
  /// sample clock (the same timestamp handed to the [MorseDecoder]). Lets a
  /// caller position decoded characters in the audio.
  void Function(bool isOn, Duration at)? onKeyTransition;
  int _blocks = 0;
  int _oddByte = -1;
  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // Output

  /// Decoded text so far.
  String get text => _decoder.text;

  /// `.`/`-` pattern of the character currently being received.
  String get pendingPattern => _decoder.pendingPattern;

  /// Decode events (element / character / word / unknownPattern), emitted
  /// synchronously from within [feed].
  Stream<DecodeEvent> get events => _decoder.events;

  /// One value per [feed] call: the loudest block level in that chunk, 0..1.
  Stream<double> get signalLevel => _level.stream;

  /// Level of the most recent block, 0..1 (see [EnvelopeGate.level]).
  double get currentLevel => _gate.level;

  /// Whether the gate currently reports the tone as keyed.
  bool get isToneOn => _gate.isOn;

  /// Whether a tone stands far enough above the noise to be gated.
  bool get hasSignal => _gate.hasSignal;

  /// Frequency the detector is currently tuned to.
  double get detectedFrequency => _goertzel.frequencyHz;

  /// True once auto-tune has locked onto a tone (always false in manual).
  bool get isToneLocked => _autoTune && _finder.isLocked;

  /// Latest spectrum decision from the tone finder.
  ToneScan? get lastToneScan => _finder.lastScan;

  Duration get estimatedDit => _decoder.estimatedDit;

  /// PARIS speed implied by [estimatedDit].
  double get estimatedWpm {
    final int us = _decoder.estimatedDit.inMicroseconds;
    return us <= 0 ? 0 : 1200 * Duration.microsecondsPerMillisecond / us;
  }

  /// Sample-count clock: audio time consumed so far.
  Duration get position => _duration(_blocks * blockSize + _samples.length);

  /// Duration of one analysis block.
  Duration get blockDuration => _gate.blockDuration;

  // ---------------------------------------------------------------------------
  // Tuning

  bool get autoTune => _autoTune;

  set autoTune(bool value) {
    if (value == _autoTune) return;
    _autoTune = value;
    _applyTuning();
  }

  /// Frequency used when [autoTune] is off (and as the fallback before the
  /// finder has seen a tone). Setting it switches auto-tune off.
  double get manualFrequencyHz => _manualFrequencyHz;

  set manualFrequencyHz(double hz) {
    _manualFrequencyHz = hz;
    _autoTune = false;
    _applyTuning();
  }

  void _applyTuning() {
    _finder.manualFrequencyHz = _autoTune ? null : _manualFrequencyHz;
    _goertzel.frequencyHz = _finder.frequencyHz ?? _manualFrequencyHz;
  }

  // ---------------------------------------------------------------------------
  // Input

  /// Feeds interleaved signed 16-bit PCM with [channels] channels.
  void feed(List<int> pcm16, {int channels = 1}) {
    _checkLive();
    Pcm.downmixInt16(pcm16, channels, _samples);
    _process();
  }

  /// Feeds interleaved float PCM (nominal -1..1) with [channels] channels.
  void feedFloat(List<double> pcm, {int channels = 1}) {
    _checkLive();
    Pcm.downmixFloat(pcm, channels, _samples);
    _process();
  }

  /// Feeds raw little-endian 16-bit PCM bytes as delivered by a recorder
  /// stream. An odd trailing byte is carried over to the next call.
  void feedBytes(Uint8List bytes, {int channels = 1}) {
    _checkLive();
    Uint8List data = bytes;
    if (_oddByte >= 0) {
      data = Uint8List(bytes.length + 1)
        ..[0] = _oddByte
        ..setRange(1, bytes.length + 1, bytes);
      _oddByte = -1;
    }
    if (data.length.isOdd) {
      _oddByte = data[data.length - 1];
    }
    Pcm.downmixInt16(Pcm.int16FromBytes(data), channels, _samples);
    _process();
  }

  void _process() {
    final Float64List data = _samples.data;
    final int available = _samples.length;
    int offset = 0;
    double maxLevel = 0;
    while (available - offset >= blockSize) {
      if (_autoTune && _finder.feed(data, offset: offset, length: blockSize)) {
        _goertzel.frequencyHz = _finder.frequencyHz ?? _manualFrequencyHz;
      }
      final double power = _goertzel.power(data, offset: offset, length: blockSize);
      for (final GateTransition transition in _gate.feedAll(power)) {
        final Duration at = _duration(transition.atBlock * blockSize);
        onKeyTransition?.call(transition.isOn, at);
        if (transition.isOn) {
          _decoder.keyDown(at);
        } else {
          _decoder.keyUp(at);
        }
      }
      maxLevel = math.max(maxLevel, _gate.level);
      offset += blockSize;
      _blocks++;
    }
    _samples.consume(offset);
    if (offset == 0) return;

    // The gate commits a transition up to latencyBlocks after it began, so
    // the decoder's clock is held back by that much; otherwise a tick could
    // close a character just before the delayed keyDown that belongs to it.
    final int settled = _blocks - _gate.latencyBlocks;
    if (settled > 0) _decoder.tick(_duration(settled * blockSize));
    if (!_level.isClosed) _level.add(maxLevel);
  }

  // ---------------------------------------------------------------------------
  // Control

  /// Commits the character being received, if any, and returns the text.
  String commitPending() => _decoder.flush();

  /// Ends the input: a key still down is released at the last fed sample,
  /// so audio that stops mid-tone keeps its final mark. Returns whether a
  /// mark was cut off this way.
  bool endOfInput() {
    if (!_gate.isOn) return false;
    final Duration at = _duration(_blocks * blockSize + _samples.length);
    onKeyTransition?.call(false, at);
    _decoder.keyUp(at);
    return true;
  }

  /// Clears the text but keeps the tuning, the noise/peak estimates and the
  /// learned speed.
  void clearText() => _decoder.clearText();

  /// Forgets everything: text, speed, tuning lock, gate estimates and the
  /// sample clock. The auto-tune / manual settings are kept.
  void reset() {
    _decoder.reset();
    _gate.reset();
    _finder.reset();
    _samples.clear();
    _blocks = 0;
    _oddByte = -1;
    _applyTuning();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _decoder.dispose();
    unawaited(_level.close());
  }

  void _checkLive() {
    if (_disposed) {
      throw StateError('AudioMorseDecoder has been disposed');
    }
  }

  Duration _duration(int samples) => Duration(
        microseconds: (samples * Duration.microsecondsPerSecond) ~/ sampleRate,
      );
}

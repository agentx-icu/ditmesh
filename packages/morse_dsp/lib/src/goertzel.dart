import 'dart:math' as math;

import 'pcm.dart';

/// Single-bin tone power via the Goertzel algorithm.
///
/// Cheaper than an FFT when only one frequency matters: one multiply-add per
/// sample. The frequency does not need to sit on a DFT bin; off-bin tones
/// only pick up a small phase-dependent ripple (about 1/(N sin w)).
///
/// Power is normalised so that a full-scale sinusoid (amplitude 1.0 for
/// floats, 32768 for 16-bit) at exactly [frequencyHz] yields 1.0, i.e. the
/// result is the squared amplitude of the tone.
final class GoertzelDetector {
  GoertzelDetector({
    required double frequencyHz,
    this.sampleRate = 48000,
    this.blockSize = 256,
  })  : assert(sampleRate > 0, 'sampleRate must be positive'),
        assert(blockSize > 0, 'blockSize must be positive'),
        _frequencyHz = frequencyHz {
    _updateCoefficient();
  }

  final int sampleRate;

  /// Nominal block length. [power] accepts any length; this is the size the
  /// owner feeds and is exposed so callers can derive the block duration.
  final int blockSize;

  double _frequencyHz;
  double _coeff = 0;

  double get frequencyHz => _frequencyHz;

  set frequencyHz(double value) {
    if (value == _frequencyHz) return;
    _frequencyHz = value;
    _updateCoefficient();
  }

  /// Duration of one nominal block.
  Duration get blockDuration => Duration(
        microseconds:
            (blockSize * Duration.microsecondsPerSecond / sampleRate).round(),
      );

  /// Width of the detector's main lobe (rectangular window): `fs / N` Hz.
  double get bandwidthHz => sampleRate / blockSize;

  void _updateCoefficient() {
    final double omega = 2 * math.pi * _frequencyHz / sampleRate;
    _coeff = 2 * math.cos(omega);
  }

  /// Squared tone amplitude over `samples[offset, offset + length)` where the
  /// samples are floats in the nominal -1..1 range.
  double power(List<double> samples, {int offset = 0, int? length}) {
    final int n = length ?? (samples.length - offset);
    if (n <= 0) return 0;
    RangeError.checkValidRange(offset, offset + n, samples.length);
    final double coeff = _coeff;
    double s1 = 0;
    double s2 = 0;
    final int end = offset + n;
    for (int i = offset; i < end; i++) {
      final double s0 = samples[i] + coeff * s1 - s2;
      s2 = s1;
      s1 = s0;
    }
    return _normalise(s1, s2, n);
  }

  /// Squared tone amplitude over signed 16-bit samples, scaled so a
  /// full-scale sinusoid yields 1.0.
  double powerInt16(List<int> samples, {int offset = 0, int? length}) {
    final int n = length ?? (samples.length - offset);
    if (n <= 0) return 0;
    RangeError.checkValidRange(offset, offset + n, samples.length);
    final double coeff = _coeff;
    double s1 = 0;
    double s2 = 0;
    final int end = offset + n;
    for (int i = offset; i < end; i++) {
      final double s0 = samples[i] * Pcm.int16Scale + coeff * s1 - s2;
      s2 = s1;
      s1 = s0;
    }
    return _normalise(s1, s2, n);
  }

  /// |X(w)|^2 = s1^2 + s2^2 - coeff*s1*s2; for a tone of amplitude A that is
  /// (A N / 2)^2, so the squared amplitude is 4 |X|^2 / N^2.
  double _normalise(double s1, double s2, int n) {
    final double magSq = s1 * s1 + s2 * s2 - _coeff * s1 * s2;
    final double value = 4 * magSq / (n * n);
    return value < 0 ? 0 : value;
  }

  /// Power in dB relative to a full-scale sinusoid. Zero power maps to
  /// [silenceDb] rather than -infinity.
  static double toDb(double power) =>
      power <= 0 ? silenceDb : 10 * math.log(power) / math.ln10;

  /// dB value reported for exact digital silence.
  static const double silenceDb = -160;
}

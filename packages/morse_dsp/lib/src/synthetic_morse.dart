import 'dart:math' as math;
import 'dart:typed_data';

import 'package:morse_core/morse_core.dart';

import 'pcm.dart';

/// Renders a Morse timeline to 16-bit PCM with a keyed sine tone and
/// optional seeded Gaussian noise, for deterministic round-trip tests.
///
/// [snrDb] is the ratio of tone power to *wideband* noise power. Because the
/// detector only sees noise inside its own bin (about fs / blockSize wide),
/// the in-bin SNR is roughly `snrDb + 10 log10(sampleRate / 2 / bandwidth)`,
/// i.e. ~21 dB better for 256-sample blocks at 48 kHz.
final class SyntheticMorse {
  SyntheticMorse({
    this.sampleRate = 48000,
    this.toneHz = 700,
    this.amplitude = 0.4,
    this.snrDb,
    this.seed = 1,
    this.rampMs = 3,
    this.leadIn = const Duration(milliseconds: 300),
    this.tail = const Duration(milliseconds: 600),
    this.channels = 1,
  })  : assert(sampleRate > 0, 'sampleRate must be positive'),
        assert(amplitude >= 0 && amplitude <= 1, 'amplitude in 0..1'),
        assert(channels >= 1, 'channels must be >= 1');

  final int sampleRate;
  final double toneHz;

  /// Tone amplitude relative to full scale.
  final double amplitude;

  /// Tone-to-noise power ratio in dB; null renders without noise.
  final double? snrDb;

  /// Seed for the noise generator; same seed, same bytes.
  final int seed;

  /// Raised-cosine key ramps applied to both ends of every mark.
  final double rampMs;

  /// Silence (plus noise) before the first and after the last element, so
  /// the gate can settle and the last word can resolve.
  final Duration leadIn;
  final Duration tail;

  /// Interleaved output channels; every channel carries the same signal.
  final int channels;

  /// Renders [timeline] (e.g. from `MorseEncoder.encode`).
  Int16List render(List<MorseElement> timeline) {
    final int total = _samplesFor(leadIn) +
        timeline.fold<int>(0, (int n, MorseElement e) => n + _samplesFor(e.duration)) +
        _samplesFor(tail);
    final Float64List mono = Float64List(total);
    int cursor = _samplesFor(leadIn);
    final int ramp = (rampMs * sampleRate / 1000).round();
    final double omega = 2 * math.pi * toneHz / sampleRate;
    for (final MorseElement e in timeline) {
      final int n = _samplesFor(e.duration);
      if (e.on) {
        final int r = math.min(ramp, n ~/ 2);
        for (int i = 0; i < n; i++) {
          final int t = cursor + i;
          mono[t] = amplitude * math.sin(omega * t) * _envelope(i, n, r);
        }
      }
      cursor += n;
    }
    _addNoise(mono);
    return _toInt16(mono);
  }

  /// Convenience: encodes [text] at [wpm] (optionally Farnsworth) and renders it.
  Int16List renderText(String text, {double wpm = 20, double? farnsworthWpm}) =>
      render(MorseEncoder.encode(
        text,
        MorseTiming(wpm: wpm, farnsworthWpm: farnsworthWpm),
      ));

  /// Splits interleaved 16-bit PCM into little-endian byte chunks of
  /// [framesPerChunk] frames, the shape a recorder stream delivers.
  static List<Uint8List> toByteChunks(
    Int16List pcm,
    int framesPerChunk, {
    int channels = 1,
  }) {
    final int step = framesPerChunk * channels;
    final List<Uint8List> out = <Uint8List>[];
    for (int i = 0; i < pcm.length; i += step) {
      final int end = math.min(pcm.length, i + step);
      out.add(Pcm.bytesFromInt16(pcm.sublist(i, end)));
    }
    return out;
  }

  int _samplesFor(Duration d) =>
      (d.inMicroseconds * sampleRate / Duration.microsecondsPerSecond).round();

  static double _envelope(int i, int n, int ramp) {
    if (ramp <= 0) return 1;
    if (i < ramp) return 0.5 * (1 - math.cos(math.pi * i / ramp));
    final int fromEnd = n - 1 - i;
    if (fromEnd < ramp) return 0.5 * (1 - math.cos(math.pi * fromEnd / ramp));
    return 1;
  }

  void _addNoise(Float64List mono) {
    final double? snr = snrDb;
    if (snr == null) return;
    final double tonePower = amplitude * amplitude / 2;
    final double sigma = math.sqrt(tonePower / math.pow(10, snr / 10));
    final math.Random rng = math.Random(seed);
    for (int i = 0; i < mono.length; i += 2) {
      // Box-Muller: two Gaussians per draw.
      final double u1 = 1 - rng.nextDouble();
      final double u2 = rng.nextDouble();
      final double mag = sigma * math.sqrt(-2 * math.log(u1));
      mono[i] += mag * math.cos(2 * math.pi * u2);
      if (i + 1 < mono.length) mono[i + 1] += mag * math.sin(2 * math.pi * u2);
    }
  }

  Int16List _toInt16(Float64List mono) {
    final Int16List out = Int16List(mono.length * channels);
    for (int i = 0; i < mono.length; i++) {
      final int v = (mono[i] * 32767).round().clamp(-32768, 32767).toInt();
      final int base = i * channels;
      for (int c = 0; c < channels; c++) {
        out[base + c] = v;
      }
    }
    return out;
  }
}

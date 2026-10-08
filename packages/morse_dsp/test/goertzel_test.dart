import 'dart:math' as math;
import 'dart:typed_data';

import 'package:morse_dsp/morse_dsp.dart';
import 'package:test/test.dart';

Float64List _sine(double hz, double amplitude, int n, {int sampleRate = 48000}) {
  final Float64List out = Float64List(n);
  for (int i = 0; i < n; i++) {
    out[i] = amplitude * math.sin(2 * math.pi * hz * i / sampleRate);
  }
  return out;
}

void main() {
  group('GoertzelDetector', () {
    test('reports the squared amplitude of an on-bin tone', () {
      // 750 Hz is exactly bin 4 for N = 256 at 48 kHz.
      final GoertzelDetector det = GoertzelDetector(frequencyHz: 750);
      final double power = det.power(_sine(750, 0.8, 256));
      expect(power, closeTo(0.64, 0.01));
    });

    test('rejects a tone on a different bin', () {
      final GoertzelDetector det = GoertzelDetector(frequencyHz: 937.5);
      final double power = det.power(_sine(750, 0.8, 256));
      expect(power, lessThan(1e-6));
    });

    test('Int16 input matches the float path', () {
      final Float64List f = _sine(750, 0.8, 256);
      final Int16List i16 = Int16List.fromList(
        f.map((double v) => (v * 32767).round()).toList(growable: false),
      );
      final GoertzelDetector det = GoertzelDetector(frequencyHz: 750);
      expect(det.powerInt16(i16), closeTo(det.power(f), 0.001));
    });

    test('picks the right bin among 25 Hz candidates', () {
      const int n = 2048;
      final Float64List tone = _sine(640, 0.5, n);
      double best = -1;
      double bestHz = 0;
      for (double hz = 400; hz <= 1000; hz += 25) {
        final double p =
            GoertzelDetector(frequencyHz: hz, blockSize: n).power(tone);
        if (p > best) {
          best = p;
          bestHz = hz;
        }
      }
      expect(bestHz, 650);
    });

    test('silence is zero power and a finite dB value', () {
      final GoertzelDetector det = GoertzelDetector(frequencyHz: 700);
      final double p = det.power(Float64List(256));
      expect(p, 0);
      expect(GoertzelDetector.toDb(p), GoertzelDetector.silenceDb);
      expect(GoertzelDetector.toDb(1), closeTo(0, 1e-9));
      expect(GoertzelDetector.toDb(0.1), closeTo(-10, 1e-9));
    });

    test('offset and length select a sub-range', () {
      final Float64List buf = Float64List(1024);
      buf.setRange(512, 768, _sine(750, 0.5, 256));
      final GoertzelDetector det = GoertzelDetector(frequencyHz: 750);
      expect(det.power(buf, offset: 512, length: 256), closeTo(0.25, 0.01));
      expect(det.power(buf, offset: 0, length: 256), 0);
    });

    test('retuning changes the response', () {
      final GoertzelDetector det = GoertzelDetector(frequencyHz: 750);
      final Float64List tone = _sine(937.5, 0.8, 256);
      expect(det.power(tone), lessThan(1e-6));
      det.frequencyHz = 937.5;
      expect(det.power(tone), closeTo(0.64, 0.01));
      expect(det.blockDuration.inMicroseconds, 5333);
      expect(det.bandwidthHz, 187.5);
    });
  });
}

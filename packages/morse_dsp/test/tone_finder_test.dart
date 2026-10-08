import 'dart:math' as math;
import 'dart:typed_data';

import 'package:morse_dsp/morse_dsp.dart';
import 'package:test/test.dart';

Float64List _tone(double hz, int windows, {double amplitude = 0.3}) {
  const int n = 2048;
  final Float64List out = Float64List(n * windows);
  for (int i = 0; i < out.length; i++) {
    out[i] = amplitude * math.sin(2 * math.pi * hz * i / 48000);
  }
  return out;
}

void main() {
  group('ToneFinder', () {
    test('scan finds a tone between two candidates', () {
      final ToneFinder finder = ToneFinder();
      final ToneScan scan = finder.scan(_tone(637, 1));
      expect(scan.isTone, isTrue);
      expect(scan.frequencyHz, closeTo(637, 8));
      expect(scan.prominenceDb, greaterThan(12));
    });

    test('scan treats silence as no tone', () {
      final ToneFinder finder = ToneFinder();
      final ToneScan scan = finder.scan(Float64List(2048));
      expect(scan.isTone, isFalse);
      expect(finder.frequencyHz, isNull);
    });

    test('scan treats white noise as no tone', () {
      final math.Random rng = math.Random(7);
      final Float64List noise = Float64List(2048);
      for (int i = 0; i < noise.length; i++) {
        noise[i] = (rng.nextDouble() * 2 - 1) * 0.1;
      }
      final ToneFinder finder = ToneFinder();
      // 25 bins of white noise: the max sits well under 12 dB over the
      // median for essentially every seed; check a handful.
      int tones = 0;
      for (int trial = 0; trial < 20; trial++) {
        for (int i = 0; i < noise.length; i++) {
          noise[i] = (rng.nextDouble() * 2 - 1) * 0.1;
        }
        if (finder.scan(noise).isTone) tones++;
      }
      expect(tones, lessThanOrEqualTo(1));
    });

    test('locks after three agreeing windows', () {
      final ToneFinder finder = ToneFinder();
      expect(finder.feed(_tone(640, 1)), isTrue);
      expect(finder.isLocked, isFalse);
      expect(finder.frequencyHz, closeTo(640, 8), reason: 'provisional');
      finder.feed(_tone(640, 2));
      expect(finder.isLocked, isTrue);
      expect(finder.lockedFrequencyHz, closeTo(640, 8));
    });

    test('holds the lock through silence and short intrusions', () {
      final ToneFinder finder = ToneFinder()..feed(_tone(640, 3));
      expect(finder.isLocked, isTrue);
      finder.feed(Float64List(2048 * 10));
      expect(finder.frequencyHz, closeTo(640, 8));
      finder.feed(_tone(900, 3));
      expect(finder.frequencyHz, closeTo(640, 8));
      expect(finder.lastScan!.frequencyHz, closeTo(900, 8));
    });

    test('moves the lock after six windows of another tone', () {
      final ToneFinder finder = ToneFinder()..feed(_tone(640, 3));
      finder.feed(_tone(900, 5));
      expect(finder.frequencyHz, closeTo(640, 8));
      expect(finder.feed(_tone(900, 1)), isTrue);
      expect(finder.frequencyHz, closeTo(900, 8));
      expect(finder.isLocked, isTrue);
    });

    test('a fluctuating intruder does not accumulate towards unlock', () {
      final ToneFinder finder = ToneFinder()..feed(_tone(640, 3));
      for (int i = 0; i < 12; i++) {
        finder.feed(_tone(i.isEven ? 900 : 450, 1));
      }
      expect(finder.frequencyHz, closeTo(640, 8));
    });

    test('manual override wins and survives reset', () {
      final ToneFinder finder = ToneFinder()..manualFrequencyHz = 555;
      finder.feed(_tone(640, 6));
      expect(finder.frequencyHz, 555);
      expect(finder.lastScan!.frequencyHz, closeTo(640, 8));
      finder.reset();
      expect(finder.frequencyHz, 555);
      finder.manualFrequencyHz = null;
      expect(finder.frequencyHz, isNull);
    });

    test('feed accepts partial windows across calls', () {
      final ToneFinder finder = ToneFinder();
      final Float64List tone = _tone(700, 3);
      for (int i = 0; i < tone.length; i += 256) {
        finder.feed(tone, offset: i, length: 256);
      }
      expect(finder.isLocked, isTrue);
      expect(finder.frequencyHz, closeTo(700, 8));
    });

    test('scans the configured range edge to edge', () {
      const ToneFinderConfig config = ToneFinderConfig();
      expect(config.candidateCount, 25);
      final ToneFinder finder = ToneFinder();
      expect(finder.scan(_tone(400, 1)).frequencyHz, closeTo(400, 8));
      expect(finder.scan(_tone(1000, 1)).frequencyHz, closeTo(1000, 8));
    });
  });
}

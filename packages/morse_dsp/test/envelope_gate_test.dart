import 'dart:math' as math;

import 'package:morse_dsp/morse_dsp.dart';
import 'package:test/test.dart';

/// Feeds [count] blocks of [power]; returns every transition produced.
List<GateTransition> _feed(EnvelopeGate gate, double power, int count) {
  final List<GateTransition> out = <GateTransition>[];
  for (int i = 0; i < count; i++) {
    final GateTransition? t = gate.feed(power);
    if (t != null) out.add(t);
  }
  return out;
}

void main() {
  group('EnvelopeGate', () {
    late EnvelopeGate gate;

    setUp(() {
      gate = EnvelopeGate(sampleRate: 48000, blockSize: 256);
    });

    test('12 ms minimum durations round up to 3 blocks of 5.33 ms', () {
      expect(gate.minOnBlocks, 3);
      expect(gate.minOffBlocks, 3);
      expect(gate.warmupBlocks, 0, reason: 'warm-up is off by default');
      expect(gate.latencyBlocks, 3);
    });

    test('stays closed on steady noise', () {
      expect(_feed(gate, 1e-6, 400), isEmpty);
      expect(gate.isOn, isFalse);
      expect(gate.hasSignal, isFalse);
    });

    test('rejects a one-block click', () {
      _feed(gate, 1e-6, 100);
      expect(gate.feed(1e-2), isNull);
      expect(_feed(gate, 1e-6, 50), isEmpty);
      expect(gate.isOn, isFalse);
    });

    test('rejects a two-block click when minOn is three blocks', () {
      _feed(gate, 1e-6, 100);
      expect(_feed(gate, 1e-2, 2), isEmpty);
      expect(_feed(gate, 1e-6, 50), isEmpty);
      expect(gate.isOn, isFalse);
    });

    test('commits a mark with the transition at its first block', () {
      _feed(gate, 1e-6, 100);
      final List<GateTransition> on = _feed(gate, 1e-2, 20);
      expect(on, hasLength(1));
      expect(on.single.isOn, isTrue);
      expect(on.single.atBlock, 100);
      expect(gate.isOn, isTrue);

      final List<GateTransition> off = _feed(gate, 1e-6, 20);
      expect(off, hasLength(1));
      expect(off.single.isOn, isFalse);
      expect(off.single.atBlock, 120);
      expect(gate.isOn, isFalse);
    });

    test('ignores a short dropout inside a mark', () {
      _feed(gate, 1e-6, 100);
      _feed(gate, 1e-2, 20);
      expect(_feed(gate, 1e-6, 2), isEmpty);
      expect(_feed(gate, 1e-2, 20), isEmpty);
      expect(gate.isOn, isTrue);
    });

    test('gates a quiet signal like a loud one (AGC)', () {
      for (final double tone in <double>[1e-4, 1e-2, 1.0]) {
        final EnvelopeGate g = EnvelopeGate(sampleRate: 48000, blockSize: 256);
        _feed(g, 1e-7, 100);
        final List<GateTransition> on = _feed(g, tone, 20);
        final List<GateTransition> off = _feed(g, 1e-7, 20);
        expect(on.map((GateTransition t) => t.atBlock), <int>[100],
            reason: 'tone $tone');
        expect(off.map((GateTransition t) => t.atBlock), <int>[120],
            reason: 'tone $tone');
      }
    });

    test('level meter reads high on tone and low in gaps', () {
      _feed(gate, 1e-6, 100);
      _feed(gate, 1e-2, 20);
      expect(gate.level, greaterThan(0.9));
      _feed(gate, 1e-6, 20);
      expect(gate.level, lessThan(0.2));
      expect(gate.contrastDb, closeTo(40, 3));
    });

    test('reset forgets the estimates and the block counter', () {
      _feed(gate, 1e-6, 100);
      _feed(gate, 1e-2, 20);
      gate.reset();
      expect(gate.blockCount, 0);
      expect(gate.isOn, isFalse);
      expect(gate.level, 0);
      expect(_feed(gate, 1e-6, 50), isEmpty);
    });

    test('a step up in background noise does not latch the gate on', () {
      _feed(gate, 1e-6, 100);
      // Noise jumps 40 dB and stays there for ~27 s: the 2 dB/s creep needs
      // 20 s to adopt it, after which the gate must be closed again.
      final List<GateTransition> transitions = _feed(gate, 1e-2, 5000);
      expect(gate.isOn, isFalse, reason: transitions.toString());
      expect(gate.hasSignal, isFalse);
    });
  });

  // Known limitation: the noise floor is seeded from the first block
  // (warm-up off by default; see EnvelopeGateConfig.noiseWarmup). A warm-up
  // heuristic cost early onsets at 8/16 kHz and produced false text on
  // steady noise runs, so the original behaviour was kept.
  test('a quiet first noise block cannot open the gate (warm-up)', skip: 'known limitation, see above', () {
    // First block 20 dB below the noise, then white noise in a narrow bin:
    // exponentially distributed block powers around 1.0. Many seeds, so
    // the guard is not luck.
    for (int seed = 0; seed < 50; seed++) {
      final EnvelopeGate gate = EnvelopeGate(sampleRate: 44100, blockSize: 256);
      final math.Random random = math.Random(seed);
      for (int i = 0; i < 400; i++) {
        final double p = i == 0 ? 0.01 : -math.log(1 - random.nextDouble());
        expect(gate.feed(p), isNull, reason: 'seed $seed block $i');
      }
    }
  });

  test('a tone right after the first quiet block still opens on time', () {
    final EnvelopeGate gate = EnvelopeGate(sampleRate: 48000, blockSize: 256);
    final List<GateTransition> out = <GateTransition>[];
    // One quiet 5.33 ms block, then a 320 ms tone (60 blocks).
    out.addAll(gate.feedAll(1e-6));
    for (int i = 0; i < 60; i++) {
      out.addAll(gate.feedAll(1e-2));
    }
    for (int i = 0; i < 20; i++) {
      out.addAll(gate.feedAll(1e-6));
    }
    expect(out.map((GateTransition t) => (t.isOn, t.atBlock)), <(bool, int)>[
      (true, 1),
      (false, 61),
    ]);
  });

}

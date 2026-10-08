import 'package:morse_core/morse_core.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:test/test.dart';

RadioScenario _s(RadioPreset p, {int seed = 7}) => RadioScenario.preset(
  p,
  seed: seed,
  characterWpm: 20,
  effectiveWpm: 15,
  toneHz: 650,
);

void main() {
  group('scenario', () {
    test('clear is clear; harder presets keep speeds and tone', () {
      expect(_s(RadioPreset.clear).isClear, isTrue);
      for (final p in [RadioPreset.light, RadioPreset.radio]) {
        final s = _s(p);
        expect(s.isClear, isFalse);
        expect(s.characterWpm, 20);
        expect(s.effectiveWpm, 15);
        expect(s.toneHz, 650);
        expect(s.timing.wpm, 20);
        expect(s.timing.farnsworthWpm, 15);
      }
      // Only the radio preset adds interference and timing variation.
      expect(_s(RadioPreset.light).interference, 0);
      expect(_s(RadioPreset.light).timingVariation, 0);
      expect(_s(RadioPreset.radio).interference, greaterThan(0));
    });

    test('json round trip, clamping and malformed input', () {
      final s = _s(RadioPreset.radio);
      expect(RadioScenario.fromJson(s.toJson()), s);
      final wild = RadioScenario.fromJson({
        ...s.toJson(),
        'noise': 99,
        'timingVariation': -1,
        'fadeDepth': double.nan,
      })!;
      expect(wild.noise, RadioScenario.maxNoise);
      expect(wild.timingVariation, 0);
      expect(wild.fadeDepth, 0);
      expect(RadioScenario.fromJson({'seed': 'x'}), isNull);
      expect(RadioScenario.fromJson(null), isNull);
    });

    test('rounds get their own seed; comparable key ignores it', () {
      final s = _s(RadioPreset.light);
      expect(s.forRound(1).seed, isNot(s.forRound(2).seed));
      expect(s.forRound(3).comparableKey, s.comparableKey);
      expect(_s(RadioPreset.light, seed: 99).comparableKey, s.comparableKey);
      expect(_s(RadioPreset.radio).comparableKey, isNot(s.comparableKey));
    });
  });

  group('timing variation', () {
    final timeline = MorseEncoder.encode('PARIS QRL', const MorseTiming(wpm: 20));

    test('bounded, positive, never reorders or drops elements', () {
      final s = _s(RadioPreset.radio);
      final varied = RadioTiming.vary(timeline, s);
      expect(varied.map((e) => e.kind), timeline.map((e) => e.kind));
      for (var i = 0; i < timeline.length; i++) {
        final ratio = varied[i].duration.inMicroseconds /
            timeline[i].duration.inMicroseconds;
        expect(varied[i].duration, greaterThan(Duration.zero));
        expect(ratio, inInclusiveRange(1 - s.timingVariation - 1e-6, 1 + s.timingVariation + 1e-6));
      }
      // Marks stay shorter than the following gap would need to be to
      // swap: a dit never becomes as long as a dah at 12 % variation.
      final dit = varied.where((e) => e.kind == MorseElementKind.dit);
      final dah = varied.where((e) => e.kind == MorseElementKind.dah);
      final longestDit = dit.map((e) => e.duration).reduce((a, b) => a > b ? a : b);
      final shortestDah = dah.map((e) => e.duration).reduce((a, b) => a < b ? a : b);
      expect(longestDit, lessThan(shortestDah));
    });

    test('same seed reproduces; another seed differs; clear is identity', () {
      final a = RadioTiming.vary(timeline, _s(RadioPreset.radio));
      final b = RadioTiming.vary(timeline, _s(RadioPreset.radio));
      final c = RadioTiming.vary(timeline, _s(RadioPreset.radio, seed: 8));
      expect(a.map((e) => e.duration), b.map((e) => e.duration));
      expect(a.map((e) => e.duration), isNot(c.map((e) => e.duration)));
      expect(
        RadioTiming.vary(timeline, _s(RadioPreset.light)).map((e) => e.duration),
        timeline.map((e) => e.duration),
      );
    });
  });

  group('renderer', () {
    test('reproducible for a fixed version, settings and seed', () {
      final a = RadioRenderer.render('CQ DE K1ABC', _s(RadioPreset.radio));
      final b = RadioRenderer.render('CQ DE K1ABC', _s(RadioPreset.radio));
      final c = RadioRenderer.render('CQ DE K1ABC', _s(RadioPreset.radio, seed: 8));
      expect(a, b);
      expect(a, isNot(c));
    });

    test('bounded: never above a clean rendering, never clipped or NaN', () {
      final clean = RadioRenderer.render('PARIS', _s(RadioPreset.clear));
      double peak(List<double> xs) =>
          xs.fold(0.0, (m, v) => v.abs() > m ? v.abs() : m);
      expect(peak(clean), closeTo(RadioRenderer.cleanPeak, 0.01));
      for (final p in [RadioPreset.light, RadioPreset.radio]) {
        for (var seed = 0; seed < 5; seed++) {
          final x = RadioRenderer.render('PARIS QRL', _s(p, seed: seed));
          expect(x.any((v) => v.isNaN), isFalse);
          expect(peak(x), lessThanOrEqualTo(RadioRenderer.cleanPeak + 1e-6));
        }
      }
    });

    test('noise and fading change neither length nor nominal speed', () {
      const lead = Duration(milliseconds: 400);
      final nominal = MorseEncoder.totalDuration(
        MorseEncoder.encode('PARIS', _s(RadioPreset.light).timing),
      );
      final x = RadioRenderer.render('PARIS', _s(RadioPreset.light));
      final expected = nominal + lead + lead;
      expect(
        (RadioRenderer.lengthOf(x) - expected).inMilliseconds.abs(),
        lessThanOrEqualTo(2),
      );
    });

    test('WAV header and size', () {
      final x = RadioRenderer.render('E', _s(RadioPreset.light));
      final wav = RadioRenderer.wav(x);
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
      expect(wav.length, 44 + x.length * 2);
    });
  });

  group('records and credit', () {
    test('conditions practice earns activity only', () {
      final credit = CreditPolicy.decide(
        source: ExerciseSource.conditions,
        completed: true,
        answered: true,
        assistance: const {},
      );
      expect(credit.activity, isTrue);
      expect(credit.receiveStats, isFalse);
      expect(credit.unlock, isFalse);
      expect(credit.speedSample, isFalse);
    });

    test('summary keeps the scenario through json', () {
      final s = _s(RadioPreset.radio);
      final summary = SessionSummary.exercise(
        SessionScore.evaluate('PARIS', 'PARIS'),
        id: 'ex_1',
        source: ExerciseSource.conditions,
        at: DateTime.utc(2026, 10, 4),
        assistance: const {},
        conditions: s,
      );
      final back = SessionSummary.fromJson(summary.toJson());
      expect(back.conditions, s);
      expect(back.source, ExerciseSource.conditions);
      // Old records without the field load as clean.
      expect(
        SessionSummary.fromJson({...summary.toJson()}..remove('conditions')).conditions,
        isNull,
      );
    });

    test('speed advice ignores condition sessions', () {
      final s = _s(RadioPreset.radio);
      final history = [
        for (var i = 0; i < 6; i++)
          SessionSummary.exercise(
            SessionScore.evaluate('PARIS ' * 12, 'PARIS ' * 12),
            id: 'ex_$i',
            source: ExerciseSource.conditions,
            at: DateTime.utc(2026, 10, 4, 8, i),
            assistance: const {},
            characterWpm: 20,
            effectiveWpm: 15,
            conditions: s,
          ),
      ];
      final advice = SpeedRecommender.evaluate(
        history,
        characterWpm: 20,
        effectiveWpm: 15,
        now: DateTime.utc(2026, 10, 4, 9),
      );
      expect(advice.samples, 0);
    });
  });
}

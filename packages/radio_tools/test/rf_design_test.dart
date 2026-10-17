import 'dart:math' as math;

import 'package:radio_tools/radio_tools.dart';
import 'package:test/test.dart';

/// Minimal complex arithmetic for checking network input impedances.
typedef Complex = ({double re, double im});

Complex _add(Complex a, Complex b) => (re: a.re + b.re, im: a.im + b.im);

Complex _inv(Complex z) {
  final d = z.re * z.re + z.im * z.im;
  return (re: z.re / d, im: -z.im / d);
}

Complex _parallel(Complex a, Complex b) => _inv(_add(_inv(a), _inv(b)));

Complex _reactance(ReactiveElement? e) =>
    (re: 0, im: e == null ? 0 : e.reactanceOhms);

/// Impedance a source sees looking into [match] terminated by [load].
Complex _inputImpedance(LMatch match, Complex load) {
  final series = _reactance(match.series);
  if (match.shuntAtLoad) {
    final shunted = match.shunt == null
        ? load
        : _parallel(load, _reactance(match.shunt));
    return _add(shunted, series);
  }
  final withSeries = _add(load, series);
  return match.shunt == null
      ? withSeries
      : _parallel(withSeries, _reactance(match.shunt));
}

void main() {
  group('CoaxCable', () {
    final rg213 = Feedlines.catalogue.singleWhere((c) => c.name == 'RG-213');

    test('table points are returned exactly and interpolated between', () {
      expect(rg213.lossPer100mDb(100), closeTo(6.23, 1e-9));
      expect(rg213.lossPer100mDb(1000), closeTo(24.93, 1e-9));
      final mid = rg213.lossPer100mDb(150);
      expect(mid, greaterThan(6.23));
      expect(mid, lessThan(9.19));
      // Extrapolation keeps the end slope.
      expect(rg213.lossPer100mDb(2000), greaterThan(24.93));
      expect(rg213.lossPer100mDb(0.5), lessThan(0.66));
      expect(() => rg213.lossPer100mDb(0), throwsArgumentError);
    });

    test('catalogue tables are ascending and physically sane', () {
      for (final cable in Feedlines.catalogue) {
        expect(cable.velocityFactor, inInclusiveRange(0.5, 1.0));
        for (var i = 1; i < cable.lossTable.length; i++) {
          expect(cable.lossTable[i].$1, greaterThan(cable.lossTable[i - 1].$1));
          expect(cable.lossTable[i].$2, greaterThan(cable.lossTable[i - 1].$2));
        }
      }
      // Thinner cable loses more at the same frequency.
      double at(String name) => Feedlines.catalogue
          .singleWhere((c) => c.name == name)
          .lossPer100mDb(144);
      expect(at('RG-174'), greaterThan(at('RG-58')));
      expect(at('RG-58'), greaterThan(at('RG-213')));
      expect(at('RG-213'), greaterThan(at('LMR-400')));
    });

    test('wavelength along the cable uses the velocity factor', () {
      expect(rg213.wavelengthM(14.2), closeTo(299.792458 / 14.2 * 0.66, 1e-9));
    });
  });

  group('FeedlineRun', () {
    final rg58 = Feedlines.catalogue.singleWhere((c) => c.name == 'RG-58');

    test('matched run: total loss equals matched loss, SWR stays 1', () {
      final run = FeedlineRun(cable: rg58, lengthM: 30, mhz: 144);
      expect(run.matchedLossDb, closeTo(rg58.lossPer100mDb(144) * 0.3, 1e-9));
      expect(run.totalLossDb, closeTo(run.matchedLossDb, 1e-9));
      expect(run.additionalLossDb, closeTo(0, 1e-9));
      expect(run.swrAtInput, closeTo(1, 1e-9));
      expect(
        run.powerDeliveredW(100),
        closeTo(100 / math.pow(10, run.matchedLossDb / 10), 1e-9),
      );
    });

    test('mismatch adds loss and hides SWR from the radio', () {
      final run = FeedlineRun(cable: rg58, lengthM: 30, mhz: 144, swrAtLoad: 3);
      expect(run.totalLossDb, greaterThan(run.matchedLossDb));
      expect(run.swrAtInput, lessThan(3));
      expect(run.swrAtInput, greaterThan(1));
      // ARRL additional-loss chart: 1 dB matched loss with 3:1 at the load
      // (reflection coefficient 0.5) adds about 0.5 dB; the radio sees 2.3:1.
      final a = math.pow(10, 0.1).toDouble();
      final total =
          10 * math.log((a * a - 0.25) / (a * (1 - 0.25))) / math.ln10;
      expect(total, closeTo(1.5, 0.02));
      final rhoIn = 0.5 / a;
      expect((1 + rhoIn) / (1 - rhoIn), closeTo(2.3, 0.05));
    });

    test('zero length has no loss at any SWR', () {
      final run = FeedlineRun(cable: rg58, lengthM: 0, mhz: 7, swrAtLoad: 5);
      expect(run.totalLossDb, closeTo(0, 1e-9));
      expect(run.swrAtInput, closeTo(5, 1e-9));
      expect(run.electricalDegrees, 0);
    });

    test('electrical length', () {
      final run = FeedlineRun(
        cable: rg58,
        lengthM: rg58.wavelengthM(14.2) / 4,
        mhz: 14.2,
      );
      expect(run.electricalWavelengths, closeTo(0.25, 1e-9));
      expect(run.electricalDegrees, closeTo(90, 1e-9));
    });

    test('rejects impossible inputs', () {
      expect(
        () => FeedlineRun(cable: rg58, lengthM: -1, mhz: 7),
        throwsArgumentError,
      );
      expect(
        () => FeedlineRun(cable: rg58, lengthM: 1, mhz: 0),
        throwsArgumentError,
      );
      expect(
        () => FeedlineRun(cable: rg58, lengthM: 1, mhz: 7, swrAtLoad: 0.9),
        throwsArgumentError,
      );
      expect(
        () => FeedlineRun(
          cable: rg58,
          lengthM: 1,
          mhz: 7,
          swrAtLoad: double.infinity,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Propagation', () {
    test('free-space path loss', () {
      expect(
        Propagation.freeSpacePathLossDb(distanceKm: 1, mhz: 1),
        closeTo(32.45, 0.01),
      );
      expect(
        Propagation.freeSpacePathLossDb(distanceKm: 100, mhz: 144),
        closeTo(115.6, 0.05),
      );
      // Doubling the distance adds 6 dB.
      final d1 = Propagation.freeSpacePathLossDb(distanceKm: 10, mhz: 432);
      final d2 = Propagation.freeSpacePathLossDb(distanceKm: 20, mhz: 432);
      expect(d2 - d1, closeTo(6.02, 0.01));
      expect(
        () => Propagation.freeSpacePathLossDb(distanceKm: 0, mhz: 144),
        throwsArgumentError,
      );
    });

    test('horizons', () {
      expect(Propagation.radioHorizonKm(100), closeTo(41.2, 1e-9));
      expect(Propagation.opticalHorizonKm(100), closeTo(35.7, 1e-9));
      expect(Propagation.radioHorizonKm(0), 0);
      expect(Propagation.lineOfSightKm(100, 25), closeTo(41.2 + 20.6, 1e-9));
      expect(() => Propagation.radioHorizonKm(-1), throwsArgumentError);
    });

    test('S9 is 50 µV in 50 Ω', () {
      expect(Propagation.dbmToMicrovolts(-73), closeTo(50.1, 0.1));
      expect(Propagation.dbmToMicrovolts(-107), closeTo(1.0, 0.01));
      expect(
        Propagation.dbmToMicrovolts(-73, impedance: 75),
        closeTo(61.3, 0.1),
      );
    });
  });

  group('LinkBudget', () {
    test('adds up gains and losses', () {
      const link = LinkBudget(
        txDbm: 37, // 5 W
        txLossDb: 1,
        txGainDbi: 6,
        rxGainDbi: 2.15,
        distanceKm: 50,
        mhz: 144,
      );
      expect(link.eirpDbm, closeTo(42, 1e-9));
      expect(link.erpDbm, closeTo(39.85, 1e-9));
      expect(link.pathLossDb, closeTo(109.6, 0.05));
      expect(link.receivedDbm, closeTo(42 - link.pathLossDb + 2.15, 1e-9));
    });
  });

  group('Resonance', () {
    test('10 µH with 100 pF resonates at 5.03 MHz', () {
      final f = Resonance.frequencyHz(
        inductanceH: 10e-6,
        capacitanceF: 100e-12,
      );
      expect(f, closeTo(5.033e6, 1e3));
      expect(
        Resonance.inductanceH(frequencyHz: f, capacitanceF: 100e-12),
        closeTo(10e-6, 1e-12),
      );
      expect(
        Resonance.capacitanceF(frequencyHz: f, inductanceH: 10e-6),
        closeTo(100e-12, 1e-18),
      );
      final xl = Resonance.inductiveReactance(
        frequencyHz: f,
        inductanceH: 10e-6,
      );
      final xc = Resonance.capacitiveReactance(
        frequencyHz: f,
        capacitanceF: 100e-12,
      );
      expect(xl, closeTo(316.2, 0.1));
      expect(xl, closeTo(xc, 1e-6));
      expect(
        () => Resonance.frequencyHz(inductanceH: 0, capacitanceF: 1e-12),
        throwsArgumentError,
      );
    });
  });

  group('Attenuator', () {
    test('3 dB in 50 Ω: the textbook values', () {
      final a = Attenuator.design(attenuationDb: 3);
      expect(a.piSeries, closeTo(17.6, 0.05));
      expect(a.piShunt, closeTo(292.4, 0.1));
      expect(a.teeSeries, closeTo(8.55, 0.01));
      expect(a.teeShunt, closeTo(141.9, 0.1));
    });

    test('both forms present 50 Ω and attenuate as designed', () {
      for (final db in <double>[1, 6, 10, 20, 40]) {
        final a = Attenuator.design(attenuationDb: db, impedance: 50);
        double par(double x, double y) => x * y / (x + y);
        // π: shunt || (series + (shunt || load)).
        final piLoad = par(a.piShunt, 50);
        final piIn = par(a.piShunt, a.piSeries + piLoad);
        expect(piIn, closeTo(50, 1e-6), reason: 'π $db dB');
        // Voltage division along the π network.
        final vOut = piLoad / (a.piSeries + piLoad);
        expect(-20 * math.log(vOut) / math.ln10, closeTo(db, 1e-6));
        // T: series + (shunt || (series + load)).
        final teeInner = par(a.teeShunt, a.teeSeries + 50);
        expect(a.teeSeries + teeInner, closeTo(50, 1e-6), reason: 'T $db dB');
        final vMid = teeInner / (a.teeSeries + teeInner);
        final vLoad = 50 / (a.teeSeries + 50);
        expect(-20 * math.log(vMid * vLoad) / math.ln10, closeTo(db, 1e-6));
      }
    });
  });

  group('MinimumLossPad', () {
    test('75 Ω to 50 Ω', () {
      final pad = MinimumLossPad.between(50, 75);
      expect(pad.highImpedance, 75);
      expect(pad.lowImpedance, 50);
      expect(pad.seriesOhms, closeTo(43.3, 0.05));
      expect(pad.shuntOhms, closeTo(86.6, 0.05));
      expect(pad.lossDb, closeTo(5.72, 0.01));
      // Looking in from each side.
      double par(double x, double y) => x * y / (x + y);
      expect(pad.seriesOhms + par(pad.shuntOhms, 50), closeTo(75, 1e-6));
      expect(par(pad.shuntOhms, pad.seriesOhms + 75), closeTo(50, 1e-6));
      expect(() => MinimumLossPad.between(50, 50), throwsArgumentError);
    });
  });

  group('LNetwork', () {
    const f = 7.1e6;

    test('25 Ω load to 50 Ω: Q = 1, series 25 Ω, shunt 50 Ω', () {
      final sols = LNetwork.solutions(resistance: 25, frequencyHz: f);
      expect(sols, hasLength(2));
      final low = sols.singleWhere((m) => m.lowPass);
      expect(low.shuntAtLoad, isFalse);
      expect(low.q, closeTo(1, 1e-12));
      expect(low.series!.kind, ReactiveKind.inductor);
      expect(low.series!.reactanceOhms, closeTo(25, 1e-9));
      expect(low.series!.value, closeTo(25 / (2 * math.pi * f), 1e-15));
      expect(low.shunt!.kind, ReactiveKind.capacitor);
      expect(low.shunt!.reactanceOhms, closeTo(-50, 1e-9));
      expect(low.shunt!.value * 1e12, closeTo(448.3, 0.1));
    });

    test('100 Ω load to 50 Ω uses the shunt-first form', () {
      final sols = LNetwork.solutions(resistance: 100, frequencyHz: f);
      expect(sols, hasLength(2));
      expect(sols.every((m) => m.shuntAtLoad), isTrue);
      expect(sols.where((m) => m.lowPass), hasLength(1));
    });

    test('a 50 Ω load with reactance needs one series element', () {
      final sols = LNetwork.solutions(
        resistance: 50,
        reactance: 30,
        frequencyHz: f,
      );
      expect(sols, hasLength(1));
      expect(sols.single.shunt, isNull);
      expect(sols.single.series!.kind, ReactiveKind.capacitor);
      expect(sols.single.series!.reactanceOhms, closeTo(-30, 1e-9));
      expect(LNetwork.solutions(resistance: 50, frequencyHz: f), isEmpty);
    });

    test('every solution brings the load to Z0', () {
      const loads = <Complex>[
        (re: 25, im: 0),
        (re: 100, im: 0),
        (re: 20, im: -30),
        (re: 150, im: 80),
        (re: 10, im: 0),
        (re: 50, im: 40),
        (re: 30, im: 40), // R < Z0 and Rp > Z0: four solutions
        (re: 300, im: -600),
      ];
      for (final load in loads) {
        final sols = LNetwork.solutions(
          resistance: load.re,
          reactance: load.im,
          frequencyHz: f,
        );
        expect(sols, isNotEmpty, reason: '$load');
        for (final m in sols) {
          final zin = _inputImpedance(m, load);
          expect(zin.re, closeTo(50, 1e-6), reason: '$load $m');
          expect(zin.im, closeTo(0, 1e-6), reason: '$load $m');
        }
      }
      expect(
        LNetwork.solutions(resistance: 30, reactance: 40, frequencyHz: f),
        hasLength(4),
      );
    });

    test('rejects impossible inputs', () {
      expect(
        () => LNetwork.solutions(resistance: 0, frequencyHz: f),
        throwsArgumentError,
      );
      expect(
        () => LNetwork.solutions(resistance: 25, frequencyHz: 0),
        throwsArgumentError,
      );
      expect(
        () =>
            LNetwork.solutions(resistance: 25, reference: -50, frequencyHz: f),
        throwsArgumentError,
      );
    });
  });
}

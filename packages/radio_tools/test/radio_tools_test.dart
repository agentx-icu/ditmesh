import 'package:radio_tools/radio_tools.dart';
import 'package:test/test.dart';

void main() {
  const munich = GeoPoint(48.14666, 11.60833);
  const washington = GeoPoint(38.9072, -77.0369);

  group('Maidenhead', () {
    test('encodes known places', () {
      expect(Maidenhead.fromPoint(munich), 'JN58td');
      expect(Maidenhead.fromPoint(washington), 'FM18lv');
      expect(Maidenhead.fromPoint(munich, length: 4), 'JN58');
      expect(Maidenhead.fromPoint(munich, length: 2), 'JN');
      expect(Maidenhead.fromPoint(munich, length: 8), startsWith('JN58td'));
    });

    test('the world edges stay inside the grid', () {
      expect(Maidenhead.fromPoint(const GeoPoint(90, 180)), 'RR99xx');
      expect(Maidenhead.fromPoint(const GeoPoint(-90, -180)), 'AA00aa');
    });

    test('decodes to a square that contains the point', () {
      for (final length in Maidenhead.lengths) {
        final locator = Maidenhead.fromPoint(munich, length: length);
        final area = Maidenhead.toArea(locator);
        expect(area.contains(munich), isTrue, reason: locator);
        expect(Maidenhead.fromPoint(area.center, length: length), locator);
      }
      final square = Maidenhead.toArea('JN58');
      expect(square.widthDeg, 2);
      expect(square.heightDeg, 1);
      expect(square.center, const GeoPoint(48.5, 11));
    });

    test('internal edges land in the square east / north of them', () {
      expect(
        Maidenhead.fromPoint(const GeoPoint(0, 0.1), length: 8),
        'JJ00ba20',
      );
      expect(
        Maidenhead.fromPoint(const GeoPoint(0.1, 0), length: 8),
        'JJ00ac04',
      );
      expect(Maidenhead.fromPoint(const GeoPoint(0, 0)), 'JJ00aa');
      expect(Maidenhead.fromPoint(const GeoPoint(-0.0001, -0.0001)), 'II99xx');
    });

    test('every finest square round-trips on a sweep', () {
      for (var lat = -89.95; lat < 90; lat += 7.3) {
        for (var lon = -179.95; lon < 180; lon += 11.7) {
          final p = GeoPoint(lat, lon);
          final locator = Maidenhead.fromPoint(p, length: 8);
          // A float exactly on an edge may go to either side of it.
          final a = Maidenhead.toArea(locator);
          const tol = 1e-9;
          expect(
            p.latitude >= a.south - tol &&
                p.latitude <= a.north + tol &&
                p.longitude >= a.west - tol &&
                p.longitude <= a.east + tol,
            isTrue,
            reason: '$p -> $locator',
          );
        }
      }
    });

    test('validates and normalises', () {
      expect(Maidenhead.isValid('JN58TD'), isTrue);
      expect(Maidenhead.isValid(' jn58td12 '), isTrue);
      expect(Maidenhead.isValid('JS58'), isFalse);
      expect(Maidenhead.isValid('JN5'), isFalse);
      expect(Maidenhead.isValid('JN58ty'), isFalse);
      expect(Maidenhead.isValid(''), isFalse);
      expect(Maidenhead.normalize('jn58TD'), 'JN58td');
      expect(() => Maidenhead.toArea('XX00'), throwsFormatException);
    });

    test('rejects bad arguments', () {
      expect(
        () => Maidenhead.fromPoint(munich, length: 5),
        throwsArgumentError,
      );
      expect(
        () => Maidenhead.fromPoint(const GeoPoint(91, 0)),
        throwsArgumentError,
      );
    });
  });

  group('GreatCircle', () {
    test('distance London - Paris', () {
      const london = GeoPoint(51.5074, -0.1278);
      const paris = GeoPoint(48.8566, 2.3522);
      expect(GreatCircle.distanceKm(london, paris), closeTo(343.5, 1));
      expect(GreatCircle.distanceKm(london, london), 0);
    });

    test('bearings along the axes', () {
      const origin = GeoPoint(0, 0);
      expect(GreatCircle.initialBearing(origin, const GeoPoint(0, 10)), 90);
      expect(GreatCircle.initialBearing(origin, const GeoPoint(10, 0)), 0);
      expect(
        GreatCircle.initialBearing(origin, const GeoPoint(0, -10)),
        closeTo(270, 1e-9),
      );
      expect(
        GreatCircle.longPathBearing(origin, const GeoPoint(0, 10)),
        closeTo(270, 1e-9),
      );
      expect(GreatCircle.initialBearing(origin, origin), 0);
    });

    test('short and long path add up to a full circle', () {
      final short = GreatCircle.distanceKm(munich, washington);
      expect(short, closeTo(6817, 10));
      expect(
        short + GreatCircle.longPathKm(munich, washington),
        closeTo(40030, 5),
      );
    });
  });

  group('AmateurBands', () {
    test('band lookup depends on the region', () {
      expect(AmateurBands.bandFor(7.1, IaruRegion.region3)?.name, '40m');
      expect(AmateurBands.bandFor(7.25, IaruRegion.region1), isNull);
      expect(AmateurBands.bandFor(7.25, IaruRegion.region2)?.name, '40m');
      expect(AmateurBands.bandFor(14.06, IaruRegion.region1)?.qrpCwMhz, 14.06);
      expect(AmateurBands.bandFor(11.0, IaruRegion.region1), isNull);
    });

    test('plans are sorted and every QRP frequency is inside its band', () {
      for (final region in IaruRegion.values) {
        final plan = AmateurBands.plan(region);
        for (var i = 1; i < plan.length; i++) {
          expect(plan[i].lowerMhz, greaterThan(plan[i - 1].upperMhz));
        }
        for (final band in plan) {
          expect(band.lowerMhz, lessThan(band.upperMhz));
          if (band.qrpCwMhz != null) {
            expect(band.contains(band.qrpCwMhz!), isTrue, reason: band.name);
          }
        }
      }
    });

    test('wavelength and antenna lengths', () {
      expect(AmateurBands.wavelengthM(14), closeTo(21.414, 0.001));
      expect(AmateurBands.halfWaveDipoleM(7), closeTo(20.343, 0.001));
      expect(AmateurBands.quarterWaveM(7), closeTo(10.172, 0.001));
      expect(() => AmateurBands.wavelengthM(0), throwsArgumentError);
    });
  });

  group('CwSpeed', () {
    test('PARIS timing at 20 WPM', () {
      final s = CwSpeed(wpm: 20);
      expect(s.ditMs, 60);
      expect(s.dahMs, 180);
      expect(s.charGapMs, 180);
      expect(s.wordGapMs, 420);
      expect(s.charsPerMinute, 100);
      expect(s.parisSeconds, 3);
    });

    test('Farnsworth stretches gaps, not elements', () {
      final s = CwSpeed(wpm: 20, farnsworthWpm: 10);
      expect(s.ditMs, 60);
      expect(s.effectiveWpm, 10);
      expect(s.charsPerMinute, 50);
      expect(s.charGapMs, greaterThan(180));
    });

    test('from a dit length', () {
      expect(CwSpeed.fromDitMs(60).wpm, 20);
      expect(() => CwSpeed.fromDitMs(0), throwsArgumentError);
    });
  });

  group('RstReport', () {
    test('formats and parses, cut numbers included', () {
      final r = RstReport(readability: 5, strength: 9, tone: 9);
      expect(r.toString(), '599');
      expect(r.cut, '5NN');
      expect(RstReport.tryParse('5nn'), r);
      expect(RstReport.tryParse('59'), r);
      expect(
        RstReport.tryParse('579'),
        RstReport(readability: 5, strength: 7, tone: 9),
      );
      expect(RstReport.tryParse('609'), isNull);
      expect(RstReport.tryParse('5'), isNull);
    });

    test('rejects values off the scale', () {
      expect(() => RstReport(readability: 6, strength: 9), throwsRangeError);
      expect(() => RstReport(readability: 5, strength: 0), throwsRangeError);
    });
  });
}

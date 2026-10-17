import 'package:radio_tools/radio_tools.dart';
import 'package:test/test.dart';

void main() {
  group('Decibels', () {
    test('watts and dBm both ways', () {
      expect(Decibels.wattsToDbm(1), closeTo(30, 1e-9));
      expect(Decibels.wattsToDbm(100), closeTo(50, 1e-9));
      expect(Decibels.wattsToDbm(0.001), closeTo(0, 1e-9));
      expect(Decibels.dbmToWatts(50), closeTo(100, 1e-9));
      expect(Decibels.dbmToWatts(-30), closeTo(1e-6, 1e-15));
      expect(() => Decibels.wattsToDbm(0), throwsArgumentError);
      expect(() => Decibels.dbmToWatts(double.nan), throwsArgumentError);
    });

    test('ratios', () {
      expect(Decibels.powerRatioToDb(2), closeTo(3.0103, 1e-4));
      expect(Decibels.dbToPowerRatio(10), closeTo(10, 1e-9));
      expect(Decibels.dbToPowerRatio(-3), closeTo(0.5012, 1e-4));
      expect(Decibels.dbToVoltageRatio(6), closeTo(1.9953, 1e-4));
      expect(() => Decibels.powerRatioToDb(-1), throwsArgumentError);
    });
  });

  group('SMeterReading', () {
    test('HF scale: S9 at -73 dBm, 6 dB per unit', () {
      expect(SMeterReading.fromDbm(-73).label, 'S9');
      expect(SMeterReading.fromDbm(-53).label, 'S9+20');
      expect(SMeterReading.fromDbm(-79).label, 'S8');
      expect(SMeterReading.fromDbm(-76).label, 'S8');
      expect(SMeterReading.fromDbm(-79.5).label, 'S7');
      expect(SMeterReading.fromDbm(-121).label, 'S1');
      expect(SMeterReading.fromDbm(-130).label, 'S0');
      expect(SMeterReading.fromDbm(50).label, 'S9+123');
    });

    test('VHF scale sits 20 dB lower', () {
      expect(SMeterReading.fromDbm(-93, vhf: true).label, 'S9');
      expect(SMeterReading.fromDbm(-73, vhf: true).label, 'S9+20');
      expect(SMeterReading.fromDbm(-99, vhf: true).units, 8);
    });
  });

  group('Swr', () {
    test('from forward and reflected power', () {
      final swr = Swr.fromPowers(forwardW: 100, reflectedW: 4);
      expect(swr.reflectionCoefficient, closeTo(0.2, 1e-12));
      expect(swr.ratio, closeTo(1.5, 1e-12));
      expect(swr.returnLossDb, closeTo(13.979, 1e-3));
      expect(swr.reflectedFraction, closeTo(0.04, 1e-12));
      expect(swr.mismatchLossDb, closeTo(0.177, 1e-3));
      expect(
        () => Swr.fromPowers(forwardW: 10, reflectedW: 11),
        throwsArgumentError,
      );
      expect(
        () => Swr.fromPowers(forwardW: 0, reflectedW: 0),
        throwsArgumentError,
      );
    });

    test('perfect match and total reflection', () {
      final matched = Swr.fromPowers(forwardW: 100, reflectedW: 0);
      expect(matched.ratio, 1);
      expect(matched.returnLossDb, double.infinity);
      expect(matched.mismatchLossDb, 0);
      final open = Swr.fromPowers(forwardW: 100, reflectedW: 100);
      expect(open.ratio, double.infinity);
      expect(open.returnLossDb, 0);
      expect(open.mismatchLossDb, double.infinity);
    });

    test('from impedance', () {
      expect(Swr.fromImpedance(resistance: 50).ratio, closeTo(1, 1e-12));
      expect(Swr.fromImpedance(resistance: 100).ratio, closeTo(2, 1e-12));
      expect(Swr.fromImpedance(resistance: 25).ratio, closeTo(2, 1e-12));
      expect(
        Swr.fromImpedance(resistance: 75, reference: 75).ratio,
        closeTo(1, 1e-12),
      );
      // 50 + j50 on 50 ohm: |Γ| = 50 / sqrt(100² + 50²) = 0.4472 → 2.618:1
      expect(
        Swr.fromImpedance(resistance: 50, reactance: 50).ratio,
        closeTo(2.618, 1e-3),
      );
      expect(Swr.fromImpedance(resistance: 0).ratio, double.infinity);
      expect(
        () => Swr.fromImpedance(resistance: 50, reference: 0),
        throwsArgumentError,
      );
    });

    test('from a ratio round-trips', () {
      expect(Swr.fromRatio(3).reflectionCoefficient, closeTo(0.5, 1e-12));
      expect(Swr.fromRatio(1).ratio, 1);
      expect(Swr.fromRatio(double.infinity).ratio, double.infinity);
      expect(() => Swr.fromRatio(0.5), throwsArgumentError);
    });
  });

  group('SolarDay', () {
    const munich = GeoPoint(48.14666, 11.60833);

    Duration hm(DateTime t) => Duration(hours: t.hour, minutes: t.minute);

    void expectAbout(DateTime? actual, int hour, int minute, int tolMin) {
      expect(actual, isNotNull);
      final delta =
          (hm(actual!) - Duration(hours: hour, minutes: minute)).inMinutes;
      expect(delta.abs(), lessThanOrEqualTo(tolMin), reason: '$actual');
    }

    test('Munich on the June solstice (05:13 - 21:17 CEST)', () {
      final day = SolarDay.compute(munich, DateTime.utc(2026, 6, 21, 15));
      expect(day.date, DateTime.utc(2026, 6, 21));
      expectAbout(day.sunrise, 3, 13, 3);
      expectAbout(day.sunset, 19, 17, 3);
      expect(day.declinationDeg, closeTo(23.44, 0.05));
      expect(day.dayLength.inMinutes, closeTo(16 * 60 + 4, 5));
      expect(day.sunNeverRises, isFalse);
      expect(day.sunNeverSets, isFalse);
    });

    test('equinox at the equator: twelve hours plus refraction', () {
      final day = SolarDay.compute(
        const GeoPoint(0, 0),
        DateTime.utc(2026, 3, 20),
      );
      expectAbout(day.sunrise, 6, 4, 3);
      expectAbout(day.sunset, 18, 11, 3);
      expect(day.dayLength.inMinutes, closeTo(12 * 60 + 7, 3));
      expect(day.declinationDeg.abs(), lessThan(0.3));
    });

    test('equation of time moves solar noon', () {
      // Longitude 0: noon is 12:00 minus the equation of time.
      final november = SolarDay.compute(
        const GeoPoint(0, 0),
        DateTime.utc(2026, 11, 3),
      );
      expectAbout(november.noon, 11, 44, 2); // EoT about +16.4 min
      final february = SolarDay.compute(
        const GeoPoint(0, 0),
        DateTime.utc(2026, 2, 11),
      );
      expectAbout(february.noon, 12, 14, 2); // EoT about -14.2 min
    });

    test('longitude shifts every time by 4 minutes per degree', () {
      final greenwich = SolarDay.compute(
        const GeoPoint(30, 0),
        DateTime.utc(2026, 9, 1),
      );
      final east = SolarDay.compute(
        const GeoPoint(30, 15),
        DateTime.utc(2026, 9, 1),
      );
      expect(
        greenwich.noon.difference(east.noon).inMinutes,
        inInclusiveRange(59, 61),
      );
    });

    test('polar day and night', () {
      const tromso = GeoPoint(69.65, 18.96);
      final summer = SolarDay.compute(tromso, DateTime.utc(2026, 6, 21));
      expect(summer.sunNeverSets, isTrue);
      expect(summer.sunrise, isNull);
      expect(summer.dayLength, const Duration(hours: 24));
      final winter = SolarDay.compute(tromso, DateTime.utc(2026, 12, 21));
      expect(winter.sunNeverRises, isTrue);
      expect(winter.dayLength, Duration.zero);
      // Civil twilight still happens in Tromsø's polar night.
      final twilight = SolarDay.compute(
        tromso,
        DateTime.utc(2026, 12, 21),
        zenithDeg: SolarDay.civilTwilightZenithDeg,
      );
      expect(twilight.sunrise, isNotNull);
    });

    test('rejects an invalid point', () {
      expect(
        () => SolarDay.compute(const GeoPoint(91, 0), DateTime.utc(2026)),
        throwsArgumentError,
      );
    });
  });

  group('NcdxfBeacons', () {
    test('18 beacons, 5 bands, valid locators', () {
      expect(NcdxfBeacons.beacons, hasLength(18));
      expect(NcdxfBeacons.frequenciesMhz, hasLength(5));
      for (final b in NcdxfBeacons.beacons) {
        expect(Maidenhead.isValid(b.locator), isTrue, reason: b.callsign);
        expect(b.locator, hasLength(6));
      }
      expect(
        NcdxfBeacons.beacons.map((b) => b.callsign).toSet(),
        hasLength(18),
      );
    });

    test('4U1UN opens the cycle on 14.100 and steps up the bands', () {
      final start = DateTime.utc(2026, 10, 17, 12, 0, 0);
      expect(NcdxfBeacons.secondsIntoCycle(start), 0);
      expect(NcdxfBeacons.onAir(start, 0).callsign, '4U1UN');
      expect(NcdxfBeacons.onAir(start, 1).callsign, 'YV5B');
      expect(NcdxfBeacons.onAir(start, 4).callsign, 'CS3B');
      final tenSeconds = start.add(const Duration(seconds: 10));
      expect(NcdxfBeacons.onAir(tenSeconds, 0).callsign, 'VE8AT');
      expect(NcdxfBeacons.onAir(tenSeconds, 1).callsign, '4U1UN');
      final nextCycle = start.add(const Duration(minutes: 3, seconds: 9));
      expect(NcdxfBeacons.onAir(nextCycle, 0).callsign, '4U1UN');
      expect(NcdxfBeacons.slotRemaining(nextCycle), const Duration(seconds: 1));
      expect(NcdxfBeacons.slotRemaining(start), const Duration(seconds: 10));
    });

    test('every beacon is on exactly one band at a time', () {
      for (var s = 0; s < 180; s += 7) {
        final t = DateTime.utc(2026, 1, 1, 0, 0, s);
        final onAir = <String>{
          for (var band = 0; band < 5; band++)
            NcdxfBeacons.onAir(t, band).callsign,
        };
        expect(onAir, hasLength(5), reason: '$s s');
      }
    });

    test('untilNext counts down to the beacon\'s slot', () {
      final start = DateTime.utc(2026, 10, 17, 12, 0, 0);
      final w6wx = NcdxfBeacons.beacons[2];
      expect(NcdxfBeacons.untilNext(start, w6wx), const Duration(seconds: 20));
      expect(
        NcdxfBeacons.untilNext(start, w6wx, band: 1),
        const Duration(seconds: 30),
      );
      expect(
        NcdxfBeacons.untilNext(start, NcdxfBeacons.beacons[0]),
        Duration.zero,
      );
      final later = start.add(const Duration(seconds: 25));
      expect(
        NcdxfBeacons.untilNext(later, w6wx),
        const Duration(minutes: 2, seconds: 55),
      );
      expect(
        () => NcdxfBeacons.untilNext(start, const Beacon('XX0X', 'AA00aa')),
        throwsArgumentError,
      );
      expect(() => NcdxfBeacons.onAir(start, 5), throwsRangeError);
    });
  });
}

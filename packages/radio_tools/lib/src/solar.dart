import 'dart:math';

import 'geo.dart';

/// Sunrise, solar noon and sunset at a point on one UTC date, on the NOAA
/// solar calculator's formulas (good to about a minute away from the
/// poles). Grey-line DX lives around these times.
final class SolarDay {
  const SolarDay._({
    required this.date,
    required this.noon,
    required this.sunrise,
    required this.sunset,
    required this.declinationDeg,
    required this.sunNeverRises,
    required this.sunNeverSets,
  });

  /// Zenith angle of the upper limb at the horizon, refraction included.
  static const double sunriseZenithDeg = 90.833;

  /// Zenith angle that ends civil twilight.
  static const double civilTwilightZenithDeg = 96;

  /// The sun's day at [point] on the UTC calendar date of [date].
  ///
  /// [zenithDeg] is the sun's zenith angle that counts as rising or
  /// setting: [sunriseZenithDeg] for the visible sun (the default) or
  /// [civilTwilightZenithDeg] for the edges of civil twilight.
  factory SolarDay.compute(
    GeoPoint point,
    DateTime date, {
    double zenithDeg = sunriseZenithDeg,
  }) {
    if (!point.isValid) {
      throw ArgumentError.value(point, 'point', 'out of range');
    }
    if (!zenithDeg.isFinite || zenithDeg <= 0 || zenithDeg >= 180) {
      throw ArgumentError.value(
        zenithDeg,
        'zenithDeg',
        'must be an angle between 0 and 180 degrees',
      );
    }
    final utc = date.toUtc();
    final day = DateTime.utc(utc.year, utc.month, utc.day);
    final jd0 =
        day.millisecondsSinceEpoch / Duration.millisecondsPerDay + 2440587.5;
    // Solar noon in minutes after 0h UTC; the equation of time depends on
    // the moment, so refine it once from the first estimate.
    var noonMinutes = 720 - 4 * point.longitude;
    late _Sun sun;
    for (var pass = 0; pass < 2; pass++) {
      sun = _Sun.at(jd0 + noonMinutes / Duration.minutesPerDay);
      noonMinutes = 720 - 4 * point.longitude - sun.equationOfTimeMin;
    }
    final phi = _rad(point.latitude);
    final delta = _rad(sun.declinationDeg);
    final cosHa =
        (cos(_rad(zenithDeg)) - sin(phi) * sin(delta)) /
        (cos(phi) * cos(delta));
    final noon = day.add(_minutes(noonMinutes));
    if (cosHa.isNaN || cosHa > 1) {
      return SolarDay._(
        date: day,
        noon: noon,
        sunrise: null,
        sunset: null,
        declinationDeg: sun.declinationDeg,
        sunNeverRises: true,
        sunNeverSets: false,
      );
    }
    if (cosHa < -1) {
      return SolarDay._(
        date: day,
        noon: noon,
        sunrise: null,
        sunset: null,
        declinationDeg: sun.declinationDeg,
        sunNeverRises: false,
        sunNeverSets: true,
      );
    }
    final haMinutes = 4 * _deg(acos(cosHa));
    return SolarDay._(
      date: day,
      noon: noon,
      sunrise: day.add(_minutes(noonMinutes - haMinutes)),
      sunset: day.add(_minutes(noonMinutes + haMinutes)),
      declinationDeg: sun.declinationDeg,
      sunNeverRises: false,
      sunNeverSets: false,
    );
  }

  /// Midnight UTC of the date the day was computed for.
  final DateTime date;

  /// Solar noon (transit) in UTC; defined even in polar day or night.
  final DateTime noon;

  /// Null when the sun never rises or never sets on [date].
  final DateTime? sunrise;
  final DateTime? sunset;

  /// The sun's declination at noon, degrees north.
  final double declinationDeg;

  /// Polar night: the sun stays below the horizon all day.
  final bool sunNeverRises;

  /// Polar day (midnight sun): the sun stays above the horizon all day.
  final bool sunNeverSets;

  /// Hours of daylight: 0 in polar night, 24 in polar day.
  Duration get dayLength {
    if (sunNeverRises) return Duration.zero;
    if (sunNeverSets) return const Duration(hours: 24);
    return sunset!.difference(sunrise!);
  }

  static double _rad(double deg) => deg * pi / 180;
  static double _deg(double rad) => rad * 180 / pi;
  static Duration _minutes(double m) =>
      Duration(milliseconds: (m * Duration.millisecondsPerMinute).round());
}

/// The sun's declination and equation of time at a Julian day (NOAA).
final class _Sun {
  const _Sun._(this.declinationDeg, this.equationOfTimeMin);

  factory _Sun.at(double julianDay) {
    final t = (julianDay - 2451545) / 36525; // Julian centuries from J2000
    final l0 = (280.46646 + t * (36000.76983 + t * 0.0003032)) % 360;
    final m = _r(357.52911 + t * (35999.05029 - 0.0001537 * t));
    final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
    final c =
        sin(m) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
        sin(2 * m) * (0.019993 - 0.000101 * t) +
        sin(3 * m) * 0.000289;
    final omega = _r(125.04 - 1934.136 * t);
    final lambda = _r(l0 + c - 0.00569 - 0.00478 * sin(omega));
    final eps0 =
        23 +
        (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60;
    final eps = _r(eps0 + 0.00256 * cos(omega));
    final declination = asin(sin(eps) * sin(lambda));
    final y = pow(tan(eps / 2), 2).toDouble();
    final l0r = _r(l0);
    final eot =
        y * sin(2 * l0r) -
        2 * e * sin(m) +
        4 * e * y * sin(m) * cos(2 * l0r) -
        0.5 * y * y * sin(4 * l0r) -
        1.25 * e * e * sin(2 * m);
    return _Sun._(declination * 180 / pi, 4 * eot * 180 / pi);
  }

  final double declinationDeg;

  /// Apparent minus mean solar time, minutes.
  final double equationOfTimeMin;

  static double _r(double deg) => deg * pi / 180;
}

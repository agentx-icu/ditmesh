import 'dart:math';

/// Power levels and ratios in decibels.
abstract final class Decibels {
  /// `10 log10(watts / 1 mW)`. Throws for a power that is not positive.
  static double wattsToDbm(double watts) {
    _checkPositive(watts, 'watts');
    return 10 * _log10(watts * 1000);
  }

  /// Watts for a level in dBm: `10^((dBm - 30) / 10)`.
  static double dbmToWatts(double dbm) {
    _checkFinite(dbm, 'dbm');
    return pow(10, (dbm - 30) / 10).toDouble();
  }

  /// Power ratio to decibels: `10 log10(ratio)`.
  static double powerRatioToDb(double ratio) {
    _checkPositive(ratio, 'ratio');
    return 10 * _log10(ratio);
  }

  /// Power ratio of a gain or loss in dB (3 dB is about 2x).
  static double dbToPowerRatio(double db) {
    _checkFinite(db, 'db');
    return pow(10, db / 10).toDouble();
  }

  /// Voltage ratio of a gain or loss in dB (6 dB is about 2x).
  static double dbToVoltageRatio(double db) {
    _checkFinite(db, 'db');
    return pow(10, db / 20).toDouble();
  }

  static double _log10(double x) => log(x) / ln10;

  static void _checkFinite(double v, String name) {
    if (!v.isFinite) {
      throw ArgumentError.value(v, name, 'must be finite');
    }
  }

  static void _checkPositive(double v, String name) {
    if (!v.isFinite || v <= 0) {
      throw ArgumentError.value(v, name, 'must be positive');
    }
  }
}

/// An S-meter reading on the IARU Region 1 scale (Recommendation R.1):
/// S9 is -73 dBm below 30 MHz and -93 dBm above, one S-unit is 6 dB.
///
/// Readings between two S-units round down to the unit whose threshold the
/// signal has reached, the way a stepped meter shows them; above S9 the
/// excess is given in decibels (`S9+20`).
final class SMeterReading {
  const SMeterReading._({required this.units, required this.overS9Db});

  /// S9 level below 30 MHz.
  static const double s9DbmHf = -73;

  /// S9 level above 30 MHz.
  static const double s9DbmVhf = -93;

  static const double dbPerUnit = 6;

  /// The reading for a signal of [dbm] at the receiver input.
  factory SMeterReading.fromDbm(double dbm, {bool vhf = false}) {
    if (!dbm.isFinite) {
      throw ArgumentError.value(dbm, 'dbm', 'must be finite');
    }
    final s9 = vhf ? s9DbmVhf : s9DbmHf;
    if (dbm >= s9) {
      return SMeterReading._(units: 9, overS9Db: dbm - s9);
    }
    final below = ((s9 - dbm) / dbPerUnit).ceil();
    return SMeterReading._(units: max(0, 9 - below), overS9Db: 0);
  }

  /// 0 (below S1) to 9.
  final int units;

  /// Decibels over S9; 0 unless [units] is 9.
  final double overS9Db;

  /// `S7`, `S9`, `S9+20`.
  String get label => overS9Db >= 0.5 ? 'S9+${overS9Db.round()}' : 'S$units';

  @override
  String toString() => 'SMeterReading($label)';
}

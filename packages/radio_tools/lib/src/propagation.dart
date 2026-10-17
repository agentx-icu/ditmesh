import 'dart:math' as math;

/// Free-space propagation and the radio horizon.
abstract final class Propagation {
  /// Gain of a half-wave dipole over an isotropic radiator, dB.
  static const double dipoleGainDbi = 2.15;

  /// Free-space path loss in dB for [distanceKm] at [mhz]:
  /// `20 log10(d) + 20 log10(f) + 32.45`.
  static double freeSpacePathLossDb({
    required double distanceKm,
    required double mhz,
  }) {
    if (!distanceKm.isFinite || distanceKm <= 0) {
      throw ArgumentError.value(distanceKm, 'distanceKm', 'must be positive');
    }
    if (!mhz.isFinite || mhz <= 0) {
      throw ArgumentError.value(mhz, 'mhz', 'must be positive');
    }
    return 20 * _log10(distanceKm) + 20 * _log10(mhz) + 32.44778;
  }

  /// Distance to the radio horizon in km for an antenna [heightM] above
  /// level ground, with the usual 4/3-earth allowance for refraction.
  static double radioHorizonKm(double heightM) => 4.12 * _sqrtHeight(heightM);

  /// Distance to the visible horizon in km, no refraction.
  static double opticalHorizonKm(double heightM) => 3.57 * _sqrtHeight(heightM);

  /// Radio line-of-sight range between two antennas: both horizons added.
  static double lineOfSightKm(double heightAM, double heightBM) =>
      radioHorizonKm(heightAM) + radioHorizonKm(heightBM);

  /// RMS voltage in microvolts that a level in dBm develops across
  /// [impedance] ohms: -73 dBm is 50 µV in 50 Ω.
  static double dbmToMicrovolts(double dbm, {double impedance = 50}) {
    if (!dbm.isFinite) throw ArgumentError.value(dbm, 'dbm');
    if (!impedance.isFinite || impedance <= 0) {
      throw ArgumentError.value(impedance, 'impedance', 'must be positive');
    }
    final watts = math.pow(10, (dbm - 30) / 10).toDouble();
    return math.sqrt(watts * impedance) * 1e6;
  }

  static double _sqrtHeight(double heightM) {
    if (!heightM.isFinite || heightM < 0) {
      throw ArgumentError.value(heightM, 'heightM', 'must be 0 or more');
    }
    return math.sqrt(heightM);
  }
}

/// A one-way link: transmitter, both antennas and the free-space path.
final class LinkBudget {
  const LinkBudget({
    required this.txDbm,
    this.txLossDb = 0,
    this.txGainDbi = 0,
    this.rxGainDbi = 0,
    this.rxLossDb = 0,
    required this.distanceKm,
    required this.mhz,
  });

  final double txDbm;
  final double txLossDb;
  final double txGainDbi;
  final double rxGainDbi;
  final double rxLossDb;
  final double distanceKm;
  final double mhz;

  /// Power radiated relative to an isotropic antenna, dBm.
  double get eirpDbm => txDbm - txLossDb + txGainDbi;

  /// Power radiated relative to a half-wave dipole, dBm.
  double get erpDbm => eirpDbm - Propagation.dipoleGainDbi;

  double get pathLossDb =>
      Propagation.freeSpacePathLossDb(distanceKm: distanceKm, mhz: mhz);

  /// Level at the far receiver's antenna socket, dBm.
  double get receivedDbm => eirpDbm - pathLossDb + rxGainDbi - rxLossDb;
}

double _log10(double x) => math.log(x) / math.ln10;

/// The three IARU / ITU regions; amateur allocations differ between them.
enum IaruRegion {
  /// Europe, Africa, Middle East, northern Asia.
  region1,

  /// The Americas.
  region2,

  /// Asia-Pacific, including China, Japan and Oceania.
  region3,
}

/// One amateur band with its edges in a region.
final class BandAllocation {
  const BandAllocation({
    required this.name,
    required this.lowerMhz,
    required this.upperMhz,
    this.qrpCwMhz,
  });

  /// Conventional wavelength name: `40m`, `70cm`.
  final String name;
  final double lowerMhz;
  final double upperMhz;

  /// IARU QRP CW centre of activity, when the band has a common one.
  final double? qrpCwMhz;

  bool contains(double mhz) => mhz >= lowerMhz && mhz <= upperMhz;

  @override
  String toString() => 'BandAllocation($name $lowerMhz-$upperMhz MHz)';
}

/// ITU Radio Regulations amateur allocations from LF to UHF, per region.
///
/// These are the international edges; national rules are often narrower
/// (and sometimes secondary), so the app labels them as a guide, not a
/// licence.
abstract final class AmateurBands {
  /// Speed of light in m/MHz (so `c / f[MHz]` is metres).
  static const double speedOfLight = 299.792458;

  static const Map<IaruRegion, List<BandAllocation>> _plans =
      <IaruRegion, List<BandAllocation>>{
        IaruRegion.region1: <BandAllocation>[
          BandAllocation(name: '2200m', lowerMhz: 0.1357, upperMhz: 0.1378),
          BandAllocation(name: '630m', lowerMhz: 0.472, upperMhz: 0.479),
          BandAllocation(name: '160m', lowerMhz: 1.810, upperMhz: 2.000),
          BandAllocation(
            name: '80m',
            lowerMhz: 3.500,
            upperMhz: 3.800,
            qrpCwMhz: 3.560,
          ),
          BandAllocation(name: '60m', lowerMhz: 5.3515, upperMhz: 5.3665),
          BandAllocation(
            name: '40m',
            lowerMhz: 7.000,
            upperMhz: 7.200,
            qrpCwMhz: 7.030,
          ),
          _m30,
          _m20,
          _m17,
          _m15,
          _m12,
          _m10,
          BandAllocation(name: '6m', lowerMhz: 50.000, upperMhz: 52.000),
          BandAllocation(name: '2m', lowerMhz: 144.000, upperMhz: 146.000),
          BandAllocation(name: '70cm', lowerMhz: 430.000, upperMhz: 440.000),
        ],
        IaruRegion.region2: <BandAllocation>[
          BandAllocation(name: '2200m', lowerMhz: 0.1357, upperMhz: 0.1378),
          BandAllocation(name: '630m', lowerMhz: 0.472, upperMhz: 0.479),
          BandAllocation(name: '160m', lowerMhz: 1.800, upperMhz: 2.000),
          BandAllocation(
            name: '80m',
            lowerMhz: 3.500,
            upperMhz: 4.000,
            qrpCwMhz: 3.560,
          ),
          BandAllocation(name: '60m', lowerMhz: 5.3515, upperMhz: 5.3665),
          BandAllocation(
            name: '40m',
            lowerMhz: 7.000,
            upperMhz: 7.300,
            qrpCwMhz: 7.030,
          ),
          _m30,
          _m20,
          _m17,
          _m15,
          _m12,
          _m10,
          BandAllocation(name: '6m', lowerMhz: 50.000, upperMhz: 54.000),
          BandAllocation(name: '2m', lowerMhz: 144.000, upperMhz: 148.000),
          BandAllocation(name: '70cm', lowerMhz: 420.000, upperMhz: 450.000),
        ],
        IaruRegion.region3: <BandAllocation>[
          BandAllocation(name: '2200m', lowerMhz: 0.1357, upperMhz: 0.1378),
          BandAllocation(name: '630m', lowerMhz: 0.472, upperMhz: 0.479),
          BandAllocation(name: '160m', lowerMhz: 1.800, upperMhz: 2.000),
          BandAllocation(
            name: '80m',
            lowerMhz: 3.500,
            upperMhz: 3.900,
            qrpCwMhz: 3.560,
          ),
          BandAllocation(name: '60m', lowerMhz: 5.3515, upperMhz: 5.3665),
          BandAllocation(
            name: '40m',
            lowerMhz: 7.000,
            upperMhz: 7.200,
            qrpCwMhz: 7.030,
          ),
          _m30,
          _m20,
          _m17,
          _m15,
          _m12,
          _m10,
          BandAllocation(name: '6m', lowerMhz: 50.000, upperMhz: 54.000),
          BandAllocation(name: '2m', lowerMhz: 144.000, upperMhz: 148.000),
          BandAllocation(name: '70cm', lowerMhz: 430.000, upperMhz: 440.000),
        ],
      };

  // Worldwide (identical in all three regions).
  static const BandAllocation _m30 = BandAllocation(
    name: '30m',
    lowerMhz: 10.100,
    upperMhz: 10.150,
    qrpCwMhz: 10.116,
  );
  static const BandAllocation _m20 = BandAllocation(
    name: '20m',
    lowerMhz: 14.000,
    upperMhz: 14.350,
    qrpCwMhz: 14.060,
  );
  static const BandAllocation _m17 = BandAllocation(
    name: '17m',
    lowerMhz: 18.068,
    upperMhz: 18.168,
    qrpCwMhz: 18.086,
  );
  static const BandAllocation _m15 = BandAllocation(
    name: '15m',
    lowerMhz: 21.000,
    upperMhz: 21.450,
    qrpCwMhz: 21.060,
  );
  static const BandAllocation _m12 = BandAllocation(
    name: '12m',
    lowerMhz: 24.890,
    upperMhz: 24.990,
    qrpCwMhz: 24.906,
  );
  static const BandAllocation _m10 = BandAllocation(
    name: '10m',
    lowerMhz: 28.000,
    upperMhz: 29.700,
    qrpCwMhz: 28.060,
  );

  /// Bands of [region], lowest first.
  static List<BandAllocation> plan(IaruRegion region) => _plans[region]!;

  /// The band containing [mhz] in [region], or null outside every band.
  static BandAllocation? bandFor(double mhz, IaruRegion region) {
    for (final band in plan(region)) {
      if (band.contains(mhz)) return band;
    }
    return null;
  }

  /// Free-space wavelength in metres.
  static double wavelengthM(double mhz) {
    _checkFrequency(mhz);
    return speedOfLight / mhz;
  }

  /// Cut length of a half-wave wire dipole (both legs) in metres.
  ///
  /// [endFactor] shortens the free-space half wave for wire thickness and
  /// end effect; 0.95 is the usual starting point before trimming.
  static double halfWaveDipoleM(double mhz, {double endFactor = 0.95}) =>
      wavelengthM(mhz) / 2 * endFactor;

  /// Length of a quarter-wave vertical radiator in metres.
  static double quarterWaveM(double mhz, {double endFactor = 0.95}) =>
      wavelengthM(mhz) / 4 * endFactor;

  static void _checkFrequency(double mhz) {
    if (!mhz.isFinite || mhz <= 0) {
      throw ArgumentError.value(mhz, 'mhz', 'must be a positive frequency');
    }
  }
}

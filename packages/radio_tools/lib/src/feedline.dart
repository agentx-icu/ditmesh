import 'dart:math' as math;

import 'swr.dart';

/// A transmission-line type with its nominal matched attenuation.
///
/// Attenuation figures are typical manufacturer values; a real run, its
/// connectors and its age add to them.
final class CoaxCable {
  const CoaxCable({
    required this.name,
    required this.impedance,
    required this.velocityFactor,
    required this.lossTable,
  });

  /// Product designation, the same in every language (`RG-213`).
  final String name;

  /// Characteristic impedance in ohms.
  final double impedance;

  /// Velocity of propagation relative to free space, 0 < vf <= 1.
  final double velocityFactor;

  /// `(MHz, dB per 100 m)` pairs in ascending frequency.
  final List<(double, double)> lossTable;

  /// Matched loss in dB per 100 m at [mhz]: log-log interpolation between
  /// the table points, extrapolated along the end segments.
  double lossPer100mDb(double mhz) {
    if (!mhz.isFinite || mhz <= 0) {
      throw ArgumentError.value(mhz, 'mhz', 'must be a positive frequency');
    }
    final table = lossTable;
    var i = 1;
    while (i < table.length - 1 && table[i].$1 < mhz) {
      i++;
    }
    final (f0, a0) = table[i - 1];
    final (f1, a1) = table[i];
    final slope = math.log(a1 / a0) / math.log(f1 / f0);
    return a0 * math.pow(mhz / f0, slope);
  }

  /// Matched loss of [lengthM] metres at [mhz], in dB.
  double matchedLossDb({required double lengthM, required double mhz}) =>
      lossPer100mDb(mhz) * lengthM / 100;

  /// One wavelength along this cable at [mhz], in metres.
  double wavelengthM(double mhz) => 299.792458 / mhz * velocityFactor;
}

/// Common amateur feedlines with nominal attenuation.
abstract final class Feedlines {
  static const List<CoaxCable> catalogue = <CoaxCable>[
    CoaxCable(
      name: 'RG-174',
      impedance: 50,
      velocityFactor: 0.66,
      lossTable: <(double, double)>[
        (1, 6.23),
        (10, 10.83),
        (50, 21.65),
        (100, 29.2),
        (200, 41.0),
        (400, 57.4),
        (1000, 98.4),
      ],
    ),
    CoaxCable(
      name: 'RG-58',
      impedance: 50,
      velocityFactor: 0.66,
      lossTable: <(double, double)>[
        (1, 1.31),
        (10, 4.59),
        (50, 10.83),
        (100, 16.08),
        (200, 23.95),
        (400, 36.74),
        (1000, 65.6),
      ],
    ),
    CoaxCable(
      name: 'RG-8X',
      impedance: 50,
      velocityFactor: 0.80,
      lossTable: <(double, double)>[
        (1, 0.98),
        (10, 2.95),
        (50, 6.56),
        (100, 10.17),
        (200, 15.42),
        (400, 22.64),
        (1000, 41.0),
      ],
    ),
    CoaxCable(
      name: 'RG-213',
      impedance: 50,
      velocityFactor: 0.66,
      lossTable: <(double, double)>[
        (1, 0.66),
        (10, 1.97),
        (50, 4.27),
        (100, 6.23),
        (200, 9.19),
        (400, 14.11),
        (1000, 24.93),
      ],
    ),
    CoaxCable(
      name: 'RG-8 foam',
      impedance: 50,
      velocityFactor: 0.84,
      lossTable: <(double, double)>[
        (1, 0.33),
        (10, 1.31),
        (50, 2.95),
        (100, 4.27),
        (200, 6.23),
        (400, 9.19),
        (1000, 15.09),
      ],
    ),
    CoaxCable(
      name: 'LMR-400',
      impedance: 50,
      velocityFactor: 0.85,
      lossTable: <(double, double)>[
        (1, 0.43),
        (10, 1.31),
        (50, 2.95),
        (100, 3.94),
        (200, 5.58),
        (400, 8.2),
        (1000, 13.45),
      ],
    ),
    CoaxCable(
      name: '1/2" hardline',
      impedance: 50,
      velocityFactor: 0.88,
      lossTable: <(double, double)>[
        (1, 0.16),
        (10, 0.56),
        (50, 1.31),
        (100, 1.97),
        (200, 2.79),
        (400, 3.94),
        (1000, 6.56),
      ],
    ),
    CoaxCable(
      name: 'RG-6',
      impedance: 75,
      velocityFactor: 0.82,
      lossTable: <(double, double)>[
        (1, 0.66),
        (10, 1.97),
        (50, 4.59),
        (100, 6.56),
        (200, 9.19),
        (400, 14.11),
        (1000, 20.0),
      ],
    ),
    CoaxCable(
      name: '450 Ω window line',
      impedance: 450,
      velocityFactor: 0.91,
      lossTable: <(double, double)>[
        (1, 0.07),
        (10, 0.33),
        (50, 0.66),
        (100, 0.98),
        (200, 1.64),
        (400, 2.62),
        (1000, 4.92),
      ],
    ),
  ];
}

/// A run of [cable] into a load with a given SWR: what the mismatch does
/// to the loss and to the SWR the radio sees.
final class FeedlineRun {
  FeedlineRun({
    required this.cable,
    required this.lengthM,
    required this.mhz,
    this.swrAtLoad = 1,
  }) {
    if (!lengthM.isFinite || lengthM < 0) {
      throw ArgumentError.value(lengthM, 'lengthM', 'must be 0 or more');
    }
    if (!mhz.isFinite || mhz <= 0) {
      throw ArgumentError.value(mhz, 'mhz', 'must be a positive frequency');
    }
    if (!swrAtLoad.isFinite || swrAtLoad < 1) {
      throw ArgumentError.value(swrAtLoad, 'swrAtLoad', 'must be 1 or more');
    }
  }

  final CoaxCable cable;
  final double lengthM;
  final double mhz;
  final double swrAtLoad;

  /// Loss into a matched load, dB.
  double get matchedLossDb => cable.matchedLossDb(lengthM: lengthM, mhz: mhz);

  double get _rho => Swr.fromRatio(swrAtLoad).reflectionCoefficient;

  /// Matched loss as a power ratio (>= 1).
  double get _a => math.pow(10, matchedLossDb / 10).toDouble();

  /// Loss into the mismatched load, dB: the reflected power travels the
  /// line again, so the loss grows with SWR.
  double get totalLossDb {
    final a = _a;
    final rho2 = _rho * _rho;
    return 10 * _log10((a * a - rho2) / (a * (1 - rho2)));
  }

  /// Extra loss caused by the mismatch alone, dB.
  double get additionalLossDb => totalLossDb - matchedLossDb;

  /// SWR at the radio end: the line's loss attenuates the reflection.
  double get swrAtInput => Swr.fromReflectionCoefficient(_rho / _a).ratio;

  /// Power reaching the load for [inputW] watts delivered into the line.
  double powerDeliveredW(double inputW) =>
      inputW / math.pow(10, totalLossDb / 10);

  /// Length of the run in wavelengths along the cable.
  double get electricalWavelengths => lengthM / cable.wavelengthM(mhz);

  /// Length of the run in electrical degrees (360 per wavelength).
  double get electricalDegrees => electricalWavelengths * 360;
}

double _log10(double x) => math.log(x) / math.ln10;

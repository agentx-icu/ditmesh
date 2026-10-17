import 'dart:math' as math;

/// LC resonance and reactance.
abstract final class Resonance {
  /// `1 / (2π √(LC))`, Hz.
  static double frequencyHz({
    required double inductanceH,
    required double capacitanceF,
  }) {
    _positive(inductanceH, 'inductanceH');
    _positive(capacitanceF, 'capacitanceF');
    return 1 / (2 * math.pi * math.sqrt(inductanceH * capacitanceF));
  }

  /// Inductance resonating with [capacitanceF] at [frequencyHz], henries.
  static double inductanceH({
    required double frequencyHz,
    required double capacitanceF,
  }) {
    _positive(frequencyHz, 'frequencyHz');
    _positive(capacitanceF, 'capacitanceF');
    final w = 2 * math.pi * frequencyHz;
    return 1 / (w * w * capacitanceF);
  }

  /// Capacitance resonating with [inductanceH] at [frequencyHz], farads.
  static double capacitanceF({
    required double frequencyHz,
    required double inductanceH,
  }) {
    _positive(frequencyHz, 'frequencyHz');
    _positive(inductanceH, 'inductanceH');
    final w = 2 * math.pi * frequencyHz;
    return 1 / (w * w * inductanceH);
  }

  /// `2πfL`, ohms.
  static double inductiveReactance({
    required double frequencyHz,
    required double inductanceH,
  }) {
    _positive(frequencyHz, 'frequencyHz');
    _positive(inductanceH, 'inductanceH');
    return 2 * math.pi * frequencyHz * inductanceH;
  }

  /// `1 / (2πfC)`, ohms.
  static double capacitiveReactance({
    required double frequencyHz,
    required double capacitanceF,
  }) {
    _positive(frequencyHz, 'frequencyHz');
    _positive(capacitanceF, 'capacitanceF');
    return 1 / (2 * math.pi * frequencyHz * capacitanceF);
  }
}

/// Resistor values for a symmetric π or T attenuator between equal
/// impedances.
final class Attenuator {
  const Attenuator._({
    required this.attenuationDb,
    required this.impedance,
    required this.piSeries,
    required this.piShunt,
    required this.teeSeries,
    required this.teeShunt,
  });

  factory Attenuator.design({
    required double attenuationDb,
    double impedance = 50,
  }) {
    _positive(attenuationDb, 'attenuationDb');
    _positive(impedance, 'impedance');
    final k = math.pow(10, attenuationDb / 20).toDouble();
    return Attenuator._(
      attenuationDb: attenuationDb,
      impedance: impedance,
      piSeries: impedance * (k * k - 1) / (2 * k),
      piShunt: impedance * (k + 1) / (k - 1),
      teeSeries: impedance * (k - 1) / (k + 1),
      teeShunt: 2 * impedance * k / (k * k - 1),
    );
  }

  final double attenuationDb;
  final double impedance;

  /// π: the one resistor between the two ports.
  final double piSeries;

  /// π: the resistor from each port to ground.
  final double piShunt;

  /// T: the resistor in series at each port.
  final double teeSeries;

  /// T: the one resistor from the middle to ground.
  final double teeShunt;
}

/// The two-resistor pad that matches two unequal impedances with the
/// least loss a resistive network can manage (75 Ω <-> 50 Ω: 5.7 dB).
final class MinimumLossPad {
  const MinimumLossPad._({
    required this.highImpedance,
    required this.lowImpedance,
    required this.seriesOhms,
    required this.shuntOhms,
    required this.lossDb,
  });

  /// Pad between any two different positive impedances; the order does
  /// not matter.
  factory MinimumLossPad.between(double a, double b) {
    _positive(a, 'a');
    _positive(b, 'b');
    if (a == b) {
      throw ArgumentError.value(b, 'b', 'impedances must differ');
    }
    final high = math.max(a, b);
    final low = math.min(a, b);
    final ratio = high / low;
    return MinimumLossPad._(
      highImpedance: high,
      lowImpedance: low,
      seriesOhms: math.sqrt(high * (high - low)),
      shuntOhms: low * math.sqrt(high / (high - low)),
      lossDb:
          20 * math.log(math.sqrt(ratio) + math.sqrt(ratio - 1)) / math.ln10,
    );
  }

  final double highImpedance;
  final double lowImpedance;

  /// Resistor in series with the higher-impedance port.
  final double seriesOhms;

  /// Resistor across the lower-impedance port.
  final double shuntOhms;

  /// Loss through the pad, dB.
  final double lossDb;
}

void _positive(double value, String name) {
  if (!value.isFinite || value <= 0) {
    throw ArgumentError.value(value, name, 'must be positive');
  }
}

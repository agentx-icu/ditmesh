import 'dart:math';

/// Standing-wave ratio and the figures that follow from the magnitude of
/// the reflection coefficient: return loss, reflected power and mismatch
/// loss.
final class Swr {
  /// From the reflection coefficient magnitude, 0 (matched) to 1 (open or
  /// short).
  Swr.fromReflectionCoefficient(this.reflectionCoefficient) {
    if (!reflectionCoefficient.isFinite ||
        reflectionCoefficient < 0 ||
        reflectionCoefficient > 1) {
      throw ArgumentError.value(
        reflectionCoefficient,
        'reflectionCoefficient',
        'must be between 0 and 1',
      );
    }
  }

  /// From a ratio such as 1.5 (for 1.5:1). Infinity is an open or short.
  factory Swr.fromRatio(double swr) {
    if (swr.isNaN || swr < 1) {
      throw ArgumentError.value(swr, 'swr', 'must be at least 1');
    }
    if (swr.isInfinite) return Swr.fromReflectionCoefficient(1);
    return Swr.fromReflectionCoefficient((swr - 1) / (swr + 1));
  }

  /// From the forward and reflected power a directional wattmeter shows.
  /// Reflected power may equal but not exceed forward power.
  factory Swr.fromPowers({
    required double forwardW,
    required double reflectedW,
  }) {
    if (!forwardW.isFinite || forwardW <= 0) {
      throw ArgumentError.value(forwardW, 'forwardW', 'must be positive');
    }
    if (!reflectedW.isFinite || reflectedW < 0 || reflectedW > forwardW) {
      throw ArgumentError.value(
        reflectedW,
        'reflectedW',
        'must be between 0 and the forward power',
      );
    }
    return Swr.fromReflectionCoefficient(sqrt(reflectedW / forwardW));
  }

  /// From a load of [resistance] + j[reactance] ohms on a line of real
  /// characteristic impedance [reference] ohms (50 by default).
  factory Swr.fromImpedance({
    required double resistance,
    double reactance = 0,
    double reference = 50,
  }) {
    if (!resistance.isFinite || resistance < 0) {
      throw ArgumentError.value(resistance, 'resistance', 'must be >= 0');
    }
    if (!reactance.isFinite) {
      throw ArgumentError.value(reactance, 'reactance', 'must be finite');
    }
    if (!reference.isFinite || reference <= 0) {
      throw ArgumentError.value(reference, 'reference', 'must be positive');
    }
    // |Γ| = |Z - Z0| / |Z + Z0| with Z0 real.
    final numerator = sqrt(pow(resistance - reference, 2) + pow(reactance, 2));
    final denominator = sqrt(
      pow(resistance + reference, 2) + pow(reactance, 2),
    );
    return Swr.fromReflectionCoefficient(min(1, numerator / denominator));
  }

  /// |Γ|, 0..1.
  final double reflectionCoefficient;

  /// The ratio itself: 1 for a perfect match, infinity for total reflection.
  double get ratio => reflectionCoefficient >= 1
      ? double.infinity
      : (1 + reflectionCoefficient) / (1 - reflectionCoefficient);

  /// Return loss in dB (positive; infinity for a perfect match).
  double get returnLossDb => reflectionCoefficient <= 0
      ? double.infinity
      : -20 * log(reflectionCoefficient) / ln10;

  /// Share of the forward power that comes back, 0..1.
  double get reflectedFraction => reflectionCoefficient * reflectionCoefficient;

  /// Power lost to the mismatch in dB (infinity for total reflection).
  double get mismatchLossDb => reflectionCoefficient >= 1
      ? double.infinity
      : -10 * log(1 - reflectedFraction) / ln10;

  @override
  String toString() => 'Swr(${ratio.toStringAsFixed(2)}:1)';
}

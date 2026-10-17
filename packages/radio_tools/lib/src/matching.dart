import 'dart:math' as math;

/// What a reactive element is.
enum ReactiveKind { inductor, capacitor }

/// One coil or capacitor of a matching network.
final class ReactiveElement {
  const ReactiveElement._({
    required this.kind,
    required this.reactanceOhms,
    required this.value,
  });

  /// The element that has reactance [reactanceOhms] at [frequencyHz]:
  /// positive is a coil, negative a capacitor.
  factory ReactiveElement.fromReactance(
    double reactanceOhms,
    double frequencyHz,
  ) {
    final w = 2 * math.pi * frequencyHz;
    return reactanceOhms > 0
        ? ReactiveElement._(
            kind: ReactiveKind.inductor,
            reactanceOhms: reactanceOhms,
            value: reactanceOhms / w,
          )
        : ReactiveElement._(
            kind: ReactiveKind.capacitor,
            reactanceOhms: reactanceOhms,
            value: 1 / (w * -reactanceOhms),
          );
  }

  final ReactiveKind kind;

  /// Signed reactance: positive inductive, negative capacitive.
  final double reactanceOhms;

  /// Henries for a coil, farads for a capacitor.
  final double value;
}

/// One way of matching a load with an L-network.
final class LMatch {
  const LMatch({
    required this.series,
    required this.shunt,
    required this.shuntAtLoad,
    required this.q,
  });

  /// Element between the two sides; null when none is needed.
  final ReactiveElement? series;

  /// Element from the line to ground; null when none is needed.
  final ReactiveElement? shunt;

  /// True: the shunt element sits across the load and the series element
  /// leads to the source. False: the series element is at the load and
  /// the shunt element sits across the source.
  final bool shuntAtLoad;

  /// Loaded Q of the network, 0 for a single-element match.
  final double q;

  /// A series coil with a shunt capacitor passes DC and stops harmonics.
  bool get lowPass =>
      (series?.kind ?? ReactiveKind.inductor) == ReactiveKind.inductor &&
      (shunt?.kind ?? ReactiveKind.capacitor) == ReactiveKind.capacitor;
}

/// Two-element L-network solutions that bring a load `R + jX` to a real
/// [reference] impedance.
abstract final class LNetwork {
  /// Up to four solutions: the series-first pair when `R < Z0` and the
  /// shunt-first pair when the load's parallel resistance is above `Z0`.
  /// A load already at `Z0` with some reactance gets a single series
  /// element; an exact match gets an empty list.
  static List<LMatch> solutions({
    required double resistance,
    double reactance = 0,
    double reference = 50,
    required double frequencyHz,
  }) {
    if (!resistance.isFinite || resistance <= 0) {
      throw ArgumentError.value(resistance, 'resistance', 'must be positive');
    }
    if (!reactance.isFinite) throw ArgumentError.value(reactance, 'reactance');
    if (!reference.isFinite || reference <= 0) {
      throw ArgumentError.value(reference, 'reference', 'must be positive');
    }
    if (!frequencyHz.isFinite || frequencyHz <= 0) {
      throw ArgumentError.value(frequencyHz, 'frequencyHz', 'must be positive');
    }
    final r = resistance;
    final x = reactance;
    final z0 = reference;
    final tolerance = z0 * 1e-9;
    final out = <LMatch>[];

    if ((r - z0).abs() <= tolerance) {
      if (x.abs() > tolerance) {
        out.add(
          LMatch(
            series: ReactiveElement.fromReactance(-x, frequencyHz),
            shunt: null,
            shuntAtLoad: false,
            q: 0,
          ),
        );
      }
      return out;
    }

    if (r < z0) {
      // Series element first: R + j(X + Xs) = R(1 ± jQ), then a shunt
      // element cancels the remaining susceptance.
      final q = math.sqrt(z0 / r - 1);
      for (final sign in <double>[1, -1]) {
        out.add(
          LMatch(
            series: _element(sign * q * r - x, frequencyHz, tolerance),
            shunt: _element(-sign * z0 / q, frequencyHz, tolerance),
            shuntAtLoad: false,
            q: q,
          ),
        );
      }
    }

    final g = r / (r * r + x * x);
    final b = -x / (r * r + x * x);
    if (1 / g > z0 + tolerance) {
      // Shunt element first: G + j(B + Bp) = G(1 ± jQ), then a series
      // element cancels the remaining reactance.
      final q = math.sqrt(1 / (g * z0) - 1);
      for (final sign in <double>[1, -1]) {
        final shuntSusceptance = sign * q * g - b;
        out.add(
          LMatch(
            series: _element(sign * q * z0, frequencyHz, tolerance),
            shunt: shuntSusceptance.abs() <= 1e-9 / z0
                ? null
                : ReactiveElement.fromReactance(
                    -1 / shuntSusceptance,
                    frequencyHz,
                  ),
            shuntAtLoad: true,
            q: q,
          ),
        );
      }
    }
    return out;
  }

  static ReactiveElement? _element(
    double reactance,
    double frequencyHz,
    double tolerance,
  ) => reactance.abs() <= tolerance
      ? null
      : ReactiveElement.fromReactance(reactance, frequencyHz);
}

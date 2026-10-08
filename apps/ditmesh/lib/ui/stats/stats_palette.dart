import 'package:flutter/material.dart';

import 'stats_math.dart';

/// The only colours the dashboard uses, all derived from the active
/// [ColorScheme] so light and dark themes are covered without hard-coding.
///
/// * Sequential (magnitude): one hue, [surfaceContainerHighest] -> [primary].
/// * Categorical (identity): receive = primary, send = tertiary, fixed order.
/// * Accuracy buckets: a four-step sequential ramp plus a neutral "none".
final class StatsPalette {
  const StatsPalette(this.scheme);

  final ColorScheme scheme;

  /// Recessive grid / axis stroke.
  Color get grid => scheme.outlineVariant;

  Color get axisText => scheme.onSurfaceVariant;

  /// Series colours in fixed order: receive first, send second.
  Color get receive => scheme.primary;

  Color get send => scheme.tertiary;

  /// Colour for a single undistinguished series.
  Color get single => scheme.primary;

  /// One-hue sequential ramp: `t` in 0..1, 0 = empty cell, 1 = maximum.
  Color sequential(double t) {
    if (t <= 0) {
      return scheme.surfaceContainerHighest;
    }
    final clamped = t.clamp(0.0, 1.0);
    return Color.lerp(scheme.primaryContainer, scheme.primary, clamped)!;
  }

  /// Quantised ramp for `level` in `0..levels - 1`.
  Color sequentialLevel(int level, {int levels = 5}) =>
      level <= 0 ? sequential(0) : sequential(level / (levels - 1));

  /// Text colour that reads on [sequential] at `t`.
  Color onSequential(double t) {
    if (t <= 0) {
      return scheme.onSurfaceVariant;
    }
    return t >= 0.55 ? scheme.onPrimary : scheme.onPrimaryContainer;
  }

  /// Background for an accuracy bucket. Weak is the error container so it is
  /// unmistakable; the rest climb the primary ramp.
  Color bucketBackground(AccuracyBucket bucket) => switch (bucket) {
    AccuracyBucket.none => scheme.surfaceContainerHighest,
    AccuracyBucket.weak => scheme.errorContainer,
    AccuracyBucket.fair => sequential(0.25),
    AccuracyBucket.good => sequential(0.6),
    AccuracyBucket.strong => sequential(1),
  };

  Color bucketForeground(AccuracyBucket bucket) => switch (bucket) {
    AccuracyBucket.none => scheme.onSurfaceVariant,
    AccuracyBucket.weak => scheme.onErrorContainer,
    AccuracyBucket.fair => scheme.onPrimaryContainer,
    AccuracyBucket.good => scheme.onPrimary,
    AccuracyBucket.strong => scheme.onPrimary,
  };
}

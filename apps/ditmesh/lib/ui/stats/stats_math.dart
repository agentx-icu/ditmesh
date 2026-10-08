import 'dart:math' as math;

import 'package:intl/intl.dart';

/// Pure helpers behind the statistics painters: accuracy buckets, "nice" axis
/// scaling, heat-level quantisation and calendar-day arithmetic. No Flutter
/// imports so they unit-test with plain `test`.

/// Coarse accuracy class used to colour the per-character grid.
enum AccuracyBucket {
  /// No attempts recorded.
  none,

  /// Below [kWeakBelow].
  weak,

  /// [kWeakBelow] up to but excluding [kGoodFrom].
  fair,

  /// [kGoodFrom] up to but excluding [kStrongFrom].
  good,

  /// [kStrongFrom] and above.
  strong,
}

const double kWeakBelow = 0.70;
const double kGoodFrom = 0.90;
const double kStrongFrom = 0.98;

/// Maps an accuracy fraction (0..1) and attempt count to a bucket.
///
/// Zero attempts is always [AccuracyBucket.none] regardless of [accuracy], so
/// the "0 % of nothing" case never renders as weak.
AccuracyBucket bucketFor(double accuracy, {required int attempts}) {
  if (attempts <= 0) {
    return AccuracyBucket.none;
  }
  if (accuracy < kWeakBelow) {
    return AccuracyBucket.weak;
  }
  if (accuracy < kGoodFrom) {
    return AccuracyBucket.fair;
  }
  if (accuracy < kStrongFrom) {
    return AccuracyBucket.good;
  }
  return AccuracyBucket.strong;
}

/// A linear axis with rounded bounds and evenly spaced ticks.
final class AxisScale {
  const AxisScale({required this.min, required this.max, required this.ticks})
    : assert(max > min, 'max must exceed min');

  final double min;
  final double max;
  final List<double> ticks;

  double get span => max - min;

  /// Fraction 0..1 of [value] along the axis, clamped to the bounds.
  double normalize(double value) => ((value - min) / span).clamp(0.0, 1.0);

  /// Pixel position of [value] between [start] and [end] (either direction,
  /// so a y axis passes `start: bottom, end: top`).
  double project(double value, {required double start, required double end}) =>
      start + (end - start) * normalize(value);
}

/// Picks a "nice" tick step (1, 2, 2.5 or 5 x 10^k) that yields roughly
/// [targetTicks] ticks across [span].
double niceStep(double span, {int targetTicks = 5}) {
  if (span <= 0 || targetTicks <= 0) {
    return 1;
  }
  final raw = span / targetTicks;
  final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor());
  final residual = raw / magnitude;
  final double nice;
  if (residual <= 1) {
    nice = 1;
  } else if (residual <= 2) {
    nice = 2;
  } else if (residual <= 2.5) {
    nice = 2.5;
  } else if (residual <= 5) {
    nice = 5;
  } else {
    nice = 10;
  }
  return nice * magnitude;
}

/// Builds an axis whose bounds are multiples of a nice step enclosing
/// [minValue]..[maxValue], optionally clamped to [hardMin]..[hardMax].
///
/// A degenerate range (all values equal) is widened by one step so the axis
/// still has height. Ticks include both bounds.
AxisScale niceAxis(
  double minValue,
  double maxValue, {
  int targetTicks = 5,
  double? hardMin,
  double? hardMax,
}) {
  var lo = math.min(minValue, maxValue);
  var hi = math.max(minValue, maxValue);
  if (hi - lo < 1e-9) {
    final step = niceStep(hi.abs() == 0 ? 1 : hi.abs(), targetTicks: 2);
    lo -= step;
    hi += step;
  }
  final step = niceStep(hi - lo, targetTicks: targetTicks);
  // Snap the bounds exactly like the ticks: `floor * step` drifts in binary
  // (3 * 0.2 = 0.6000000000000001) and the painter compares them to ticks.
  var min = _snap((lo / step).floor() * step, step);
  var max = _snap((hi / step).ceil() * step, step);
  if (hardMin != null) {
    min = math.max(min, hardMin);
  }
  if (hardMax != null) {
    max = math.min(max, hardMax);
  }
  if (max - min < 1e-9) {
    // Both clamps collapsed the range (e.g. every value is exactly 1.0).
    if (hardMin != null && min - step >= hardMin - 1e-9) {
      min = _snap(min - step, step);
    } else {
      max = _snap(max + step, step);
    }
  }
  final ticks = <double>[];
  for (var t = min; t <= max + step / 2; t += step) {
    ticks.add(_snap(t, step));
  }
  if ((ticks.last - max).abs() > 1e-9) {
    ticks.add(max);
  }
  return AxisScale(min: min, max: max, ticks: ticks);
}

/// Axis for accuracy fractions: 0..1 hard bounds, floor a little below the
/// worst session so a plateau near 100 % still shows its wobble.
AxisScale accuracyAxis(Iterable<double> values, {int targetTicks = 5}) {
  if (values.isEmpty) {
    return niceAxis(0, 1, targetTicks: targetTicks, hardMin: 0, hardMax: 1);
  }
  final lo = values.reduce(math.min);
  return niceAxis(
    math.max(0, lo - 0.05),
    1,
    targetTicks: targetTicks,
    hardMin: 0,
    hardMax: 1,
  );
}

double _snap(double value, double step) {
  final decimals = math.max(0, -(math.log(step) / math.ln10).floor() + 1);
  final factor = math.pow(10, decimals).toDouble();
  return (value * factor).round() / factor;
}

/// Quantises [count] against [max] into `0..levels - 1`, where 0 is reserved
/// for zero and the top level for the maximum. Uses a square root so a single
/// heavy day does not flatten every other day to level 1.
int heatLevel(int count, {required int max, int levels = 5}) {
  assert(levels >= 2, 'need at least an empty and a full level');
  if (count <= 0 || max <= 0) {
    return 0;
  }
  if (count >= max) {
    return levels - 1;
  }
  final ratio = math.sqrt(count / max);
  return math.max(1, math.min(levels - 1, (ratio * (levels - 1)).ceil()));
}

/// Continuous 0..1 intensity for a heatmap cell (square-root scaled), or 0
/// when there is nothing to show.
double heatIntensity(int count, {required int max}) {
  if (count <= 0 || max <= 0) {
    return 0;
  }
  return math.min(1, math.sqrt(count / max));
}

/// Local midnight of [when]; the calendar bucket key used everywhere here.
DateTime dayOf(DateTime when) => DateTime(when.year, when.month, when.day);

/// Whole calendar days from [a] to [b] (positive when [b] is later),
/// independent of the time-of-day and DST shifts.
int daysBetween(DateTime a, DateTime b) {
  final da = dayOf(a);
  final db = dayOf(b);
  return ((db.difference(da).inHours) / 24).round();
}

/// Groups consecutive sorted calendar days into run lengths and returns the
/// longest. [days] may contain duplicates or be unsorted.
int longestDailyRun(Iterable<DateTime> days) {
  final distinct = days.map(dayOf).toSet().toList()..sort();
  var best = 0;
  var run = 0;
  DateTime? previous;
  for (final day in distinct) {
    if (previous != null && daysBetween(previous, day) == 1) {
      run++;
    } else {
      run = 1;
    }
    best = math.max(best, run);
    previous = day;
  }
  return best;
}

/// The Monday on or before [day] (ISO week start), at local midnight.
DateTime weekStartOf(DateTime day) {
  final d = dayOf(day);
  return d.subtract(Duration(days: d.weekday - DateTime.monday));
}

/// Narrow weekday label for [weekday] (1 = Monday) in [locale] (intl's
/// default when null): `M`/`T`/`W` in English, `一`/`二`/`三` in Chinese.
String weekdayInitial(int weekday, {String? locale}) => DateFormat.EEEEE(
  locale,
  // 2024-01-01 is a Monday, so day n of that week has weekday n.
).format(DateTime(2024, 1, (weekday - 1).clamp(0, 6) + 1));

/// Abbreviated month name for [month] (1..12) in [locale]: `Jan` / `1月`.
String monthAbbreviation(int month, {String? locale}) =>
    DateFormat.MMM(locale).format(DateTime(2024, (month - 1).clamp(0, 11) + 1));

/// Chooses which x indices (0..count-1) get an axis label so at most
/// [maxLabels] are shown and both ends are always included.
///
/// Labels step by a constant integer stride so the gaps are even: rounding a
/// fractional step used to yield `1 2 3 5 6 7` for seven sessions (the 4 was
/// skipped while 1-3 were consecutive). The last index is always labelled;
/// the stride label just before it is dropped when it would sit closer to
/// the end than half a stride, so the two never crowd each other.
List<int> labelledIndices(int count, {int maxLabels = 6}) {
  if (count <= 0) {
    return const <int>[];
  }
  // Both ends are always labelled, so the budget is at least two.
  final budget = math.max(2, maxLabels);
  if (count <= budget) {
    return List<int>.generate(count, (i) => i);
  }
  final last = count - 1;
  // ceil(last / (budget - 1)) in integer arithmetic: no double rounding.
  final stride = (last + budget - 2) ~/ (budget - 1);
  final out = <int>[0];
  // Advance by subtraction from `last` so a huge count cannot overflow.
  while (last - out.last > stride) {
    out.add(out.last + stride);
  }
  // The stride label just before the end is dropped when it would sit
  // closer to the end than half a stride.
  if (out.length > 1 && 2 * (last - out.last) < stride) {
    out.removeLast();
  }
  out.add(last);
  return out;
}

/// Index of the point whose x pixel is nearest to [x]; null when [xs] is
/// empty or the nearest point is further than [maxDistance].
int? nearestIndex(List<double> xs, double x, {double maxDistance = 32}) {
  int? best;
  var bestDistance = double.infinity;
  for (var i = 0; i < xs.length; i++) {
    final d = (xs[i] - x).abs();
    if (d < bestDistance) {
      bestDistance = d;
      best = i;
    }
  }
  return bestDistance <= maxDistance ? best : null;
}

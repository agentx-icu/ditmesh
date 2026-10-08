/// Small 1-D clustering helpers used by the adaptive decoder.
///
/// Everything here is deterministic and allocation-light so it can run on
/// every key-up without measurable cost.
library;

import 'dart:math' as math;

/// Result of splitting a set of samples into a short and a long cluster.
final class ClusterSplit {
  const ClusterSplit({
    required this.lowMean,
    required this.highMean,
    required this.lowCount,
    required this.highCount,
  });

  /// Arithmetic mean of the short cluster.
  final double lowMean;

  /// Arithmetic mean of the long cluster.
  final double highMean;

  final int lowCount;
  final int highCount;

  /// `highMean / lowMean`; large when two clusters are clearly present.
  double get separation => lowMean <= 0 ? double.infinity : highMean / lowMean;

  @override
  String toString() =>
      'ClusterSplit(low: $lowMean x$lowCount, high: $highMean x$highCount)';
}

/// Arithmetic mean of [values]; 0 for an empty list.
double mean(Iterable<double> values) {
  double sum = 0;
  int n = 0;
  for (final double v in values) {
    sum += v;
    n++;
  }
  return n == 0 ? 0 : sum / n;
}

/// Two-cluster 1-D k-means over `log(value)`, seeded with the expected
/// centroids [seedLow] / [seedHigh] (in linear units, all strictly positive).
///
/// Why log scale: keying jitter is proportional to the element length, so a
/// dah wanders three times as far as a dit. In linear units the midpoint
/// between the cluster means (2 dit) lies *inside* the dah spread and every
/// dah that lands below it drags the short cluster's mean up, which moves the
/// boundary further into the dahs (positive feedback). In log units both
/// clusters have the same width and the boundary sits at their geometric
/// mean (~1.73 dit), in the empty band between them. A variance-optimal
/// (Otsu) split has a related failure: with a dah-heavy window it prefers to
/// cut the wide dah cluster in half.
///
/// Samples below the current boundary join the low cluster, the rest the
/// high cluster; centroids are recomputed until the assignment is stable (at
/// most [maxIterations] rounds). If the seeded boundary leaves one cluster
/// empty (all data on one side), the split is re-seeded from the sample
/// extremes so a grossly wrong prior can still be corrected. Returns null when
/// fewer than two samples are available or all samples are identical.
///
/// The reported means are *arithmetic* means of the members in linear units.
ClusterSplit? splitTwoClusters(
  List<double> values, {
  required double seedLow,
  required double seedHigh,
  int maxIterations = 16,
}) {
  if (values.length < 2) return null;
  final List<double> logs = List<double>.generate(
    values.length,
    (int i) => math.log(values[i]),
    growable: false,
  );

  double lo = math.log(seedLow);
  double hi = math.log(seedHigh);
  ClusterSplit? result;
  bool reseeded = false;

  for (int iteration = 0; iteration < maxIterations; iteration++) {
    final double boundary = (lo + hi) / 2;
    double lowLogSum = 0;
    double highLogSum = 0;
    double lowSum = 0;
    double highSum = 0;
    int lowCount = 0;
    int highCount = 0;
    for (int i = 0; i < logs.length; i++) {
      if (logs[i] < boundary) {
        lowLogSum += logs[i];
        lowSum += values[i];
        lowCount++;
      } else {
        highLogSum += logs[i];
        highSum += values[i];
        highCount++;
      }
    }

    if (lowCount == 0 || highCount == 0) {
      if (reseeded) return null;
      reseeded = true;
      double min = logs.first;
      double max = logs.first;
      for (final double v in logs) {
        if (v < min) min = v;
        if (v > max) max = v;
      }
      if (min == max) return null; // all samples identical
      lo = min;
      hi = max;
      continue;
    }

    final double newLo = lowLogSum / lowCount;
    final double newHi = highLogSum / highCount;
    result = ClusterSplit(
      lowMean: lowSum / lowCount,
      highMean: highSum / highCount,
      lowCount: lowCount,
      highCount: highCount,
    );
    if (newLo == lo && newHi == hi) break;
    lo = newLo;
    hi = newHi;
  }
  return result;
}

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ditmesh/ui/stats/stats_math.dart';

void main() {
  // In the app flutter_localizations loads the date symbols for the active
  // locale; a bare `dart test` has only intl's en_US fallback, and asking
  // DateFormat for 'en' throws LocaleDataException without this.
  setUpAll(() => initializeDateFormatting('en'));

  group('bucketFor', () {
    test('zero attempts is none regardless of accuracy', () {
      expect(bucketFor(0, attempts: 0), AccuracyBucket.none);
      expect(bucketFor(1, attempts: 0), AccuracyBucket.none);
    });

    test('maps thresholds inclusively at the upper edge', () {
      expect(bucketFor(0.69, attempts: 10), AccuracyBucket.weak);
      expect(bucketFor(0.70, attempts: 10), AccuracyBucket.fair);
      expect(bucketFor(0.899, attempts: 10), AccuracyBucket.fair);
      expect(bucketFor(0.90, attempts: 10), AccuracyBucket.good);
      expect(bucketFor(0.979, attempts: 10), AccuracyBucket.good);
      expect(bucketFor(0.98, attempts: 10), AccuracyBucket.strong);
      expect(bucketFor(1.0, attempts: 10), AccuracyBucket.strong);
    });
  });

  group('niceStep', () {
    test('snaps to 1 / 2 / 2.5 / 5 x 10^k', () {
      expect(niceStep(1, targetTicks: 5), 0.2);
      expect(niceStep(10, targetTicks: 5), 2);
      expect(niceStep(0.3, targetTicks: 5), 0.1);
      expect(niceStep(100, targetTicks: 4), 25);
      expect(niceStep(7, targetTicks: 5), 2);
    });

    test('degenerate inputs fall back to 1', () {
      expect(niceStep(0), 1);
      expect(niceStep(-5), 1);
      expect(niceStep(10, targetTicks: 0), 1);
    });
  });

  group('niceAxis', () {
    test('encloses the data with rounded bounds and ticks at both ends', () {
      final axis = niceAxis(0.63, 0.97);
      expect(axis.min, lessThanOrEqualTo(0.63));
      expect(axis.max, greaterThanOrEqualTo(0.97));
      expect(axis.ticks.first, axis.min);
      expect(axis.ticks.last, axis.max);
      for (var i = 1; i < axis.ticks.length; i++) {
        expect(axis.ticks[i], greaterThan(axis.ticks[i - 1]));
      }
    });

    test('respects hard bounds', () {
      final axis = niceAxis(-0.3, 1.4, hardMin: 0, hardMax: 1);
      expect(axis.min, 0);
      expect(axis.max, 1);
    });

    test('widens a flat range so the axis still has height', () {
      final axis = niceAxis(0.5, 0.5);
      expect(axis.max, greaterThan(axis.min));
      expect(axis.normalize(0.5), closeTo(0.5, 0.01));
    });

    test('all-perfect accuracies keep a visible band under 100 %', () {
      final axis = accuracyAxis(<double>[1, 1, 1]);
      expect(axis.max, 1);
      expect(axis.min, lessThan(1));
      expect(axis.min, greaterThanOrEqualTo(0));
    });

    test('empty accuracy series is the full 0..1 axis', () {
      final axis = accuracyAxis(const <double>[]);
      expect(axis.min, 0);
      expect(axis.max, 1);
    });
  });

  group('AxisScale', () {
    const axis = AxisScale(min: 0, max: 1, ticks: <double>[0, 0.5, 1]);

    test('normalize clamps to 0..1', () {
      expect(axis.normalize(-1), 0);
      expect(axis.normalize(0.25), 0.25);
      expect(axis.normalize(2), 1);
    });

    test('project maps between start and end in either direction', () {
      expect(axis.project(0, start: 200, end: 0), 200);
      expect(axis.project(1, start: 200, end: 0), 0);
      expect(axis.project(0.5, start: 200, end: 0), 100);
      expect(axis.project(0.5, start: 10, end: 110), 60);
    });
  });

  group('heat levels', () {
    test('heatLevel reserves 0 for empty and the top level for the max', () {
      expect(heatLevel(0, max: 100), 0);
      expect(heatLevel(5, max: 0), 0);
      expect(heatLevel(100, max: 100), 4);
      expect(heatLevel(1, max: 100), greaterThanOrEqualTo(1));
      expect(heatLevel(1, max: 100), lessThan(4));
    });

    test('heatLevel is monotonic', () {
      var last = 0;
      for (var c = 0; c <= 50; c++) {
        final level = heatLevel(c, max: 50);
        expect(level, greaterThanOrEqualTo(last));
        last = level;
      }
    });

    test('heatIntensity is sqrt-scaled and capped at 1', () {
      expect(heatIntensity(0, max: 4), 0);
      expect(heatIntensity(1, max: 4), closeTo(0.5, 1e-9));
      expect(heatIntensity(4, max: 4), 1);
      expect(heatIntensity(9, max: 4), 1);
    });
  });

  group('calendar helpers', () {
    test('dayOf strips time', () {
      expect(dayOf(DateTime(2026, 9, 30, 23, 59)), DateTime(2026, 9, 30));
    });

    test('daysBetween counts calendar days', () {
      expect(daysBetween(DateTime(2026, 9, 29, 23), DateTime(2026, 9, 30)), 1);
      expect(daysBetween(DateTime(2026, 9, 30), DateTime(2026, 9, 28)), -2);
      expect(
        daysBetween(DateTime(2026, 9, 30, 1), DateTime(2026, 9, 30, 23)),
        0,
      );
    });

    test('longestDailyRun ignores duplicates and gaps', () {
      final days = <DateTime>[
        DateTime(2026, 9, 1, 9),
        DateTime(2026, 9, 1, 18),
        DateTime(2026, 9, 2),
        DateTime(2026, 9, 3),
        DateTime(2026, 9, 5),
        DateTime(2026, 9, 6),
      ];
      expect(longestDailyRun(days), 3);
      expect(longestDailyRun(const <DateTime>[]), 0);
      expect(longestDailyRun(<DateTime>[DateTime(2026, 9, 1)]), 1);
    });

    test('weekStartOf returns the Monday of the ISO week', () {
      // 2026-09-30 is a Wednesday.
      expect(weekStartOf(DateTime(2026, 9, 30, 15)), DateTime(2026, 9, 28));
      expect(weekStartOf(DateTime(2026, 9, 28)), DateTime(2026, 9, 28));
      expect(weekStartOf(DateTime(2026, 10, 4)), DateTime(2026, 9, 28));
    });

    test('labels', () {
      expect(weekdayInitial(DateTime.monday, locale: 'en'), 'M');
      expect(weekdayInitial(DateTime.sunday, locale: 'en'), 'S');
      expect(monthAbbreviation(1, locale: 'en'), 'Jan');
      expect(monthAbbreviation(12, locale: 'en'), 'Dec');
    });
  });

  group('labelledIndices', () {
    test('returns every index when there is room', () {
      expect(labelledIndices(4, maxLabels: 6), <int>[0, 1, 2, 3]);
      expect(labelledIndices(0), isEmpty);
    });

    test('always keeps both ends and stays within the budget', () {
      final idx = labelledIndices(30, maxLabels: 6);
      expect(idx.first, 0);
      expect(idx.last, 29);
      expect(idx.length, lessThanOrEqualTo(6));
      expect(idx, orderedEquals(idx.toSet().toList()..sort()));
    });

    test('drops the stride label that would crowd the last one', () {
      // 14 sessions, budget 6: stride 3 -> 0 3 6 9 12, and 12 is only one
      // step from 13, so it goes.
      expect(labelledIndices(14, maxLabels: 6), <int>[0, 3, 6, 9, 13]);
    });

    test('one over budget with tiny budgets keeps both ends', () {
      expect(labelledIndices(3, maxLabels: 2), <int>[0, 2]);
      expect(labelledIndices(4, maxLabels: 3), <int>[0, 2, 3]);
      // Budgets below two are treated as two.
      expect(labelledIndices(9, maxLabels: 0), <int>[0, 8]);
      expect(labelledIndices(9, maxLabels: 1), <int>[0, 8]);
    });

    test('never exceeds the budget and survives huge counts', () {
      for (final count in <int>[7, 8, 11, 12, 13, 25, 100, 1 << 40]) {
        for (final budget in <int>[2, 3, 4, 6, 9]) {
          final idx = labelledIndices(count, maxLabels: budget);
          expect(idx.first, 0, reason: '$count/$budget');
          expect(idx.last, count - 1, reason: '$count/$budget');
          expect(idx.length, lessThanOrEqualTo(math.max(2, budget)),
              reason: '$count/$budget');
          expect(idx, orderedEquals(idx.toSet().toList()..sort()),
              reason: '$count/$budget');
        }
      }
    });

    test('steps evenly instead of skipping one index mid-run', () {
      // Seven sessions used to label 1 2 3 5 6 7 (the rounded fractional
      // step skipped the 4). Every gap must be the same stride.
      expect(labelledIndices(7, maxLabels: 6), <int>[0, 2, 4, 6]);
      final idx = labelledIndices(30, maxLabels: 6);
      final gaps = <int>{
        for (var i = 1; i < idx.length - 1; i++) idx[i] - idx[i - 1],
      };
      expect(gaps, hasLength(1));
      // The last label never crowds the stride label before it.
      expect(idx.last - idx[idx.length - 2], greaterThanOrEqualTo(3));
    });
  });

  group('nearestIndex', () {
    test('finds the closest x within the distance budget', () {
      final xs = <double>[10, 50, 90];
      expect(nearestIndex(xs, 48), 1);
      expect(nearestIndex(xs, 5), 0);
      expect(nearestIndex(xs, 200, maxDistance: 32), isNull);
      expect(nearestIndex(const <double>[], 5), isNull);
    });
  });
}

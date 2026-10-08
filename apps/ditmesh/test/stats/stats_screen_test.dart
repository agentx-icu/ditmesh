import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/ui/stats/accuracy_trend_chart.dart';
import 'package:ditmesh/ui/stats/char_grid.dart';
import 'package:ditmesh/ui/stats/confusion_heatmap.dart';
import 'package:ditmesh/ui/stats/practice_calendar.dart';
import 'package:ditmesh/ui/stats/stats_model.dart';
import 'package:ditmesh/ui/stats/stats_screen.dart';
import 'package:ditmesh/ui/stats/stats_widgets.dart';

import '../learn/helpers/l10n.dart';
import 'stats_model_test.dart' show buildProgress, kNow;

const Size kPhone = Size(390, 844);
const Size kDesktop = Size(1280, 900);

Future<void> _setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required Future<TrainerProgress> Function() load,
  ThemeData? theme,
}) async {
  await _setSize(tester, size);
  await tester.pumpWidget(
    l10nApp(theme: theme, home: StatsScreen(loadProgress: load, now: kNow)),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('StatsScreen', () {
    testWidgets('shows the empty state for a fresh identity', (tester) async {
      await _pump(tester, size: kPhone, load: () async => TrainerProgress());
      expect(find.text(en.statsTitle), findsOneWidget);
      expect(find.text(en.statsEmptyTitle), findsOneWidget);
      expect(find.text(en.statsEmptyCallToAction), findsOneWidget);
      expect(find.byType(OverviewTiles), findsNothing);
      expect(find.byType(AccuracyTrendChart), findsNothing);
    });

    testWidgets('shows a loading state until the future resolves', (
      tester,
    ) async {
      await _setSize(tester, kPhone);
      await tester.pumpWidget(
        l10nApp(
          home: StatsScreen(
            loadProgress: () => Future<TrainerProgress>.delayed(
              const Duration(seconds: 1),
              TrainerProgress.new,
            ),
            now: kNow,
          ),
        ),
      );
      await tester.pump();
      expect(find.text(en.statsLoading), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text(en.statsEmptyTitle), findsOneWidget);
    });

    testWidgets('shows an error state with retry', (tester) async {
      var calls = 0;
      await _pump(
        tester,
        size: kPhone,
        load: () {
          calls++;
          if (calls == 1) {
            return Future<TrainerProgress>.error(StateError('disk'));
          }
          return Future<TrainerProgress>.value(buildProgress());
        },
      );
      expect(find.text(en.statsLoadFailed), findsOneWidget);
      await tester.tap(find.text(en.statsRetry));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.byType(OverviewTiles), findsOneWidget);
    });

    testWidgets('renders overview tiles on a phone', (tester) async {
      await _pump(
        tester,
        size: kPhone,
        load: () async => buildProgress(days: 3),
      );
      expect(find.text(en.statsTileLesson), findsOneWidget);
      expect(find.text(en.statsLessonOf(3, 42)), findsOneWidget);
      expect(find.text(en.statsCharsLearned(4)), findsOneWidget);
      expect(find.text(formatPercent(en, 34 / 36)), findsOneWidget);
      expect(
        find.text(formatPracticeDuration(en, const Duration(minutes: 6))),
        findsOneWidget,
      );
      expect(find.text(en.statsDays(3)), findsOneWidget);
      expect(find.text(en.statsBestStreak(3)), findsOneWidget);
      expect(find.text(en.statsGoalProgress(12, 20)), findsOneWidget);
      expect(find.text(en.statsGoalRemaining(8)), findsOneWidget);
      expect(find.text(en.statsTrendTitle), findsOneWidget);

      // Single column: the trend chart sits below the overview.
      final overview = tester.getRect(find.byType(OverviewTiles));
      final trend = tester.getRect(find.byType(AccuracyTrendChart));
      expect(trend.top, greaterThanOrEqualTo(overview.bottom));
      expect(trend.left, closeTo(overview.left, 1));
    });

    testWidgets('uses two columns at desktop width', (tester) async {
      await _pump(
        tester,
        size: kDesktop,
        load: () async => buildProgress(days: 3),
      );
      final trend = tester.getRect(find.byType(AccuracyTrendChart));
      final chars = tester.getRect(find.byType(CharGrid));
      expect(chars.top, closeTo(trend.top, 1));
      expect(chars.left, greaterThan(trend.right - 1));
      expect(find.byType(ConfusionHeatmap), findsOneWidget);
      expect(find.byType(PracticeCalendar), findsOneWidget);
    });

    testWidgets('daily goal met is reported', (tester) async {
      final progress = buildProgress(days: 1).copyWith(dailyGoalChars: 10);
      await _pump(tester, size: kPhone, load: () async => progress);
      expect(find.text(en.statsGoalMet), findsOneWidget);
    });

    testWidgets('tapping the trend chart shows a session tooltip', (
      tester,
    ) async {
      await _pump(
        tester,
        size: kDesktop,
        load: () async => buildProgress(days: 3),
      );
      expect(find.text(en.statsTrendHint), findsOneWidget);
      // Not `find.byType(CustomPaint).first`: the enclosing Card's ink
      // layer is a CustomPaint too and sits outside the chart's tap target.
      final chart = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is TrendPainter,
      );
      final rect = tester.getRect(chart);
      // The newest session sits at the right edge of the plot.
      await tester.tapAt(
        Offset(rect.right - TrendGeometry.kRightInset, rect.center.dy),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(en.statsTooltipSession(3, 3)),
        findsOneWidget,
      );
      expect(find.text(en.statsTrendHint), findsNothing);
    });

    testWidgets('legend appears only when send and receive both exist', (
      tester,
    ) async {
      await _pump(
        tester,
        size: kDesktop,
        load: () async => buildProgress(days: 2, withSendToday: true),
      );
      expect(find.text(en.statsSeriesReceive), findsOneWidget);
      expect(find.text(en.statsSeriesSend), findsOneWidget);
    });

    testWidgets('tapping a character opens the detail sheet', (tester) async {
      await _pump(
        tester,
        size: kDesktop,
        load: () async => buildProgress(days: 3),
      );
      final cell = find.byWidgetPredicate(
        (w) => w is CharCell && w.char == 'S',
      );
      expect(cell, findsOneWidget);
      await tester.tap(cell);
      await tester.pumpAndSettle();
      expect(find.byType(CharDetailSheet), findsOneWidget);
      expect(find.text(en.statsSrsTitle), findsOneWidget);
      expect(find.text(en.statsCorrectOf(7, 9)), findsOneWidget);
      expect(find.text(en.statsConfusionsTitle), findsOneWidget);
      expect(find.text(en.statsTimes(2)), findsOneWidget);
      // Two demotions at box 0 then one promotion: box 1, due tomorrow.
      expect(find.textContaining(en.statsSrsBox(1, 4)), findsOneWidget);
      expect(find.textContaining(en.statsSrsDueIn(1)), findsOneWidget);
    });

    testWidgets('unpractised character reports no data', (tester) async {
      await _pump(
        tester,
        size: kDesktop,
        load: () async => buildProgress(days: 1),
      );
      await tester.tap(
        find.byWidgetPredicate((w) => w is CharCell && w.char == 'U'),
      );
      await tester.pumpAndSettle();
      expect(find.text(en.statsCharsNotStarted), findsWidgets);
      expect(find.text(en.statsLessonIntroduced(4)), findsOneWidget);
      expect(find.text(en.statsSrsNotTracked), findsOneWidget);
      expect(find.text(en.statsConfusionsNone), findsOneWidget);
    });

    testWidgets('heatmap hides when nothing was confused', (tester) async {
      await _pump(
        tester,
        size: kDesktop,
        load: () async => buildProgress(days: 1),
      );
      expect(find.text(en.statsHeatmapEmpty), findsOneWidget);
    });

    testWidgets('heatmap renders and reads a tapped cell', (tester) async {
      await _pump(
        tester,
        size: kDesktop,
        load: () async => buildProgress(days: 3),
      );
      expect(find.text(en.statsHeatmapEmpty), findsNothing);
      final paint = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is HeatmapPainter,
      );
      final rect = tester.getRect(paint);
      const cell = ConfusionHeatmap.kCell;
      await tester.tapAt(rect.topLeft + const Offset(cell * 1.5, cell * 1.5));
      await tester.pumpAndSettle();
      expect(find.text(en.statsHeatmapCell('S', 'R', 2)), findsOneWidget);
    });

    testWidgets('calendar shows active days and streak explanation', (
      tester,
    ) async {
      await _pump(
        tester,
        size: kDesktop,
        load: () async => buildProgress(days: 3),
      );
      expect(find.textContaining(en.statsActiveDays(3)), findsOneWidget);
      expect(find.text(en.statsStreakExplanation), findsOneWidget);
    });

    testWidgets('renders under the dark theme', (tester) async {
      await _pump(
        tester,
        size: kDesktop,
        load: () async => buildProgress(days: 3, withSendToday: true),
        theme: ThemeData.dark(useMaterial3: true),
      );
      expect(find.byType(OverviewTiles), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('StatsSummaryCard', () {
    testWidgets('shows headline numbers', (tester) async {
      await _setSize(tester, kPhone);
      await tester.pumpWidget(
        l10nApp(
          home: Scaffold(
            body: StatsSummaryCard(progress: buildProgress(days: 3), now: kNow),
          ),
        ),
      );
      expect(find.text(en.statsSummaryTitle), findsOneWidget);
      expect(find.text(formatPercent(en, 34 / 36)), findsOneWidget);
      expect(find.text(en.statsDays(3)), findsOneWidget);
      expect(find.text(en.statsSummaryOpen), findsNothing);
    });

    testWidgets('empty progress and open action', (tester) async {
      var opened = 0;
      await _setSize(tester, kPhone);
      await tester.pumpWidget(
        l10nApp(
          home: Scaffold(
            body: StatsSummaryCard(
              progress: TrainerProgress(),
              now: kNow,
              onOpen: () => opened++,
            ),
          ),
        ),
      );
      expect(find.text(en.statsEmptyTitle), findsOneWidget);
      await tester.tap(find.text(en.statsSummaryOpen));
      expect(opened, 1);
    });
  });

  group('geometry helpers', () {
    test('TrendGeometry spaces points across the plot', () {
      final points = <TrendPoint>[
        for (var i = 0; i < 3; i++)
          TrendPoint(
            index: i + 1,
            summary: SessionSummary(
              at: kNow,
              totalChars: 10,
              correctChars: 5 + i * 2,
            ),
            isSend: false,
          ),
      ];
      final g = TrendGeometry(points: points, size: const Size(300, 200));
      expect(g.xs.first, TrendGeometry.kLeftInset);
      expect(g.xs.last, 300 - TrendGeometry.kRightInset);
      expect(g.xs[1], closeTo((g.xs.first + g.xs.last) / 2, 1e-9));
      expect(g.ys.first, greaterThan(g.ys.last));
      expect(g.ys.every((y) => y >= g.plot.top && y <= g.plot.bottom), isTrue);
    });

    test('a single point is centred', () {
      final g = TrendGeometry(
        points: <TrendPoint>[
          TrendPoint(
            index: 1,
            summary: SessionSummary(at: kNow, totalChars: 4, correctChars: 4),
            isSend: true,
          ),
        ],
        size: const Size(300, 200),
      );
      expect(g.xs.single, closeTo(g.plot.center.dx, 1e-9));
    });

    test('CalendarGeometry fits and hit-tests squares', () {
      final g = CalendarGeometry.fit(dayCount: 84, maxWidth: 200);
      expect(g.weeks, 12);
      expect(g.cell, lessThanOrEqualTo(CalendarGeometry.kMaxCell));
      expect(g.size.width, lessThanOrEqualTo(200 + 1e-9));
      expect(g.indexAt(g.rectFor(0).center), 0);
      expect(g.indexAt(g.rectFor(83).center), 83);
      expect(g.indexAt(g.rectFor(9).center), 9);
      expect(g.indexAt(const Offset(0, 0)), isNull);
      expect(g.indexAt(Offset(g.size.width + 5, g.size.height + 5)), isNull);
    });

    test('CalendarGeometry grows squares on wide layouts up to the cap', () {
      final g = CalendarGeometry.fit(dayCount: 84, maxWidth: 1000);
      expect(g.cell, CalendarGeometry.kMaxCell);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../i18n/l10n_extension.dart';
import '../common/app_bar_title.dart';
import '../responsive.dart';
import 'accuracy_trend_chart.dart';
import 'char_grid.dart';
import 'confusion_heatmap.dart';
import 'practice_calendar.dart';
import 'stats_model.dart';
import 'stats_widgets.dart';

/// Minimum width at which the dashboard lays its sections out in two columns.
const double kStatsTwoColumnMinWidth = 900;

/// Training statistics dashboard.
///
/// [loadProgress] is called once per mount (and again on retry / refresh);
/// pass the same closure the Learn tab uses so wiring is a one-liner. Pass
/// [now] to pin the clock in tests.
class StatsScreen extends StatefulWidget {
  const StatsScreen({
    super.key,
    required this.loadProgress,
    this.course,
    this.now,
    this.showAppBar = true,
  });

  final Future<TrainerProgress> Function() loadProgress;
  final KochCourse? course;
  final DateTime? now;

  /// Set false when embedding under a shell that already draws a title.
  final bool showAppBar;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<TrainerProgress> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loadProgress();
  }

  Future<void> _reload() {
    final next = widget.loadProgress();
    // Block body: an arrow closure would return the assigned Future, which
    // trips setState's "callback returned a Future" assertion in debug.
    setState(() {
      _future = next;
    });
    return next.then<void>((_) {}, onError: (Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<TrainerProgress>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErrorState(onRetry: _reload);
        }
        final progress = snapshot.data;
        if (progress == null) {
          return const _LoadingState();
        }
        final stats = StatsSnapshot.from(
          progress,
          course: widget.course,
          now: widget.now,
        );
        return RefreshIndicator(
          onRefresh: _reload,
          child: stats.isEmpty
              ? const _ScrollableEmpty()
              : StatsDashboard(snapshot: stats),
        );
      },
    );
    if (!widget.showAppBar) {
      return body;
    }
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(context.s.statsTitle)),
      body: body,
    );
  }
}

/// The populated dashboard: single scrolling column on phones, two columns
/// from [kStatsTwoColumnMinWidth].
class StatsDashboard extends StatelessWidget {
  const StatsDashboard({super.key, required this.snapshot});

  final StatsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final overview = OverviewTiles(snapshot: snapshot);
    final trend = AccuracyTrendChart(snapshot: snapshot);
    final chars = CharGrid(snapshot: snapshot);
    final confusions = ConfusionHeatmap(snapshot: snapshot);
    final calendar = PracticeCalendar(snapshot: snapshot);

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= kStatsTwoColumnMinWidth;
        final children = twoColumns
            ? <Widget>[
                overview,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(children: <Widget>[trend, calendar]),
                    ),
                    Expanded(
                      child: Column(children: <Widget>[chars, confusions]),
                    ),
                  ],
                ),
              ]
            : <Widget>[overview, trend, chars, confusions, calendar];
        // Two columns stop growing on a wide monitor; a 1300 px chart is
        // no easier to read than a 600 px one.
        return ReadableBody(
          maxWidth: 1200,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
            children: children,
          ),
        );
      },
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            context.s.statsLoading,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = context.s;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              s.statsLoadFailed,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: Text(s.statsRetry)),
          ],
        ),
      ),
    );
  }
}

/// Empty state inside a scrollable so pull-to-refresh still works.
class _ScrollableEmpty extends StatelessWidget {
  const _ScrollableEmpty();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: const StatsEmptyState(),
        ),
      ),
    );
  }
}

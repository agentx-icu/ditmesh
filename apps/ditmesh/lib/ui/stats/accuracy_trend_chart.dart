import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../i18n/l10n_extension.dart';
import 'stats_math.dart';
import 'stats_model.dart';
import 'stats_palette.dart';
import 'stats_widgets.dart';

/// Pixel layout of the trend chart for a given size: where each session sits
/// and how the accuracy axis maps to y. Shared by the painter and the tap
/// handler so hit-testing cannot drift from what is drawn.
final class TrendGeometry {
  TrendGeometry({required List<TrendPoint> points, required Size size})
    : axis = accuracyAxis(points.map((p) => p.accuracy)),
      plot = Rect.fromLTRB(
        kLeftInset,
        kTopInset,
        size.width - kRightInset,
        size.height - kBottomInset,
      ) {
    final n = points.length;
    for (var i = 0; i < n; i++) {
      xs.add(n == 1 ? plot.center.dx : plot.left + plot.width * (i / (n - 1)));
      ys.add(
        axis.project(points[i].accuracy, start: plot.bottom, end: plot.top),
      );
    }
  }

  static const double kLeftInset = 44;
  static const double kRightInset = 12;
  static const double kTopInset = 12;

  /// Two label rows: the session ticks, then the axis caption on its own
  /// line (a caption anchored at the plot's right edge collided with the
  /// last tick's number).
  static const double kBottomInset = 44;

  final AxisScale axis;
  final Rect plot;
  final List<double> xs = <double>[];
  final List<double> ys = <double>[];

  double yFor(double accuracy) =>
      axis.project(accuracy, start: plot.bottom, end: plot.top);
}

/// Line chart of per-session accuracy over the trend window, one series per
/// drill direction when both send and receive sessions are present. Tap a
/// point to inspect that session.
class AccuracyTrendChart extends StatefulWidget {
  const AccuracyTrendChart({super.key, required this.snapshot});

  final StatsSnapshot snapshot;

  static const double kChartHeight = 200;

  @override
  State<AccuracyTrendChart> createState() => _AccuracyTrendChartState();
}

class _AccuracyTrendChartState extends State<AccuracyTrendChart> {
  int? _selected;

  @override
  void didUpdateWidget(covariant AccuracyTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot != widget.snapshot) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = context.s;
    final palette = StatsPalette(scheme);
    final points = widget.snapshot.trend;
    final split = widget.snapshot.trendHasBothKinds;
    final labelStyle =
        theme.textTheme.labelSmall?.copyWith(color: palette.axisText) ??
        TextStyle(fontSize: 11, color: palette.axisText);
    final selected = _selected;

    return StatsSection(
      title: s.statsTrendTitle,
      subtitle: s.statsTrendSubtitle(points.length),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (split)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 16,
                children: <Widget>[
                  _LegendItem(
                    color: palette.receive,
                    label: s.statsSeriesReceive,
                  ),
                  _LegendItem(color: palette.send, label: s.statsSeriesSend),
                ],
              ),
            ),
          SizedBox(
            height: AccuracyTrendChart.kChartHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(
                  constraints.maxWidth,
                  AccuracyTrendChart.kChartHeight,
                );
                final geometry = TrendGeometry(points: points, size: size);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) {
                    final hit = nearestIndex(
                      geometry.xs,
                      details.localPosition.dx,
                    );
                    setState(() => _selected = hit == _selected ? null : hit);
                  },
                  child: Semantics(
                    label: s.statsTrendTitle,
                    child: CustomPaint(
                      size: size,
                      painter: TrendPainter(
                        points: points,
                        geometry: geometry,
                        palette: palette,
                        split: split,
                        selected: selected,
                        labelStyle: labelStyle,
                        axisLabel: s.statsAxisSessions,
                        percentLabel: (tick) =>
                            s.statsPercent('${(tick * 100).round()}'),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          if (selected != null && selected < points.length)
            _TrendTooltip(
              point: points[selected],
              total: points.length,
              split: split,
            )
          else
            Text(
              s.statsTrendHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _TrendTooltip extends StatelessWidget {
  const _TrendTooltip({
    required this.point,
    required this.total,
    required this.split,
  });

  final TrendPoint point;
  final int total;
  final bool split;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = context.s;
    final summary = point.summary;
    final kind = point.isSend ? s.statsSeriesSend : s.statsSeriesReceive;
    final lesson = summary.lesson;
    final details = <String>[
      s.statsTooltipCopied(summary.correctChars, summary.totalChars),
      if (lesson != null) s.statsTooltipLesson(lesson),
      if (split || point.isSend) kind,
      if (summary.elapsed != null) formatPracticeDuration(s, summary.elapsed!),
    ];
    final locale = Localizations.localeOf(context).toString();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${s.statsTooltipSession(point.index, total)} - '
            '${formatPercent(s, point.accuracy)}',
            style: theme.textTheme.labelLarge,
          ),
          Text(
            details.join(' / '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          Text(
            _formatDate(summary.at, locale),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime at, String locale) =>
      DateFormat.yMd(locale).add_Hm().format(at.toLocal());
}

/// Draws grid, axes, series polylines, markers and the selection crosshair.
class TrendPainter extends CustomPainter {
  TrendPainter({
    required this.points,
    required this.geometry,
    required this.palette,
    required this.split,
    required this.selected,
    required this.labelStyle,
    required this.axisLabel,
    required this.percentLabel,
  });

  final List<TrendPoint> points;
  final TrendGeometry geometry;
  final StatsPalette palette;
  final bool split;
  final int? selected;
  final TextStyle labelStyle;

  /// Caption of the x axis (localised by the widget).
  final String axisLabel;

  /// Formats a y-axis tick (0..1) as a percentage in the current locale.
  final String Function(double tick) percentLabel;

  static const double kMarkerRadius = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = geometry.plot;
    final gridPaint = Paint()
      ..color = palette.grid
      ..strokeWidth = 1;

    for (final tick in geometry.axis.ticks) {
      final y = geometry.yFor(tick);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      _label(
        canvas,
        percentLabel(tick),
        Offset(plot.left - 6, y),
        anchor: Alignment.centerRight,
      );
    }

    final labelled = labelledIndices(points.length);
    for (final i in labelled) {
      _label(
        canvas,
        '${points[i].index}',
        Offset(geometry.xs[i], plot.bottom + 6),
        anchor: Alignment.topCenter,
      );
    }
    _label(
      canvas,
      axisLabel,
      Offset(plot.center.dx, size.height - 2),
      anchor: Alignment.bottomCenter,
    );

    if (split) {
      _series(canvas, (p) => !p.isSend, palette.receive);
      _series(canvas, (p) => p.isSend, palette.send);
    } else {
      _series(canvas, (_) => true, palette.single);
    }

    final sel = selected;
    if (sel != null && sel < points.length) {
      final x = geometry.xs[sel];
      final y = geometry.ys[sel];
      canvas.drawLine(
        Offset(x, plot.top),
        Offset(x, plot.bottom),
        Paint()
          ..color = palette.axisText
          ..strokeWidth = 1,
      );
      final color = split && points[sel].isSend
          ? palette.send
          : (split ? palette.receive : palette.single);
      canvas.drawCircle(
        Offset(x, y),
        kMarkerRadius + 3,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _series(Canvas canvas, bool Function(TrendPoint) where, Color color) {
    final path = Path();
    var started = false;
    final line = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color;
    final ring = Paint()
      ..color = palette.scheme.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < points.length; i++) {
      if (!where(points[i])) {
        continue;
      }
      final p = Offset(geometry.xs[i], geometry.ys[i]);
      if (started) {
        path.lineTo(p.dx, p.dy);
      } else {
        path.moveTo(p.dx, p.dy);
        started = true;
      }
    }
    canvas.drawPath(path, line);
    for (var i = 0; i < points.length; i++) {
      if (!where(points[i])) {
        continue;
      }
      final p = Offset(geometry.xs[i], geometry.ys[i]);
      canvas.drawCircle(p, kMarkerRadius, fill);
      canvas.drawCircle(p, kMarkerRadius, ring);
    }
  }

  void _label(
    Canvas canvas,
    String text,
    Offset at, {
    required Alignment anchor,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = at.dx - painter.width * (anchor.x + 1) / 2;
    final dy = at.dy - painter.height * (anchor.y + 1) / 2;
    painter.paint(canvas, Offset(dx, dy));
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant TrendPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.selected != selected ||
      oldDelegate.split != split ||
      oldDelegate.palette.scheme != palette.scheme ||
      oldDelegate.geometry.plot != geometry.plot ||
      oldDelegate.axisLabel != axisLabel;
}

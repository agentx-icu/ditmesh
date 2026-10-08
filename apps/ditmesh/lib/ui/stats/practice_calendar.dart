import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../i18n/l10n_extension.dart';
import 'confusion_heatmap.dart';
import 'stats_math.dart';
import 'stats_model.dart';
import 'stats_palette.dart';
import 'stats_widgets.dart';

/// GitHub-style heat squares for the last 12 weeks of practice: one column
/// per ISO week, Monday at the top. Tap a square to read its date and count.
class PracticeCalendar extends StatefulWidget {
  const PracticeCalendar({super.key, required this.snapshot});

  final StatsSnapshot snapshot;

  @override
  State<PracticeCalendar> createState() => _PracticeCalendarState();
}

class _PracticeCalendarState extends State<PracticeCalendar> {
  int? _selected;

  @override
  void didUpdateWidget(covariant PracticeCalendar oldWidget) {
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
    final locale = Localizations.localeOf(context).toString();
    final palette = StatsPalette(scheme);
    final days = widget.snapshot.calendar;
    final max = widget.snapshot.calendarMaxChars;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final labelStyle =
        theme.textTheme.labelSmall?.copyWith(color: palette.axisText) ??
        TextStyle(fontSize: 11, color: palette.axisText);
    final sel = _selected;

    return StatsSection(
      title: s.statsCalendarTitle,
      subtitle:
          '${s.statsCalendarSubtitle} / '
          '${s.statsActiveDays(widget.snapshot.activeDays)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          LayoutBuilder(
            builder: (context, constraints) {
              final geometry = CalendarGeometry.fit(
                dayCount: days.length,
                maxWidth: constraints.maxWidth,
              );
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  final hit = geometry.indexAt(details.localPosition);
                  setState(() => _selected = hit == _selected ? null : hit);
                },
                child: Semantics(
                  label: s.statsCalendarTitle,
                  child: CustomPaint(
                    size: geometry.size,
                    painter: CalendarPainter(
                      days: days,
                      max: max,
                      geometry: geometry,
                      palette: palette,
                      labelStyle: labelStyle,
                      selected: sel,
                      today: dayOf(widget.snapshot.now),
                      locale: locale,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          if (sel != null && sel < days.length)
            Text(
              s.statsCalendarDay(
                DateFormat.yMd(locale).format(days[sel].day),
                days[sel].chars,
              ),
              style: theme.textTheme.labelLarge,
            ),
          const SizedBox(height: 8),
          HeatLegend(
            palette: palette,
            lowLabel: s.statsCalendarLegendLess,
            highLabel: s.statsCalendarLegendMore,
          ),
          const SizedBox(height: 12),
          Text(s.statsStreakExplanation, style: muted),
        ],
      ),
    );
  }
}

/// Cell/gap sizes and hit-testing for the calendar grid.
final class CalendarGeometry {
  const CalendarGeometry({
    required this.weeks,
    required this.cell,
    required this.gap,
  });

  /// Shrinks the squares until [weeks] columns fit into [maxWidth].
  factory CalendarGeometry.fit({
    required int dayCount,
    required double maxWidth,
  }) {
    final weeks = (dayCount / 7).ceil();
    const gap = 3.0;
    final available = maxWidth - kLabelWidth - gap * (weeks - 1);
    final cell = weeks == 0
        ? kMaxCell
        : (available / weeks).clamp(kMinCell, kMaxCell).toDouble();
    return CalendarGeometry(weeks: weeks, cell: cell, gap: gap);
  }

  static const double kLabelWidth = 22;
  static const double kHeaderHeight = 16;
  static const double kMinCell = 8;
  static const double kMaxCell = 18;

  final int weeks;
  final double cell;
  final double gap;

  Size get size => Size(
    kLabelWidth + weeks * cell + (weeks - 1) * gap,
    kHeaderHeight + 7 * cell + 6 * gap,
  );

  Rect rectFor(int index) {
    final week = index ~/ 7;
    final weekday = index % 7;
    return Rect.fromLTWH(
      kLabelWidth + week * (cell + gap),
      kHeaderHeight + weekday * (cell + gap),
      cell,
      cell,
    );
  }

  /// Index of the square under [p], or null in a gap or label area.
  int? indexAt(Offset p) {
    final x = p.dx - kLabelWidth;
    final y = p.dy - kHeaderHeight;
    if (x < 0 || y < 0) {
      return null;
    }
    final week = (x / (cell + gap)).floor();
    final weekday = (y / (cell + gap)).floor();
    if (week >= weeks || weekday >= 7) {
      return null;
    }
    if (x - week * (cell + gap) > cell || y - weekday * (cell + gap) > cell) {
      return null;
    }
    return week * 7 + weekday;
  }
}

/// Paints weekday initials, month labels and one square per day.
class CalendarPainter extends CustomPainter {
  CalendarPainter({
    required this.days,
    required this.max,
    required this.geometry,
    required this.palette,
    required this.labelStyle,
    required this.selected,
    required this.today,
    this.locale,
  });

  final List<CalendarDay> days;
  final int max;
  final CalendarGeometry geometry;
  final StatsPalette palette;
  final TextStyle labelStyle;
  final int? selected;
  final DateTime today;

  /// Locale for the weekday / month labels; intl's default when null.
  final String? locale;

  @override
  void paint(Canvas canvas, Size size) {
    for (final weekday in const <int>[
      DateTime.monday,
      DateTime.wednesday,
      DateTime.friday,
    ]) {
      final r = geometry.rectFor(weekday - 1);
      _text(
        canvas,
        weekdayInitial(weekday, locale: locale),
        Offset(0, r.center.dy),
      );
    }

    int? lastMonth;
    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      final rect = geometry.rectFor(i);
      if (i % 7 == 0) {
        // Label a column when it contains the first day of a month.
        for (var d = i; d < i + 7 && d < days.length; d++) {
          if (days[d].day.day == 1 && days[d].day.month != lastMonth) {
            lastMonth = days[d].day.month;
            _text(
              canvas,
              monthAbbreviation(lastMonth, locale: locale),
              Offset(rect.left, CalendarGeometry.kHeaderHeight / 2),
              anchorLeft: true,
            );
            break;
          }
        }
      }
      final level = heatLevel(day.chars, max: max);
      final future = day.day.isAfter(today);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
      final paint = Paint()
        ..color = future
            ? palette.scheme.surfaceContainerHighest.withValues(alpha: 0.35)
            : palette.sequentialLevel(level);
      canvas.drawRRect(rrect, paint);
      if (day.day == today) {
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = palette.scheme.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
      if (selected == i) {
        canvas.drawRRect(
          rrect.inflate(1),
          Paint()
            ..color = palette.scheme.onSurface
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  void _text(Canvas canvas, String text, Offset at, {bool anchorLeft = true}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        anchorLeft ? at.dx : at.dx - painter.width,
        at.dy - painter.height / 2,
      ),
    );
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant CalendarPainter oldDelegate) =>
      oldDelegate.days != days ||
      oldDelegate.max != max ||
      oldDelegate.selected != selected ||
      oldDelegate.geometry.cell != geometry.cell ||
      oldDelegate.palette.scheme != palette.scheme ||
      oldDelegate.locale != locale;
}

import 'package:flutter/material.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../i18n/l10n_extension.dart';
import 'stats_math.dart';
import 'stats_model.dart';
import 'stats_palette.dart';
import 'stats_widgets.dart';

/// Target x answered heatmap of wrong answers for the learned set, built from
/// the lifetime [ConfusionMatrix]. Rows/columns without data are hidden.
/// Scrolls horizontally on narrow screens; tap a cell to read it.
class ConfusionHeatmap extends StatefulWidget {
  const ConfusionHeatmap({super.key, required this.snapshot});

  final StatsSnapshot snapshot;

  static const double kCell = 30;

  @override
  State<ConfusionHeatmap> createState() => _ConfusionHeatmapState();
}

class _ConfusionHeatmapState extends State<ConfusionHeatmap> {
  (int, int)? _selected;

  @override
  void didUpdateWidget(covariant ConfusionHeatmap oldWidget) {
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
    final targets = widget.snapshot.confusedTargets;
    final answers = widget.snapshot.confusedAnswers;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    if (targets.isEmpty || answers.isEmpty) {
      return StatsSection(
        title: s.statsHeatmapTitle,
        child: Text(s.statsHeatmapEmpty, style: muted),
      );
    }

    final max = widget.snapshot.confusionMax;
    const cell = ConfusionHeatmap.kCell;
    final size = Size(cell * (answers.length + 1), cell * (targets.length + 1));
    final labelStyle =
        theme.textTheme.labelSmall?.copyWith(color: palette.axisText) ??
        TextStyle(fontSize: 11, color: palette.axisText);
    final sel = _selected;

    return StatsSection(
      title: s.statsHeatmapTitle,
      subtitle: s.statsHeatmapSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${s.statsHeatmapAxisTarget} ↓ / ${s.statsHeatmapAxisAnswered} →',
            style: muted,
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final col = (details.localPosition.dx / cell).floor() - 1;
                final row = (details.localPosition.dy / cell).floor() - 1;
                final inside =
                    row >= 0 &&
                    row < targets.length &&
                    col >= 0 &&
                    col < answers.length;
                setState(() {
                  final next = inside ? (row, col) : null;
                  _selected = next == _selected ? null : next;
                });
              },
              child: Semantics(
                label: s.statsHeatmapTitle,
                child: CustomPaint(
                  size: size,
                  painter: HeatmapPainter(
                    targets: targets,
                    answers: answers,
                    countFor: widget.snapshot.confusionCount,
                    max: max,
                    palette: palette,
                    labelStyle: labelStyle,
                    selected: sel,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (sel != null)
            Text(
              s.statsHeatmapCell(
                targets[sel.$1],
                _answerLabel(s, answers[sel.$2]),
                widget.snapshot.confusionCount(
                  targets[sel.$1],
                  answers[sel.$2],
                ),
              ),
              style: theme.textTheme.labelLarge,
            ),
          const SizedBox(height: 8),
          HeatLegend(palette: palette),
        ],
      ),
    );
  }

  static String _answerLabel(S s, String answered) =>
      answered == ConfusionMatrix.missed ? s.statsConfusionMissed : answered;
}

/// Sequential colour key: "Rare" -> "Frequent" unless the caller passes its
/// own end labels (the calendar uses "Less" / "More").
class HeatLegend extends StatelessWidget {
  const HeatLegend({
    super.key,
    required this.palette,
    this.lowLabel,
    this.highLabel,
    this.levels = 5,
  });

  final StatsPalette palette;
  final String? lowLabel;
  final String? highLabel;
  final int levels;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: palette.axisText);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(lowLabel ?? context.s.statsHeatmapLegendLow, style: style),
        const SizedBox(width: 6),
        for (var level = 0; level < levels; level++)
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: palette.sequentialLevel(level, levels: levels),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        const SizedBox(width: 3),
        Text(highLabel ?? context.s.statsHeatmapLegendHigh, style: style),
      ],
    );
  }
}

/// Paints row/column headers and one square per (target, answered) pair.
class HeatmapPainter extends CustomPainter {
  HeatmapPainter({
    required this.targets,
    required this.answers,
    required this.countFor,
    required this.max,
    required this.palette,
    required this.labelStyle,
    required this.selected,
  });

  final List<String> targets;
  final List<String> answers;
  final int Function(String target, String answered) countFor;
  final int max;
  final StatsPalette palette;
  final TextStyle labelStyle;
  final (int, int)? selected;

  static const double kGap = 2;

  @override
  void paint(Canvas canvas, Size size) {
    const cell = ConfusionHeatmap.kCell;
    for (var c = 0; c < answers.length; c++) {
      _text(
        canvas,
        _header(answers[c]),
        Rect.fromLTWH(cell * (c + 1), 0, cell, cell),
        labelStyle,
      );
    }
    for (var r = 0; r < targets.length; r++) {
      _text(
        canvas,
        targets[r],
        Rect.fromLTWH(0, cell * (r + 1), cell, cell),
        labelStyle,
      );
      for (var c = 0; c < answers.length; c++) {
        final count = countFor(targets[r], answers[c]);
        final t = heatIntensity(count, max: max);
        final rect = Rect.fromLTWH(
          cell * (c + 1) + kGap / 2,
          cell * (r + 1) + kGap / 2,
          cell - kGap,
          cell - kGap,
        );
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
        canvas.drawRRect(rrect, Paint()..color = palette.sequential(t));
        if (count > 0) {
          _text(
            canvas,
            '$count',
            rect,
            labelStyle.copyWith(color: palette.onSequential(t)),
          );
        }
        if (selected == (r, c)) {
          canvas.drawRRect(
            rrect,
            Paint()
              ..color = palette.scheme.onSurface
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      }
    }
  }

  static String _header(String answered) =>
      answered == ConfusionMatrix.missed ? '∅' : answered;

  void _text(Canvas canvas, String text, Rect box, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: box.width);
    painter.paint(
      canvas,
      Offset(
        box.left + (box.width - painter.width) / 2,
        box.top + (box.height - painter.height) / 2,
      ),
    );
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant HeatmapPainter oldDelegate) =>
      oldDelegate.targets != targets ||
      oldDelegate.answers != answers ||
      oldDelegate.max != max ||
      oldDelegate.selected != selected ||
      oldDelegate.palette.scheme != palette.scheme;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';
import 'send_tips.dart';

/// Localised headline for a rhythm issue (reuses the send-tip titles).
String rhythmIssueLabel(S s, RhythmIssue issue) => switch (issue) {
  RhythmIssue.ditTooLong => titleFor(s, SendIssueKind.ditTooLong),
  RhythmIssue.dahTooShort => titleFor(s, SendIssueKind.dahTooShort),
  RhythmIssue.dahTooLong => titleFor(s, SendIssueKind.dahTooLong),
  RhythmIssue.intraGapTooLong => titleFor(s, SendIssueKind.intraGapTooLong),
  RhythmIssue.charGapTooShort => titleFor(s, SendIssueKind.charGapTooShort),
  RhythmIssue.wordGapTooShort => titleFor(s, SendIssueKind.wordGapTooShort),
};

/// "My rhythm" over "Standard rhythm" (functional spec §7.1): bar position
/// and length are the marks, whitespace the gaps; problem elements carry a
/// colour *and* a text label on the symbol cards. Zoom and scroll instead of
/// squeezing a long attempt into the screen width. Symbol cards replay the
/// measured timing, the standard, or start targeted practice.
class SendTimelineView extends StatefulWidget {
  const SendTimelineView({
    super.key,
    required this.timeline,
    required this.onPlayMine,
    required this.onPlayStandard,
    required this.onPractice,
  });

  final SendTimeline timeline;

  /// Plays measured / standard timing of a symbol (null = whole attempt).
  final void Function(int? symbol) onPlayMine;
  final void Function(int? symbol) onPlayStandard;

  /// Targeted practice of a symbol (null = the whole target).
  final void Function(String text) onPractice;

  @override
  State<SendTimelineView> createState() => _SendTimelineViewState();
}

class _SendTimelineViewState extends State<SendTimelineView> {
  double _zoom = 1;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final t = widget.timeline;
    final total = math.max(
      t.mineDuration.inMicroseconds,
      t.standardDuration.inMicroseconds,
    );
    final pxPerMs = 0.25 * _zoom;
    final width = math.max(240.0, total / 1000 * pxPerMs + 16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                s.learnRhythmTitle,
                style: theme.textTheme.titleSmall,
              ),
            ),
            IconButton(
              tooltip: s.learnRhythmZoomOut,
              onPressed: _zoom > 0.5
                  ? () => setState(() => _zoom /= 1.5)
                  : null,
              icon: const Icon(Icons.zoom_out),
            ),
            IconButton(
              tooltip: s.learnRhythmZoomIn,
              onPressed: _zoom < 6 ? () => setState(() => _zoom *= 1.5) : null,
              icon: const Icon(Icons.zoom_in),
            ),
          ],
        ),
        Text(
          s.learnRhythmNormalizedNote(t.estimatedDit.inMilliseconds),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(s.learnRhythmMine, style: theme.textTheme.labelMedium),
                _Lane(elements: t.mine, pxPerMs: pxPerMs, mine: true),
                const SizedBox(height: 6),
                Text(s.learnRhythmStandard, style: theme.textTheme.labelMedium),
                _Lane(elements: t.standard, pxPerMs: pxPerMs, mine: false),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: <Widget>[
            TextButton.icon(
              onPressed: () => widget.onPlayMine(null),
              icon: const Icon(Icons.play_arrow),
              label: Text(s.learnRhythmPlayMine),
            ),
            TextButton.icon(
              onPressed: () => widget.onPlayStandard(null),
              icon: const Icon(Icons.play_arrow_outlined),
              label: Text(s.learnRhythmPlayStandard),
            ),
          ],
        ),
        if (!t.aligned) ...<Widget>[
          Text(s.learnRhythmNotLocated, style: theme.textTheme.bodySmall),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton(
              onPressed: () => widget.onPractice(t.target),
              child: Text(s.learnRhythmPracticeWhole),
            ),
          ),
        ] else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final sym in t.perSymbol) _SymbolCard(sym, widget: widget),
            ],
          ),
      ],
    );
  }
}

class _Lane extends StatelessWidget {
  const _Lane({
    required this.elements,
    required this.pxPerMs,
    required this.mine,
  });

  final List<RhythmElement> elements;
  final double pxPerMs;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: CustomPaint(
        size: const Size(double.infinity, 28),
        painter: _LanePainter(
          elements: elements,
          pxPerMs: pxPerMs,
          color: mine ? scheme.primary : scheme.outline,
          problem: scheme.error,
          gapProblem: scheme.errorContainer,
        ),
      ),
    );
  }
}

class _LanePainter extends CustomPainter {
  _LanePainter({
    required this.elements,
    required this.pxPerMs,
    required this.color,
    required this.problem,
    required this.gapProblem,
  });

  final List<RhythmElement> elements;
  final double pxPerMs;
  final Color color;
  final Color problem;
  final Color gapProblem;

  @override
  void paint(Canvas canvas, Size size) {
    for (final e in elements) {
      final x = e.start.inMicroseconds / 1000 * pxPerMs + 8;
      final w = math.max(1.0, e.duration.inMicroseconds / 1000 * pxPerMs);
      if (e.isMark) {
        final paint = Paint()..color = e.issue == null ? color : problem;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 6, w, size.height - 12),
            const Radius.circular(2),
          ),
          paint,
        );
      } else if (e.issue != null) {
        // A problem gap is shaded and underlined.
        canvas.drawRect(
          Rect.fromLTWH(x, size.height - 4, w, 3),
          Paint()..color = problem,
        );
        canvas.drawRect(
          Rect.fromLTWH(x, 6, w, size.height - 12),
          Paint()..color = gapProblem.withValues(alpha: 0.5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LanePainter old) =>
      old.elements != elements || old.pxPerMs != pxPerMs;
}

class _SymbolCard extends StatelessWidget {
  const _SymbolCard(this.symbol, {required this.widget});

  final SymbolRhythm symbol;
  final SendTimelineView widget;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final bad = symbol.issues.isNotEmpty;
    final label = bad
        ? symbol.issues.map((i) => rhythmIssueLabel(s, i)).join(', ')
        : s.learnRhythmSymbolOk;
    return Card(
      color: bad ? theme.colorScheme.errorContainer : null,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    bad ? Icons.warning_amber : Icons.check_circle_outline,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(symbol.symbol, style: theme.textTheme.titleMedium),
                ],
              ),
              Text(label, style: theme.textTheme.bodySmall),
              Wrap(
                children: <Widget>[
                  IconButton(
                    tooltip: s.learnRhythmPlayMine,
                    onPressed: () => widget.onPlayMine(symbol.index),
                    icon: const Icon(Icons.play_arrow),
                  ),
                  IconButton(
                    tooltip: s.learnRhythmPlayStandard,
                    onPressed: () => widget.onPlayStandard(symbol.index),
                    icon: const Icon(Icons.play_arrow_outlined),
                  ),
                  if (bad)
                    IconButton(
                      key: ValueKey('rhythm-practice-${symbol.index}'),
                      tooltip: s.learnRhythmPracticePart(3),
                      onPressed: () => widget.onPractice(symbol.symbol),
                      icon: const Icon(Icons.fitness_center),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A circular progress ring with a centred child.
class GoalRing extends StatelessWidget {
  const GoalRing({
    super.key,
    required this.fraction,
    this.size = 80,
    this.strokeWidth = 8,
    this.child,
  });

  final double fraction;
  final double size;
  final double strokeWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          fraction: fraction.clamp(0.0, 1.0),
          strokeWidth: strokeWidth,
          track: scheme.surfaceContainerHighest,
          fill: fraction >= 1 ? scheme.tertiary : scheme.primary,
        ),
        // Inside the stroke, shrunk rather than wrapped out of the ring at
        // large text ("100%" at 3x is wider than the ring).
        child: Padding(
          padding: EdgeInsets.all(strokeWidth + 4),
          child: Center(
            child: child == null
                ? null
                : FittedBox(fit: BoxFit.scaleDown, child: child),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fraction,
    required this.strokeWidth,
    required this.track,
    required this.fill,
  });

  final double fraction;
  final double strokeWidth;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(strokeWidth / 2);
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final fillPaint = Paint()
      ..color = fill
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(inset, 0, 2 * math.pi, false, trackPaint);
    if (fraction > 0) {
      canvas.drawArc(
        inset,
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction ||
      old.strokeWidth != strokeWidth ||
      old.track != track ||
      old.fill != fill;
}

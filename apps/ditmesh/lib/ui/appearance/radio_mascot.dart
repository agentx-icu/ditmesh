import 'package:flutter/material.dart';

/// A small decorative radio; never competes with Morse or keying feedback.
class RadioMascot extends StatelessWidget {
  const RadioMascot({super.key, this.size = 64});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _RadioPainter(Theme.of(context).colorScheme)),
    ),
  );
}

class _RadioPainter extends CustomPainter {
  const _RadioPainter(this.scheme);
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);
    final ink = Paint()
      ..color = scheme.onSurface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(43, 20), const Offset(49, 5), ink);
    canvas.drawCircle(const Offset(50, 4), 2.5, ink);
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(7, 20, 50, 36),
      const Radius.circular(10),
    );
    canvas.drawRRect(body, Paint()..color = scheme.primaryContainer);
    canvas.drawRRect(body, ink);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(12, 26, 38, 23),
        const Radius.circular(6),
      ),
      Paint()..color = scheme.surfaceContainerLow,
    );
    final eye = Paint()..color = scheme.onSurface;
    canvas.drawCircle(const Offset(23, 35), 2.5, eye);
    canvas.drawCircle(const Offset(39, 35), 2.5, eye);
    canvas.drawArc(const Rect.fromLTWH(26, 35, 10, 9), 0.2, 2.7, false, ink);
    canvas.drawLine(const Offset(15, 57), const Offset(15, 60), ink);
    canvas.drawLine(const Offset(48, 57), const Offset(48, 60), ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RadioPainter oldDelegate) => oldDelegate.scheme != scheme;
}

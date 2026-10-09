// Layout review (2026-10-09): the printed label of the straight key and the
// paddles stays inside the key at any text size. A long translation
// ("MANIPULATEUR") or 3x text used to wrap out of the circle and the paddle
// because the label was an unconstrained Text in a fixed-size box.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';

final class _Key implements StraightKeyInput {
  @override
  void press(Duration at) {}

  @override
  void release(Duration at) {}
}

final class _Paddles implements PaddleInput {
  @override
  void ditPaddle(bool down, Duration at) {}

  @override
  void dahPaddle(bool down, Duration at) {}
}

Future<void> _pump(WidgetTester tester, Widget child, double scale) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
}

/// [label] is drawn whole (its paragraph is not cut to a narrower box than
/// the text needs) and inside [key].
void _expectInside(WidgetTester tester, String label, Rect key) {
  final Rect text = tester.getRect(find.text(label));
  expect(key.contains(text.topLeft), isTrue, reason: '$label $text in $key');
  expect(
    key.contains(text.bottomRight - const Offset(0.01, 0.01)),
    isTrue,
    reason: '$label $text in $key',
  );
  final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
    find.text(label),
  );
  expect(
    paragraph.size.width,
    greaterThanOrEqualTo(paragraph.getMaxIntrinsicWidth(double.infinity) - 0.5),
    reason: '$label is cut sideways',
  );
  expect(
    paragraph.size.height,
    greaterThanOrEqualTo(
      paragraph.getMaxIntrinsicHeight(paragraph.size.width) - 0.5,
    ),
    reason: '$label is cut at the bottom',
  );
}

void main() {
  for (final double scale in <double>[1, 2, 3]) {
    testWidgets('a long straight-key label stays in the circle at ${scale}x', (
      tester,
    ) async {
      await _pump(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: StraightKeyButton(
            input: _Key(),
            keyboard: false,
            size: 120,
            label: 'MANIPULATEUR',
          ),
        ),
        scale,
      );
      final Rect key = tester.getRect(find.byType(StraightKeyButton));
      _expectInside(tester, 'MANIPULATEUR', key);
      expect(tester.takeException(), isNull);
    });

    testWidgets('long paddle labels stay in the paddles at ${scale}x', (
      tester,
    ) async {
      await _pump(
        tester,
        PaddleButtons(
          input: _Paddles(),
          keyboard: false,
          height: 96,
          ditLabel: 'POINT',
          dahLabel: 'STRICHPADDLE',
        ),
        scale,
      );
      final Rect paddles = tester.getRect(find.byType(PaddleButtons));
      _expectInside(tester, 'POINT', paddles);
      _expectInside(tester, 'STRICHPADDLE', paddles);
      // Each label stays within its own half.
      final Rect dah = tester.getRect(find.text('STRICHPADDLE'));
      expect(dah.left, greaterThanOrEqualTo(paddles.center.dx));
      expect(tester.takeException(), isNull);
    });
  }
}

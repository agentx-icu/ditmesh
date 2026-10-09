// The shared layout primitives in lib/ui/responsive.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/fill_or_scroll_view.dart';
import 'package:ditmesh/ui/responsive.dart';

Widget _view() => FillOrScrollView(
  children: <Widget>[
    const SizedBox(key: ValueKey('fixed'), height: 300),
    FlexFloor(
      height: 160,
      child: ListView(
        key: const ValueKey('inner'),
        children: <Widget>[for (var i = 0; i < 50; i++) Text('line $i')],
      ),
    ),
    // Wrapping text: its height is only known once laid out at the width.
    Text('word ' * 40, key: const ValueKey('wrap')),
  ],
);

Future<void> _pump(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('FillOrScrollView', () {
    testWidgets('fills a tall viewport without scrolling', (tester) async {
      await _pump(tester, const Size(400, 800), _view());
      final double wrap = tester
          .getSize(find.byKey(const ValueKey('wrap')))
          .height;
      expect(wrap, greaterThan(20), reason: 'the text wraps');
      expect(
        tester.getSize(find.byKey(const ValueKey('inner'))).height,
        800 - 300 - wrap,
      );
      final ScrollableState outer = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(outer.position.maxScrollExtent, 0);
    });

    testWidgets('keeps the floor and scrolls in a short viewport', (
      tester,
    ) async {
      await _pump(tester, const Size(400, 360), _view());
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byKey(const ValueKey('inner'))).height, 160);
      final double wrap = tester
          .getSize(find.byKey(const ValueKey('wrap')))
          .height;
      final ScrollableState outer = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(outer.position.maxScrollExtent, 300 + 160 + wrap - 360);
    });

    testWidgets('keeps one element tree across the threshold', (tester) async {
      await _pump(tester, const Size(400, 800), _view());
      final Element before = tester.element(
        find.byKey(const ValueKey('inner')),
      );
      tester.view.physicalSize = const Size(400, 360);
      await tester.pump();
      expect(tester.element(find.byKey(const ValueKey('inner'))), same(before));
    });
  });

  group('ReadableBody', () {
    testWidgets('centres a full-height column on a wide window', (
      tester,
    ) async {
      await _pump(
        tester,
        const Size(2000, 800),
        const ReadableBody(child: ColoredBox(color: Colors.red)),
      );
      final Rect box = tester.getRect(find.byType(ColoredBox).last);
      expect(box.width, kReadableMaxWidth);
      expect(box.center.dx, 1000);
      expect(box.height, 800);
    });

    testWidgets('fills a narrow window and keeps clear of the notch', (
      tester,
    ) async {
      tester.view.padding = const FakeViewPadding(left: 47, right: 47);
      await _pump(
        tester,
        const Size(844, 390),
        const ReadableBody(
          maxWidth: 2000,
          child: ColoredBox(color: Colors.red),
        ),
      );
      final Rect box = tester.getRect(find.byType(ColoredBox).last);
      expect(box.left, 47);
      expect(box.right, 797);
    });

    testWidgets('starts beside a side list when asked', (tester) async {
      await _pump(
        tester,
        const Size(2000, 800),
        const ReadableBody(
          maxWidth: 960,
          alignment: AlignmentDirectional.topStart,
          child: ColoredBox(color: Colors.red),
        ),
      );
      expect(tester.getRect(find.byType(ColoredBox).last).left, 0);
    });
  });
}

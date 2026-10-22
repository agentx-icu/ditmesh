import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';

void main() {
  testWidgets('light output stays in a small indicator and preserves content', (
    tester,
  ) async {
    final on = ValueNotifier(true);
    addTearDown(on.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: FlashOverlay(
            isOn: on,
            child: const SizedBox(width: 400, height: 600),
          ),
        ),
      ),
    );
    final boxes = tester.widgetList<ColoredBox>(find.byType(ColoredBox));
    expect(boxes.length, 1);
    final size = tester.getSize(find.byType(ColoredBox));
    expect(size.width, lessThanOrEqualTo(24));
    expect(size.height, lessThanOrEqualTo(24));
  });
  testWidgets('reduced motion does not track rapid key transitions', (
    tester,
  ) async {
    final on = ValueNotifier(true);
    addTearDown(on.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: FlashOverlay(
            isOn: on,
            child: const SizedBox(width: 400, height: 600),
          ),
        ),
      ),
    );
    final color = tester.widget<ColoredBox>(find.byType(ColoredBox)).color;
    on.value = false;
    await tester.pump();
    expect(tester.widget<ColoredBox>(find.byType(ColoredBox)).color, color);
    expect(find.byType(ValueListenableBuilder<bool>), findsNothing);
  });
}

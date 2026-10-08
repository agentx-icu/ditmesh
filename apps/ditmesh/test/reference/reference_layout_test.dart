import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/reference/morse_to_text_view.dart';
import 'package:ditmesh/ui/reference/reference_layout.dart';
import 'package:ditmesh/ui/reference/text_to_morse_view.dart';
import 'package:ditmesh/ui/reference/translator_screen.dart';

import 'reference_test_support.dart';

/// A portrait phone's soft keyboard: leaves the translator pane well under
/// either view's minimum height.
const FakeViewPadding _keyboard = FakeViewPadding(bottom: 450);

EditableText _editable(WidgetTester tester, Key inputKey) =>
    tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(inputKey),
        matching: find.byType(EditableText),
      ),
    );

void main() {
  for (final (TranslatorMode mode, Key inputKey) in <(TranslatorMode, Key)>[
    (TranslatorMode.textToMorse, TextToMorseView.inputKey),
    (TranslatorMode.morseToText, MorseToTextView.inputKey),
  ]) {
    testWidgets('${mode.name}: opening the soft keyboard keeps the input '
        'focused', (tester) async {
      setSurfaceSize(tester, kPhone);
      addTearDown(tester.view.resetViewInsets);
      final fake = FakeReferencePlayer();
      await pumpScreen(
        tester,
        TranslatorScreen(
          playerFactory: fake.create,
          clock: fake.clock,
          initialMode: mode,
        ),
      );
      await tester.showKeyboard(find.byKey(inputKey));
      await tester.pump();
      final FocusNode node = _editable(tester, inputKey).focusNode;
      expect(node.hasFocus, isTrue);

      // The keyboard slides up: the pane drops below its minimum height
      // and starts scrolling. The field must survive that, not remount.
      tester.view.viewInsets = _keyboard;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_editable(tester, inputKey).focusNode, same(node));
      expect(node.hasFocus, isTrue);
      expect(
        find.descendant(
          of: find.byType(ReferenceMinHeight),
          matching: find.byType(Scrollable),
        ),
        findsWidgets,
      );

      // And back down again.
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_editable(tester, inputKey).focusNode, same(node));
      expect(node.hasFocus, isTrue);
    });
  }

  testWidgets('ReferenceMinHeight keeps one element tree across the '
      'threshold', (tester) async {
    // A plain key: a GlobalKey would reparent and hide a remount.
    const Key childKey = ValueKey<String>('child');
    Widget host(double height) => Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 300,
          height: height,
          child: ReferenceMinHeight(
            minHeight: 200,
            child: const SizedBox.expand(key: childKey),
          ),
        ),
      ),
    );
    await tester.pumpWidget(host(400));
    final Element before = tester.element(find.byKey(childKey));
    expect(tester.getSize(find.byKey(childKey)).height, 400);

    await tester.pumpWidget(host(100));
    expect(tester.element(find.byKey(childKey)), same(before));
    expect(tester.getSize(find.byKey(childKey)).height, 200);

    await tester.pumpWidget(host(400));
    expect(tester.element(find.byKey(childKey)), same(before));
    expect(tester.getSize(find.byKey(childKey)).height, 400);
  });
}

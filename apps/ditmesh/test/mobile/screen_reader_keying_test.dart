// T10 (mobile review): VoiceOver / TalkBack intercept raw pointer events, so
// the on-screen key cannot be timed by a screen-reader user. The composer's
// straight key offers the same custom "dit" / "dah" actions as the Learn
// keyer, and the paddles expose one element per activation; keying by
// hardware keyboard works regardless.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../chat/test_support.dart';

Future<ChatHarness> _pump(WidgetTester tester) => pumpChat(tester, (h) {
  h.addAnn();
  return ConversationScreen(
    target: ConversationTarget(
      id: 'c2c_$kPeerKey',
      title: 'Ann',
      kind: ConversationKind.c2c,
    ),
  );
});

void main() {
  testWidgets('the composer straight key exposes dit and dah actions', (
    tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final ChatHarness h = await _pump(tester);
    final CustomSemanticsAction dit = CustomSemanticsAction(
      label: s.learnDitLabel,
    );
    final CustomSemanticsAction dah = CustomSemanticsAction(
      label: s.learnDahLabel,
    );
    final SemanticsNode node = tester.getSemantics(
      find.byType(StraightKeyButton),
    );
    expect(
      node,
      matchesSemantics(
        // Announced once: the printed label is excluded from semantics.
        label: s.learnStraightKeyLabel,
        isButton: true,
        isFocusable: true,
        isFocused: true,
        hasFocusAction: true,
        customActions: <CustomSemanticsAction>[dit, dah],
      ),
    );

    // Activating "dit" keys one dit through the same input: an E lands in
    // the draft once the character gap has elapsed.
    final Duration ditLength = h.settings.timing.dit;
    tester.semantics.performAction(
      find.semantics.byLabel(s.learnStraightKeyLabel),
      SemanticsAction.customAction,
      args: CustomSemanticsAction.getIdentifier(dit),
    );
    await tester.pump();
    h.clock.advance(ditLength);
    await tester.pump(ditLength);
    h.clock.advance(ditLength * 4);
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      startsWith('E'),
    );
    handle.dispose();
  });

  testWidgets('each paddle is a button that keys one element', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await _pump(tester);
    await tester.tap(find.byTooltip(s.chatModePaddles));
    await tester.pumpAndSettle();
    final Finder paddles = find.descendant(
      of: find.byType(PaddleButtons),
      matching: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.button == true,
      ),
    );
    expect(paddles, findsNWidgets(2));
    expect(
      tester.getSemantics(paddles.first),
      matchesSemantics(
        label: s.learnDitLabel,
        isButton: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(paddles.last),
      matchesSemantics(
        label: s.learnDahLabel,
        isButton: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });
}

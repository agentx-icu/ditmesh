// Mobile review, wave 2 (Codex finding on T1): two composers of the same
// conversation share one draft controller. When one of them leaves the tree
// with a character still in its keyer, the committed character must reach
// the shared controller, not only the departing editor's private draft copy,
// or the surviving editor's next save would overwrite it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:ditmesh/ui/chat/message_input.dart';

import 'test_support.dart';

void main() {
  testWidgets(
    'a character committed on teardown reaches the other editor of the '
    'same conversation',
    (tester) async {
      final GlobalKey survivor = GlobalKey();
      final String id = 'c2c_$kPeerKey';
      late ChatHarness h;
      Widget editors({required bool departing}) => SingleChildScrollView(
        child: Column(
          children: [
            if (departing)
              MessageInput(
                service: h.service,
                conversationId: id,
                playback: h.playback,
              ),
            MessageInput(
              key: survivor,
              service: h.service,
              conversationId: id,
              playback: h.playback,
            ),
          ],
        ),
      );
      h = await pumpChat(tester, (harness) {
        h = harness;
        harness.addAnn();
        return editors(departing: true);
      }, size: const Size(600, 1400));

      // One dit on the departing composer's key, released before the
      // character gap elapsed: the decoder still holds the pattern.
      final TestGesture gesture = await tester.press(
        find.byType(StraightKeyButton).first,
      );
      await tester.pump();
      h.clock.advance(const Duration(milliseconds: 60));
      await gesture.up();
      await tester.pump();

      // The departing composer goes; its keyer commits the character.
      await tester.pumpWidget(h.wrap(editors(departing: false)));
      await tester.pump();
      final TextField field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(survivor),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller?.text, 'E');

      // Both editors' saves settle on the committed text.
      await tester.pump(const Duration(seconds: 1));
      expect(h.service.conversations.firstWhere((c) => c.id == id).draft, 'E');
      expect(field.controller?.text, 'E');
    },
  );

  testWidgets(
    'when both editors leave in one frame the committed character still '
    'wins over the other editor\'s stale dispose flush',
    (tester) async {
      final String id = 'c2c_$kPeerKey';
      late ChatHarness h;
      Widget editors() => SingleChildScrollView(
        child: Column(
          children: [
            for (var i = 0; i < 2; i++)
              MessageInput(
                service: h.service,
                conversationId: id,
                playback: h.playback,
              ),
          ],
        ),
      );
      h = await pumpChat(tester, (harness) {
        h = harness;
        harness.addAnn();
        return editors();
      }, size: const Size(600, 1400));

      final TestGesture gesture = await tester.press(
        find.byType(StraightKeyButton).first,
      );
      await tester.pump();
      h.clock.advance(const Duration(milliseconds: 60));
      await gesture.up();
      await tester.pump();

      // Both go: the first commits 'E', the second's dispose flush must not
      // write its stale '' over it.
      await tester.pumpWidget(h.wrap(const SizedBox()));
      await tester.pump(const Duration(seconds: 1));
      expect(h.service.conversations.firstWhere((c) => c.id == id).draft, 'E');
    },
  );
}

// T2 (mobile review): Android gesture navigation reserves a back-gesture
// zone on both screen edges (`systemGestureInsets.left/right`, ~30 dp). A
// paddle press that starts there and drifts inward becomes a system back
// instead of a dah: the pads must stay clear of those zones while keeping
// their touch target.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../chat/test_support.dart' as chat;
import 'phone_support.dart';

/// The two paddle surfaces (raw listeners inside [PaddleButtons]).
Finder get _paddles => find.descendant(
  of: find.byType(PaddleButtons),
  matching: find.byType(Listener),
);

void expectPaddlesClearOfGestureZones(WidgetTester tester, Size size) {
  expect(tester.takeException(), isNull);
  expect(_paddles, findsNWidgets(2));
  final Rect left = tester.getRect(_paddles.first);
  final Rect right = tester.getRect(_paddles.last);
  expect(left.left, greaterThanOrEqualTo(kGestureNavInsets.left));
  expect(right.right, lessThanOrEqualTo(size.width - kGestureNavInsets.right));
  for (final Rect pad in <Rect>[left, right]) {
    expect(pad.height, greaterThanOrEqualTo(PaddleButtons.minTouchTarget));
    expect(pad.width, greaterThanOrEqualTo(PaddleButtons.minTouchTarget));
  }
}

void main() {
  for (final Size size in <Size>[
    const Size(390, 844),
    kSmallPhone,
    kLandscapeSmallPhone,
  ]) {
    testWidgets('composer paddles avoid the back-gesture zones at $size', (
      tester,
    ) async {
      final h = chat.ChatHarness();
      addTearDown(h.dispose);
      setPhone(tester, size, gestureInsets: kGestureNavInsets);
      h.addAnn();
      await tester.pumpWidget(
        h.wrap(
          ConversationScreen(
            target: ConversationTarget(
              id: 'c2c_${chat.kPeerKey}',
              title: 'Ann',
              kind: ConversationKind.c2c,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(chat.s.chatModePaddles));
      await tester.pumpAndSettle();
      expectPaddlesClearOfGestureZones(tester, size);
    });
  }

  testWidgets('the straight key is unaffected (centred, never at an edge)', (
    tester,
  ) async {
    final h = chat.ChatHarness();
    addTearDown(h.dispose);
    setPhone(tester, kSmallPhone, gestureInsets: kGestureNavInsets);
    h.addAnn();
    await tester.pumpWidget(
      h.wrap(
        ConversationScreen(
          target: ConversationTarget(
            id: 'c2c_${chat.kPeerKey}',
            title: 'Ann',
            kind: ConversationKind.c2c,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final Rect key = tester.getRect(find.byType(StraightKeyButton));
    expect(key.left, greaterThanOrEqualTo(kGestureNavInsets.left));
    expect(
      key.right,
      lessThanOrEqualTo(kSmallPhone.width - kGestureNavInsets.right),
    );
  });
}

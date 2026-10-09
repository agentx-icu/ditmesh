import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/chat/conversation_timeline.dart';
import 'package:ditmesh/ui/chat/input_mode.dart';
import 'package:ditmesh/ui/chat/morse_playback_controller.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'test_support.dart';

ConversationTarget _ann() => ConversationTarget(
  id: 'c2c_$kPeerKey',
  title: 'Ann',
  kind: ConversationKind.c2c,
);

/// Keys one dit on the straight key by touch, with the harness clock.
Future<void> _keyDit(WidgetTester tester, ChatHarness h) async {
  final gesture = await tester.press(find.byType(StraightKeyButton));
  await tester.pump();
  h.clock.advance(const Duration(milliseconds: 60));
  await gesture.up();
  await tester.pump();
}

void main() {
  testWidgets('sending cancels a preview queued behind hand keying', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return ConversationScreen(target: _ann());
    });
    await _keyDit(tester, h);
    await tester.tap(find.byKey(const ValueKey('draft-preview')));
    await tester.pump();
    expect(h.playback.queuedIds, contains('draft:c2c_$kPeerKey'));
    await tester.tap(find.byTooltip(s.chatSend));
    await tester.pumpAndSettle();
    expect(h.playback.queuedIds, isEmpty);
    expect(h.playback.playingId, isNull);
  });

  testWidgets('emptying the draft keeps queued preview Stop enabled', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return ConversationScreen(target: _ann());
    });
    await _keyDit(tester, h);
    await tester.tap(find.byKey(const ValueKey('draft-preview')));
    await tester.pump();
    await tester.tap(find.byTooltip(s.chatDeleteLast));
    await tester.pump();
    final stop = tester.widget<IconButton>(
      find.byKey(const ValueKey('draft-preview')),
    );
    expect(stop.onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('draft-preview')));
    await tester.pump();
    expect(h.playback.queuedIds, isEmpty);
  });

  testWidgets('draft preview commits keying without sending and can stop', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return ConversationScreen(target: _ann());
    });
    await _keyDit(tester, h);
    await tester.tap(find.byKey(const ValueKey('draft-preview')));
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'E');
    h.clock.advance(MorsePlaybackController.keyingHoldoff);
    await tester.pump(const Duration(milliseconds: 20));
    expect(h.playback.playingId, 'draft:c2c_$kPeerKey');
    expect(await h.service.loadHistory('c2c_$kPeerKey'), isEmpty);
    await tester.tap(find.byKey(const ValueKey('draft-preview')));
    await tester.pump();
    expect(h.playback.playingId, isNull);
    expect(field.controller!.text, 'E');
  });

  for (final group in [false, true]) {
    testWidgets(
      '${group ? 'group' : 'direct'} chat only accepts decoded Morse',
      (tester) async {
        final h = await pumpChat(tester, (h) {
          if (group) {
            final net = h.service.addFakeGroup(
              const Group(id: 'tox_1', name: 'Net', kind: GroupKind.group),
            );
            return ConversationScreen(
              target: ConversationTarget.fromGroup(net),
            );
          }
          h.addAnn(withMessage: false);
          return ConversationScreen(target: _ann());
        });
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.readOnly, isTrue);
        expect(field.canRequestFocus, isFalse);
        expect(find.byTooltip(s.chatModeStraightKey), findsOneWidget);
        expect(find.byTooltip(s.chatModePaddles), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
        await tester.pump();
        expect(
          field.controller!.text,
          isEmpty,
          reason: 'ordinary typing is ignored',
        );
        await _keyDit(tester, h);
        await tester.tap(find.byTooltip(s.chatSend));
        await tester.pumpAndSettle();
        final history = await h.service.loadHistory(
          group ? 'group_tox_1' : 'c2c_$kPeerKey',
        );
        expect(history.map((message) => message.text), ['E']);
      },
    );
  }

  for (final Size size in const [Size(780, 360), Size(667, 375)]) {
    for (final InputMode mode in InputMode.values) {
      testWidgets('landscape ${size.width.toInt()}x${size.height.toInt()} '
          '(${mode.name}): the conversation keeps room', (tester) async {
        final h = ChatHarness();
        h.settings.inputMode = mode;
        await pumpChat(
          tester,
          (h) {
            h.addAnn();
            return ConversationScreen(target: _ann());
          },
          size: size,
          harness: h,
        );
        await keyIn(tester, 'CQ CQ CQ DE W1AW W1AW W1AW PSE K CQ CQ DE');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final double history = tester
            .getSize(find.byType(ConversationTimeline))
            .height;
        expect(history, greaterThanOrEqualTo(100));
        // Both modalities stay reachable: the pad and the mode switch.
        expect(
          find.byType(
            mode == InputMode.paddles ? PaddleButtons : StraightKeyButton,
          ),
          findsOneWidget,
        );
        expect(find.byType(SegmentedButton<InputMode>), findsOneWidget);
      });
    }
  }

  testWidgets('Send commits the character still being keyed', (tester) async {
    final h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return ConversationScreen(target: _ann());
    });
    await _keyDit(tester, h);
    // The dit waits for the character gap, which the frozen clock never
    // reaches; Send must still be offered and must commit it.
    final IconButton send = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.send),
    );
    expect(send.onPressed, isNotNull);
    await tester.tap(find.byTooltip(s.chatSend));
    await tester.pumpAndSettle();
    final history = await h.service.loadHistory('c2c_$kPeerKey');
    expect(history.map((m) => m.text), ['E']);
    final TextField draft = tester.widget<TextField>(find.byType(TextField));
    expect(draft.controller!.text, isEmpty);
  });

  testWidgets('switching input mode keeps the character being keyed', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return ConversationScreen(target: _ann());
    });
    await _keyDit(tester, h);
    await tester.tap(find.byTooltip(s.chatModePaddles));
    await tester.pumpAndSettle();
    final TextField draft = tester.widget<TextField>(find.byType(TextField));
    expect(draft.controller!.text, 'E');
  });

  testWidgets('Send keeps a paddle dah being keyed a dah', (tester) async {
    final h = ChatHarness();
    h.settings.inputMode = InputMode.paddles;
    await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return ConversationScreen(target: _ann());
    }, harness: h);
    // Right paddle = dah. Send 60 ms into it (a dit's length at 15 wpm is
    // 80 ms, a dah 240 ms).
    final Offset dah = tester.getCenter(find.text('DAH'));
    final gesture = await tester.startGesture(dah);
    await tester.pump();
    h.clock.advance(const Duration(milliseconds: 60));
    // Let the composer's 40 ms tick see the key down (Send is offered).
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byTooltip(s.chatSend));
    await gesture.up();
    await tester.pumpAndSettle();
    final history = await h.service.loadHistory('c2c_$kPeerKey');
    expect(history.map((m) => m.text), ['T']);
  });
}

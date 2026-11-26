import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/chat/conversation_timeline.dart';
import 'package:ditmesh/ui/chat/input_mode.dart';
import 'package:ditmesh/ui/chat/keying_input.dart';
import 'package:ditmesh/ui/chat/message_bubble.dart';
import 'package:ditmesh/ui/chat/morse_playback_controller.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../layout/layout_profiles.dart';
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
  testWidgets('wide conversation uses 24 dp gutters and caps each bubble', (
    tester,
  ) async {
    await pumpChat(tester, (h) {
      h.addAnn(online: true, withMessage: false);
      h.service.receiveMessage(_ann().id, 'CQ CQ DE ANN ' * 6);
      return ConversationScreen(target: _ann(), embedded: true);
    }, size: const Size(1920, 1080));
    await keyIn(tester, 'TNX DE ME ' * 6);
    await tester.tap(find.byTooltip(s.chatSend));
    await tester.pumpAndSettle();

    Rect bubble({required bool mine}) => tester.getRect(
      find
          .descendant(
            of: find.byWidgetPredicate(
              (widget) =>
                  widget is MessageBubble && widget.message.isMine == mine,
            ),
            matching: find.byType(Material),
          )
          .first,
    );

    final Rect timeline = tester.getRect(find.byType(ConversationTimeline));
    final Rect incoming = bubble(mine: false);
    final Rect outgoing = bubble(mine: true);
    expect(timeline.width, 1920);
    expect(incoming.left - timeline.left, 24);
    expect(timeline.right - outgoing.right, 24);
    expect(incoming.width, 520);
    expect(outgoing.width, 520);
    expect(tester.getRect(find.byType(KeyingInput)).left, 24);
  });

  for (final group in [false, true]) {
    testWidgets(
      'short wide ${group ? 'group' : 'direct'} chat docks both columns',
      (tester) async {
        applyProfile(
          tester,
          const LayoutProfile(
            'keyed-landscape',
            Size(640, 360),
            textScale: 1.5,
            padding: FakeViewPadding(left: 47, right: 47, bottom: 21),
          ),
        );
        final h = ChatHarness();
        addTearDown(h.dispose);
        h.settings.inputMode = InputMode.paddles;
        final ConversationTarget target;
        if (group) {
          final net = h.service.addFakeGroup(
            const Group(id: 'tox_1', name: 'Net', kind: GroupKind.group),
          );
          target = ConversationTarget.fromGroup(net);
          h.service.receiveMessage(target.id, 'CQ CQ DE NET');
        } else {
          h.addAnn();
          target = _ann();
        }
        await tester.pumpWidget(h.wrap(ConversationScreen(target: target)));
        await tester.pumpAndSettle();
        await keyIn(tester, 'CQ CQ DE BG2AN ' * 4);

        final Rect pad = tester.getRect(find.byType(PaddleButtons));
        final Rect draft = tester.getRect(find.byType(TextField));
        expect(pad.right, lessThanOrEqualTo(draft.left));
        expect(pad.top, lessThan(draft.bottom));
        expect(pad.bottom, greaterThan(draft.top));
        expect(find.byTooltip(s.chatSend).hitTestable(), findsOneWidget);
        expect(
          find.byTooltip(s.chatPreviewDraft).hitTestable(),
          findsOneWidget,
        );
        expect(
          tester.getSize(find.byType(ConversationTimeline)).height,
          greaterThanOrEqualTo(100),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('localized Delete is one line with its full semantic name', (
    tester,
  ) async {
    applyProfile(
      tester,
      const LayoutProfile(
        'keyed-portrait',
        Size(320, 568),
        textScale: 2,
        padding: FakeViewPadding(top: 24, bottom: 48),
      ),
    );
    final h = ChatHarness()..addAnn();
    addTearDown(h.dispose);
    await tester.pumpWidget(
      h.wrap(
        Builder(
          builder: (context) => Localizations.override(
            context: context,
            locale: const Locale('de'),
            child: ConversationScreen(target: _ann()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await keyIn(tester, 'CQ');
    final strings = S.of(tester.element(find.byType(ConversationScreen)));
    final delete = find.byTooltip(strings.chatDeleteLast);
    final label = find.descendant(
      of: delete,
      matching: find.text(strings.actionDelete),
    );
    final icon = find.descendant(
      of: delete,
      matching: find.byIcon(Icons.backspace_outlined),
    );
    expect(label, findsOneWidget);
    expect(tester.widget<Text>(label).softWrap, isFalse);
    expect(tester.getRect(icon).right, lessThan(tester.getRect(label).left));
    expect(
      tester.getRect(icon).center.dy,
      closeTo(tester.getRect(label).center.dy, 1),
    );
    final node = find.bySemanticsLabel(strings.chatDeleteLast);
    expect(node, findsOneWidget);
    expect(
      tester
          .getSemantics(node)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    await tester.tap(delete);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'C',
    );
    final Finder send = find.byTooltip(strings.chatSend);
    expect(
      send.hitTestable(),
      findsOneWidget,
      reason: 'Send sits at ${tester.getRect(send)} in the 320×568 viewport',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('resizing while keying retains the draft and recorded mark', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return ConversationScreen(target: _ann());
    });
    await _keyDit(tester, h);
    h.clock.advance(const Duration(milliseconds: 210));
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'E',
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();
    h.clock.advance(const Duration(milliseconds: 30));
    tester.view.physicalSize = const Size(640, 360);
    await tester.pump();
    h.clock.advance(const Duration(milliseconds: 53));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.tap(find.byTooltip(s.chatSend));
    await tester.pumpAndSettle();

    final ChatMessage sent = (await h.service.loadHistory(_ann().id)).single;
    expect(sent.text, 'EE');
    expect(sent.recording?.durationsMs.last, 83);
    expect(tester.takeException(), isNull);
  });

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

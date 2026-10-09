import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/chat/message_bubble.dart';
import 'package:ditmesh/ui/chat/message_playback_panel.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:morse_io/morse_io.dart';
import 'test_support.dart';
import 'package:ditmesh/ui/chat/message_status_icon.dart';

void main() {
  for (final size in [const Size(320, 640), const Size(667, 375)]) {
    testWidgets('full composer and player stay functional at 3x $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = ChatHarness()..addAnn(withMessage: false);
      h.settings.originalRhythm = true;
      addTearDown(h.dispose);
      await tester.pumpWidget(
        h.wrap(
          ConversationScreen(
            target: ConversationTarget(
              id: 'c2c_$kPeerKey',
              title: 'Ann',
              kind: ConversationKind.c2c,
            ),
          ),
          textScaler: TextScaler.linear(3),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(StraightKeyButton));
      final gesture = await tester.press(find.byType(StraightKeyButton));
      h.clock.advance(const Duration(milliseconds: 83));
      await gesture.up();
      await tester.ensureVisible(find.byTooltip(s.chatSend));
      await tester.pump();
      await tester.tap(find.byTooltip(s.chatSend));
      await tester.pumpAndSettle();
      final row = (await h.service.loadHistory('c2c_$kPeerKey')).single;
      expect(row.recording?.durationsMs, [83]);
      expect(tester.takeException(), isNull);
      final delivery = tester.getSize(find.byType(MessageStatusIcon));
      expect(delivery.width, greaterThanOrEqualTo(48));
      expect(delivery.height, greaterThanOrEqualTo(48));
      await tester.ensureVisible(find.byType(MessageBubble));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('learn-menu-${row.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(s.chatMessagePlayback));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(ValueKey('player-repeat-range')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('player-repeat-range')));
      h.clock.advance(const Duration(milliseconds: 1500));
      await tester.pump();
      expect(h.playback.playingId, row.id);
      expect(h.playback.usingOriginal, isTrue);
      await tester.ensureVisible(find.byKey(ValueKey('player-pause')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('player-pause')));
      await tester.pump();
      expect(h.playback.isPaused, isTrue);
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.byType(MessagePlaybackPanel))).pop();
      await tester.pumpAndSettle();
    });
  }
}

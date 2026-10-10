import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:ditmesh/ui/chat/message_bubble.dart';
import 'package:ditmesh/ui/telegraph/telegraph_interpret_sheet.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../learn/helpers/l10n.dart';

ChatMessage _msg(String text) => ChatMessage(
  id: 'm1',
  conversationId: 'c2c_${'A' * 64}',
  senderId: 'A' * 64,
  text: text,
  timestamp: DateTime.utc(2026, 10, 4),
  status: MessageStatus.received,
  isMine: false,
);

Widget _bubble(ChatMessage m, {bool training = false}) => l10nApp(
  home: Scaffold(
    body: MessageBubble(
      message: m,
      trainingMode: training,
      revealed: false,
      playing: false,
      onPlay: () {},
      onReveal: () {},
    ),
  ),
);

void main() {
  group('chat interpretation', () {
    testWidgets('offered only for visible four-digit groups', (tester) async {
      await tester.pumpWidget(_bubble(_msg('599 TU')));
      expect(find.byKey(const ValueKey('learn-menu-m1')), findsNothing);
      await tester.pumpWidget(_bubble(_msg('0022 0948'), training: true));
      expect(find.byKey(const ValueKey('learn-menu-m1')), findsNothing,
          reason: 'hidden text is not interpreted');
      await tester.pumpWidget(_bubble(_msg('CQ 0022 12345 9999')));
      await tester.tap(find.byKey(const ValueKey('learn-menu-m1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.telegraphInterpretAction));
      await tester.pumpAndSettle();
      expect(find.byType(TelegraphInterpretation), findsOneWidget);
      expect(find.text('中'), findsOneWidget);
      expect(find.text(en.telegraphMalformed), findsOneWidget);
      expect(find.text(en.telegraphUnresolved), findsOneWidget);
      expect(find.text(en.telegraphNotCode), findsOneWidget);
      // The message itself is unchanged underneath.
      expect(find.text('CQ 0022 12345 9999', findRichText: true), findsWidgets);
    });

    testWidgets('the codebook switch re-reads the groups', (tester) async {
      final tw = ChineseTelegraphCode.codeOf('國', codebook: TelegraphCodebook.taiwan)!;
      await tester.pumpWidget(l10nApp(home: Scaffold(body: TelegraphInterpretation(text: tw))));
      await tester.tap(find.byKey(const ValueKey('codebook-taiwan')));
      await tester.pump();
      expect(find.text('國'), findsOneWidget);
    });
  });
}

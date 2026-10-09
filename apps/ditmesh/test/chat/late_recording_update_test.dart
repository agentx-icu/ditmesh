import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/chat/conversation_timeline.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'test_support.dart';

void main() {
  testWidgets('late rhythm enriches a parked row without a second arrival', (
    tester,
  ) async {
    final id = 'c2c_$kPeerKey';
    final h = ChatHarness()..addAnn(withMessage: false);
    for (var i = 0; i < 300; i++) {
      h.service.receiveMessage(
        id,
        i == 100 ? 'NEEDLE' : 'CQ $i',
        timestamp: DateTime(2026, 10, 9).add(Duration(minutes: i)),
      );
    }
    await pumpChat(
      tester,
      (_) => ConversationScreen(
        target: ConversationTarget(
          id: id,
          title: 'Ann',
          kind: ConversationKind.c2c,
        ),
      ),
      harness: h,
    );
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.chatSearchMessages));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'needle');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NEEDLE'));
    await tester.pumpAndSettle();

    final arrival = h.service.receiveMessage(id, 'NEW CQ');
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ConversationTimeline>(find.byType(ConversationTimeline))
          .newCount,
      1,
    );
    final unread = h.service.conversations.single.unreadCount;
    final recording = KeyedRecording(durationsMs: [83, 117, 256]);
    h.service.attachRecording(arrival.id, recording);
    await tester.pumpAndSettle();
    final parked = tester.widget<ConversationTimeline>(
      find.byType(ConversationTimeline),
    );
    expect(parked.newCount, 1);
    expect(parked.messages.any((row) => row.id == arrival.id), isFalse);
    expect(h.service.conversations.single.unreadCount, unread);

    await tester.tap(find.byKey(const ValueKey('new-messages')));
    await tester.pumpAndSettle();
    final latest = tester.widget<ConversationTimeline>(
      find.byType(ConversationTimeline),
    );
    expect(latest.messages.where((row) => row.id == arrival.id), hasLength(1));
    expect(
      latest.messages.singleWhere((row) => row.id == arrival.id).recording,
      recording,
    );
    expect(latest.newCount, 0);
  });
}

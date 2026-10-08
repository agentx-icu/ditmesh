import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/chat/message_bubble.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'test_support.dart';

ConversationTarget _ann() => ConversationTarget(
  id: 'c2c_$kPeerKey',
  title: 'Ann',
  kind: ConversationKind.c2c,
);

Future<void> _send(WidgetTester tester, String text) async {
  await keyIn(tester, text);
  await tester.pump();
  await tester.tap(find.byTooltip(s.chatSend));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('input mode survives closing and reopening a conversation', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return ConversationScreen(target: _ann());
    });
    await tester.tap(find.byTooltip(s.chatModePaddles));
    await tester.pumpAndSettle();
    await tester.pumpWidget(h.wrap(const SizedBox()));
    await tester.pumpWidget(h.wrap(ConversationScreen(target: _ann())));
    await tester.pumpAndSettle();
    expect(find.text('DIT'), findsOneWidget);
    expect(find.text('DAH'), findsOneWidget);
  });
  testWidgets('background flushes a draft before the debounce expires', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return ConversationScreen(target: _ann());
    });
    await keyIn(tester, 'UNSENT CQ');
    await tester.pump();
    expect(h.service.conversations.single.draft, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pump();
    expect(h.service.conversations.single.draft, 'UNSENT CQ');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('sending to an offline peer appends a pending bubble', (
    tester,
  ) async {
    final ChatHarness h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return ConversationScreen(target: _ann());
    });
    expect(find.text(s.chatNoMessages), findsOneWidget);
    expect(find.text(s.connectionOffline), findsOneWidget);

    await _send(tester, 'CQ');
    expect(find.byType(MessageBubble), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.text('-.-. --.-'), findsOneWidget);
    expect(
      h.service.conversations.single.lastMessage?.status,
      MessageStatus.pending,
    );
    // The pending glyph explains that Tox has no store-and-forward server.
    expect(
      find.byTooltip(
        '${s.messageStatusPending}\n${s.messageStatusPendingDetail}',
      ),
      findsOneWidget,
    );

    // Peer comes online: the status event flips the glyph to sent.
    h.service.setFriendOnline(kPeerKey, true);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.schedule), findsNothing);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byTooltip(s.messageStatusSent), findsOneWidget);
    expect(find.text(s.connectionOnline), findsOneWidget);
  });

  testWidgets('sending to an online peer appends a sent bubble', (
    tester,
  ) async {
    await pumpChat(tester, (h) {
      h.addAnn(online: true, withMessage: false);
      return ConversationScreen(target: _ann());
    });
    await _send(tester, 'K');
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsNothing);
    // Draft field is cleared and the byte counter is back to the budget.
    expect(find.text(s.chatBytesLeftCount(1322)), findsOneWidget);
  });

  testWidgets('training mode hides inbound text until revealed', (
    tester,
  ) async {
    final ChatHarness h = await pumpChat(tester, (h) {
      h.addAnn();
      return ConversationScreen(target: _ann());
    });
    expect(find.text('CQ CQ DE ANN'), findsOneWidget);

    await tester.tap(find.byTooltip(s.chatTrainingMode));
    await tester.pumpAndSettle();
    expect(h.settings.trainingMode, isTrue);
    expect(find.text('CQ CQ DE ANN'), findsNothing);
    expect(find.text(s.chatHiddenText), findsOneWidget);
    // The pattern layer stays visible so the listener can follow along.
    expect(
      find.text('-.-. --.- / -.-. --.- / -.. . / .- -. -.'),
      findsOneWidget,
    );

    await tester.tap(find.text(s.chatReveal));
    await tester.pumpAndSettle();
    expect(find.text('CQ CQ DE ANN'), findsOneWidget);

    // A new inbound message is hidden again; revealed state is per message.
    h.service.receiveMessage('c2c_$kPeerKey', 'R');
    await tester.pumpAndSettle();
    expect(find.text(s.chatHiddenText), findsOneWidget);
    expect(find.text('CQ CQ DE ANN'), findsOneWidget);
  });

  testWidgets('play toggles the controller and highlights marks', (
    tester,
  ) async {
    final ChatHarness h = await pumpChat(tester, (h) {
      h.addAnn();
      return ConversationScreen(target: _ann());
    });
    await tester.tap(find.byTooltip(s.chatPlay));
    await tester.pumpAndSettle();
    expect(h.playback.playingId, 'msg_1');
    expect(find.byTooltip(s.chatStop), findsOneWidget);
    await tester.tap(find.byTooltip(s.chatStop));
    await tester.pumpAndSettle();
    expect(h.playback.playingId, isNull);
  });

  testWidgets('opening marks the conversation read and restores the draft', (
    tester,
  ) async {
    final ChatHarness h = ChatHarness();
    h.addAnn();
    await h.service.setDraft('c2c_$kPeerKey', 'CQ DE');
    expect(h.service.conversations.single.unreadCount, 1);
    await pumpChat(
      tester,
      (_) => ConversationScreen(target: _ann()),
      harness: h,
    );
    expect(h.service.conversations.single.unreadCount, 0);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'CQ DE',
    );
    expect(find.text(s.chatBytesLeftCount(1317)), findsOneWidget);
  });

  testWidgets('over-budget draft disables send and shows the error', (
    tester,
  ) async {
    final ChatHarness h = ChatHarness(
      service: FakeChatService(selfPublicKey: kSelfKey, maxMessageBytes: 3),
    );
    await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return ConversationScreen(target: _ann());
    }, harness: h);
    await keyIn(tester, 'ABCD');
    await tester.pump();
    expect(find.text(s.chatTooLong), findsOneWidget);
    expect(find.text(s.chatBytesLeftCount(-1)), findsOneWidget);
    await tester.tap(find.byTooltip(s.chatSend));
    await tester.pumpAndSettle();
    expect(find.byType(MessageBubble), findsNothing);
  });

  testWidgets('the composer switches between straight key and paddles', (
    tester,
  ) async {
    await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return ConversationScreen(target: _ann());
    });
    await tester.tap(find.byTooltip(s.chatModeStraightKey));
    await tester.pumpAndSettle();
    expect(find.text('KEY'), findsOneWidget);
    expect(find.text(s.chatKeyHint), findsOneWidget);
    await tester.tap(find.byTooltip(s.chatModePaddles));
    await tester.pumpAndSettle();
    expect(find.text('DIT'), findsOneWidget);
    expect(find.text('DAH'), findsOneWidget);
    await tester.tap(find.byTooltip(s.chatModeStraightKey));
    await tester.pumpAndSettle();
    expect(find.text('DIT'), findsNothing);
    expect(find.text('KEY'), findsOneWidget);
  });
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/notifications/notifications.dart';
import 'package:ditmesh/notifications/testing/fake_badge_api.dart';
import 'package:ditmesh/notifications/testing/fake_local_notifications_api.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import 'test_support.dart';

ConversationTarget _ann() => ConversationTarget(
  id: 'c2c_$kPeerKey',
  title: 'Ann',
  kind: ConversationKind.c2c,
);

int _unread(ChatHarness h) =>
    h.service.conversations.firstWhere((c) => c.id == 'c2c_$kPeerKey').unreadCount;

/// The screen inside a switchable TickerMode, the way a shell tab hides it.
class _Tab extends StatelessWidget {
  const _Tab({required this.visible, required this.child});

  final ValueListenable<bool> visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: visible,
    builder: (context, on, _) => TickerMode(enabled: on, child: child),
  );
}

void main() {
  testWidgets('a hidden tab does not mark messages read until shown', (
    tester,
  ) async {
    final ValueNotifier<bool> visible = ValueNotifier<bool>(true);
    addTearDown(visible.dispose);
    final h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return _Tab(visible: visible, child: ConversationScreen(target: _ann()));
    });
    visible.value = false;
    await tester.pumpAndSettle();
    h.service.receiveMessage('c2c_$kPeerKey', 'CQ');
    await tester.pumpAndSettle();
    expect(_unread(h), 1);

    visible.value = true;
    await tester.pumpAndSettle();
    expect(_unread(h), 0);
  });

  testWidgets('a backgrounded app does not mark messages read', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return ConversationScreen(target: _ann());
    });
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    h.service.receiveMessage('c2c_$kPeerKey', 'CQ');
    await tester.pumpAndSettle();
    expect(_unread(h), 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(_unread(h), 0);
  });

  testWidgets('a dialog over the conversation defers the read', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return ConversationScreen(target: _ann());
    });
    final BuildContext context = tester.element(find.byType(ConversationScreen));
    final Future<void> dialog = showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(content: Text('busy')),
    );
    await tester.pumpAndSettle();
    h.service.receiveMessage('c2c_$kPeerKey', 'CQ');
    await tester.pumpAndSettle();
    expect(_unread(h), 1);

    Navigator.of(context).pop();
    await dialog;
    await tester.pumpAndSettle();
    expect(_unread(h), 0);
  });

  testWidgets('the screen claims the notification centre while attended', (
    tester,
  ) async {
    final ChatHarness h = ChatHarness();
    final ValueNotifier<bool> foreground = ValueNotifier<bool>(true);
    final NotificationPrefs prefs = NotificationPrefs();
    final NotificationCenter center = NotificationCenter(
      chat: h.service,
      notifications: FakeLocalNotificationsApi(),
      badge: FakeBadgeApi(),
      prefs: prefs,
      isForeground: foreground,
      platform: NotificationPlatform.linux,
    );
    addTearDown(() async {
      await center.dispose();
      prefs.dispose();
      foreground.dispose();
    });
    final ValueNotifier<bool> visible = ValueNotifier<bool>(true);
    addTearDown(visible.dispose);
    await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return Provider<NotificationCenter?>.value(
        value: center,
        child: _Tab(visible: visible, child: ConversationScreen(target: _ann())),
      );
    }, harness: h);
    expect(center.activeConversation, 'c2c_$kPeerKey');

    visible.value = false;
    await tester.pumpAndSettle();
    expect(center.activeConversation, isNull);

    visible.value = true;
    await tester.pumpAndSettle();
    expect(center.activeConversation, 'c2c_$kPeerKey');

    await tester.pumpWidget(h.wrap(const SizedBox()));
    await tester.pumpAndSettle();
    expect(center.activeConversation, isNull);
  });

  testWidgets('a chat opened before the session exists loads once connected', (
    tester,
  ) async {
    final FakeIdentityService identity = FakeIdentityService.withProfile(
      identity: Identity(toxId: kSelfToxId, displayName: 'Me'),
      connectDelay: Duration.zero,
    );
    await identity.open();
    final ChatHarness h = ChatHarness(
      service: FakeChatService(identity: identity),
    );
    addTearDown(identity.dispose);
    await pumpChat(tester, (h) {
      h.service.addFakeFriend(
        Friend(publicKey: kPeerKey, displayName: 'Ann'),
      );
      return Provider<IdentityService>.value(
        value: identity,
        child: ConversationScreen(target: _ann()),
      );
    }, harness: h);
    expect(find.text(s.chatRetryHistory), findsOneWidget);

    await identity.connect();
    await tester.pumpAndSettle();
    expect(find.text(s.chatRetryHistory), findsNothing);
    expect(find.text(s.chatNoMessages), findsOneWidget);
  });

  testWidgets('the load is retried when the session starts, before online', (
    tester,
  ) async {
    // Tox still connecting (no DHT yet), but the chat session is bound.
    final FakeIdentityService identity = FakeIdentityService.withProfile(
      identity: Identity(toxId: kSelfToxId, displayName: 'Me'),
      connectDelay: const Duration(hours: 1),
    );
    await identity.open();
    final ChatHarness h = ChatHarness(
      service: FakeChatService(identity: identity),
    );
    addTearDown(identity.dispose);
    await pumpChat(tester, (h) {
      h.service.addFakeFriend(
        Friend(publicKey: kPeerKey, displayName: 'Ann'),
      );
      return ConversationScreen(target: _ann());
    }, harness: h);
    expect(find.text(s.chatRetryHistory), findsOneWidget);
    unawaited(identity.connect());
    await tester.pump();
    await tester.pump();
    expect(identity.connectionStatus, ConnectionStatus.connecting);
    expect(find.text(s.chatRetryHistory), findsNothing);
    await identity.disconnect();
  });
}

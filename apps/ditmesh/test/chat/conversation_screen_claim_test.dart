import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/lifecycle/app_lifecycle_coordinator.dart';
import 'package:ditmesh/notifications/notifications.dart';
import 'package:ditmesh/notifications/testing/fake_badge_api.dart';
import 'package:ditmesh/notifications/testing/fake_local_notifications_api.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import 'test_support.dart';

final String _annId = 'c2c_$kPeerKey';

ConversationTarget _ann() =>
    ConversationTarget(id: _annId, title: 'Ann', kind: ConversationKind.c2c);

/// The conversation screen with the app-level services it reads: the
/// lifecycle coordinator (foreground / background) and the notification
/// centre (active conversation, OS banners).
final class _Env {
  _Env(this.h)
    : lifecycle = AppLifecycleCoordinator(
        identity: h.identity,
        platform: NotificationPlatform.linux, // no background countdown
      ),
      api = FakeLocalNotificationsApi(),
      prefs = NotificationPrefs() {
    center = NotificationCenter(
      chat: h.service,
      notifications: api,
      badge: FakeBadgeApi(),
      prefs: prefs,
      isForeground: lifecycle.isForeground,
      platform: NotificationPlatform.android,
      strings: () => s,
    );
  }

  final ChatHarness h;
  final AppLifecycleCoordinator lifecycle;
  final FakeLocalNotificationsApi api;
  final NotificationPrefs prefs;
  late final NotificationCenter center;

  int get unread =>
      h.service.conversations.firstWhere((c) => c.id == _annId).unreadCount;

  Widget wrap(Widget child) => MultiProvider(
    providers: [
      Provider<AppLifecycleCoordinator>.value(value: lifecycle),
      Provider<NotificationCenter?>.value(value: center),
    ],
    child: h.wrap(child),
  );

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = kPhone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    lifecycle.attach();
    await center.start();
    addTearDown(() async {
      await center.dispose();
      await lifecycle.dispose();
      prefs.dispose();
      await h.dispose();
    });
    await tester.pumpWidget(wrap(child));
    await tester.pumpAndSettle();
  }
}

Future<_Env> _env() async {
  final ChatHarness h = ChatHarness();
  h.addAnn();
  return _Env(h);
}

void _lifecycle(WidgetTester tester, List<AppLifecycleState> states) {
  for (final AppLifecycleState state in states) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

const List<AppLifecycleState> _toBackground = [
  AppLifecycleState.inactive,
  AppLifecycleState.hidden,
  AppLifecycleState.paused,
];
const List<AppLifecycleState> _toForeground = [
  AppLifecycleState.hidden,
  AppLifecycleState.inactive,
  AppLifecycleState.resumed,
];

void main() {
  testWidgets('the open conversation is the active one and posts no banner', (
    tester,
  ) async {
    final _Env env = await _env();
    await env.pump(tester, ConversationScreen(target: _ann()));
    expect(env.center.activeConversation, _annId);

    env.h.service.receiveMessage(_annId, 'QRL?');
    await tester.pumpAndSettle();
    expect(env.api.shown, isEmpty);

    await tester.pumpWidget(env.wrap(const SizedBox()));
    await tester.pumpAndSettle();
    expect(env.center.activeConversation, isNull);
    env.h.service.receiveMessage(_annId, 'QRL? QRL?');
    await tester.pumpAndSettle();
    expect(env.api.shown, hasLength(1));
  });

  testWidgets('closing does not clear another conversation made active', (
    tester,
  ) async {
    final _Env env = await _env();
    await env.pump(tester, ConversationScreen(target: _ann()));
    env.center.claimActiveConversation('c2c_${'C' * 64}', Object());
    await tester.pumpWidget(env.wrap(const SizedBox()));
    await tester.pumpAndSettle();
    expect(env.center.activeConversation, 'c2c_${'C' * 64}');
  });

  testWidgets('a message received in the background stays unread until the '
      'app is back in the foreground', (tester) async {
    final _Env env = await _env();
    await env.pump(tester, ConversationScreen(target: _ann()));
    expect(env.unread, 0);

    _lifecycle(tester, _toBackground);
    env.h.service.receiveMessage(_annId, 'QRL?');
    await tester.pumpAndSettle();
    expect(env.unread, 1, reason: 'nobody has seen it yet');
    expect(env.api.shown, hasLength(1), reason: 'the OS banner stays up');
    final int bannerId = env.api.shown.single.id;

    _lifecycle(tester, _toForeground);
    await tester.pumpAndSettle();
    expect(env.unread, 0);
    expect(env.api.cancelled, contains(bannerId));
  });

  testWidgets('opening while backgrounded defers mark-read to the foreground', (
    tester,
  ) async {
    final _Env env = await _env();
    _lifecycle(tester, _toBackground);
    await env.pump(tester, ConversationScreen(target: _ann()));
    expect(env.unread, 1);
    _lifecycle(tester, _toForeground);
    await tester.pumpAndSettle();
    expect(env.unread, 0);
  });

  testWidgets('iOS inactive (control centre, call banner) still counts as '
      'seen', (tester) async {
    final _Env env = await _env();
    await env.pump(tester, ConversationScreen(target: _ann()));
    _lifecycle(tester, [AppLifecycleState.inactive]);
    env.h.service.receiveMessage(_annId, 'QRL?');
    await tester.pumpAndSettle();
    expect(env.unread, 0);
    _lifecycle(tester, [AppLifecycleState.resumed]);
  });

  testWidgets('a pane on a hidden tab neither marks read nor is active', (
    tester,
  ) async {
    final _Env env = await _env();
    final ValueNotifier<bool> shown = ValueNotifier<bool>(false);
    addTearDown(shown.dispose);
    await env.pump(
      tester,
      ValueListenableBuilder<bool>(
        valueListenable: shown,
        builder: (_, enabled, child) =>
            TickerMode(enabled: enabled, child: child!),
        child: ConversationScreen(target: _ann()),
      ),
    );
    expect(env.unread, 1);
    expect(env.center.activeConversation, isNull);

    shown.value = true;
    await tester.pumpAndSettle();
    expect(env.unread, 0);
    expect(env.center.activeConversation, _annId);

    shown.value = false;
    await tester.pumpAndSettle();
    expect(env.center.activeConversation, isNull);
  });
}

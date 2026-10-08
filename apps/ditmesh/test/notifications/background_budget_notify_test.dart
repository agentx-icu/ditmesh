import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/testing.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/lifecycle/lifecycle.dart';
import 'package:ditmesh/notifications/notifications.dart';
import 'package:ditmesh/notifications/testing/fake_badge_api.dart';
import 'package:ditmesh/notifications/testing/fake_local_notifications_api.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';

import 'support/stub_identity_service.dart';

/// The notification centre driven by the real [AppLifecycleCoordinator]
/// (iOS budget, fake clock), the way `AppServices` wires them: what a
/// message that lands while the app is backgrounded but still running does.
void main() {
  final String ann = 'A' * 64;
  final String annConv = 'c2c_$ann';
  final DateTime now = DateTime(2026, 10, 8, 12);

  late FakeClock clock;
  late StubIdentityService identity;
  late FakeChatService chat;
  late FakeLocalNotificationsApi api;
  late NotificationPrefs prefs;
  late AppLifecycleCoordinator lifecycle;
  late NotificationCenter center;

  setUp(() async {
    clock = FakeClock();
    identity = StubIdentityService();
    chat = FakeChatService(selfPublicKey: 'F' * 64, clock: () => now);
    api = FakeLocalNotificationsApi();
    prefs = NotificationPrefs();
    lifecycle = AppLifecycleCoordinator(
      identity: identity,
      clock: clock,
      platform: NotificationPlatform.ios,
    );
    center = NotificationCenter(
      chat: chat,
      notifications: api,
      badge: FakeBadgeApi(),
      prefs: prefs,
      isForeground: lifecycle.isForeground,
      identity: identity,
      platform: NotificationPlatform.ios,
      strings: () => lookupS(const Locale('en')),
      clock: () => now,
    );
    chat.addFakeFriend(Friend(publicKey: ann, displayName: 'Ann'));
    lifecycle.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await center.start();
    await pumpEventQueue();
  });

  tearDown(() async {
    await center.dispose();
    await lifecycle.dispose();
    await chat.dispose();
    await identity.dispose();
    prefs.dispose();
  });

  void background() {
    lifecycle.didChangeAppLifecycleState(AppLifecycleState.inactive);
    lifecycle.didChangeAppLifecycleState(AppLifecycleState.hidden);
    lifecycle.didChangeAppLifecycleState(AppLifecycleState.paused);
  }

  void resume() {
    lifecycle.didChangeAppLifecycleState(AppLifecycleState.hidden);
    lifecycle.didChangeAppLifecycleState(AppLifecycleState.inactive);
    lifecycle.didChangeAppLifecycleState(AppLifecycleState.resumed);
  }

  test('a message inside the background budget notifies, open conversation '
      'included', () async {
    // The conversation screen stays mounted while the app is backgrounded.
    center.claimActiveConversation(annConv, Object());
    background();
    clock.advance(const Duration(seconds: 20));
    chat.receiveMessage(annConv, 'CQ CQ DE ANN');
    await pumpEventQueue();
    expect(api.shown, hasLength(1));
    expect(api.shown.single.title, 'Ann');
    expect(lifecycle.mayBeDisconnected.value, isFalse);

    // Past the budget the OS may have frozen the process; while it still
    // runs, a later message still replaces the banner in place.
    clock.advance(const Duration(seconds: 10));
    expect(lifecycle.mayBeDisconnected.value, isTrue);
    chat.receiveMessage(annConv, 'K');
    await pumpEventQueue();
    expect(api.shown, hasLength(2));
    expect(api.active, hasLength(1));
  });

  test('resume on the open conversation withdraws its banner', () async {
    center.claimActiveConversation(annConv, Object());
    background();
    clock.advance(const Duration(seconds: 20));
    chat.receiveMessage(annConv, 'CQ');
    await pumpEventQueue();
    expect(api.active, hasLength(1));

    resume();
    await pumpEventQueue();
    expect(api.active, isEmpty);
    expect(lifecycle.mayBeDisconnected.value, isFalse);
    expect(identity.connectCalls, 1);
  });

  test('resume on another screen keeps the banner', () async {
    background();
    clock.advance(const Duration(seconds: 20));
    chat.receiveMessage(annConv, 'CQ');
    await pumpEventQueue();

    resume();
    await pumpEventQueue();
    expect(api.active, hasLength(1));
  });
}

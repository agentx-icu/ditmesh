import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/testing.dart';
import 'package:ditmesh/lifecycle/lifecycle.dart';
import 'package:ditmesh/notifications/notification_platform.dart';

import 'support/stub_identity_service.dart';

void main() {
  late FakeClock clock;
  late StubIdentityService identity;
  late List<LifecycleHint> hints;

  setUp(() {
    clock = FakeClock();
    identity = StubIdentityService();
    hints = <LifecycleHint>[];
  });

  tearDown(() async {
    await identity.dispose();
  });

  AppLifecycleCoordinator build(
    NotificationPlatform platform, {
    Future<void> Function()? onBackground,
  }) {
    final AppLifecycleCoordinator c = AppLifecycleCoordinator(
      identity: identity,
      clock: clock,
      platform: platform,
      onBackground: onBackground,
    );
    c.hints.listen(hints.add);
    addTearDown(c.dispose);
    return c;
  }

  test('iOS: background budget expires after 30 s, resume reconnects', () async {
    final AppLifecycleCoordinator c = build(NotificationPlatform.ios);
    expect(c.isForeground.value, isTrue);
    expect(c.backgroundBudget, const Duration(seconds: 30));

    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(c.isForeground.value, isFalse);
    expect(c.mayBeDisconnected.value, isFalse);

    clock.advance(const Duration(seconds: 29));
    expect(c.mayBeDisconnected.value, isFalse);
    clock.advance(const Duration(seconds: 1));
    expect(c.mayBeDisconnected.value, isTrue);

    c.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(c.isForeground.value, isTrue);
    expect(c.mayBeDisconnected.value, isFalse);
    expect(identity.connectCalls, 1);
    expect(hints, <LifecycleHint>[
      LifecycleHint.background,
      LifecycleHint.mayBeDisconnected,
      LifecycleHint.foreground,
      LifecycleHint.reconnectRequested,
    ]);
  });

  test('Android: 60 s budget, hidden counts as background', () async {
    final AppLifecycleCoordinator c = build(NotificationPlatform.android);
    c.didChangeAppLifecycleState(AppLifecycleState.hidden);
    c.didChangeAppLifecycleState(AppLifecycleState.paused); // no double hint
    clock.advance(const Duration(seconds: 60));
    await pumpEventQueue();
    expect(c.mayBeDisconnected.value, isTrue);
    expect(hints, <LifecycleHint>[
      LifecycleHint.background,
      LifecycleHint.mayBeDisconnected,
    ]);
  });

  test('resume before the budget: reconnect still runs, flag never flips', () async {
    final AppLifecycleCoordinator c = build(NotificationPlatform.ios);
    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    clock.advance(const Duration(seconds: 10));
    c.didChangeAppLifecycleState(AppLifecycleState.resumed);
    clock.advance(const Duration(minutes: 5)); // cancelled timer stays quiet
    await pumpEventQueue();
    expect(c.mayBeDisconnected.value, isFalse);
    expect(identity.connectCalls, 1);
    expect(hints, isNot(contains(LifecycleHint.mayBeDisconnected)));
    expect(clock.pendingTimers, 0);
  });

  test('desktop: no countdown, but resume after hidden still reconnects', () async {
    final AppLifecycleCoordinator c = build(NotificationPlatform.macos);
    expect(c.backgroundBudget, isNull);
    c.didChangeAppLifecycleState(AppLifecycleState.hidden);
    clock.advance(const Duration(hours: 1));
    expect(c.mayBeDisconnected.value, isFalse);
    expect(clock.pendingTimers, 0);

    c.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(identity.connectCalls, 1);
  });

  test('an explicit budget overrides the platform default', () {
    final AppLifecycleCoordinator c = AppLifecycleCoordinator(
      identity: identity,
      clock: clock,
      platform: NotificationPlatform.linux,
      backgroundBudget: const Duration(seconds: 5),
    );
    addTearDown(c.dispose);
    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    clock.advance(const Duration(seconds: 5));
    expect(c.mayBeDisconnected.value, isTrue);
  });

  test('inactive is not background; initial resume does not reconnect', () async {
    final AppLifecycleCoordinator c = build(NotificationPlatform.ios);
    c.didChangeAppLifecycleState(AppLifecycleState.inactive);
    expect(c.isForeground.value, isTrue);
    c.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(identity.connectCalls, 0);
    expect(hints, isEmpty);
  });

  test('no identity loaded: resume does not call connect', () async {
    identity.clearIdentity();
    final AppLifecycleCoordinator c = build(NotificationPlatform.ios);
    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    c.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(identity.connectCalls, 0);
    expect(hints, <LifecycleHint>[
      LifecycleHint.background,
      LifecycleHint.foreground,
    ]);
  });

  test('connect() throwing surfaces as reconnectFailed', () async {
    identity.connectError = StateError('bootstrap failed');
    final AppLifecycleCoordinator c = build(NotificationPlatform.android);
    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    c.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(hints.last, LifecycleHint.reconnectFailed);
  });

  test('onBackground hook runs once per background transition', () async {
    var calls = 0;
    final AppLifecycleCoordinator c = build(
      NotificationPlatform.ios,
      onBackground: () async => calls++,
    );
    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    c.didChangeAppLifecycleState(AppLifecycleState.detached);
    await pumpEventQueue();
    expect(calls, 1);
  });

  test('dispose cancels the countdown and stops emitting', () async {
    final AppLifecycleCoordinator c = AppLifecycleCoordinator(
      identity: identity,
      clock: clock,
      platform: NotificationPlatform.ios,
    );
    c.hints.listen(hints.add);
    c.didChangeAppLifecycleState(AppLifecycleState.paused);
    await c.dispose();
    clock.advance(const Duration(minutes: 1));
    expect(clock.pendingTimers, 0);
    expect(hints, <LifecycleHint>[LifecycleHint.background]);
  });

  testWidgets('attach() observes the real binding', (tester) async {
    final AppLifecycleCoordinator c = build(NotificationPlatform.ios);
    c.attach();
    c.attach(); // idempotent
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(c.isForeground.value, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(c.isForeground.value, isTrue);
    expect(identity.connectCalls, 1);
    c.detach();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(c.isForeground.value, isTrue); // no longer observing
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
}

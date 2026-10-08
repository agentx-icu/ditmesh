import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/testing.dart';
import 'package:ditmesh/notifications/connection_banner_policy.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'support/stub_identity_service.dart';

void main() {
  late FakeClock clock;
  late StubIdentityService identity;
  late ConnectionBannerPolicy policy;

  setUp(() {
    clock = FakeClock();
    identity = StubIdentityService();
    policy = ConnectionBannerPolicy(identity: identity, clock: clock);
    policy.start();
    policy.start(); // idempotent
  });

  tearDown(() async {
    await policy.dispose();
    await identity.dispose();
  });

  Future<void> status(ConnectionStatus s) async {
    identity.setStatus(s);
    await pumpEventQueue();
  }

  test('starts offline: banner only after two continuous minutes', () {
    expect(policy.offlineBannerVisible.value, isFalse);
    clock.advance(const Duration(minutes: 1, seconds: 59));
    expect(policy.offlineBannerVisible.value, isFalse);
    clock.advance(const Duration(seconds: 1));
    expect(policy.offlineBannerVisible.value, isTrue);
  });

  test('going online hides the banner and cancels the countdown', () async {
    clock.advance(const Duration(minutes: 1));
    await status(ConnectionStatus.online);
    clock.advance(const Duration(minutes: 5));
    expect(policy.offlineBannerVisible.value, isFalse);
    expect(clock.pendingTimers, 0);

    // A later drop starts a fresh two minutes.
    await status(ConnectionStatus.offline);
    clock.advance(const Duration(minutes: 1));
    expect(policy.offlineBannerVisible.value, isFalse);
    clock.advance(const Duration(minutes: 1));
    expect(policy.offlineBannerVisible.value, isTrue);

    await status(ConnectionStatus.online);
    expect(policy.offlineBannerVisible.value, isFalse);
  });

  test('connecting counts as not online', () async {
    await status(ConnectionStatus.connecting);
    clock.advance(const Duration(minutes: 2));
    expect(policy.offlineBannerVisible.value, isTrue);
  });

  test('flapping between offline and connecting never resets the clock', () async {
    for (var i = 0; i < 6; i++) {
      await status(
        i.isEven ? ConnectionStatus.connecting : ConnectionStatus.offline,
      );
      clock.advance(const Duration(seconds: 20));
    }
    // 120 s of not-online in total, regardless of the churn in between.
    expect(policy.offlineBannerVisible.value, isTrue);
    expect(clock.pendingTimers, 0); // exactly one timer ever ran
  });

  test('starting while already online shows nothing', () async {
    final StubIdentityService online = StubIdentityService()
      ..setStatus(ConnectionStatus.online);
    final ConnectionBannerPolicy p = ConnectionBannerPolicy(
      identity: online,
      clock: clock,
    );
    addTearDown(() async {
      await p.dispose();
      await online.dispose();
    });
    p.start();
    clock.advance(const Duration(minutes: 10));
    expect(p.offlineBannerVisible.value, isFalse);
    expect(clock.pendingTimers, 0);
  });
}

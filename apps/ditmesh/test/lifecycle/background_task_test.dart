import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/testing.dart';
import 'package:ditmesh/lifecycle/lifecycle.dart';
import 'package:ditmesh/notifications/notification_platform.dart';

import '../notifications/support/stub_identity_service.dart';

/// Records begin/end like iOS would see them.
final class FakeBackgroundTaskApi implements BackgroundTaskApi {
  FakeBackgroundTaskApi({this.grant = true});

  bool grant;
  int _next = 0;
  final Set<int> open = <int>{};
  final List<int> ended = <int>[];
  int begins = 0;

  @override
  Future<int?> begin() async {
    begins++;
    if (!grant) return null;
    final int token = ++_next;
    open.add(token);
    return token;
  }

  @override
  Future<void> end(int token) async {
    ended.add(token);
    open.remove(token);
  }
}

void main() {
  late FakeClock clock;
  late StubIdentityService identity;
  late FakeBackgroundTaskApi tasks;

  setUp(() {
    clock = FakeClock();
    identity = StubIdentityService();
    tasks = FakeBackgroundTaskApi();
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
      backgroundTasks: tasks,
    );
    addTearDown(c.dispose);
    return c;
  }

  group('AppLifecycleCoordinator background task', () {
    test('iOS: held while the flush runs and until the budget ends', () async {
      // Without the task iOS freezes the app ~5 s in, mid-flush.
      final Completer<void> flush = Completer<void>();
      final AppLifecycleCoordinator c = build(
        NotificationPlatform.ios,
        onBackground: () => flush.future,
      );
      c.didChangeAppLifecycleState(AppLifecycleState.hidden);
      c.didChangeAppLifecycleState(AppLifecycleState.paused);
      await pumpEventQueue();
      expect(tasks.begins, 1);
      expect(tasks.open, hasLength(1));

      flush.complete();
      clock.advance(const Duration(seconds: 29));
      await pumpEventQueue();
      expect(tasks.open, hasLength(1), reason: 'Tox keeps running for sends');

      clock.advance(const Duration(seconds: 1));
      await pumpEventQueue();
      expect(tasks.open, isEmpty);
      expect(tasks.ended, <int>[1]);
      expect(c.mayBeDisconnected.value, isTrue);
    });

    test('resume ends it early; the next background asks again', () async {
      final AppLifecycleCoordinator c = build(NotificationPlatform.ios);
      c.didChangeAppLifecycleState(AppLifecycleState.paused);
      await pumpEventQueue();
      c.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await pumpEventQueue();
      expect(tasks.open, isEmpty);
      expect(tasks.ended, <int>[1]);

      c.didChangeAppLifecycleState(AppLifecycleState.paused);
      await pumpEventQueue();
      expect(tasks.begins, 2);
      expect(tasks.open, <int>{2});
    });

    test('a resume before the OS answered still ends the task', () async {
      final AppLifecycleCoordinator c = build(NotificationPlatform.ios);
      c.didChangeAppLifecycleState(AppLifecycleState.paused);
      c.didChangeAppLifecycleState(AppLifecycleState.resumed); // same tick
      await pumpEventQueue();
      expect(tasks.open, isEmpty);
    });

    test('a refused task is not ended', () async {
      tasks.grant = false;
      final AppLifecycleCoordinator c = build(NotificationPlatform.ios);
      c.didChangeAppLifecycleState(AppLifecycleState.paused);
      clock.advance(const Duration(seconds: 30));
      await pumpEventQueue();
      expect(tasks.begins, 1);
      expect(tasks.ended, isEmpty);
    });

    test(
      'no budget (desktop): released as soon as the flush is done',
      () async {
        final Completer<void> flush = Completer<void>();
        build(
          NotificationPlatform.macos,
          onBackground: () => flush.future,
        ).didChangeAppLifecycleState(AppLifecycleState.hidden);
        await pumpEventQueue();
        expect(tasks.open, hasLength(1));
        flush.complete();
        await pumpEventQueue();
        expect(tasks.open, isEmpty);
      },
    );

    test('a listener resuming re-entrantly leaves no task behind', () async {
      final AppLifecycleCoordinator c = build(NotificationPlatform.ios);
      var reentered = false;
      c.isForeground.addListener(() {
        if (c.isForeground.value || reentered) return;
        reentered = true;
        c.didChangeAppLifecycleState(AppLifecycleState.resumed);
      });
      c.didChangeAppLifecycleState(AppLifecycleState.paused);
      await pumpEventQueue();
      expect(c.isForeground.value, isTrue);
      expect(tasks.open, isEmpty);
      expect(clock.pendingTimers, 0);
    });

    test('a listener disposing re-entrantly leaves no task behind', () async {
      final AppLifecycleCoordinator c = AppLifecycleCoordinator(
        identity: identity,
        clock: clock,
        platform: NotificationPlatform.ios,
        backgroundTasks: tasks,
      );
      c.isForeground.addListener(() {
        if (!c.isForeground.value) unawaited(c.dispose());
      });
      c.didChangeAppLifecycleState(AppLifecycleState.paused);
      await pumpEventQueue();
      expect(tasks.begins, 1);
      expect(tasks.open, isEmpty);
      expect(clock.pendingTimers, 0);
    });

    test('dispose ends an outstanding task', () async {
      final AppLifecycleCoordinator c = AppLifecycleCoordinator(
        identity: identity,
        clock: clock,
        platform: NotificationPlatform.ios,
        backgroundTasks: tasks,
      );
      c.didChangeAppLifecycleState(AppLifecycleState.paused);
      await pumpEventQueue();
      await c.dispose();
      await pumpEventQueue();
      expect(tasks.open, isEmpty);
    });
  });

  group('MethodChannelBackgroundTaskApi', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const MethodChannel channel = MethodChannel(
      MethodChannelBackgroundTaskApi.channelName,
    );

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('round-trips begin / end with the native side', () async {
      final List<MethodCall> calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            calls.add(call);
            return call.method == 'begin' ? 7 : null;
          });
      final MethodChannelBackgroundTaskApi api =
          MethodChannelBackgroundTaskApi();
      expect(await api.begin(), 7);
      await api.end(7);
      expect(
        calls.map((MethodCall c) => '${c.method}:${c.arguments}'),
        <String>['begin:null', 'end:7'],
      );
    });

    test('a missing native side degrades to "no task"', () async {
      final MethodChannelBackgroundTaskApi api =
          MethodChannelBackgroundTaskApi();
      expect(await api.begin(), isNull);
      await api.end(1); // does not throw
    });

    test('forPlatform picks the channel on iOS only', () {
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(
        BackgroundTaskApi.forPlatform(),
        isA<MethodChannelBackgroundTaskApi>(),
      );
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(BackgroundTaskApi.forPlatform(), isA<NoopBackgroundTaskApi>());
    });
  });
}

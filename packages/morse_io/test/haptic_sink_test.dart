import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';

final class _FakeHapticApi implements HapticApi {
  _FakeHapticApi({this.continuous = false});

  final bool continuous;
  final List<String> calls = <String>[];

  @override
  Future<bool> supportsContinuousVibration() async {
    calls.add('supports');
    return continuous;
  }

  @override
  Future<void> heavyImpact() async => calls.add('heavyImpact');

  @override
  Future<void> vibrate(Duration duration) async =>
      calls.add('vibrate(${duration.inMilliseconds})');

  @override
  Future<void> cancel() async => calls.add('cancel');
}

final class _ThrowingHapticApi implements HapticApi {
  @override
  Future<bool> supportsContinuousVibration() async => true;

  @override
  Future<void> heavyImpact() async => throw StateError('no channel');

  @override
  Future<void> vibrate(Duration duration) async =>
      throw StateError('no channel');

  @override
  Future<void> cancel() async => throw StateError('no channel');
}

/// Fails before a future exists, the way a misbehaving channel wrapper can.
final class _SyncThrowingHapticApi implements HapticApi {
  _SyncThrowingHapticApi({this.probeThrows = false});

  final bool probeThrows;

  @override
  Future<bool> supportsContinuousVibration() {
    if (probeThrows) throw StateError('no channel');
    return Future<bool>.value(true);
  }

  @override
  Future<void> heavyImpact() => throw StateError('no channel');

  @override
  Future<void> vibrate(Duration duration) => throw StateError('no channel');

  @override
  Future<void> cancel() => throw StateError('no channel');
}

final class _FakeForeground implements AppForeground {
  @override
  bool isForeground = true;
  void Function(bool foreground)? listener;
  int cancelled = 0;

  @override
  VoidCallback listen(void Function(bool foreground) onChange) {
    listener = onChange;
    return () => cancelled++;
  }

  void set(bool foreground) {
    isForeground = foreground;
    listener?.call(foreground);
  }
}

void main() {
  for (final platform in <TargetPlatform>[
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
  ]) {
    test('is a no-op on ${platform.name}', () async {
      final api = _FakeHapticApi(continuous: true);
      final sink = HapticSink(api: api, platformOverride: platform);
      expect(sink.isEnabled, isFalse);
      await sink.prepare();
      sink.on();
      sink.off();
      await sink.dispose();
      expect(api.calls, isEmpty);
    });
  }

  for (final platform in <TargetPlatform>[
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    test('impact strategy on ${platform.name}', () async {
      final api = _FakeHapticApi();
      final sink = HapticSink(api: api, platformOverride: platform);
      expect(sink.isEnabled, isTrue);
      await sink.prepare();
      expect(sink.usesContinuousVibration, isFalse);
      sink.on();
      sink.on(); // ignored while already on
      sink.off();
      await Future<void>.delayed(Duration.zero);
      expect(api.calls, <String>['supports', 'heavyImpact']);
    });

    test('continuous strategy on ${platform.name}', () async {
      final api = _FakeHapticApi(continuous: true);
      final sink = HapticSink(
        api: api,
        platformOverride: platform,
        maxPulse: const Duration(seconds: 2),
      );
      await sink.prepare();
      expect(sink.usesContinuousVibration, isTrue);
      sink.on();
      sink.off();
      sink.off(); // ignored while already off
      await Future<void>.delayed(Duration.zero);
      expect(api.calls, <String>['supports', 'vibrate(2000)', 'cancel']);
    });
  }

  test('preferContinuous: false forces impacts', () async {
    final api = _FakeHapticApi(continuous: true);
    final sink = HapticSink(
      api: api,
      platformOverride: TargetPlatform.android,
      preferContinuous: false,
    );
    await sink.prepare();
    sink.on();
    await Future<void>.delayed(Duration.zero);
    expect(api.calls, <String>['heavyImpact']);
  });

  test('platform-channel failures are swallowed', () async {
    final sink = HapticSink(
      api: _ThrowingHapticApi(),
      platformOverride: TargetPlatform.iOS,
    );
    await sink.prepare();
    sink.on();
    sink.off();
    await Future<void>.delayed(Duration.zero);
    // Reaching here without an unhandled async error is the assertion.
  });

  test('synchronous channel failures never reach the keyer either', () async {
    final sink = HapticSink(
      api: _SyncThrowingHapticApi(),
      platformOverride: TargetPlatform.android,
    );
    await sink.prepare();
    expect(sink.usesContinuousVibration, isTrue);
    expect(sink.on, returnsNormally);
    expect(sink.off, returnsNormally);
    await Future<void>.delayed(Duration.zero);
  });

  test('a capability probe that throws answers "impacts"', () async {
    final sink = HapticSink(
      api: _SyncThrowingHapticApi(probeThrows: true),
      platformOverride: TargetPlatform.iOS,
    );
    await expectLater(sink.prepare(), completes);
    expect(sink.usesContinuousVibration, isFalse);
  });

  group('mobile lifecycle', () {
    test('backgrounding cancels the running pulse and mutes key-downs until '
        'the app is back', () async {
      final api = _FakeHapticApi(continuous: true);
      final foreground = _FakeForeground();
      final sink = HapticSink(
        api: api,
        foreground: foreground,
        platformOverride: TargetPlatform.android,
        maxPulse: const Duration(seconds: 2),
      );
      await sink.prepare();
      sink.on();
      foreground.set(false);
      await Future<void>.delayed(Duration.zero);
      expect(api.calls, <String>['supports', 'vibrate(2000)', 'cancel']);
      // The player keeps running its timeline; the phone must stay still.
      sink.off();
      sink.on();
      sink.off();
      await Future<void>.delayed(Duration.zero);
      expect(api.calls.length, 3);
      foreground.set(true);
      sink.on();
      sink.off();
      await Future<void>.delayed(Duration.zero);
      expect(api.calls.sublist(3), <String>['vibrate(2000)', 'cancel']);
    });

    test('impacts are not fired in the background', () async {
      final api = _FakeHapticApi();
      final foreground = _FakeForeground();
      final sink = HapticSink(
        api: api,
        foreground: foreground,
        platformOverride: TargetPlatform.iOS,
      );
      await sink.prepare();
      foreground.set(false);
      sink.on();
      sink.off();
      await Future<void>.delayed(Duration.zero);
      expect(api.calls, <String>['supports']);
    });

    test('prepared in the background: silent until the foreground', () async {
      final api = _FakeHapticApi(continuous: true);
      final foreground = _FakeForeground()..isForeground = false;
      final sink = HapticSink(
        api: api,
        foreground: foreground,
        platformOverride: TargetPlatform.android,
      );
      await sink.prepare();
      sink.on();
      await Future<void>.delayed(Duration.zero);
      expect(api.calls, <String>['supports']);
      foreground.set(true);
      sink.on();
      await Future<void>.delayed(Duration.zero);
      expect(api.calls.last, 'vibrate(3000)');
    });

    test('dispose stops listening to the lifecycle', () async {
      final foreground = _FakeForeground();
      final sink = HapticSink(
        api: _FakeHapticApi(),
        foreground: foreground,
        platformOverride: TargetPlatform.android,
      );
      await sink.prepare();
      expect(foreground.listener, isNotNull);
      await sink.dispose();
      expect(foreground.cancelled, 1);
    });

    test('desktop never subscribes', () async {
      final foreground = _FakeForeground();
      final sink = HapticSink(
        api: _FakeHapticApi(),
        foreground: foreground,
        platformOverride: TargetPlatform.linux,
      );
      await sink.prepare();
      expect(foreground.listener, isNull);
      await sink.dispose();
    });
  });
}

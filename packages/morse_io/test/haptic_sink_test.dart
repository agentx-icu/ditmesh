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
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_dsp/testing.dart';
import 'package:ditmesh/ui/listen/listen_controller.dart';
import 'package:ditmesh/ui/listen/listen_settings.dart';

import 'fake_pcm_source.dart';

void _pushText(FakePcmSource source, String text, {double wpm = 20}) {
  final pcm = SyntheticMorse(snrDb: 20).renderText(text, wpm: wpm);
  for (final chunk in SyntheticMorse.toByteChunks(pcm, 960)) {
    source.push(chunk);
  }
}

/// Captures [debugPrint] output for the current test.
List<String> _captureDebugPrint() {
  final lines = <String>[];
  final previous = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) lines.add(message);
  };
  addTearDown(() => debugPrint = previous);
  return lines;
}

void main() {
  test('start/stop lifecycle and decoded text', () async {
    final source = FakePcmSource();
    final controller = ListenController(source: source);
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);

    expect(controller.status, ListenStatus.idle);
    await controller.start();
    expect(controller.status, ListenStatus.listening);
    expect(source.isStreaming, isTrue);

    _pushText(source, 'SOS');
    expect(controller.text.trim(), 'SOS');
    expect(controller.wpm, closeTo(20, 3));
    expect(controller.isToneLocked, isTrue);
    expect(controller.frequencyHz, closeTo(700, 15));
    expect(controller.meter.value.hasSignal, isTrue);
    expect(notifications, greaterThan(3));

    await controller.stop();
    expect(controller.status, ListenStatus.idle);
    expect(source.isStreaming, isFalse);
    expect(controller.text.trim(), 'SOS');
  });

  test('permission denied does not start the stream', () async {
    final source = FakePcmSource(permissionGranted: false);
    final controller = ListenController(source: source);
    addTearDown(controller.dispose);
    await controller.start();
    expect(controller.status, ListenStatus.failed);
    expect(
      controller.failure,
      const ListenFailure(ListenFailureKind.permissionDenied),
    );
    expect(source.startCalls, 0);
    expect(source.stopCalls, 0);
  });

  test(
    'a throwing permission query is a start failure, not a denial',
    () async {
      final logs = _captureDebugPrint();
      final source = FakePcmSource(
        permissionError: StateError('permission service unavailable'),
      );
      final controller = ListenController(source: source);
      addTearDown(controller.dispose);
      await controller.start();
      expect(controller.status, ListenStatus.failed);
      expect(controller.failure!.kind, ListenFailureKind.startFailed);
      expect(source.startCalls, 0);
      expect(logs.join('\n'), contains('permission service unavailable'));
    },
  );

  test('start failure with an empty device list is noInputDevice', () async {
    final logs = _captureDebugPrint();
    final source = FakePcmSource(
      startError: StateError('opaque platform error'),
      inputDevicePresent: false,
    );
    final controller = ListenController(source: source);
    addTearDown(controller.dispose);
    await controller.start();
    expect(controller.status, ListenStatus.failed);
    expect(controller.failure!.kind, ListenFailureKind.noInputDevice);
    expect(controller.failure!.detail, contains('opaque platform error'));
    expect(logs.join('\n'), contains('opaque platform error'));
    expect(source.isStreaming, isFalse);
  });

  test('start failure is never classified from the error text', () async {
    _captureDebugPrint();
    // Text that the old substring matcher took for "no microphone"; with
    // devices present it is a plain start failure.
    final source = FakePcmSource(startError: StateError('No input device'));
    final controller = ListenController(source: source);
    addTearDown(controller.dispose);
    await controller.start();
    expect(controller.failure!.kind, ListenFailureKind.startFailed);
    expect(source.hasInputDeviceCalls, 1);
  });

  test(
    'start failure when the device list is unknown is startFailed',
    () async {
      _captureDebugPrint();
      final source = FakePcmSource(
        startError: StateError('boom'),
        inputDevicePresent: null,
      );
      final controller = ListenController(source: source);
      addTearDown(controller.dispose);
      await controller.start();
      expect(controller.failure!.kind, ListenFailureKind.startFailed);
    },
  );

  test('a successful start never queries the device list', () async {
    final source = FakePcmSource(inputDevicePresent: false);
    final controller = ListenController(source: source);
    addTearDown(controller.dispose);
    await controller.start();
    expect(controller.status, ListenStatus.listening);
    expect(controller.failure, isNull);
    expect(source.hasInputDeviceCalls, 0);
  });

  test('a stream error is streamFailed and releases the source', () async {
    final logs = _captureDebugPrint();
    final source = FakePcmSource();
    final controller = ListenController(source: source);
    addTearDown(controller.dispose);
    await controller.start();
    _pushText(source, 'E');
    source.failStream(StateError('device unplugged'));
    expect(controller.status, ListenStatus.failed);
    expect(controller.failure!.kind, ListenFailureKind.streamFailed);
    expect(source.isStreaming, isFalse);
    expect(logs.join('\n'), contains('device unplugged'));

    // Retrying clears the failure.
    await controller.start();
    expect(controller.status, ListenStatus.listening);
    expect(controller.failure, isNull);
  });

  test('stream ending on its own returns to idle', () async {
    final source = FakePcmSource();
    final controller = ListenController(source: source);
    addTearDown(controller.dispose);
    await controller.start();
    await source.endStream();
    expect(controller.status, ListenStatus.idle);
  });

  test('changing block size keeps the text decoded so far', () async {
    final source = FakePcmSource();
    final controller = ListenController(source: source);
    addTearDown(controller.dispose);
    await controller.start();
    _pushText(source, 'SOS');
    controller.updateSettings(controller.settings.copyWith(blockSize: 128));
    expect(controller.text.trim(), 'SOS');
    _pushText(source, 'CQ');
    expect(controller.text.trim(), 'SOS CQ');
    expect(controller.settings.blockSize, 128);
  });

  test('manual frequency turns auto-tune off and back on', () async {
    final source = FakePcmSource();
    final controller = ListenController(source: source);
    addTearDown(controller.dispose);
    controller.setManualFrequency(650);
    expect(controller.settings.autoTune, isFalse);
    expect(controller.settings.manualHz, 650);
    expect(controller.frequencyHz, 650);
    controller.setAutoTune(true);
    expect(controller.settings.autoTune, isTrue);
  });

  test('clear empties text and forgets the background note', () async {
    final source = FakePcmSource();
    final controller = ListenController(source: source);
    addTearDown(controller.dispose);
    await controller.start();
    _pushText(source, 'E');
    await controller.stop(fromBackground: true);
    expect(controller.stoppedInBackground, isTrue);
    controller.clear();
    expect(controller.text, isEmpty);
    expect(controller.stoppedInBackground, isFalse);
  });

  test('owned source is disposed with the controller', () async {
    final source = FakePcmSource();
    final controller = ListenController(source: source, ownsSource: true);
    await controller.start();
    controller.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(source.isStreaming, isFalse);
    expect(source.disposed, isTrue);
  });

  test('settings value semantics', () {
    const a = ListenSettings();
    expect(a.copyWith(), a);
    expect(a.copyWith(minElementMs: 20), isNot(a));
    expect(a.blockMs(48000), closeTo(5.33, 0.01));
  });

  group('a stop while start is pending invalidates that attempt', () {
    test('device query resolving after stop and restart is ignored', () async {
      _captureDebugPrint();
      final gate = Completer<void>();
      final source = FakePcmSource(
        startError: StateError('opaque'),
        inputDevicePresent: false,
      )..inputDeviceGate = gate;
      final controller = ListenController(source: source);
      addTearDown(controller.dispose);

      final first = controller.start();
      await pumpEventQueue();
      expect(source.hasInputDeviceCalls, 1); // parked on the gate
      await controller.stop();
      expect(controller.status, ListenStatus.idle);

      source.startError = null;
      await controller.start();
      expect(controller.status, ListenStatus.listening);
      final stopsBefore = source.stopCalls;

      gate.complete();
      await first;
      expect(controller.status, ListenStatus.listening);
      expect(controller.failure, isNull);
      expect(source.isStreaming, isTrue);
      expect(source.stopCalls, stopsBefore);
      _pushText(source, 'E');
      expect(controller.text.trim(), 'E');
    });

    test('permission answer arriving after stop does not start', () async {
      final gate = Completer<void>();
      final source = FakePcmSource()..permissionGate = gate;
      final controller = ListenController(source: source);
      addTearDown(controller.dispose);

      final first = controller.start();
      await controller.stop();
      gate.complete();
      await first;
      expect(controller.status, ListenStatus.idle);
      expect(source.startCalls, 0);
    });

    test('permission error arriving after stop is not reported', () async {
      final gate = Completer<void>();
      final source = FakePcmSource(permissionError: StateError('late'))
        ..permissionGate = gate;
      final controller = ListenController(source: source);
      addTearDown(controller.dispose);

      final first = controller.start();
      await controller.stop();
      gate.complete();
      await first;
      expect(controller.status, ListenStatus.idle);
      expect(controller.failure, isNull);
    });

    test('a capture that opens after stop is released, not adopted', () async {
      final gate = Completer<void>();
      final source = FakePcmSource()..startGate = gate;
      final controller = ListenController(source: source);
      addTearDown(controller.dispose);

      final first = controller.start();
      await pumpEventQueue();
      expect(source.startCalls, 1);
      await controller.stop();
      gate.complete();
      await first;
      await pumpEventQueue();
      expect(controller.status, ListenStatus.idle);
      expect(source.isStreaming, isFalse);
    });

    test('a stale capture does not stop a newer one', () async {
      final gate = Completer<void>();
      final source = FakePcmSource(startError: StateError('opaque'))
        ..startGate = gate;
      final controller = ListenController(source: source);
      addTearDown(controller.dispose);
      _captureDebugPrint();

      final first = controller.start();
      await pumpEventQueue();
      await controller.stop();
      source.startError = null;
      await controller.start();
      expect(controller.status, ListenStatus.listening);
      final stopsBefore = source.stopCalls;

      // The first attempt's start fails late: no device query, no failure.
      gate.complete();
      await first;
      expect(controller.status, ListenStatus.listening);
      expect(controller.failure, isNull);
      expect(source.stopCalls, stopsBefore);
      expect(source.hasInputDeviceCalls, 0);
    });
  });
}

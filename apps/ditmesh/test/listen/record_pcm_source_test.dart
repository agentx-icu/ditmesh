import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:ditmesh/ui/listen/listen_controller.dart';
import 'package:ditmesh/ui/listen/record_pcm_source.dart';
import 'package:record/record.dart';

/// Stand-in for the plugin's [AudioRecorder]: the test drives the PCM and
/// state streams by hand. Members the adapter does not use fall through to
/// [noSuchMethod] and fail loudly.
final class _FakeRecorder implements AudioRecorder {
  StreamController<RecordState> states =
      StreamController<RecordState>.broadcast();
  StreamController<Uint8List>? pcm;
  Object? startError;
  Object? listError;
  List<InputDevice> devices = const <InputDevice>[];
  int stopCalls = 0;
  bool disposed = false;

  @override
  Future<bool> hasPermission({bool request = true}) async => true;

  @override
  Stream<RecordState> onStateChanged() => states.stream;

  @override
  Future<Stream<Uint8List>> startStream(RecordConfig config) async {
    final error = startError;
    if (error != null) throw error;
    pcm = StreamController<Uint8List>();
    return pcm!.stream;
  }

  @override
  Future<List<InputDevice>> listInputDevices() async {
    final error = listError;
    if (error != null) throw error;
    return devices;
  }

  @override
  Future<String?> stop() async {
    stopCalls++;
    await pcm?.close();
    pcm = null;
    return null;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await states.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _CountingSession implements AudioSessionApi {
  int restores = 0;

  @override
  Future<void> configureForPlayback() async => restores++;
}

Future<Stream<Uint8List>> _start(RecordPcmSource source) =>
    source.start(sampleRate: 48000, channels: 1);

void main() {
  late _FakeRecorder recorder;
  late RecordPcmSource source;

  setUp(() {
    recorder = _FakeRecorder();
    source = RecordPcmSource(recorder: recorder);
  });

  test('PCM chunks pass through', () async {
    final stream = await _start(source);
    final chunks = <Uint8List>[];
    final sub = stream.listen(chunks.add);
    addTearDown(sub.cancel);
    recorder.pcm!.add(Uint8List(4));
    await pumpEventQueue();
    expect(chunks, hasLength(1));
  });

  test('a state-stream error becomes an error on the PCM stream', () async {
    final stream = await _start(source);
    final errors = <Object>[];
    final sub = stream.listen((_) {}, onError: errors.add);
    addTearDown(sub.cancel);
    recorder.states.add(RecordState.record);
    recorder.states.addError(PlatformException(code: '-1'));
    await pumpEventQueue();
    expect(errors.single, isA<PlatformException>());
  });

  test('the platform stopping on its own ends the PCM stream', () async {
    final stream = await _start(source);
    var done = false;
    final sub = stream.listen((_) {}, onDone: () => done = true);
    addTearDown(sub.cancel);
    recorder.states.add(RecordState.record);
    recorder.states.add(RecordState.stop);
    await pumpEventQueue();
    expect(done, isTrue);
    expect(recorder.states.hasListener, isFalse);
  });

  group('playback session', () {
    late _CountingSession session;

    setUp(() {
      session = _CountingSession();
      source = RecordPcmSource(recorder: recorder, audioSession: session);
    });

    test('a capture the platform ends restores it without stop()', () async {
      // Regression (merge with the _CaptureSession rewrite): a platform-side
      // stop ends the stream and the controller goes idle without calling
      // stop(), so iOS stayed in playAndRecord.
      final stream = await _start(source);
      final sub = stream.listen((_) {});
      addTearDown(sub.cancel);
      recorder.states
        ..add(RecordState.record)
        ..add(RecordState.stop);
      await pumpEventQueue();
      expect(session.restores, 1);
      expect(recorder.stopCalls, 0, reason: 'the platform already stopped');
      await source.stop();
      expect(session.restores, 1, reason: 'restored once per capture');
    });

    test(
      'an explicit stop restores once and the end is not double-counted',
      () async {
        final stream = await _start(source);
        final sub = stream.listen((_) {});
        await source.stop();
        await sub.cancel();
        await pumpEventQueue();
        expect(session.restores, 1);
        expect(recorder.stopCalls, 1);
      },
    );

    test('an old capture ending does not stop a newer one', () async {
      final first = await _start(source);
      final firstSub = first.listen((_) {});
      addTearDown(firstSub.cancel);
      final second = await _start(source);
      final secondSub = second.listen((_) {});
      addTearDown(secondSub.cancel);
      await pumpEventQueue();
      expect(recorder.stopCalls, 0, reason: 'the restart replaced capture 1');
      expect(session.restores, 0);
      await source.stop();
      expect(session.restores, 1);
    });
  });

  test('a late stop from the previous capture is ignored', () async {
    final stream = await _start(source);
    var done = false;
    final sub = stream.listen((_) {}, onDone: () => done = true);
    addTearDown(sub.cancel);
    recorder.states.add(RecordState.stop); // before this capture's record
    await pumpEventQueue();
    expect(done, isFalse);
    expect(recorder.states.hasListener, isTrue);
  });

  test('stop and dispose cancel the state subscription', () async {
    final stream = await _start(source);
    final sub = stream.listen((_) {});
    addTearDown(sub.cancel);
    expect(recorder.states.hasListener, isTrue);
    await source.stop();
    expect(recorder.states.hasListener, isFalse);
    expect(recorder.stopCalls, 1);

    await _start(source);
    expect(recorder.states.hasListener, isTrue);
    await source.dispose();
    expect(recorder.states.hasListener, isFalse);
    expect(recorder.disposed, isTrue);
  });

  test('a failed start rethrows and leaves no state subscription', () async {
    recorder.startError = PlatformException(code: 'record');
    await expectLater(_start(source), throwsA(isA<PlatformException>()));
    expect(recorder.states.hasListener, isFalse);
  });

  test('hasInputDevice reflects the device list, null when unknown', () async {
    expect(await source.hasInputDevice(), isFalse);
    recorder.devices = const <InputDevice>[InputDevice(id: '1', label: 'Mic')];
    expect(await source.hasInputDevice(), isTrue);
    final previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {};
    addTearDown(() => debugPrint = previous);
    recorder.listError = MissingPluginException();
    expect(await source.hasInputDevice(), isNull);
  });

  test('an Android-style state error fails a listening controller', () async {
    final previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {};
    addTearDown(() => debugPrint = previous);
    final controller = ListenController(source: source);
    addTearDown(controller.dispose);
    await controller.start();
    expect(controller.status, ListenStatus.listening);
    recorder.states.add(RecordState.record);
    recorder.states.addError(
      PlatformException(code: '-1', message: 'ERROR_DEAD_OBJECT'),
    );
    await pumpEventQueue();
    expect(controller.status, ListenStatus.failed);
    expect(controller.failure!.kind, ListenFailureKind.streamFailed);
    expect(recorder.states.hasListener, isFalse);
    expect(recorder.stopCalls, 1);
  });
}

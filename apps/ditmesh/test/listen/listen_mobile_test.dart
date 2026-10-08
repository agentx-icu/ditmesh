import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/ui/listen/listen_screen.dart';
import 'package:ditmesh/ui/listen/record_pcm_source.dart';
import 'package:record/record.dart';

import 'fake_pcm_source.dart';

final S en = lookupS(const Locale('en'));

final class _FakeWake implements ScreenWakeApi {
  final List<bool> calls = <bool>[];

  @override
  Future<void> keepOn(bool on) async => calls.add(on);
}

final class _FakeSession implements AudioSessionApi {
  _FakeSession(this.log);

  final List<String> log;

  /// When set, [configureForPlayback] holds until it completes.
  Completer<void>? gate;

  @override
  Future<void> configureForPlayback() async {
    log.add('session');
    await gate?.future;
    log.add('session done');
  }
}

/// Only what [RecordPcmSource] calls.
final class _FakeRecorder implements AudioRecorder {
  _FakeRecorder(this.log);

  final List<String> log;

  /// When set, [stop] holds until it completes.
  Completer<void>? stopGate;

  @override
  Stream<RecordState> onStateChanged() => const Stream<RecordState>.empty();

  @override
  Future<Stream<Uint8List>> startStream(RecordConfig config) async {
    log.add('start');
    // Open until stopped, like the plugin's: a finished stream would read
    // as the platform ending the capture on its own.
    return (_pcm = StreamController<Uint8List>()).stream;
  }

  StreamController<Uint8List>? _pcm;

  @override
  Future<String?> stop() async {
    log.add('stop');
    await stopGate?.future;
    unawaited(_pcm?.close());
    _pcm = null;
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(
  WidgetTester tester,
  FakePcmSource source,
  ScreenWakeApi wake,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: const Locale('en'),
      home: ListenScreen(source: source, screenWake: wake),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('keeps the screen on only while capturing', (tester) async {
    // Without this the phone's auto-lock backgrounds the app during a
    // hands-free session and the lifecycle stop ends the capture.
    final wake = _FakeWake();
    await _pump(tester, FakePcmSource(), wake);
    expect(wake.calls, isEmpty);
    await tester.tap(find.text(en.listenStart));
    await tester.pumpAndSettle();
    expect(wake.calls, <bool>[true]);
    await tester.tap(find.text(en.listenStop));
    await tester.pumpAndSettle();
    expect(wake.calls, <bool>[true, false]);
    await tester.pumpWidget(const SizedBox());
    expect(wake.calls, <bool>[true, false], reason: 'nothing left to release');
  });

  testWidgets('releases the screen when capture stops in the background or '
      'the screen closes', (tester) async {
    final wake = _FakeWake();
    await _pump(tester, FakePcmSource(), wake);
    await tester.tap(find.text(en.listenStart));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pumpAndSettle();
    expect(wake.calls, <bool>[true, false]);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.listenStart));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    expect(wake.calls, <bool>[true, false, true, false]);
  });

  test('RecordPcmSource restores the playback session after capture', () async {
    // iOS: the record plugin leaves the session in playAndRecord, which
    // routes a later sidetone over Bluetooth HFP and stops other audio.
    final log = <String>[];
    final source = RecordPcmSource(
      recorder: _FakeRecorder(log),
      audioSession: _FakeSession(log),
    );
    await source.stop();
    expect(log, <String>['stop'], reason: 'nothing was captured');
    await source.start(sampleRate: 48000, channels: 1);
    await source.stop();
    await source.stop();
    expect(log, <String>[
      'stop',
      'start',
      'stop',
      'session',
      'session done',
      'stop',
    ]);
  });

  test('a capture restarted during a restore waits for it', () async {
    final log = <String>[];
    final session = _FakeSession(log)..gate = Completer<void>();
    final source = RecordPcmSource(
      recorder: _FakeRecorder(log),
      audioSession: session,
    );
    await source.start(sampleRate: 48000, channels: 1);
    final stopping = source.stop();
    await pumpEventQueue();
    final restarting = source.start(sampleRate: 48000, channels: 1);
    await pumpEventQueue();
    expect(log.last, 'session', reason: 'start must not overtake the restore');
    session.gate!.complete();
    await stopping;
    await restarting;
    expect(log, <String>['start', 'stop', 'session', 'session done', 'start']);
  });

  test('a capture restarted while the recorder is stopping still restores '
      'the session when it stops', () async {
    // Regression: the restart used to slip in while `_recorder.stop()` was
    // pending; the old stop then cleared the restarted capture's flag, so
    // stopping the restart skipped the restore and iOS stayed in
    // playAndRecord.
    final log = <String>[];
    final recorder = _FakeRecorder(log)..stopGate = Completer<void>();
    final source = RecordPcmSource(
      recorder: recorder,
      audioSession: _FakeSession(log),
    );
    await source.start(sampleRate: 48000, channels: 1);
    final stopping = source.stop();
    await pumpEventQueue();
    final restarting = source.start(sampleRate: 48000, channels: 1);
    await pumpEventQueue();
    expect(log, <String>['start', 'stop'], reason: 'start waits for stop');
    recorder.stopGate!.complete();
    recorder.stopGate = null;
    await stopping;
    await restarting;
    await source.stop();
    expect(log, <String>[
      'start',
      'stop',
      'session',
      'session done',
      'start',
      'stop',
      'session',
      'session done',
    ]);
  });
}

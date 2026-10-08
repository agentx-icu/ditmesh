import 'dart:async';
import 'dart:typed_data';

import 'package:ditmesh/ui/listen/pcm_source.dart';

/// Test double for the microphone: the test pushes PCM bytes by hand.
///
/// The stream is synchronous so a `push` is decoded before the call
/// returns, which keeps widget tests free of timing.
final class FakePcmSource implements PcmSource {
  FakePcmSource({
    this.permissionGranted = true,
    this.permissionError,
    this.startError,
    this.inputDevicePresent = true,
  });

  /// Answer for [hasPermission].
  bool permissionGranted;

  /// When set, [hasPermission] throws it (the permission query failed).
  Object? permissionError;

  /// When set, [start] throws it.
  Object? startError;

  /// Answer for [hasInputDevice]; `null` means the platform cannot tell.
  bool? inputDevicePresent;
  int hasInputDeviceCalls = 0;

  /// When set, the next call of the matching method waits for the gate
  /// (consumed by that call), to model a slow platform round trip.
  Completer<void>? permissionGate;
  Completer<void>? startGate;
  Completer<void>? inputDeviceGate;

  StreamController<Uint8List>? _controller;
  int startCalls = 0;
  int stopCalls = 0;
  bool disposed = false;
  int? lastSampleRate;
  int? lastChannels;

  bool get isStreaming => _controller != null;

  @override
  Future<bool> hasPermission() async {
    await _pass(permissionGate, () => permissionGate = null);
    final error = permissionError;
    if (error != null) throw error;
    return permissionGranted;
  }

  @override
  Future<bool?> hasInputDevice() async {
    hasInputDeviceCalls++;
    final answer = inputDevicePresent;
    await _pass(inputDeviceGate, () => inputDeviceGate = null);
    return answer;
  }

  @override
  Future<Stream<Uint8List>> start({
    required int sampleRate,
    required int channels,
  }) async {
    startCalls++;
    lastSampleRate = sampleRate;
    lastChannels = channels;
    final error = startError;
    await _pass(startGate, () => startGate = null);
    if (error != null) throw error;
    _controller = StreamController<Uint8List>(sync: true);
    return _controller!.stream;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    // The controller is synchronous, so close() is immediate; its future is
    // the root-zone `_nullFuture` once the listener cancelled, which never
    // resumes under FakeAsync, so it must not be awaited.
    unawaited(_controller?.close());
    _controller = null;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await stop();
  }

  static Future<void> _pass(Completer<void>? gate, void Function() consume) {
    if (gate == null) return Future<void>.value();
    consume();
    return gate.future;
  }

  /// Delivers one chunk of little-endian PCM16 bytes to the listener.
  void push(Uint8List bytes) {
    final controller = _controller;
    if (controller == null) {
      throw StateError('FakePcmSource.push called while not streaming');
    }
    controller.add(bytes);
  }

  /// Reports an error on the PCM stream, as a platform would mid-capture.
  void failStream(Object error) {
    final controller = _controller;
    if (controller == null) {
      throw StateError('FakePcmSource.failStream called while not streaming');
    }
    controller.addError(error);
  }

  /// Ends the stream as the OS would when the device disappears.
  Future<void> endStream() async {
    unawaited(_controller?.close());
    _controller = null;
  }
}

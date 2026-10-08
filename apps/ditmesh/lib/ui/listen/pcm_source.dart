import 'dart:typed_data';

/// A source of raw little-endian signed 16-bit PCM, normally the microphone.
///
/// The Listen screen talks only to this interface so widget tests can push
/// synthetic audio through a fake and the production implementation
/// ([RecordPcmSource]) can be swapped without touching the UI.
abstract interface class PcmSource {
  /// Whether capture is allowed. Implementations may prompt the user (this
  /// is what the `record` plugin does on Android and iOS).
  Future<bool> hasPermission();

  /// Starts capture and returns the byte stream. Chunks are interleaved
  /// 16-bit little-endian frames with [channels] channels at [sampleRate].
  /// Throws when no input device is available or the platform refuses.
  Future<Stream<Uint8List>> start({
    required int sampleRate,
    required int channels,
  });

  /// Whether the platform reports at least one audio input device: `true`
  /// or `false` when it can enumerate devices, `null` when it cannot tell
  /// (unsupported, or the query itself failed). Must not throw.
  ///
  /// Only consulted after [start] has thrown, to tell "no microphone" apart
  /// from other start failures without parsing the platform's error text.
  Future<bool?> hasInputDevice();

  /// Stops capture. Safe to call when not capturing.
  Future<void> stop();

  /// Releases platform resources. The source is unusable afterwards.
  Future<void> dispose();
}

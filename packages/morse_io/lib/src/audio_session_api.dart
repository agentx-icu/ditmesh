import 'dart:io' show Platform;

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

/// The OS audio-session state Morse output needs.
///
/// Only iOS has such a thing to set: `flutter_soloud` 4.x starts miniaudio
/// with `sessionCategory = none` and never activates the session, leaving
/// both to the app. Left alone, iOS runs the app in the default
/// `SoloAmbient` category, where the ring/silent switch and screen lock mute
/// the sidetone. The microphone plugin (`record`) also switches the session
/// to `playAndRecord` and leaves it there after capture stops.
abstract interface class AudioSessionApi {
  /// Puts the shared session in the playback state. Idempotent; never throws
  /// (a failure only means the OS default category stays in effect).
  Future<void> configureForPlayback();
}

/// Production [AudioSessionApi]: on iOS, category `playback` with
/// `mixWithOthers`, then activate. A no-op on every other platform.
///
/// * `playback`: the tone sounds with the silent switch on, like any
///   instrument or learning app. (Background playback is not implied: the
///   sinks stop their voice while the app is in the background, see
///   `SidetoneSink`.)
/// * `mixWithOthers`: opening a screen that prepares a sidetone must not stop
///   the user's music or podcast; the session is also never interrupted by a
///   non-mixable app starting.
final class PlatformAudioSessionApi implements AudioSessionApi {
  const PlatformAudioSessionApi();

  @override
  Future<void> configureForPlayback() async {
    if (kIsWeb || !Platform.isIOS) {
      return;
    }
    try {
      final session = AVAudioSession();
      await session.setCategory(
        AVAudioSessionCategory.playback,
        AVAudioSessionCategoryOptions.mixWithOthers,
        AVAudioSessionMode.defaultMode,
      );
      await session.setActive(true);
    } on Object catch (e) {
      // A call in progress can refuse activation; the engine restarts the
      // device (and activates the session) on the next key-down anyway.
      debugPrint('morse_io: audio session setup failed: $e');
    }
  }
}

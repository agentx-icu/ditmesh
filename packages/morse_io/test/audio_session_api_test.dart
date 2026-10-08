import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';

/// Records what [PlatformAudioSessionApi] hands to the plugin. Only the two
/// calls the adapter makes are implemented.
final class _RecordingSession implements AVAudioSession {
  final List<String> calls = <String>[];
  AVAudioSessionCategory? seenCategory;
  AVAudioSessionCategoryOptions? seenOptions;
  AVAudioSessionMode? seenMode;
  AVAudioSessionRouteSharingPolicy? seenPolicy;
  Object? activateError;

  @override
  Future<void> setCategory(
    AVAudioSessionCategory? category, [
    AVAudioSessionCategoryOptions? options,
    AVAudioSessionMode? mode,
    AVAudioSessionRouteSharingPolicy? policy,
  ]) async {
    calls.add('setCategory');
    seenCategory = category;
    seenOptions = options;
    seenMode = mode;
    seenPolicy = policy;
  }

  @override
  Future<bool> setActive(
    bool active, {
    AVAudioSessionSetActiveOptions? avOptions,
  }) async {
    calls.add('setActive($active)');
    final error = activateError;
    if (error != null) throw error;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('iOS: category playback with mixWithOthers in the default mode, '
      'then activate', () async {
    final session = _RecordingSession();
    final api = PlatformAudioSessionApi(
      platformOverride: TargetPlatform.iOS,
      openSession: () => session,
    );
    await api.configureForPlayback();
    expect(session.calls, <String>['setCategory', 'setActive(true)']);
    // The silent switch must not mute the tone...
    expect(session.seenCategory, AVAudioSessionCategory.playback);
    // ...and preparing a sidetone must not stop the user's music.
    expect(session.seenOptions, AVAudioSessionCategoryOptions.mixWithOthers);
    expect(session.seenMode, AVAudioSessionMode.defaultMode);
    expect(session.seenPolicy, isNull);
  });

  test('activation refused (call in progress) never throws', () async {
    final session = _RecordingSession()
      ..activateError = PlatformException(code: '!act');
    final api = PlatformAudioSessionApi(
      platformOverride: TargetPlatform.iOS,
      openSession: () => session,
    );
    await api.configureForPlayback();
    expect(session.calls, <String>['setCategory', 'setActive(true)']);
  });

  test('a session that cannot be opened never throws', () async {
    // The plugin's own factory refuses off iOS; the adapter must swallow
    // that like any other session failure.
    final api = PlatformAudioSessionApi(
      platformOverride: TargetPlatform.iOS,
      openSession: () => throw StateError('no session here'),
    );
    await api.configureForPlayback();
  });

  for (final platform in <TargetPlatform>[
    TargetPlatform.android,
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
  ]) {
    test('${platform.name} never opens the session', () async {
      var opened = 0;
      final api = PlatformAudioSessionApi(
        platformOverride: platform,
        openSession: () {
          opened++;
          return _RecordingSession();
        },
      );
      await api.configureForPlayback();
      expect(opened, 0);
    });
  }
}

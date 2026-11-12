import 'dart:io';

import 'package:ditmesh/di/app_preferences.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';

final class _FailingStore implements KeyValueStore {
  @override
  String? getString(String key) => null;

  @override
  Future<void> setString(String key, String value) async =>
      throw const FileSystemException(
        'PRIVATE_PREFERENCE_MARKER',
        '/private/account/data',
      );

  @override
  Future<void> remove(String key) async => throw const FileSystemException(
    'PRIVATE_PREFERENCE_MARKER',
    '/private/account/data',
  );
}

void main() {
  test('product-policy CI selects actual release-mode constants', () {
    if (const bool.fromEnvironment('DITMESH_TEST_PRODUCT_POLICY')) {
      expect(kReleaseMode, isTrue);
      expect(kDebugMode, isFalse);
    }
  });

  test(
    'the actual preference catch preserves failure without release raw logs',
    () async {
      final previous = debugPrint;
      final output = <String?>[];
      final identity = FakeIdentityService();
      final preferences = AppPreferences(
        _FailingStore(),
        backendLabel: 'test',
        identity: identity,
      );
      addTearDown(() async {
        preferences.dispose();
        await identity.dispose();
        debugPrint = previous;
      });
      debugPrint = (message, {wrapWidth}) => output.add(message);
      preferences.playback.wpm = 23;
      await expectLater(preferences.flush(), throwsStateError);
      if (kDebugMode) {
        expect(output.join('\n'), contains('PRIVATE_PREFERENCE_MARKER'));
      } else {
        expect(output, isEmpty);
      }
    },
  );

  test(
    'shared audio and wake failures obey the compiled console policy',
    () async {
      final previous = debugPrint;
      final output = <String?>[];
      addTearDown(() => debugPrint = previous);
      debugPrint = (message, {wrapWidth}) => output.add(message);
      const error = FileSystemException(
        'PRIVATE_DEVICE_MARKER',
        '/private/device',
      );
      await PlatformAudioSessionApi(
        platformOverride: TargetPlatform.iOS,
        openSession: () => throw error,
      ).configureForPlayback();
      await SerializedScreenWake((_) async => throw error).keepOn(true);
      if (kDebugMode) {
        expect(output, hasLength(2));
        expect(
          output.every((line) => line!.contains('PRIVATE_DEVICE_MARKER')),
          isTrue,
        );
      } else {
        expect(output, isEmpty);
      }
    },
  );
}

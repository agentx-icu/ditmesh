import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/app_scope.dart';
import 'package:ditmesh/di/app_preferences.dart';
import 'package:ditmesh/di/fake_backend_factory.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/notifications/notification_prefs.dart';
import 'package:ditmesh/ui/appearance/ui_style.dart';
import 'package:ditmesh/ui/chat/morse_playback_settings.dart';
import 'package:ditmesh/ui/chat/input_mode.dart';
import 'package:ditmesh/ui/listen/listen_settings.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:provider/provider.dart';

final class _FailingPlaybackStore implements KeyValueStore {
  final _delegate = InMemoryKeyValueStore();
  bool failPlayback = true;
  bool failRemove = false;
  @override
  String? getString(String key) => _delegate.getString(key);
  @override
  Future<void> remove(String key) => failRemove
      ? Future<void>.error(StateError('disk unavailable'))
      : _delegate.remove(key);
  @override
  Future<void> setString(String key, String value) =>
      failPlayback && key == 'chat.playback'
      ? Future<void>.error(StateError('disk unavailable'))
      : _delegate.setString(key, value);
}

void main() {
  test(
    'an unrelated successful save cannot hide a failed preference write',
    () async {
      final identity = FakeIdentityService();
      final store = _FailingPlaybackStore();
      final prefs = AppPreferences(
        store,
        backendLabel: 'test',
        identity: identity,
      );
      prefs.playback.wpm = 23;
      await pumpEventQueue();
      prefs.notifications.sound = false;
      await pumpEventQueue();
      await expectLater(prefs.flush(), throwsStateError);
      prefs.dispose();
      await identity.dispose();
    },
  );
  test(
    'flush retries a failed unchanged preference after storage recovers',
    () async {
      final identity = FakeIdentityService();
      final store = _FailingPlaybackStore();
      final prefs = AppPreferences(
        store,
        backendLabel: 'test',
        identity: identity,
      );
      prefs.playback.wpm = 23;
      await pumpEventQueue();
      await expectLater(prefs.flush(), throwsStateError);
      store.failPlayback = false;
      await prefs.flush();
      expect(jsonDecode(store.getString('chat.playback')!)['wpm'], 23);
      prefs.dispose();
      await identity.dispose();
    },
  );

  test(
    'failed mute removal retries without leaking into a replacement',
    () async {
      final identity = FakeIdentityService();
      final first = await identity.create(displayName: 'first');
      final store = _FailingPlaybackStore()..failPlayback = false;
      final prefs = AppPreferences(
        store,
        backendLabel: 'test',
        identity: identity,
      );
      prefs.notifications.setMuted('c2c_peer', true);
      await prefs.flush();
      final backup = await identity.exportBackup();
      await prefs.prepareForReplacement();
      expect(
        store.getString('notifications.muted.${first.publicKey}'),
        isNotNull,
      );
      store.failRemove = true;
      await identity.deleteIdentity();
      await identity.importBackup(backup);
      expect(identity.current!.publicKey, first.publicKey);
      await pumpEventQueue();
      expect(prefs.notifications.mutedConversations, isEmpty);
      await expectLater(prefs.flush(), throwsStateError);
      store.failRemove = false;
      await prefs.flush();
      expect(store.getString('notifications.muted.${first.publicKey}'), isNull);
      prefs.dispose();
      await identity.dispose();
    },
  );

  late Directory dir;
  late File file;
  late NotificationPrefs notifications;
  late MorsePlaybackSettings playback;
  late AppPreferences preferences;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('ditmesh_app_preferences_');
    file = File('${dir.path}/settings.json');
  });
  tearDown(() async => dir.delete(recursive: true));

  Future<void> mount(WidgetTester tester, KeyValueStore store) async {
    await tester.pumpWidget(
      AppScope(
        factory: FakeBackendFactory(),
        localeStore: store,
        child: Builder(
          builder: (context) {
            preferences = context.read<AppPreferences>();
            notifications = context.read<NotificationPrefs>();
            playback = context.read<MorsePlaybackSettings>();
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Future<void> restart(WidgetTester tester) async {
    await tester.runAsync(preferences.flush);
    await tester.pumpWidget(const SizedBox());
    final reopened = await tester.runAsync(() async {
      await pumpEventQueue(times: 30);
      return JsonFileKeyValueStore.open(file);
    });
    await mount(tester, reopened!);
  }

  test(
    'reference and microphone choices restore from a fresh file store',
    () async {
      final identity = FakeIdentityService();
      final store = await JsonFileKeyValueStore.open(file);
      final first = AppPreferences(
        store,
        backendLabel: 'test',
        identity: identity,
      );
      first.reference.wpm = 30;
      first.reference.farnsworthWpm = 14;
      first.reference.toneHz = 600;
      first.listen.update(
        const ListenSettings(
          blockSize: 512,
          minElementMs: 24,
          autoTune: false,
          manualHz: 800,
        ),
      );
      await first.flush();
      first.dispose();
      final second = AppPreferences(
        await JsonFileKeyValueStore.open(file),
        backendLabel: 'test',
        identity: identity,
      );
      expect(second.reference.wpm, 30);
      expect(second.reference.farnsworthWpm, 14);
      expect(second.reference.toneHz, 600);
      expect(
        second.listen.settings,
        const ListenSettings(
          blockSize: 512,
          minElementMs: 24,
          autoTune: false,
          manualHz: 800,
        ),
      );
      second.dispose();
      await identity.dispose();
    },
  );

  test(
    'invalid options use defaults without dropping valid sibling fields',
    () async {
      final identity = FakeIdentityService();
      final prefs = AppPreferences(
        InMemoryKeyValueStore({
          'app.theme': 'unknown',
          'notifications': '{"enabled":"no","showText":false}',
          'chat.playback': '{"wpm":999,"farnsworthWpm":500,"toneHz":"bad"}',
          'reference.playback': '[1,2]',
          'listen.decoder':
              '{"blockSize":1024,"minElementMs":-10,"autoTune":false}',
        }),
        backendLabel: 'test',
        identity: identity,
      );
      expect(prefs.settings.themeMode, ThemeMode.system);
      expect(prefs.notifications.enabled, isTrue);
      expect(prefs.notifications.showText, isFalse);
      expect(prefs.playback.wpm, 40);
      expect(prefs.playback.farnsworthWpm, 40);
      expect(prefs.playback.toneHz, 700);
      expect(prefs.reference.wpm, 15);
      expect(prefs.listen.settings.blockSize, 256);
      expect(prefs.listen.settings.minElementMs, 4);
      expect(prefs.listen.settings.autoTune, isFalse);
      prefs.dispose();
      await identity.dispose();
    },
  );

  test(
    'conversation mutes are isolated by identity and removed on delete',
    () async {
      final store = InMemoryKeyValueStore();
      final identity = FakeIdentityService(seed: 7);
      final firstId = await identity.create(displayName: 'first');
      final prefs = AppPreferences(
        store,
        backendLabel: 'test',
        identity: identity,
      );
      prefs.notifications.setMuted('group_shared', true);
      await prefs.flush();
      expect(
        store.getString('notifications.muted.${firstId.publicKey}'),
        isNotNull,
      );
      final second = FakeIdentityService(seed: 9);
      await second.create(displayName: 'second');
      await identity.importBackup(await second.exportBackup());
      await pumpEventQueue();
      expect(prefs.notifications.isMuted('group_shared'), isFalse);
      prefs.notifications.setMuted('c2c_shared', true);
      await prefs.flush();
      final secondKey = identity.current!.publicKey;
      await identity.deleteIdentity();
      await pumpEventQueue();
      await prefs.flush();
      expect(store.getString('notifications.muted.$secondKey'), isNull);
      expect(prefs.notifications.mutedConversations, isEmpty);
      prefs.dispose();
      await identity.dispose();
      await second.dispose();
    },
  );

  test(
    'aborted replacement preserves mutes and resumes same-key saves',
    () async {
      final identity = FakeIdentityService();
      await identity.create(displayName: 'same');
      final store = InMemoryKeyValueStore();
      final prefs = AppPreferences(
        store,
        backendLabel: 'test',
        identity: identity,
      );
      prefs.notifications.setMuted('c2c_peer', true);
      await prefs.flush();
      await prefs.prepareForReplacement();
      await identity.updateProfile(displayName: 'restored');
      await pumpEventQueue();
      expect(prefs.notifications.isMuted('c2c_peer'), isTrue);
      prefs.notifications.setMuted('c2c_other', true);
      await prefs.flush();
      expect(
        store.getString('notifications.muted.${identity.current!.publicKey}'),
        contains('c2c_other'),
      );
      prefs.dispose();
      await identity.dispose();
    },
  );

  test('appearance survives a reopened settings file', () async {
    final identity = FakeIdentityService();
    addTearDown(identity.dispose);
    final first = AppPreferences(
      await JsonFileKeyValueStore.open(file),
      backendLabel: 'test',
      identity: identity,
    );
    await first.settings.applyAppearance(
      style: UiStyle.radio,
      themeMode: ThemeMode.dark,
    );
    await first.flush();
    first.dispose();
    final reopened = AppPreferences(
      await JsonFileKeyValueStore.open(file),
      backendLabel: 'test',
      identity: identity,
    );
    addTearDown(reopened.dispose);
    expect(reopened.settings.themeMode, ThemeMode.dark);
    expect(reopened.settings.style, UiStyle.radio);
  });

  testWidgets('notification privacy and sound choices survive restart', (
    tester,
  ) async {
    final store = await tester.runAsync(() => JsonFileKeyValueStore.open(file));
    await mount(tester, store!);
    await tester.runAsync(() async {
      notifications.enabled = false;
      notifications.showText = false;
      notifications.showPattern = false;
      notifications.sound = false;
      await pumpEventQueue(times: 30);
    });
    await restart(tester);
    expect(notifications.enabled, isFalse);
    expect(notifications.showText, isFalse);
    expect(notifications.showPattern, isFalse);
    expect(notifications.sound, isFalse);
  });

  testWidgets('chat playback and listen-first choices survive restart', (
    tester,
  ) async {
    final store = await tester.runAsync(() => JsonFileKeyValueStore.open(file));
    await mount(tester, store!);
    await tester.runAsync(() async {
      playback.wpm = 28;
      playback.farnsworthWpm = 12;
      playback.toneHz = 550;
      playback.trainingMode = true;
      playback.inputMode = InputMode.paddles;
      playback.autoPlay = true;
      await pumpEventQueue(times: 30);
    });
    await restart(tester);
    expect(playback.wpm, 28);
    expect(playback.farnsworthWpm, 12);
    expect(playback.toneHz, 550);
    expect(playback.trainingMode, isTrue);
    expect(playback.inputMode, InputMode.paddles);
    expect(playback.autoPlay, isTrue);
  });
}

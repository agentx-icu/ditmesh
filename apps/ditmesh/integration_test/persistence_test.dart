// Real OS persistence, isolated from the app's own identity and settings.
// Run on each supported native platform with the fake-backend build flag:
// flutter test integration_test/persistence_test.dart -d macos \
//   --dart-define=DITMESH_FAKE_BACKEND=true
// Android builds without staged Tox binaries also need:
// ORG_GRADLE_PROJECT_ditmeshAllowMissingFfi=true
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:morse_trainer/morse_trainer.dart';
import 'package:ditmesh/desktop/window_bounds.dart';
import 'package:ditmesh/di/app_preferences.dart';
import 'package:ditmesh/di/desktop_store_adapter.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/i18n/locale_controller.dart';
import 'package:ditmesh/training/file_trainer_store.dart';
import 'package:ditmesh/training/training_settings.dart';
import 'package:ditmesh/training/training_settings_store.dart';
import 'package:ditmesh/ui/appearance/ui_style.dart';
import 'package:ditmesh/ui/listen/listen_settings.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart'
    show FlutterSecureStore, SharedPreferencesStore;
import 'package:ditmesh_chat_api/testing.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('backend preferences survive an uncached platform read', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final prefix =
          'ditmesh.persistence_test.${DateTime.now().microsecondsSinceEpoch}';
      final keys = [
        'string',
        'bool',
        'int',
        'list',
      ].map((suffix) => '$prefix.$suffix').toList();
      final first = await SharedPreferencesStore.open();
      try {
        await first.setString(keys[0], '好友与群组');
        await first.setBool(keys[1], true);
        await first.setInt(keys[2], 42);
        await first.setStringList(keys[3], ['peer-a', 'group-b']);
        // open() wraps the plugin singleton; reload() is essential to force a
        // real OS read rather than confirming the plugin's in-memory cache.
        await (await SharedPreferences.getInstance()).reload();
        final reopened = await SharedPreferencesStore.open();
        expect(reopened.getString(keys[0]), '好友与群组');
        expect(reopened.getBool(keys[1]), isTrue);
        expect(reopened.getInt(keys[2]), 42);
        expect(reopened.getStringList(keys[3]), ['peer-a', 'group-b']);
        for (final key in keys) {
          await reopened.remove(key);
        }
        await (await SharedPreferences.getInstance()).reload();
        expect(
          (await SharedPreferencesStore.open()).keys().intersection(
            keys.toSet(),
          ),
          isEmpty,
        );
      } finally {
        // Never clear the application preference domain: only these test keys.
        for (final key in keys) {
          await first.remove(key);
        }
      }
    });
  });

  testWidgets('production secure store survives fresh instances', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final key =
          'ditmesh.persistence_test.${DateTime.now().microsecondsSinceEpoch}';
      final first = FlutterSecureStore();
      var written = false;
      try {
        expect(await first.read(key), isNull);
        await first.write(key, 'test verifier: 密钥');
        written = true;
        final reopened = FlutterSecureStore();
        expect(await reopened.read(key), 'test verifier: 密钥');
        await reopened.write(key, 'updated verifier');
        expect(await FlutterSecureStore().read(key), 'updated verifier');
        await reopened.delete(key);
        written = false;
        expect(await FlutterSecureStore().read(key), isNull);
      } finally {
        if (written) await FlutterSecureStore().delete(key);
      }
    });
  });

  testWidgets('app preferences restore from the platform support directory', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final directory = await _testDirectory();
      final identity = FakeIdentityService(dataDirectoryPath: directory.path);
      AppPreferences? first;
      AppPreferences? reopened;
      LocaleController? locale;
      LocaleController? reopenedLocale;
      try {
        await identity.create(displayName: 'Disposable persistence test');
        final file = File(p.join(directory.path, 'settings.json'));
        final store = await JsonFileKeyValueStore.open(file);
        first = AppPreferences(store, backendLabel: 'test', identity: identity);
        locale = LocaleController(store);
        await first.settings.applyAppearance(
          style: UiStyle.radio,
          themeMode: ThemeMode.dark,
        );
        first.notifications.enabled = false;
        first.notifications.showText = false;
        first.notifications.showPattern = false;
        first.notifications.sound = false;
        first.notifications.setMuted('c2c_disposable_peer', true);
        first.playback.wpm = 28;
        first.playback.farnsworthWpm = 12;
        first.playback.toneHz = 550;
        first.playback.trainingMode = true;
        first.playback.originalRhythm = true;
        first.firstChat.dismiss();
        final conversation = first.conversations.forConversation(
          'c2c_disposable_peer',
          first.playback,
        );
        conversation.wpm = 24;
        conversation.farnsworthWpm = 10;
        conversation.originalRhythm = true;
        conversation.repeatStart = 1;
        conversation.repeatEnd = 2;
        conversation.repeatLoop = true;
        first.reference.wpm = 30;
        first.reference.farnsworthWpm = 14;
        first.reference.toneHz = 600;
        const listen = ListenSettings(
          blockSize: 512,
          minElementMs: 24,
          autoTune: false,
          manualHz: 800,
        );
        first.listen.update(listen);
        await locale.setLocale(const Locale('zh'));
        const bounds = WindowBounds(
          rect: Rect.fromLTWH(50, 60, 1000, 800),
          maximized: true,
        );
        await DesktopStoreAdapter(
          store,
        ).set('test.window.bounds', bounds.encode());
        await first.flush();
        first.dispose();
        first = null;
        locale.dispose();
        locale = null;

        final freshStore = await JsonFileKeyValueStore.open(file);
        reopened = AppPreferences(
          freshStore,
          backendLabel: 'test',
          identity: identity,
        );
        reopenedLocale = LocaleController(freshStore);
        expect(reopened.settings.themeMode, ThemeMode.dark);
        expect(reopened.settings.style, UiStyle.radio);
        expect(reopened.notifications.enabled, isFalse);
        expect(reopened.notifications.showText, isFalse);
        expect(reopened.notifications.showPattern, isFalse);
        expect(reopened.notifications.sound, isFalse);
        expect(reopened.notifications.isMuted('c2c_disposable_peer'), isTrue);
        expect(reopened.playback.wpm, 28);
        expect(reopened.playback.farnsworthWpm, 12);
        expect(reopened.playback.toneHz, 550);
        expect(reopened.playback.trainingMode, isTrue);
        expect(reopened.playback.originalRhythm, isTrue);
        expect(reopened.firstChat.dismissed, isTrue);
        final restoredConversation = reopened.conversations.forConversation(
          'c2c_disposable_peer',
          reopened.playback,
        );
        expect(restoredConversation.wpm, 24);
        expect(restoredConversation.farnsworthWpm, 10);
        expect(restoredConversation.originalRhythm, isTrue);
        expect(restoredConversation.repeatStart, 1);
        expect(restoredConversation.repeatEnd, 2);
        expect(restoredConversation.repeatLoop, isTrue);
        expect(reopened.reference.wpm, 30);
        expect(reopened.reference.farnsworthWpm, 14);
        expect(reopened.reference.toneHz, 600);
        expect(reopened.listen.settings, listen);
        expect(reopenedLocale.locale?.languageCode, 'zh');
        expect(
          WindowBounds.decode(
            await DesktopStoreAdapter(freshStore).get('test.window.bounds'),
          ),
          bounds,
        );
        await reopenedLocale.setLocale(null);
        final lastStore = await JsonFileKeyValueStore.open(file);
        final lastLocale = LocaleController(lastStore);
        expect(lastLocale.followsSystem, isTrue);
        lastLocale.dispose();
      } finally {
        first?.dispose();
        reopened?.dispose();
        locale?.dispose();
        reopenedLocale?.dispose();
        await identity.dispose();
        await directory.delete(recursive: true);
      }
    });
  });

  testWidgets('training progress and settings survive fresh file stores', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final directory = await _testDirectory();
      try {
        final day = DateTime(2026, 10, 1, 12);
        final progress = TrainerProgress(currentLesson: 5, dailyGoalChars: 120)
            .recordSession(
              SessionScore.evaluate(
                'KMRS',
                'KMRT',
                at: day,
                elapsed: const Duration(seconds: 12),
                lesson: 5,
                drillKind: 'receive',
              ),
              now: day,
            );
        final store = FileTrainerStore.inDataDirectory(directory.path);
        await store.save(progress);
        final restored = await FileTrainerStore.inDataDirectory(
          directory.path,
        ).load();
        expect(restored?.toJson(), progress.toJson());

        const settings = TrainingSettings(
          trainer: TrainerSettings(
            characterWpm: 30,
            farnsworthWpm: 12,
            toneHz: 550,
            sessionLengthChars: 80,
            sessionLengthSeconds: 120,
            groupSize: 3,
          ),
          soundEnabled: false,
          flashEnabled: true,
          hapticEnabled: true,
        );
        await FileTrainingSettingsStore.inDataDirectory(
          directory.path,
        ).save(settings);
        expect(
          await FileTrainingSettingsStore.inDataDirectory(
            directory.path,
          ).load(),
          settings,
        );

        // Exercise replacement of an existing file on every OS, then removal
        // of both the primary and the previous-save backup.
        final updated = progress.withLesson(6);
        await store.save(updated);
        expect(
          (await FileTrainerStore.inDataDirectory(
            directory.path,
          ).load())?.toJson(),
          updated.toJson(),
        );
        await FileTrainerStore.inDataDirectory(directory.path).clear();
        await FileTrainingSettingsStore.inDataDirectory(directory.path).clear();
        expect(
          await FileTrainerStore.inDataDirectory(directory.path).load(),
          isNull,
        );
        expect(
          await FileTrainingSettingsStore.inDataDirectory(
            directory.path,
          ).load(),
          isNull,
        );
      } finally {
        await directory.delete(recursive: true);
      }
    });
  });
}

Future<Directory> _testDirectory() async {
  final support = await getApplicationSupportDirectory();
  await support.create(recursive: true);
  return support.createTemp('ditmesh_persistence_test_');
}

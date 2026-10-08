// Product screenshots: boots the real app (in-memory backend, seeded demo
// data) on the real platform, walks every scene in each locale and captures
// the Flutter layer. Run through `tool/screenshots/capture.sh`, or directly:
//
//   flutter drive --driver=test_driver/integration_test.dart \
//       --target=integration_test/screenshots_test.dart -d macos \
//       --dart-define=DITMESH_FAKE_BACKEND=true
//
// Under plain `flutter test integration_test/ -d <device>` it still runs as a
// UI walk (every scene must render without an overflow or a missing widget);
// the frames are then discarded.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ditmesh/di/app_settings.dart';
import 'package:ditmesh/di/fake_backend_factory.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/i18n/locale_controller.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/main.dart';
import 'package:ditmesh/ui/account/backup_file_gateway.dart';
import 'package:ditmesh_chat_api/testing.dart';

import 'support/scene_walk.dart';
import 'support/seed_data.dart';
import 'support/shot_harness.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final shots = ShotHarness(binding);

  for (final locale in shotLocales()) {
    testWidgets('screenshots [$locale]', (tester) async {
      final copy = seedCopyFor(locale);
      final S s = lookupS(parseShotLocale(locale));
      final scratch = await Directory.systemTemp.createTemp('ditmesh_shots_');
      addTearDown(() => scratch.delete(recursive: true));
      // The seeded identity has accepted the community guidelines (the
      // onboarding walk stops at the backup wizard, before the gate).
      KeyValueStore localeStore() => InMemoryKeyValueStore({
        LocaleController.storageKey: locale,
        AppSettings.termsKey: '$kTermsVersion',
      });

      // 1. First run: welcome → create → backup wizard.
      await tester.pumpWidget(
        shots.wrap(
          DitmeshApp(
            // Distinct keys: a same-typed root would be UPDATED in place and
            // AppScope would keep the first backend.
            key: ValueKey<String>('onboarding-$locale'),
            backend: FakeBackendFactory(
              identityService: FakeIdentityService(
                connectDelay: Duration.zero,
                dataDirectoryPath: '${scratch.path}/fresh',
              ),
            ),
            backupFiles: FakeBackupFileGateway(),
            localeStore: localeStore(),
          ),
        ),
      );
      await shots.prepareWindow(tester);
      await walkOnboarding(tester, shots, s, copy, locale: locale);

      // 2. Established identity with demo data: every shell scene.
      final seed = await buildSeed(copy, dataDir: '${scratch.path}/seeded');
      final network = FakeNetworkBootstrapService(supportsLan: isDesktopHost);
      await network.selectNode(network.catalogue.nodes.first);
      await tester.pumpWidget(
        shots.wrap(
          DitmeshApp(
            key: ValueKey<String>('shell-$locale'),
            backend: FakeBackendFactory(
              identityService: seed.identity,
              networkBootstrapService: network,
              chatService: (_) => seed.chat,
            ),
            backupFiles: FakeBackupFileGateway(),
            localeStore: localeStore(),
          ),
        ),
      );
      await walkShell(tester, shots, s, seed, locale: locale);

      final mine = shots.captured.where((n) => n.contains('/$locale/'));
      expect(mine.length, kScenes.length, reason: 'all scenes captured');
    });
  }
}

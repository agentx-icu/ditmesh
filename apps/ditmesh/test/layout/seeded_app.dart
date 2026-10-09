// The whole app over the screenshot demo data (friends, a QSO, a group net,
// a friend request, a week of training), for the layout tests.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/app_settings.dart';
import 'package:ditmesh/di/fake_backend_factory.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/i18n/locale_controller.dart';
import 'package:ditmesh/main.dart';
import 'package:ditmesh/ui/account/backup_file_gateway.dart';

import '../../integration_test/support/seed_data.dart';
import '../account/test_app.dart' show settle;

/// Pumps [DitmeshApp] in [locale] over freshly seeded demo data and settles
/// on the shell. [key] distinguishes reboots within one test.
Future<SeededBackend> pumpSeededApp(
  WidgetTester tester, {
  String locale = 'en',
  Key? key,
}) async {
  final dir = await tester.runAsync(
    () => Directory.systemTemp.createTemp('ditmesh_layout_'),
  );
  addTearDown(() => dir!.delete(recursive: true));
  final seed = await tester.runAsync(
    () => buildSeed(
      seedCopyFor(locale.startsWith('zh') ? 'zh' : 'en'),
      dataDir: dir!.path,
    ),
  );
  await tester.pumpWidget(
    DitmeshApp(
      key: key,
      backend: FakeBackendFactory(
        identityService: seed!.identity,
        chatService: (_) => seed.chat,
      ),
      backupFiles: FakeBackupFileGateway(),
      localeStore: InMemoryKeyValueStore({
        AppSettings.termsKey: '$kTermsVersion',
        LocaleController.storageKey: locale,
      }),
    ),
  );
  await settle(tester);
  return seed;
}

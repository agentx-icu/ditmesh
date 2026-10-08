import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/app_settings.dart';
import 'package:ditmesh/di/fake_backend_factory.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/main.dart';
import 'package:ditmesh/ui/account/account_routes.dart';
import 'package:ditmesh/ui/account/backup_file_gateway.dart';
import 'package:ditmesh/ui/moderation/terms_gate_page.dart';
import 'package:ditmesh/ui/shell/app_shell.dart';
import 'package:ditmesh_chat_api/testing.dart';

import '../account/test_app.dart';
import '../chat/test_support.dart' show s;
import 'fake_url_launcher.dart';

final class _FailingStore implements KeyValueStore {
  @override
  String? getString(String key) => null;

  @override
  Future<void> setString(String key, String value) async =>
      throw StateError('disk full');

  @override
  Future<void> remove(String key) async {}
}

Future<void> _pump(
  WidgetTester tester,
  KeyValueStore store, {
  FakeIdentityService? identity,
}) async {
  tester.view.physicalSize = kPhoneSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    DitmeshApp(
      backend: FakeBackendFactory(
        identityService: identity ?? seededIdentityService(),
      ),
      backupFiles: FakeBackupFileGateway(),
      localeStore: store,
    ),
  );
  await settle(tester);
}

void main() {
  testWidgets('an identity opens on the guidelines until they are accepted, '
      'then the shell; the answer is saved', (tester) async {
    final store = InMemoryKeyValueStore();
    await _pump(tester, store);
    expect(find.byType(TermsGatePage), findsOneWidget);
    expect(find.byType(AppShell), findsNothing, reason: 'no tab, no route');
    expect(find.text(s.termsGateRuleZero), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('terms-agree')));
    await settle(tester);
    expect(find.byType(AppShell), findsOneWidget);
    expect(store.values[AppSettings.termsKey], '$kTermsVersion');
  });

  testWidgets('an older accepted version asks again', (tester) async {
    await _pump(
      tester,
      InMemoryKeyValueStore({AppSettings.termsKey: '${kTermsVersion - 1}'}),
    );
    expect(find.byType(TermsGatePage), findsOneWidget);
  });

  testWidgets('a failed save keeps the gate and says so', (tester) async {
    await _pump(tester, _FailingStore());
    await tester.tap(find.byKey(const ValueKey('terms-agree')));
    await settle(tester);
    expect(find.byType(TermsGatePage), findsOneWidget);
    expect(find.text(s.termsGateSaveFailed), findsOneWidget);
  });

  testWidgets('the full terms open in the browser', (tester) async {
    final launcher = FakeUrlLauncher.install();
    await _pump(tester, InMemoryKeyValueStore());
    await tester.tap(find.byKey(const ValueKey('terms-read-full')));
    await settle(tester);
    expect(launcher.launched, [kTermsUrl]);
  });

  testWidgets('fresh chat identity setup has no guest-learning bypass', (
    tester,
  ) async {
    await _pump(
      tester,
      InMemoryKeyValueStore(),
      identity: freshIdentityService(),
    );
    expect(find.byKey(const ValueKey('try-learning-first')), findsNothing);
    expect(find.byType(AppShell), findsNothing);
  });
}

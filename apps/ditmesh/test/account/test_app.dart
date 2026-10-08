import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/training/guest_profile.dart';
import 'package:ditmesh/di/app_settings.dart';
import 'package:ditmesh/di/fake_backend_factory.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/main.dart';
import 'package:ditmesh/ui/account/backup_file_gateway.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';

/// Phone-class size used by the account tests. Still `compact` (< 600) so the
/// shell renders a bottom NavigationBar. Wider than an iPhone 12 because the
/// Learn home's row overflows at 390 px (see the account agent's report).
const Size kPhoneSize = Size(540, 960);
const Size kDesktopSize = Size(1280, 800);

/// A ready-to-use identity for seeded fakes.
Identity testIdentity({bool hasPassword = false}) => Identity(
  toxId: FakeIdentityService.toxIdForSeed(42),
  displayName: 'Ann',
  statusMessage: 'QRV on 40m',
  hasPassword: hasPassword,
);

/// Per-test scratch directory so the Learn tab's per-identity file stores
/// never see another test's progress.
String freshDataDirectory() =>
    Directory.systemTemp.createTempSync('ditmesh_account_test_').path;

/// Fake service with no profile on disk (first run) and instant connection.
FakeIdentityService freshIdentityService() => FakeIdentityService(
  connectDelay: Duration.zero,
  dataDirectoryPath: freshDataDirectory(),
);

/// Fake service that already has a plain (or, with [password], encrypted)
/// profile on disk and connects instantly.
FakeIdentityService seededIdentityService({
  String? password,
  Duration connectDelay = Duration.zero,
}) => FakeIdentityService.withProfile(
  identity: testIdentity(hasPassword: password != null),
  password: password,
  connectDelay: connectDelay,
  dataDirectoryPath: freshDataDirectory(),
);

/// A preferences store in which this device already accepted the community
/// guidelines ([kTermsVersion]), plus [more] entries: the startup gate then
/// opens the shell instead of the terms page.
InMemoryKeyValueStore acceptedTermsStore([Map<String, String>? more]) =>
    InMemoryKeyValueStore({AppSettings.termsKey: '$kTermsVersion', ...?more});

/// Settles the tree while letting REAL asynchronous work finish.
///
/// The Learn tab (inside the shell) loads its progress from files through
/// `dart:io`; in the FakeAsync test zone those futures only complete while
/// the event loop runs, which `pumpAndSettle` alone never allows. So: a few
/// frames under `runAsync`, then a normal `pumpAndSettle` for animations.
Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  });
  await tester.pumpAndSettle();
}

/// Pumps the whole app (scope + gate + shell) at a phone or desktop size.
Future<void> pumpApp(
  WidgetTester tester, {
  required FakeIdentityService identity,
  FakeBackupFileGateway? backupFiles,
  Size size = kPhoneSize,
  GuestStore? guestStore,
  bool termsAccepted = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    DitmeshApp(
      backend: FakeBackendFactory(identityService: identity),
      backupFiles: backupFiles ?? FakeBackupFileGateway(),
      guestStore: guestStore,
      localeStore: termsAccepted ? acceptedTermsStore() : null,
    ),
  );
  await settle(tester);
}

/// Intercepts `Clipboard.setData` and records the copied text.
class ClipboardSpy {
  ClipboardSpy(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          final args = call.arguments as Map<Object?, Object?>;
          copied.add(args['text'] as String);
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
  }

  final List<String> copied = [];
}

/// Scrolls [finder] into view (onboarding pages scroll on a phone) and taps.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await settle(tester);
}

/// Whether the button carrying [label] is enabled.
bool buttonEnabled(WidgetTester tester, String label) {
  final finder = find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );
  return tester.widget<ButtonStyleButton>(finder).onPressed != null;
}

/// Fills the encrypted backup page's passphrase twice and creates the
/// backup (F10). Leaves the result to the caller's expectations.
Future<void> completeEncryptedBackup(
  WidgetTester tester, {
  String passphrase = 'correct horse',
}) async {
  Finder field(String key) => find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(field('backup-x-passphrase'));
  await tester.enterText(field('backup-x-passphrase'), passphrase);
  await tester.ensureVisible(field('backup-x-confirm'));
  await tester.enterText(field('backup-x-confirm'), passphrase);
  await tapVisible(tester, find.byKey(const ValueKey('backup-x-export')));
}

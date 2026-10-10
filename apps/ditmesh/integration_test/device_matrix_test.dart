// Simulator / emulator device-matrix probe (wave 3 of the mobile-device
// review, doc/VALIDATION.md "Simulator / emulator evidence").
//
// Runs the app's own main() with the REAL Tox backend and keeps it open as a
// remote-controlled probe, so a host script can mix OS-level actions (home /
// back, airplane mode, Wi-Fi off, force-stop, text size, notification
// channel settings) with UI steps, and read what the app saw as log lines:
//
//   DMX_LIFE / DMX_HINT / DMX_CONN / DMX_MSG   events, with epoch ms
//   DMX_STATE {json}                            whenever the snapshot changes
//   DMX_HB <epoch ms>                           once a second (freeze gaps)
//   DMX_DONE <seq> ok|error <detail>            per executed command
//
// Commands are lines "<seq> <verb> [args]" appended to `<support dir>/dmx/cmd`
// (printed at start as DMX_CMD_DIR). On Android write it with
// `adb shell run-as icu.agentx.ditmesh`, on the iOS Simulator into the app
// data container (`xcrun simctl get_app_container <dev> <bundle> data`).
// Verbs: see [DeviceProbe.execute].
//
//   flutter test integration_test/device_matrix_test.dart -d <device> \
//       --dart-define=DMX_NAME=SimA [--dart-define=DMX_SECONDS=3600]
//
// It never runs under `DITMESH_FAKE_BACKEND`: evidence from the fake backend
// would say nothing about the node, the network path or the durable outbox.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ditmesh/di/backend_factory.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/main.dart' as app;
import 'package:ditmesh/startup/startup_gate.dart';
import 'package:ditmesh/ui/account/welcome_page.dart';
import 'package:ditmesh/ui/moderation/terms_gate_page.dart';
import 'package:ditmesh/ui/shell/app_shell.dart';

import 'support/device_probe.dart';
import 'support/scene_walk.dart';
import 'support/shot_harness.dart';

const String _name = String.fromEnvironment('DMX_NAME', defaultValue: 'Sim');
const int _seconds = int.fromEnvironment('DMX_SECONDS', defaultValue: 3600);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('device-matrix probe (real backend)', (tester) async {
    expect(
      kForceFakeBackend,
      isFalse,
      reason: 'the device-matrix probe needs the real Tox backend',
    );
    await app.main();
    await settle(tester, extra: const Duration(milliseconds: 500));
    await _reachShell(tester);
    final probe = DeviceProbe(tester);
    await probe.start();
    try {
      await probe.run(const Duration(seconds: _seconds));
    } finally {
      await probe.stop();
    }
  }, timeout: Timeout.none);
}

/// First launch: onboarding with [_name] and the terms gate. Later launches
/// (identity on disk, no password) go straight to the shell.
Future<void> _reachShell(WidgetTester tester) async {
  S s() => S.of(tester.element(find.byType(Scaffold).first));
  final deadline = DateTime.now().add(const Duration(minutes: 2));
  while (DateTime.now().isBefore(deadline)) {
    if (find.byType(AppShell).evaluate().isNotEmpty) return;
    if (find.byType(WelcomePage).evaluate().isNotEmpty) {
      await tapText(tester, s().accountCreateIdentity);
      await tester.enterText(find.byType(TextField).first, _name);
      await tapText(tester, s().accountCreateButton);
      await waitFor(tester, find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await settle(tester);
      await tapText(tester, s().accountBackupContinue);
      continue;
    }
    if (find.byType(TermsGatePage).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const ValueKey('terms-agree')));
      await settle(tester);
      continue;
    }
    await tester.pump(const Duration(milliseconds: 200));
  }
  if (find.byType(StartupGate).evaluate().isNotEmpty) {
    await dumpStartupState(tester);
  }
  fail('did not reach the shell within 2 minutes');
}

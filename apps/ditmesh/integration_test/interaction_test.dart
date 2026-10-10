// Real input on the real platform: the app's own `main()` driven by pointer
// and hardware-keyboard events the way an operator keys, plus the flows a
// first-time user goes through after onboarding (a group, the appearance
// settings, deleting the identity). app_launch_test covers the first walk
// through the tabs; this file covers what only a real device proves: real
// pointer timing on the straight key against the wall clock, the platform's
// key events, the plugins behind the sidetone and the settings file.
//
//   flutter test integration_test/interaction_test.dart -d <device> \
//       --dart-define=DITMESH_FAKE_BACKEND=true
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ditmesh/di/backend_factory.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/main.dart' as app;
import 'package:ditmesh/ui/account/welcome_page.dart';
import 'package:ditmesh/ui/appearance/appearance_page.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/message_bubble.dart';
import 'package:ditmesh/ui/moderation/terms_gate_page.dart';
import 'package:ditmesh/ui/shell/app_shell.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:morse_io/morse_io.dart';

import 'support/scene_walk.dart';
import 'support/shot_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('keying by touch and keyboard, a group, dark mode, delete', (
    tester,
  ) async {
    expect(
      kForceFakeBackend,
      isTrue,
      reason: 'run with --dart-define=DITMESH_FAKE_BACKEND=true',
    );
    final fakeRoot = Directory(FakeIdentityService.defaultDataRoot);
    if (fakeRoot.existsSync()) fakeRoot.deleteSync(recursive: true);
    await app.main();
    await settle(tester, extra: const Duration(milliseconds: 500));
    S s() => S.of(tester.element(find.byType(Scaffold).first));

    await _onboard(tester, s);

    // 1. Note to self, keyed on the on-screen straight key with real
    //    pointer timing: one long press is a dah, a dah alone is T.
    await selectTab(tester, ShellTab.chat);
    await tapTooltip(tester, s().chatContacts);
    await tapHittable(
      tester,
      find.byKey(const ValueKey<String>('contacts_self')),
      'me row',
    );
    expect(find.byType(ConversationScreen), findsOneWidget);
    final straightKey = find.byType(StraightKeyButton);
    expect(straightKey, findsOneWidget, reason: 'straight key by default');
    await tester.ensureVisible(straightKey);
    await tester.pump();
    final gesture = await tester.startGesture(tester.getCenter(straightKey));
    await _realWait(tester, const Duration(milliseconds: 600));
    await gesture.up();
    // Let the character gap pass on the wall clock.
    await _waitForDraft(tester, (t) => t.contains('T'), 'T keyed by touch');

    // The same key from the hardware keyboard (Space, the default binding):
    // a second long press gives another T.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await _realWait(tester, const Duration(milliseconds: 600));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await _waitForDraft(
      tester,
      (t) => 'T'.allMatches(t.replaceAll(' ', '')).length >= 2,
      'T keyed by Space',
    );
    final keyed = _draft(tester).trim();
    await tapTooltip(tester, s().chatSend);
    expect(
      find.byWidgetPredicate(
        (w) => w is MessageBubble && w.message.text.trim() == keyed,
      ),
      findsOneWidget,
      reason: 'the keyed line "$keyed" was sent',
    );
    expect(_draft(tester), isEmpty);
    await popIfCan(tester);

    // 2. A group: create it, open it, send a line.
    await selectTab(tester, ShellTab.groups);
    await tapTooltip(tester, s().chatCreateGroup);
    await tester.enterText(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextFormField),
      ),
      'NETS',
    );
    await settle(tester);
    await tapText(tester, s().chatCreate);
    if (find.byType(ConversationScreen).evaluate().isEmpty) {
      await tapHittable(tester, find.text('NETS').last, 'group row');
    }
    expect(find.byType(ConversationScreen), findsOneWidget);
    _setDraft(tester, 'QST NETS');
    await tester.pump();
    await tapTooltip(tester, s().chatSend);
    expect(
      find.byWidgetPredicate(
        (w) => w is MessageBubble && w.message.text == 'QST NETS',
      ),
      findsOneWidget,
    );
    await popIfCan(tester);

    // 3. Appearance: dark mode applies to the whole app, then back.
    await selectTab(tester, ShellTab.me);
    await tapText(tester, s().appearanceTitle);
    expect(find.byType(AppearancePage), findsOneWidget);
    await tapHittable(
      tester,
      find.byKey(const ValueKey('mode-dark')),
      'dark mode',
    );
    await tapHittable(
      tester,
      find.byKey(const ValueKey('appearance-apply')),
      'apply',
    );
    expect(
      Theme.of(tester.element(find.byType(AppearancePage))).brightness,
      Brightness.dark,
    );
    // The "applied" SnackBar sits over the controls on a phone.
    ScaffoldMessenger.of(
      tester.element(find.byType(AppearancePage)),
    ).clearSnackBars();
    await settle(tester);
    await tapHittable(
      tester,
      find.byKey(const ValueKey('mode-system')),
      'system mode',
    );
    await tapHittable(
      tester,
      find.byKey(const ValueKey('appearance-apply')),
      'apply',
    );
    await popIfCan(tester);

    // 4. Delete the identity: back to the welcome page, nothing left.
    await selectTab(tester, ShellTab.me);
    await tapText(tester, s().accountDeleteIdentity);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      s().accountDeleteConfirmWord,
    );
    await settle(tester);
    await tapText(tester, s().accountDeleteButton);
    await settle(tester, extra: const Duration(milliseconds: 500));
    expect(find.byType(AppShell), findsNothing);
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.text(s().accountCreateIdentity), findsOneWidget);
  });
}

/// Welcome → create → backup acknowledged → (first run) guidelines.
Future<void> _onboard(WidgetTester tester, S Function() s) async {
  await tapText(tester, s().accountCreateIdentity);
  await tester.enterText(find.byType(TextField).first, 'Kim');
  await tapText(tester, s().accountCreateButton);
  await tapHittable(
    tester,
    find.byType(CheckboxListTile),
    'backup acknowledged',
  );
  await tapText(tester, s().accountBackupContinue);
  if (find.byType(TermsGatePage).evaluate().isNotEmpty) {
    await scrollToAndTap(
      tester,
      find.byKey(const ValueKey('terms-agree')),
      'terms agree',
    );
  }
  expect(find.byType(AppShell), findsOneWidget);
}

/// Lets [d] pass on the wall clock while frames keep being produced (the
/// keyer and decoder run on real timers and the system clock).
Future<void> _realWait(WidgetTester tester, Duration d) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

TextField _draftField(WidgetTester tester) => tester.widget<TextField>(
  find
      .descendant(
        of: find.byType(ConversationScreen),
        matching: find.byType(TextField),
      )
      .last,
);

String _draft(WidgetTester tester) => _draftField(tester).controller!.text;

void _setDraft(WidgetTester tester, String text) =>
    _draftField(tester).controller!.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

Future<void> _waitForDraft(
  WidgetTester tester,
  bool Function(String) done,
  String what,
) async {
  final end = DateTime.now().add(const Duration(seconds: 5));
  while (!done(_draft(tester))) {
    if (DateTime.now().isAfter(end)) {
      fail('$what: draft is "${_draft(tester)}"');
    }
    await _realWait(tester, const Duration(milliseconds: 100));
  }
}

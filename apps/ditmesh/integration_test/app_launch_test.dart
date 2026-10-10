// Real launch + click-through smoke: runs the app's own `main()` on the real
// platform (desktop shell, notifications, settings file included) and walks
// the product the way a first-time user does. This is the top of the test
// pyramid; `test/` covers the same screens hermetically.
//
// Requires `--dart-define=DITMESH_FAKE_BACKEND=true`: the in-memory backend
// keeps nothing on disk, so every launch starts at onboarding. With the Tox
// backend a real identity would be created on the device.
//
//   flutter test integration_test/app_launch_test.dart -d macos \
//       --dart-define=DITMESH_FAKE_BACKEND=true
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ditmesh/di/backend_factory.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/main.dart' as app;
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/message_bubble.dart';
import 'package:ditmesh/ui/contacts/add_friend_sheet.dart';
import 'package:ditmesh/ui/moderation/terms_gate_page.dart';
import 'package:ditmesh/ui/reference/morse_pattern_text.dart';
import 'package:ditmesh/ui/reference/text_to_morse_view.dart';
import 'package:ditmesh/ui/reference/translator_screen.dart';
import 'package:ditmesh/ui/shell/app_shell.dart';
import 'package:ditmesh_chat_api/testing.dart';

import 'support/scene_walk.dart';
import 'support/shot_harness.dart';

/// A syntactically valid Tox ID that is not the hero's own.
final String kFriendToxId = '${'AB' * 32}${'0' * 12}';

/// The friend's public key: the first 64 hex digits of [kFriendToxId].
final String kFriendPublicKey = kFriendToxId.substring(0, 64);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cold start: identity setup, four tabs, Morse chat, translator', (
    tester,
  ) async {
    expect(
      kForceFakeBackend,
      isTrue,
      reason: 'run with --dart-define=DITMESH_FAKE_BACKEND=true',
    );
    // The fake's identities are deterministic, so their training data lands
    // in the same folder every run; start from nothing, like a first launch.
    final fakeRoot = Directory(FakeIdentityService.defaultDataRoot);
    if (fakeRoot.existsSync()) fakeRoot.deleteSync(recursive: true);
    await app.main();
    await settle(tester, extra: const Duration(milliseconds: 500));

    // Strings in whatever language the device's settings file selects.
    S s() => S.of(tester.element(find.byType(Scaffold).first));

    // Onboarding
    expect(find.text(s().accountCreateIdentity), findsOneWidget);
    await tapText(tester, s().accountCreateIdentity);
    await tester.enterText(find.byType(TextField).first, 'Ann');
    await tapText(tester, s().accountCreateButton);
    expect(find.text(s().accountBackupContinue), findsOneWidget);
    // On a small phone the checkbox sits below the fold.
    await tapHittable(
      tester,
      find.byType(CheckboxListTile),
      'backup acknowledged',
    );
    await tapText(tester, s().accountBackupContinue);
    // First launch on this device: the community guidelines come before
    // the shell (a device that accepted them earlier skips this).
    if (find.byType(TermsGatePage).evaluate().isNotEmpty) {
      expect(find.text(s().termsGateRuleZero), findsOneWidget);
      // A lazily built list: on a small phone the button is not built
      // until the rules above it scroll away.
      await scrollToAndTap(
        tester,
        find.byKey(const ValueKey('terms-agree')),
        'terms agree',
      );
    }
    expect(find.byType(AppShell), findsOneWidget);

    // Chat is the initial destination on every platform.
    expect(find.byIcon(Icons.school_outlined), findsNothing);

    // Chat: the default "me" contact is a local notes conversation.
    await selectTab(tester, ShellTab.chat);
    await tapTooltip(tester, s().chatContacts);
    await tapHittable(
      tester,
      find.byKey(const ValueKey<String>('contacts_self')),
      'me row',
    );
    expect(find.byType(ConversationScreen), findsOneWidget);
    expect(find.text(s().chatSelfLocalOnly), findsOneWidget);
    await keyIntoComposer(tester, 'NOTE TO SELF');
    await settle(tester);
    await tapTooltip(tester, s().chatSend);
    expect(
      find.descendant(
        of: find.byType(MessageBubble),
        matching: find.text('NOTE TO SELF'),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.schedule), findsNothing); // never queued
    await popIfCan(tester);

    // Chat: add a friend by Tox ID, open the conversation, send a line.
    await tapTooltip(tester, s().chatContacts);
    await tapTooltip(tester, s().chatAddFriend);
    await tester.enterText(find.byType(TextField).first, kFriendToxId);
    await settle(tester);
    await tapText(tester, s().chatSendRequest);
    // The sheet closes and the fake adds the friend immediately (offline).
    // Open the conversation from the friend's row by its stable key, so the
    // typed ID in a still-open sheet can never be what gets tapped.
    expect(find.byType(AddFriendForm), findsNothing);
    await tapHittable(
      tester,
      find.byKey(ValueKey<String>('friend_$kFriendPublicKey')),
      'friend row',
    );
    expect(find.byType(ConversationScreen), findsOneWidget);
    // The "request sent" SnackBar sits over the send button for 4 s; clear
    // it so the tap lands on the button and not on the toast.
    ScaffoldMessenger.of(
      tester.element(find.byType(ConversationScreen)),
    ).clearSnackBars();
    await settle(tester);
    await keyIntoComposer(tester, 'CQ CQ DE ANN');
    await settle(tester);
    await tapTooltip(tester, s().chatSend);
    // Sent: one bubble with the text, and the composer is empty again.
    expect(find.byType(MessageBubble), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MessageBubble),
        matching: find.text('CQ CQ DE ANN'),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller?.text,
      isEmpty,
    );
    await popIfCan(tester);

    // Groups tab renders.
    await selectTab(tester, ShellTab.groups);
    expect(find.text(s().chatCreateGroup), findsNothing);
    expect(find.byTooltip(s().chatCreateGroup), findsOneWidget);

    // Reference: translator encodes SOS.
    await selectTab(tester, ShellTab.reference);
    await tapTooltip(tester, s().referenceTranslatorTitle);
    expect(find.byType(TranslatorScreen), findsOneWidget);
    await tester.enterText(find.byKey(TextToMorseView.inputKey), 'SOS');
    await settle(tester);
    expect(
      find.text(displayMorsePattern('... --- ...'), findRichText: true),
      findsOneWidget,
    );
    await popIfCan(tester);

    // Me: identity card and the backend label.
    await selectTab(tester, ShellTab.me);
    expect(find.text('Ann'), findsWidgets);
    expect(find.textContaining('fake'), findsOneWidget);
  });
}

/// The chat composer is keyed, not typed, and its draft field is read-only:
/// put [text] in it the way decoded keying does.
Future<void> keyIntoComposer(WidgetTester tester, String text) async {
  tester
      .widget<TextField>(find.byType(TextField).last)
      .controller!
      .value = TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
  await tester.pump();
}

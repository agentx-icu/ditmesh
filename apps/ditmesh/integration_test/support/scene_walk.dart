// Drives the real UI from scene to scene and captures each one.
//
// Layout-aware: on a phone the shell has a bottom NavigationBar and
// conversations open as pushed routes; on desktop/tablet a NavigationRail
// and an inline detail pane. Every navigation goes through the same widgets
// a user taps, found by localized text/tooltip or by the app's stable keys.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/startup/startup_controller.dart';
import 'package:ditmesh/startup/startup_gate.dart';
import 'package:ditmesh/ui/account/backup_wizard_page.dart';
import 'package:ditmesh/ui/account/create_identity_page.dart';
import 'package:ditmesh/ui/account/welcome_page.dart';
import 'package:ditmesh/ui/chat/conversation_list.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/message_bubble.dart';
import 'package:ditmesh/ui/contacts/contacts_page.dart';
import 'package:ditmesh/ui/groups/group_list.dart';
import 'package:ditmesh/ui/listen/listen_screen.dart';
import 'package:ditmesh/ui/network/bootstrap_page.dart';
import 'package:ditmesh/ui/pages/me_page.dart';
import 'package:ditmesh/ui/pages/reference_page.dart';
import 'package:ditmesh/ui/reference/morse_pattern_text.dart';
import 'package:ditmesh/ui/reference/text_to_morse_view.dart';
import 'package:ditmesh/ui/reference/translator_screen.dart';
import 'package:ditmesh/ui/shell/app_shell.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import 'seed_data.dart';
import 'shot_harness.dart';

/// Every scene the chat build's run must produce, in capture order.
/// `tool/screenshots/capture.sh` checks the same list.
const List<String> kScenes = <String>[
  'welcome',
  'create_identity',
  'backup_wizard',
  'chat_list',
  'conversation',
  'contacts',
  'groups',
  'group_conversation',
  'reference',
  'translator',
  'listen',
  'me',
  'network_bootstrap',
];

/// Index into [kShellDestinations].
enum ShellTab { chat, groups, reference, me }

Finder _navHost() =>
    find.byWidgetPredicate((w) => w is NavigationRail || w is NavigationBar);

/// Taps a shell destination by its icon (rail labels are hidden on desktop,
/// and the bar label text also appears as the page's app-bar title).
Future<void> selectTab(WidgetTester tester, ShellTab tab) async {
  final d = kShellDestinations[tab.index];
  var finder = find.descendant(of: _navHost(), matching: find.byIcon(d.icon));
  if (finder.evaluate().isEmpty) {
    finder = find.descendant(
      of: _navHost(),
      matching: find.byIcon(d.selectedIcon),
    );
  }
  await tapHittable(tester, finder, 'destination ${tab.name}');
}

/// Taps [finder] after asserting it resolves to exactly one widget that a
/// pointer can actually reach (not covered by a SnackBar, a sheet or an
/// offstage route), then settles. `tester.tap` alone only warns on a miss.
Future<void> tapHittable(
  WidgetTester tester,
  Finder finder,
  String what,
) async {
  expect(finder, findsOneWidget, reason: what);
  await tester.ensureVisible(finder);
  await tester.pump();
  expect(finder.hitTestable(), findsOneWidget, reason: '$what is hittable');
  await tester.tap(finder);
  await settle(tester);
}

/// Asserts the screen a scene is about to capture is on stage.
void expectScreen(Type screen) {
  expect(find.byType(screen), findsOneWidget, reason: '$screen on screen');
}

/// Asserts a chat bubble carrying [text] is on screen (by message, so it
/// holds in training mode where the text itself is hidden). Only lines in
/// the viewport are built, so check the newest line: the conversation opens
/// scrolled to the bottom.
void expectBubble(String text) {
  expect(
    find.byWidgetPredicate((w) => w is MessageBubble && w.message.text == text),
    findsOneWidget,
    reason: 'bubble "$text"',
  );
}

/// Pops the top route of the root navigator when there is one (a pushed
/// conversation on a phone); a no-op for an inline desktop pane.
Future<void> popIfCan(WidgetTester tester) async {
  final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
  if (nav.canPop()) {
    nav.pop();
    await settle(tester);
  }
}

/// Prints the startup phase/error and every visible string, for the log of
/// a run that did not reach the shell.
Future<void> dumpStartupState(WidgetTester tester) async {
  final gate = find.byType(StartupGate);
  if (gate.evaluate().isNotEmpty) {
    final controller = tester.element(gate).read<StartupController>();
    debugPrint(
      '[shot] startup phase=${controller.phase} '
      'error=${controller.error} connection=${controller.connectionError}',
    );
  }
  final texts = find
      .byType(Text)
      .evaluate()
      .map((e) {
        final t = e.widget as Text;
        return t.data ?? t.textSpan?.toPlainText() ?? '';
      })
      .where((t) => t.isNotEmpty);
  debugPrint('[shot] visible text: ${texts.join(' | ')}');
}

Future<void> tapTooltip(WidgetTester tester, String tooltip) =>
    tapHittable(tester, find.byTooltip(tooltip), 'tooltip "$tooltip"');

Future<void> tapText(WidgetTester tester, String text) =>
    tapHittable(tester, find.text(text), 'text "$text"');

/// Welcome → create identity (name typed) → mandatory backup wizard.
Future<void> walkOnboarding(
  WidgetTester tester,
  ShotHarness shots,
  S s,
  SeedCopy copy, {
  required String locale,
}) async {
  await settle(tester, extra: const Duration(milliseconds: 300));
  await shots.applyTheme(tester);
  expectScreen(WelcomePage);
  expect(find.text(s.accountCreateIdentity), findsOneWidget);
  await shots.capture(tester, locale, 'welcome');

  await tapText(tester, s.accountCreateIdentity);
  expectScreen(CreateIdentityPage);
  await tester.enterText(find.byType(TextField).first, copy.heroName);
  await settle(tester);
  expect(find.text(copy.heroName), findsOneWidget);
  await shots.capture(tester, locale, 'create_identity');

  await tapText(tester, s.accountCreateButton);
  expectScreen(BackupWizardPage);
  expect(find.text(s.accountBackupContinue), findsOneWidget);
  await shots.capture(tester, locale, 'backup_wizard');
}

/// Every shell scene, from the seeded identity.
Future<void> walkShell(
  WidgetTester tester,
  ShotHarness shots,
  S s,
  SeededBackend seed, {
  required String locale,
}) async {
  await settle(tester, extra: const Duration(milliseconds: 500));
  await shots.applyTheme(tester);
  if (find.byType(AppShell).evaluate().isEmpty) {
    await dumpStartupState(tester);
  }
  expect(find.byType(AppShell), findsOneWidget);

  final copy = seed.copy;

  // Chat
  await selectTab(tester, ShellTab.chat);
  expectScreen(ConversationList);
  final qso = find.byKey(ValueKey<String>(seed.qsoConversationId));
  expect(qso, findsOneWidget, reason: 'seeded QSO in the list');
  expect(
    find.byKey(ValueKey<String>(seed.unreadConversationId)),
    findsOneWidget,
    reason: 'seeded unread conversation in the list',
  );
  await shots.capture(tester, locale, 'chat_list');
  await tapHittable(tester, qso, 'QSO conversation tile');
  await settle(tester, extra: const Duration(milliseconds: 300));
  expectScreen(ConversationScreen);
  expectBubble(copy.qso.last.text);
  await shots.capture(tester, locale, 'conversation');
  await popIfCan(tester);
  await tapTooltip(tester, s.chatContacts);
  expectScreen(ContactsPage);
  for (var i = 0; i < copy.friends.length; i++) {
    expect(
      find.byKey(ValueKey<String>('friend_${seedKey(i + 1)}')),
      findsOneWidget,
      reason: 'friend ${copy.friends[i].name}',
    );
  }
  expect(find.text(copy.requestMessage), findsOneWidget);
  await shots.capture(tester, locale, 'contacts');
  await popIfCan(tester);

  // Groups
  await selectTab(tester, ShellTab.groups);
  expectScreen(GroupList);
  final group = find.byKey(ValueKey<String>('group_${seed.groupId}'));
  expect(group, findsOneWidget, reason: 'seeded group in the list');
  await shots.capture(tester, locale, 'groups');
  await tapHittable(tester, group, 'group tile');
  await settle(tester, extra: const Duration(milliseconds: 300));
  expectScreen(ConversationScreen);
  expectBubble(copy.net.last.text);
  await shots.capture(tester, locale, 'group_conversation');
  await popIfCan(tester);

  await walkReference(tester, shots, s, locale);

  // Me
  await selectTab(tester, ShellTab.me);
  expectScreen(MePage);
  expect(find.text(copy.heroName), findsWidgets);
  await shots.capture(tester, locale, 'me');

  await tapHittable(
    tester,
    find.byKey(const ValueKey('me-network-bootstrap')),
    'network settings',
  );
  expectScreen(BootstrapPage);
  expect(find.text(s.bootstrapServiceUnavailable), findsNothing);
  final network = tester
      .element(find.byType(BootstrapPage))
      .read<NetworkBootstrapService?>()!;
  final current = network.configuration.current!;
  expect(
    find.byWidgetPredicate(
      (widget) => widget is SelectableText && widget.data == current.endpoint,
    ),
    findsOneWidget,
    reason: 'configured automatic bootstrap endpoint',
  );
  expect(find.byKey(const ValueKey('bootstrap-open-nodes')), findsOneWidget);
  await shots.capture(tester, locale, 'network_bootstrap');
}

/// Reference: the handbook, the translator and Listen. The chat app exposes these as secondary Morse tools.
Future<void> walkReference(
  WidgetTester tester,
  ShotHarness shots,
  S s,
  String locale,
) async {
  // Reference
  await selectTab(tester, ShellTab.reference);
  expectScreen(ReferencePage);
  await shots.capture(tester, locale, 'reference');
  await tapTooltip(tester, s.referenceTranslatorTitle);
  expectScreen(TranslatorScreen);
  const plain = 'CQ CQ DE DITMESH K';
  await tester.enterText(find.byKey(TextToMorseView.inputKey), plain);
  await settle(tester);
  final pattern = MorseEncoder.toPattern(plain);
  expect(
    find.byWidgetPredicate(
      (w) => w is MorsePatternText && w.pattern == pattern,
    ),
    findsOneWidget,
    reason: 'translator output for "$plain"',
  );
  await shots.capture(tester, locale, 'translator');
  await popIfCan(tester);
  await tapTooltip(tester, s.listenTitle);
  expectScreen(ListenScreen);
  await shots.capture(tester, locale, 'listen');
  await popIfCan(tester);
}

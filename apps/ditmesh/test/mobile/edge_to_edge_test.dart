// T3 (mobile review): Android 15+ enforces edge-to-edge (targetSdk 36), so
// the status and navigation bars draw over the app. The shell draws under
// them and keeps every interactive element inside the safe area: bottom
// navigation above the gesture / 3-button bar, the rail clear of the
// landscape notch and the tablet status bar, the composer above the home
// indicator.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/pages/chat_page.dart';
import 'package:ditmesh/ui/pages/groups_page.dart';
import 'package:ditmesh/ui/pages/me_page.dart';
import 'package:ditmesh/ui/pages/reference_page.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../chat/test_support.dart' as chat;
import '../learn/helpers/l10n.dart';
import 'phone_support.dart';

final List<String> _labels = <String>[
  ChatPage.title(en),
  GroupsPage.title(en),
  ReferencePage.title(en),
  MePage.title(en),
];

void main() {
  const Size phone = Size(390, 844);
  for (final (String nav, FakeViewPadding padding) in <(String, FakeViewPadding)>[
    ('gesture navigation', const FakeViewPadding(top: 47, bottom: 24)),
    ('3-button navigation', const FakeViewPadding(top: 24, bottom: 48)),
  ]) {
    testWidgets('bottom navigation draws under the $nav bar but keeps its '
        'destinations above it', (tester) async {
      setPhone(tester, phone, padding: padding);
      await bootApp(tester);
      final Rect bar = tester.getRect(find.byType(NavigationBar));
      expect(bar.bottom, phone.height, reason: 'edge-to-edge');
      for (final String label in _labels) {
        final Rect text = tester.getRect(navLabel(label));
        expect(text.bottom, lessThanOrEqualTo(phone.height - padding.bottom));
        expect(navLabel(label).hitTestable(), findsOneWidget);
      }
      // The page area ends where the bar begins: nothing hides behind it.
      expect(tester.getRect(find.byType(IndexedStack)).bottom, bar.top);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the rail keeps its destinations clear of the landscape notch', (
    tester,
  ) async {
    setPhone(tester, kLandscapePhone);
    await bootApp(tester);
    final Rect rail = tester.getRect(find.byType(NavigationRail));
    expect(rail.left, 0, reason: 'the rail surface runs under the notch');
    final Finder icons = find.descendant(
      of: find.byType(NavigationRail),
      matching: find.byType(Icon),
    );
    expect(icons, findsNWidgets(_labels.length));
    for (final Element icon in icons.evaluate()) {
      expect(tester.getRect(find.byWidget(icon.widget)).left, greaterThanOrEqualTo(47));
    }
  });

  testWidgets('the rail starts below a tablet status bar', (tester) async {
    setPhone(
      tester,
      const Size(1180, 820),
      padding: const FakeViewPadding(top: 24, bottom: 20),
    );
    await bootApp(tester);
    expect(
      tester.getRect(navLabel(_labels.first)).top,
      greaterThanOrEqualTo(24),
    );
  });

  testWidgets('the composer stays above the home indicator', (tester) async {
    final h = chat.ChatHarness();
    addTearDown(h.dispose);
    setPhone(tester, phone);
    h.addAnn();
    await tester.pumpWidget(
      h.wrap(
        ConversationScreen(
          target: ConversationTarget(
            id: 'c2c_${chat.kPeerKey}',
            title: 'Ann',
            kind: ConversationKind.c2c,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final Rect send = tester.getRect(find.byTooltip(chat.s.chatSend));
    expect(send.bottom, lessThanOrEqualTo(phone.height - 34));
  });
}

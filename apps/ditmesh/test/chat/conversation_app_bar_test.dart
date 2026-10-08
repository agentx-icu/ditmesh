// The conversation app bar on a phone: four action icons used to squeeze a
// group title like "Weekend Net" into "Weekend …" on a 402 pt iPhone. The
// less-used actions now fold into the overflow menu when the title would not
// fit, while desktop keeps every icon inline.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'test_support.dart';

/// Pushes the conversation the way the phone layout does, so the app bar
/// carries a back button like the real one.
typedef _Target = ConversationTarget Function(ChatHarness h);

Future<ChatHarness> _open(
  WidgetTester tester,
  _Target target, {
  required Size size,
}) async {
  final h = await pumpChat(tester, (_) => const SizedBox(), size: size);
  final ConversationTarget t = target(h);
  unawaited(
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ConversationScreen(target: t),
          ),
        ),
  );
  await tester.pumpAndSettle();
  return h;
}

_Target _group(String name) =>
    (h) => ConversationTarget.fromGroup(
      h.service.addFakeGroup(
        Group(id: 'tox_1', name: name, kind: GroupKind.group),
      ),
    );

_Target _friend(String name) => (h) {
  h.service.addFakeFriend(Friend(publicKey: kPeerKey, displayName: name));
  return ConversationTarget(
    id: 'c2c_$kPeerKey',
    title: name,
    kind: ConversationKind.c2c,
  );
};

void _expectFullTitle(WidgetTester tester, String title) {
  final RenderParagraph p = tester.renderObject(
    find.descendant(of: find.byType(AppBar), matching: find.text(title)),
  );
  expect(p.didExceedMaxLines, isFalse, reason: '"$title" is ellipsized');
}

Finder _inline(String tooltip) =>
    find.descendant(of: find.byType(AppBar), matching: find.byTooltip(tooltip));

Future<void> _openOverflow(WidgetTester tester) async {
  await tester.tap(find.byType(PopupMenuButton<String>));
  await tester.pumpAndSettle();
}

void main() {
  // The test font draws every glyph one em wide, so at the 22 px title size
  // a 6-letter name needs 132 px: 22 px more than four icons leave on a
  // 390 px phone with a back button, 26 px less than three icons leave.
  const String shortName = 'CW Net';
  // 8 letters (176 px) only fit beside the two fixed icons (206 px free).
  const String longName = 'Ragchews';

  for (final (String kind, _Target Function(String) target) in [
    ('group', _group),
    ('c2c', _friend),
  ]) {
    group('$kind conversation app bar', () {
      testWidgets('phone: playback settings folds into the menu', (
        tester,
      ) async {
        final h = await _open(tester, target(shortName), size: kPhone);
        _expectFullTitle(tester, shortName);
        expect(_inline(s.chatAutoPlay), findsOneWidget);
        expect(_inline(s.chatTrainingMode), findsOneWidget);
        expect(_inline(s.chatPlaybackSettings), findsNothing);

        await _openOverflow(tester);
        expect(find.text(s.chatClearHistory), findsOneWidget);
        await tester.tap(find.text(s.chatPlaybackSettings));
        await tester.pumpAndSettle();
        // The playback sheet opened from the menu entry.
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(h.settings.trainingMode, isFalse);
      });

      testWidgets('phone, longer name: training mode folds too', (
        tester,
      ) async {
        final h = await _open(tester, target(longName), size: kPhone);
        _expectFullTitle(tester, longName);
        // Auto-play is a state indicator and always stays visible.
        expect(_inline(s.chatAutoPlay), findsOneWidget);
        expect(_inline(s.chatTrainingMode), findsNothing);
        expect(_inline(s.chatPlaybackSettings), findsNothing);

        await _openOverflow(tester);
        expect(find.text(s.chatPlaybackSettings), findsOneWidget);
        await tester.tap(_trainingItem);
        await tester.pumpAndSettle();
        expect(h.settings.trainingMode, isTrue);
        expect(find.text(s.chatTrainingModeOn), findsOneWidget);

        // The menu entry reflects the toggled state.
        await _openOverflow(tester);
        final CheckedPopupMenuItem<String> item = tester.widget(_trainingItem);
        expect(item.checked, isTrue);
      });

      testWidgets('phone at 2x text: the title scale is capped like the '
          'AppBar caps it', (tester) async {
        // Regression (Codex review): AppBar clamps its title to 1.34x, so
        // 'ABC' takes 88 px, not 132 px, and all four icons still fit.
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        await _open(tester, target('ABC'), size: kPhone);
        _expectFullTitle(tester, 'ABC');
        expect(_inline(s.chatTrainingMode), findsOneWidget);
        expect(_inline(s.chatAutoPlay), findsOneWidget);
        expect(_inline(s.chatPlaybackSettings), findsOneWidget);
      });

      testWidgets('desktop: every action stays inline', (tester) async {
        await _open(tester, target(longName), size: kDesktop);
        _expectFullTitle(tester, longName);
        expect(_inline(s.chatTrainingMode), findsOneWidget);
        expect(_inline(s.chatAutoPlay), findsOneWidget);
        expect(_inline(s.chatPlaybackSettings), findsOneWidget);

        await _openOverflow(tester);
        expect(find.text(s.chatClearHistory), findsOneWidget);
        expect(find.text(s.chatPlaybackSettings), findsNothing);
        expect(_trainingItem, findsNothing);
      });
    });
  }
}

/// The training-mode entry (the menu also holds the listen-only toggle).
final Finder _trainingItem = find.widgetWithText(
  CheckedPopupMenuItem<String>,
  s.chatTrainingMode,
);

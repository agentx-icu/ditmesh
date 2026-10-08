// T4 / T1 (mobile review): leaving a screen through Android back, predictive
// back or the two-pane collapse must not lose keyed or typed input silently.
//
// * A conversation route is left without a dialog: the composer draft is
//   persisted through the shared draft writer, including a character that
//   was still half keyed when the route was popped.
// * The copy-practice screen (chat "practise", group practice rounds) asks
//   before leaving once there is an answer, like the receive and send drills.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:ditmesh/training/chat_copy_session.dart';
import 'package:ditmesh/ui/chat/conversation_route.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/chat/message_input.dart';
import 'package:ditmesh/ui/learn/chat_copy/chat_copy_screen.dart';
import 'package:ditmesh/ui/pages/chat_page.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../chat/test_support.dart';
import '../learn/helpers/fake_playback.dart';
import '../learn/helpers/l10n.dart';
import '../learn/helpers/test_controller.dart';

ConversationTarget _ann() => ConversationTarget(
  id: 'c2c_$kPeerKey',
  title: 'Ann',
  kind: ConversationKind.c2c,
);

/// A launcher page with the conversation pushed as a route (the phone
/// layout), so Android back has somewhere to go.
Future<ChatHarness> _openConversation(WidgetTester tester) async {
  final ChatHarness h = await pumpChat(tester, (h) {
    h.addAnn();
    return Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => pushConversation(context, _ann()),
            child: const Text('open'),
          ),
        ),
      ),
    );
  });
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(find.byType(ConversationScreen), findsOneWidget);
  return h;
}

/// Android back / predictive back: the platform asks the navigator to pop.
Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

Finder get _composerField => find.descendant(
  of: find.byType(MessageInput),
  matching: find.byType(TextField),
);

String _storedDraft(ChatHarness h) =>
    h.service.conversations.firstWhere((c) => c.id == 'c2c_$kPeerKey').draft;

void main() {
  group('conversation route', () {
    testWidgets('back keeps the keyed draft and shows it again on reopen', (
      tester,
    ) async {
      final ChatHarness h = await _openConversation(tester);
      await keyIn(tester, 'CQ');
      await _systemBack(tester);
      // No confirmation: the draft is persisted instead.
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(ConversationScreen), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(_storedDraft(h), 'CQ');

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(_composerField).controller?.text, 'CQ');
    });

    testWidgets('a character still being keyed lands in the draft on back', (
      tester,
    ) async {
      final ChatHarness h = await _openConversation(tester);
      // One dit, then back before the character gap elapsed: the decoder
      // still holds the pattern; the harness clock does not advance by
      // itself, so nothing commits it during the pop transition.
      final TestGesture gesture = await tester.press(
        find.byType(StraightKeyButton),
      );
      await tester.pump();
      h.clock.advance(const Duration(milliseconds: 60));
      await gesture.up();
      await tester.pump();
      expect(tester.widget<TextField>(_composerField).controller?.text, '');

      await _systemBack(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(_storedDraft(h), 'E');
    });
  });

  group('two-pane collapse (T1)', () {
    testWidgets('a character still being keyed survives the iPad rotation', (
      tester,
    ) async {
      final ChatHarness h = await pumpChat(tester, (h) {
        h.addAnn();
        return const ChatPage();
      }, size: const Size(1180, 820));
      await tester.tap(find.text('Ann').first);
      await tester.pumpAndSettle();
      final TestGesture gesture = await tester.press(
        find.byType(StraightKeyButton),
      );
      await tester.pump();
      h.clock.advance(const Duration(milliseconds: 60));
      await gesture.up();
      await tester.pump();

      tester.view.physicalSize = const Size(820, 1180);
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(_storedDraft(h), 'E');
      expect(tester.widget<TextField>(_composerField).controller?.text, 'E');
    });
  });

  group('copy practice', () {
    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final TestTraining t = await TestTraining.create();
      addTearDown(t.controller.dispose);
      final ChatCopySession session = ChatCopySession(
        text: 'CQ',
        conversationId: 'group_tox_1',
        messageId: 'm1',
        profileKey: t.controller.profileKey,
        timing: MorseTiming.koch20,
        toneHz: 600,
      );
      await tester.pumpWidget(
        l10nApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatCopyScreen(
                        controller: t.controller,
                        playback: FakeLearnPlaybackFactory(),
                        session: session,
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(ChatCopyScreen), findsOneWidget);
    }

    testWidgets('leaves freely before anything was answered', (tester) async {
      await open(tester);
      await _systemBack(tester);
      expect(find.text(en.learnLeaveDrillTitle), findsNothing);
      expect(find.byType(ChatCopyScreen), findsNothing);
    });

    testWidgets('asks before dropping a typed answer; cancel keeps it', (
      tester,
    ) async {
      await open(tester);
      await tester.enterText(find.byType(TextField), 'C');
      await tester.pump();

      await _systemBack(tester);
      expect(find.text(en.learnLeaveDrillTitle), findsOneWidget);
      await tester.tap(find.text(en.actionCancel));
      await tester.pumpAndSettle();
      expect(find.byType(ChatCopyScreen), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, 'C');

      await _systemBack(tester);
      await tester.tap(find.text(en.learnLeaveDrillConfirm));
      await tester.pumpAndSettle();
      expect(find.byType(ChatCopyScreen), findsNothing);
    });

    testWidgets('leaves freely once the answer was submitted', (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextField), 'CQ');
      await tester.pump();
      final Finder submit = find.byKey(const ValueKey('chat-practice-submit'));
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text(en.learnAccuracyPercent(100)), findsOneWidget);

      await _systemBack(tester);
      expect(find.text(en.learnLeaveDrillTitle), findsNothing);
      expect(find.byType(ChatCopyScreen), findsNothing);
    });
  });
}

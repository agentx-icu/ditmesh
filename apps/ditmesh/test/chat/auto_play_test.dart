import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/di/app_preferences.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/chat/input_mode.dart';
import 'package:ditmesh/ui/chat/morse_playback_controller.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'test_support.dart';

ConversationTarget _ann() => ConversationTarget(
  id: 'c2c_$kPeerKey',
  title: 'Ann',
  kind: ConversationKind.c2c,
);

class _Visibility extends StatefulWidget {
  const _Visibility({required this.child});

  final Widget child;

  @override
  State<_Visibility> createState() => _VisibilityState();
}

class _VisibilityState extends State<_Visibility> {
  bool visible = true;

  @override
  Widget build(BuildContext context) =>
      TickerMode(enabled: visible, child: widget.child);
}

Future<ChatHarness> _open(WidgetTester tester) => pumpChat(tester, (h) {
  h.addAnn();
  return _Visibility(child: ConversationScreen(target: _ann()));
});

void main() {
  group('auto-play', () {
    testWidgets('off by default: a received message stays silent', (
      tester,
    ) async {
      final h = await _open(tester);
      h.service.receiveMessage('c2c_$kPeerKey', 'R');
      await tester.pumpAndSettle();
      expect(h.playback.playingId, isNull);
    });

    testWidgets('the app-bar toggle plays new messages in order', (
      tester,
    ) async {
      final h = await _open(tester);
      await tester.tap(find.byTooltip(s.chatAutoPlay));
      await tester.pumpAndSettle();
      expect(h.settings.autoPlay, isTrue);
      expect(find.text(s.chatAutoPlayOn), findsOneWidget);

      final first = h.service.receiveMessage('c2c_$kPeerKey', 'R');
      final second = h.service.receiveMessage('c2c_$kPeerKey', 'TU');
      await tester.pump();
      expect(h.playback.playingId, first.id);
      // History already on screen is never auto-played.
      expect(h.playback.queuedIds, [second.id]);

      // Turning it off silences the backlog and the message sounding.
      await tester.tap(find.byTooltip(s.chatAutoPlay));
      await tester.pumpAndSettle();
      expect(h.playback.playingId, isNull);
      expect(h.playback.queuedIds, isEmpty);
    });

    testWidgets('own sends are not auto-played', (tester) async {
      final h = await _open(tester);
      h.settings.autoPlay = true;
      await keyIn(tester, 'CQ');
      await tester.tap(find.byTooltip(s.chatSend));
      await tester.pumpAndSettle();
      expect(h.playback.playingId, isNull);
    });

    testWidgets('hiding the conversation silences it and keeps it silent', (
      tester,
    ) async {
      final h = await _open(tester);
      h.settings.autoPlay = true;
      h.service.receiveMessage('c2c_$kPeerKey', 'R');
      h.service.receiveMessage('c2c_$kPeerKey', 'TU');
      await tester.pump();
      expect(h.playback.isPlaying, isTrue);
      tester.state<_VisibilityState>(find.byType(_Visibility))
        ..visible = false
        // ignore: invalid_use_of_protected_member
        ..setState(() {});
      await tester.pumpAndSettle();
      expect(h.playback.isPlaying, isFalse);
      expect(h.playback.queuedIds, isEmpty);
      h.service.receiveMessage('c2c_$kPeerKey', 'K');
      await tester.pump();
      expect(h.playback.isPlaying, isFalse);
    });

    testWidgets('backgrounding the app stops auto-play', (tester) async {
      final h = await _open(tester);
      h.settings.autoPlay = true;
      h.service.receiveMessage('c2c_$kPeerKey', 'R');
      h.service.receiveMessage('c2c_$kPeerKey', 'TU');
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();
      expect(h.playback.isPlaying, isFalse);
      expect(h.playback.queuedIds, isEmpty);
      h.service.receiveMessage('c2c_$kPeerKey', 'K');
      await tester.pump();
      expect(h.playback.isPlaying, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
    });

    testWidgets('inactive (a call banner, control centre) holds auto-play '
        'until resumed', (tester) async {
      final h = await _open(tester);
      h.settings.autoPlay = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      final first = h.service.receiveMessage('c2c_$kPeerKey', 'R');
      final second = h.service.receiveMessage('c2c_$kPeerKey', 'TU');
      await tester.pump();
      expect(h.playback.isPlaying, isFalse);
      // Queued, under the controller's limits, but held.
      expect(h.playback.queuedIds, [first.id, second.id]);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(h.playback.playingId, first.id);
      expect(h.playback.queuedIds, [second.id]);
    });

    testWidgets('a message already queued does not start while inactive', (
      tester,
    ) async {
      final h = await _open(tester);
      h.settings.autoPlay = true;
      final first = h.service.receiveMessage('c2c_$kPeerKey', 'E');
      final second = h.service.receiveMessage('c2c_$kPeerKey', 'TU');
      await tester.pump();
      expect(h.playback.playingId, first.id);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      // The first clip ends under the overlay: the next one must wait.
      h.clock.advance(const Duration(seconds: 2));
      await tester.pump();
      expect(h.playback.isPlaying, isFalse);
      expect(h.playback.queuedIds, [second.id]);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(h.playback.playingId, second.id);
    });

    testWidgets('a flood while inactive keeps only the newest messages', (
      tester,
    ) async {
      final h = await _open(tester);
      h.settings.autoPlay = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      for (var i = 0; i < 12; i++) {
        h.service.receiveMessage('c2c_$kPeerKey', 'E');
      }
      await tester.pump();
      expect(h.playback.isPlaying, isFalse);
      expect(
        h.playback.queuedIds.length,
        MorsePlaybackController.maxQueuedAuto,
      );
    });

    testWidgets('closing an inactive conversation drops its queue and '
        'releases the hold', (tester) async {
      final h = await _open(tester);
      h.settings.autoPlay = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      h.service.receiveMessage('c2c_$kPeerKey', 'R');
      await tester.pump();
      expect(h.playback.queuedIds, hasLength(1));
      expect(h.playback.holdAutomatic, isTrue);
      await tester.pumpWidget(h.wrap(const SizedBox()));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(h.playback.queuedIds, isEmpty);
      expect(h.playback.holdAutomatic, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });

    testWidgets('messages held while inactive are dropped when the app goes '
        'to the background instead', (tester) async {
      final h = await _open(tester);
      h.settings.autoPlay = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      h.service.receiveMessage('c2c_$kPeerKey', 'R');
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      // The resume sequence: a message arriving between hidden and resumed
      // waits too; the one from before the background period is gone.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      final late = h.service.receiveMessage('c2c_$kPeerKey', 'K');
      await tester.pump();
      expect(h.playback.isPlaying, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(h.playback.playingId, late.id);
      expect(h.playback.queuedIds, isEmpty);
    });

    testWidgets('the playback sheet has the switch too', (tester) async {
      final h = await _open(tester);
      await tester.tap(find.byTooltip(s.chatPlaybackSettings));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(s.chatAutoPlay));
      await tester.pumpAndSettle();
      await tester.tap(find.text(s.chatAutoPlay));
      await tester.pumpAndSettle();
      expect(h.settings.autoPlay, isTrue);
    });
  });

  group('keyed composer', () {
    testWidgets('has no typed-text mode and a read-only draft', (tester) async {
      await _open(tester);
      expect(find.byTooltip(s.chatModeStraightKey), findsOneWidget);
      expect(find.byTooltip(s.chatModePaddles), findsOneWidget);
      expect(find.text('KEY'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.readOnly, isTrue);
      expect(field.canRequestFocus, isFalse);
      expect(find.text(s.chatKeyMessage), findsOneWidget);
    });

    test('a stored typed-text mode falls back to the straight key', () {
      final prefs = AppPreferences(
        InMemoryKeyValueStore({
          'chat.playback': '{"inputMode":"keyboard","autoPlay":true}',
        }),
        backendLabel: 'test',
        identity: StubIdentityService(),
      );
      addTearDown(prefs.dispose);
      expect(prefs.playback.inputMode, InputMode.straightKey);
      expect(prefs.playback.autoPlay, isTrue);
    });
  });
}

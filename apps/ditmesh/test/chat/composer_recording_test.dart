import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/chat/message_input.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh/keying/key_profiles.dart';
import 'package:ditmesh/keying/key_profile.dart';
import 'package:ditmesh/i18n/key_value_store.dart';
import 'package:morse_core/morse_core.dart';
import 'package:provider/provider.dart';
import 'test_support.dart';

final _target = ConversationTarget(
  id: 'c2c_$kPeerKey',
  title: 'Ann',
  kind: ConversationKind.c2c,
);
void main() {
  testWidgets('draft preview can play its actual recording before send', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      h.settings.originalRhythm = true;
      return ConversationScreen(target: _target);
    });
    final gesture = await tester.press(find.byType(StraightKeyButton));
    h.clock.advance(const Duration(milliseconds: 93));
    await gesture.up();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('draft-preview')));
    h.clock.advance(const Duration(milliseconds: 1500));
    await tester.pump();
    expect(h.playback.usingOriginal, isTrue);
    expect(h.playback.total.inMilliseconds, 93);
    expect(await h.service.loadHistory(_target.id), isEmpty);
  });
  testWidgets('touch and keyboard keep actual spans after correction', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return ConversationScreen(target: _target);
    });
    final gesture = await tester.press(find.byType(StraightKeyButton));
    h.clock.advance(const Duration(milliseconds: 73));
    await gesture.up();
    h.clock.advance(const Duration(milliseconds: 511));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    h.clock.advance(const Duration(milliseconds: 237));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.tap(find.byKey(const ValueKey('draft-preview')));
    await tester.pump();
    await tester.tap(find.byTooltip(s.chatDeleteLast));
    await tester.pump();
    h.clock.advance(const Duration(milliseconds: 302));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    h.clock.advance(const Duration(milliseconds: 89));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.tap(find.byTooltip(s.chatSend));
    await tester.pumpAndSettle();
    final message = (await h.service.loadHistory(_target.id)).single;
    expect(message.text, 'E E');
    expect(message.recording?.durationsMs, [73, 1050, 89]);
  });
  testWidgets('sidetone off still records and takes priority over playback', (
    tester,
  ) async {
    final profiles = KeyProfiles(InMemoryKeyValueStore());
    await profiles.save(
      KeyProfile.defaults.copyWith(
        id: 'silent',
        name: 'Silent',
        appSidetone: false,
      ),
    );
    addTearDown(profiles.dispose);
    final h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return ChangeNotifierProvider<KeyProfiles>.value(
        value: profiles,
        child: ConversationScreen(target: _target),
      );
    });
    await h.playback.play('old', 'TEST', const MorseTiming(wpm: 20));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    expect(h.playback.playingId, isNull);
    h.clock.advance(const Duration(milliseconds: 93));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.byTooltip(s.chatSend));
    await tester.pumpAndSettle();
    expect(
      (await h.service.loadHistory(_target.id)).single.recording?.durationsMs,
      [93],
    );
  });
  testWidgets('send finishes an in-flight paddle dah in its recording', (
    tester,
  ) async {
    final h = ChatHarness();
    h.settings.inputMode = InputMode.paddles;
    await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return ConversationScreen(target: _target);
    }, harness: h);
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('DAH')),
    );
    h.clock.advance(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byTooltip(s.chatSend));
    await gesture.up();
    await tester.pumpAndSettle();
    final message = (await h.service.loadHistory(_target.id)).single;
    expect(message.text, 'T');
    expect(message.recording?.durationsMs, [240]);
  });
  testWidgets(
    'raw pattern deletion is atomic and preserves the earlier prosign trace',
    (tester) async {
      final h = await pumpChat(tester, (h) {
        h.addAnn(withMessage: false);
        return ConversationScreen(target: _target);
      });
      Future<void> pattern(String symbols) async {
        for (var i = 0; i < symbols.length; i++) {
          await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
          h.clock.advance(Duration(milliseconds: symbols[i] == '-' ? 240 : 80));
          await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
          if (i + 1 < symbols.length) {
            h.clock.advance(const Duration(milliseconds: 80));
          }
        }
        await tester.tap(find.byKey(const ValueKey('draft-preview')));
        await tester.pump();
      }

      await pattern('...-.-');
      h.clock.advance(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 40));
      await pattern('..--.');
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '<SK> <..--.>');
      await tester.tap(find.byTooltip(s.chatDeleteLast));
      await tester.pump();
      expect(field.controller!.text, '<SK> ');
      await tester.tap(find.byTooltip(s.chatSend));
      await tester.pumpAndSettle();
      final message = (await h.service.loadHistory(_target.id)).single;
      expect(message.text, '<SK>');
      expect(message.recording?.durationsMs, [
        80,
        80,
        80,
        80,
        80,
        80,
        240,
        80,
        80,
        80,
        240,
      ]);
    },
  );
  testWidgets('send releases a held straight mark into the original trace', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return ConversationScreen(target: _target);
    });
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    h.clock.advance(const Duration(milliseconds: 67));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.byTooltip(s.chatSend));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(
      (await h.service.loadHistory(_target.id)).single.recording?.durationsMs,
      [67],
    );
  });
  testWidgets('two live editors share recording and final text', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              for (var i = 0; i < 2; i++)
                MessageInput(
                  service: h.service,
                  conversationId: _target.id,
                  playback: h.playback,
                ),
            ],
          ),
        ),
      );
    }, size: kDesktop);
    var gesture = await tester.press(find.byType(StraightKeyButton).first);
    h.clock.advance(const Duration(milliseconds: 73));
    await gesture.up();
    await tester.tap(find.byKey(const ValueKey('draft-preview')).first);
    await tester.pump();
    h.clock.advance(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 40));
    gesture = await tester.press(find.byType(StraightKeyButton).last);
    h.clock.advance(const Duration(milliseconds: 240));
    await gesture.up();
    await tester.tap(find.byTooltip(s.chatSend).last);
    await tester.pumpAndSettle();
    final message = (await h.service.loadHistory(_target.id)).single;
    expect(message.text, 'E T');
    expect(message.recording?.durationsMs, [73, 600, 240]);
  });
  testWidgets('mode rebuilding preserves previous recorded token', (
    tester,
  ) async {
    final h = await pumpChat(tester, (h) {
      h.addAnn(withMessage: false);
      return ConversationScreen(target: _target);
    });
    final gesture = await tester.press(find.byType(StraightKeyButton));
    h.clock.advance(const Duration(milliseconds: 73));
    await gesture.up();
    await tester.tap(find.byTooltip(s.chatModePaddles));
    await tester.pump();
    h.clock.advance(const Duration(milliseconds: 600));
    final paddle = await tester.startGesture(
      tester.getCenter(find.text('DAH')),
    );
    h.clock.advance(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byTooltip(s.chatSend));
    await paddle.up();
    await tester.pumpAndSettle();
    final message = (await h.service.loadHistory(_target.id)).single;
    // The new decoder has no prior marks and therefore emits no word event.
    expect(message.text, 'ET');
    expect(message.recording?.durationsMs, [73, 600, 240]);
  });
  testWidgets('text-only restored draft sends without fabricated original', (
    tester,
  ) async {
    final h = ChatHarness();
    h.addAnn(withMessage: false);
    await h.service.setDraft(_target.id, 'CQ');
    await pumpChat(
      tester,
      (h) => ConversationScreen(target: _target),
      harness: h,
    );
    await tester.tap(find.byTooltip(s.chatSend));
    await tester.pumpAndSettle();
    expect((await h.service.loadHistory(_target.id)).single.recording, isNull);
  });
}

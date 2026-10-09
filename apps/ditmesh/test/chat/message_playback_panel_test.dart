import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show PipelineOwner;
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/chat/message_playback_panel.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'test_support.dart';

void main() {
  testWidgets(
    'late recording updates an open panel without restarting playback',
    (tester) async {
      final h = ChatHarness()..addAnn(withMessage: false);
      final message = h.service.receiveMessage('c2c_$kPeerKey', 'E T');
      h.settings.originalRhythm = true;
      await pumpChat(
        tester,
        (h) => Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showMessagePlaybackPanel(
                context,
                message: message,
                settings: h.settings,
                playback: h.playback,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
        harness: h,
      );
      await h.playback.play(
        message.id,
        message.text,
        h.settings.timing,
        original: true,
      );
      final originalTotal = h.playback.total;
      await tester.tap(find.text('Open'));
      // Event before the modal's first frame must be retained.
      h.service.attachRecording(
        message.id,
        KeyedRecording(durationsMs: [73, 517, 249]),
      );
      await tester.pumpAndSettle();
      expect(find.text(s.chatOriginalAvailable), findsOneWidget);
      expect(h.playback.total, originalTotal);
      expect(h.playback.usingOriginal, isFalse);
      await tester.tap(find.byKey(const ValueKey('player-repeat-range')));
      await tester.pump();
      expect(h.playback.usingOriginal, isTrue);
      expect(h.playback.total.inMilliseconds, 839);
      Navigator.of(tester.element(find.byType(MessagePlaybackPanel))).pop();
      await tester.pumpAndSettle();
      h.service.attachRecording(
        message.id,
        KeyedRecording(durationsMs: [80, 400, 240]),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  for (final (scale, size) in [
    (2.0, const Size(667, 375)),
    (3.0, const Size(667, 375)),
    (3.0, const Size(320, 640)),
  ]) {
    testWidgets(
      'modal word controls scroll at ${scale}x text on ${size.width} phone',
      (tester) async {
        final h = ChatHarness()..addAnn(withMessage: false);
        final message = h.service.receiveMessage('c2c_$kPeerKey', 'E SECRET');
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(h.dispose);
        await tester.pumpWidget(
          h.wrap(
            Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showMessagePlaybackPanel(
                    context,
                    message: message,
                    settings: h.settings,
                    playback: h.playback,
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
            textScaler: TextScaler.linear(scale),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('player-repeat-range')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('player-repeat-range')));
        await tester.pump();
        expect(h.playback.playingId, message.id);
        expect(tester.takeException(), isNull);
        Navigator.of(tester.element(find.byType(MessagePlaybackPanel))).pop();
        await tester.pumpAndSettle();
      },
    );
  }
  for (final size in [const Size(320, 640), kDesktop]) {
    testWidgets(
      'word controls fit ${size.width} and never reveal hidden text',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final h = await pumpChat(
          tester,
          (h) => Scaffold(
            body: MessagePlaybackPanel(
              message: ChatMessage(
                id: 'm',
                conversationId: 'c2c_$kPeerKey',
                senderId: kPeerKey,
                text: 'E SECRET',
                timestamp: DateTime(2026),
                isMine: false,
                status: MessageStatus.sent,
              ),
              settings: h.settings..listenOnly = true,
              playback: h.playback,
            ),
          ),
          size: size,
        );
        expect(find.textContaining('SECRET'), findsNothing);
        expect(_semanticsTree(tester), isNot(contains('SECRET')));
        expect(find.text(s.chatOriginalUnavailable), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('player-repeat-range')));
        await tester.pump();
        expect(h.playback.playingId, 'm');
        await tester.tap(find.byKey(const ValueKey('player-pause')));
        await tester.pump();
        expect(h.playback.isPaused, isTrue);
        expect(find.textContaining('SECRET'), findsNothing);
        expect(_semanticsTree(tester), isNot(contains('SECRET')));
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
}

String _semanticsTree(WidgetTester tester) {
  final lines = <String>[];
  void collect(PipelineOwner owner) {
    final root = owner.semanticsOwner?.rootSemanticsNode;
    if (root != null) lines.add(root.toStringDeep());
    owner.visitChildren(collect);
  }

  collect(tester.binding.rootPipelineOwner);
  return lines.join('\n');
}

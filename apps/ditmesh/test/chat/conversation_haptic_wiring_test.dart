import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_io/testing.dart';
import 'package:ditmesh/training/training_controller_host.dart';
import 'package:ditmesh/training/training_settings.dart';
import 'package:ditmesh/training/training_settings_store.dart';
import 'package:ditmesh/ui/chat/conversation_screen.dart';
import 'package:ditmesh/ui/chat/conversation_target.dart';
import 'package:ditmesh/ui/chat/morse_playback_controller.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import 'test_support.dart';

void main() {
  testWidgets(
    'saved vibration preference controls actual chat key and message actions',
    (tester) async {
      tester.view.physicalSize = kPhone;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = ChatHarness()..addAnn();
      addTearDown(h.dispose);
      final sound = RecordingSink(clock: h.clock);
      final vibration = RecordingSink(clock: h.clock);
      final playback = MorsePlaybackController(
        sink: sound,
        haptic: vibration,
        clock: h.clock,
      );
      addTearDown(playback.dispose);
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('ditmesh-chat-haptics-'),
      ))!;
      addTearDown(() => directory.delete(recursive: true));
      final store = FileTrainingSettingsStore.inDataDirectory(directory.path);
      await tester.runAsync(
        () => store.save(const TrainingSettings(hapticEnabled: true)),
      );
      final identity = StubIdentityService(dataDirectoryPath: directory.path);
      var host = TrainingControllerHost(identity);
      addTearDown(() => host.dispose());
      var training = (await tester.runAsync(host.controller))!;
      expect(training.settings.hapticEnabled, isTrue);

      Widget chat({bool includeHost = true}) => h.wrap(
        MultiProvider(
          providers: [
            Provider<IdentityService>.value(value: identity),
            if (includeHost)
              Provider<TrainingControllerHost?>.value(value: host),
            ChangeNotifierProvider<MorsePlaybackController>.value(
              value: playback,
            ),
          ],
          child: ConversationScreen(
            target: ConversationTarget(
              id: 'c2c_$kPeerKey',
              title: 'Ann',
              kind: ConversationKind.c2c,
            ),
          ),
        ),
      );

      Future<void> key({required bool vibrates}) async {
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(StraightKeyButton)),
        );
        await tester.pump();
        expect(sound.isOn, isTrue);
        expect(vibration.isOn, vibrates);
        h.clock.advance(const Duration(milliseconds: 60));
        await gesture.up();
        await tester.pump();
        h.clock.advance(MorsePlaybackController.keyingHoldoff);
        await tester.pump();
      }

      Future<void> playMessage({required bool vibrates}) async {
        await tester.tap(find.byTooltip(s.chatPlay));
        await tester.pumpAndSettle();
        expect(playback.isPlaying, isTrue);
        expect(sound.isOn, isTrue);
        expect(vibration.isOn, vibrates);
      }

      await tester.pumpWidget(chat());
      // The host's file I/O completes in runAsync's real event loop.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(playback.hapticEnabled, isTrue);
      await key(vibrates: true);
      await playMessage(vibrates: true);

      // Change the same per-identity setting the training page persists.
      await tester.runAsync(
        () => training.updateSettings(
          training.settings.copyWith(hapticEnabled: false),
        ),
      );
      await tester.pump();
      expect(
        vibration.isOn,
        isFalse,
        reason: 'stop the pulse already sounding',
      );
      expect(sound.isOn, isTrue, reason: 'keep audio independent');
      playback.stop();
      await tester.pump();
      await key(vibrates: false);
      await playMessage(vibrates: false);
      playback.stop();
      final persisted = await tester.runAsync(store.load);
      expect(persisted!.hapticEnabled, isFalse);

      // Reopening resolves the persisted preference through a fresh shared host.
      await tester.pumpWidget(h.wrap(const SizedBox()));
      await tester.pump();
      await host.dispose();
      host = TrainingControllerHost(identity);
      training = (await tester.runAsync(host.controller))!;
      expect(training.settings.hapticEnabled, isFalse);
      await tester.pumpWidget(chat());
      // The host's file I/O completes in runAsync's real event loop.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(playback.hapticEnabled, isFalse);
      await key(vibrates: false);
      await playMessage(vibrates: false);
      playback.stop();

      // Minimal isolated chat trees without a training host stay off as well.
      await tester.pumpWidget(h.wrap(const SizedBox()));
      await tester.pump();
      await tester.pumpWidget(chat(includeHost: false));
      await tester.pumpAndSettle();
      expect(playback.hapticEnabled, isFalse);
      await key(vibrates: false);
      await playMessage(vibrates: false);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
}

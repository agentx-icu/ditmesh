import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../i18n/l10n_extension.dart';
import '../../training/chat_copy_session.dart';
import '../../training/training_controller.dart';
import '../../training/training_controller_host.dart';
import '../learn/chat_copy/chat_copy_screen.dart';
import '../learn/learn_playback.dart';
import 'chat_layout.dart';
import 'morse_playback_controller.dart';
import 'morse_playback_settings.dart';

/// Chat-to-learning entry points (functional spec §6): practise a received
/// message on a separate page.
/// Nothing here sends anything or touches the conversation's draft.
abstract final class ConversationLearning {
  /// The app-wide per-identity controller. Only the shared host is used:
  /// a second controller on the same files would overwrite the first.
  static TrainingControllerHost? _host(BuildContext context) {
    try {
      return context.read<TrainingControllerHost?>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  static Future<TrainingController?> _controller(BuildContext context) async {
    try {
      final host = _host(context);
      if (host == null) throw StateError('no training host');
      return await host.controller();
    } on Object {
      if (context.mounted) showSnack(context, context.s.learnIdentityRequired);
      return null;
    }
  }

  static LearnPlaybackFactory _playbackFactory(BuildContext context) {
    try {
      return context.read<LearnPlaybackFactory>();
    } on ProviderNotFoundException {
      return const DevicePlaybackFactory();
    }
  }

  /// Opens copy practice for [message]. Conversation auto-play is paused
  /// while practising and restored afterwards only when the conversation is
  /// still shown and nobody changed the switch in between; messages that
  /// arrived meanwhile are not replayed.
  static Future<void> practise(
    BuildContext context, {
    required ChatMessage message,
    required MorsePlaybackSettings settings,
    required MorsePlaybackController playback,
    required String title,
  }) async {
    final controller = await _controller(context);
    if (controller == null || !context.mounted) return;
    final wasAuto = settings.autoPlay;
    // Only a change of the auto-play switch itself counts as the learner
    // deciding; other playback settings may change freely meanwhile.
    var touched = false;
    void watch() {
      if (settings.autoPlay) touched = true;
    }

    playback.stop();
    if (wasAuto) settings.autoPlay = false;
    settings.addListener(watch);
    final session = ChatCopySession(
      text: message.text,
      conversationId: message.conversationId,
      messageId: message.id,
      profileKey: controller.profileKey,
      timing: settings.timing,
      toneHz: settings.toneHz,
    );
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatCopyScreen(
            controller: controller,
            playback: _playbackFactory(context),
            session: session,
          ),
        ),
      );
    } finally {
      // The practice route is still animating out: wait until the
      // conversation is uncovered (still watching for the learner's own
      // toggles meanwhile) before judging whether it is visible.
      if (context.mounted) await _uncovered(ModalRoute.of(context));
      settings.removeListener(watch);
      if (wasAuto &&
          !touched &&
          !settings.autoPlay &&
          context.mounted &&
          _stillShowing(context) &&
          _sameProfile(context, controller)) {
        settings.autoPlay = true;
      }
    }
  }

  static Future<void> _uncovered(ModalRoute<Object?>? route) async {
    final secondary = route?.secondaryAnimation;
    if (secondary == null || secondary.status == AnimationStatus.dismissed) {
      return;
    }
    final done = Completer<void>();
    void onStatus(AnimationStatus status) {
      if (status == AnimationStatus.dismissed && !done.isCompleted) {
        done.complete();
      }
    }

    secondary.addStatusListener(onStatus);
    try {
      await done.future.timeout(const Duration(seconds: 2), onTimeout: () {});
    } finally {
      secondary.removeStatusListener(onStatus);
    }
  }

  /// The original conversation is mounted, on top and not in a hidden tab.
  static bool _stillShowing(BuildContext context) =>
      context.mounted &&
      (ModalRoute.of(context)?.isCurrent ?? true) &&
      TickerMode.valuesOf(context).enabled;

  /// The identity that owned the practice is still the open one.
  static bool _sameProfile(
    BuildContext context,
    TrainingController controller,
  ) {
    try {
      final key = context.read<IdentityService>().current?.publicKey;
      // No open identity (deleted, being replaced): never restore. An
      // unnamed controller (isolated screens) cannot be told apart.
      if (key == null || controller.isDisposed) return false;
      return controller.profileKey.isEmpty || key == controller.profileKey;
    } on Object {
      return false;
    }
  }

}

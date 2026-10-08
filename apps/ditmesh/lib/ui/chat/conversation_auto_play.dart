import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'morse_playback_controller.dart';
import 'morse_playback_settings.dart';

/// A conversation screen's link between the auto-play switch and its
/// [MorsePlaybackController]: queues received messages while auto-play is on,
/// and silences playback when the switch goes off, the screen is no longer
/// visible, or the app leaves the foreground.
///
/// Playback starts only while the app is `resumed`. While it is `inactive`
/// (an incoming-call banner, control centre, a permission dialog, the
/// `hidden - inactive - resumed` return from the background) received
/// messages still join the controller's queue under its usual limits, but
/// the controller holds every automatic start ([MorsePlaybackController.holdAutomatic])
/// until `resumed`; if the app goes to the background instead the queue is
/// dropped, like every message received in the background.
///
/// Audio-session policy (mobile review A1, 2026-10-08): auto-played messages
/// sound through the same engine and session as the user's own sidetone
/// (iOS `playback` + `mixWithOthers`, Android media attributes without audio
/// focus), so they are heard with the silent switch on and over another app's
/// music. That is deliberate: auto-play is opt-in and off by default, limited
/// to the open conversation in the foreground, and capped by the controller's
/// queue and clip limits, so a user who enabled it asked to hear messages.
/// Switching the session category per clip would glitch the audio route and
/// collide with Listen's `playAndRecord` restore, and cannot separate keying
/// from auto-play anyway. Focus modes only affect notifications. Auto-play
/// also drives the haptic sink, which stops on its own when the app leaves
/// the foreground. Any future silent-switch awareness belongs here, as a
/// decision before enqueueing, not in the session configuration.
class ConversationAutoPlay with WidgetsBindingObserver {
  ConversationAutoPlay(this._playback) {
    WidgetsBinding.instance.addObserver(this);
    _playback.holdAutomatic =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.inactive;
  }

  final MorsePlaybackController _playback;
  MorsePlaybackSettings? _settings;
  bool _autoPlay = false;
  bool _visible = true;
  bool _disposed = false;

  /// Call from `didChangeDependencies`: picks up the settings instance and
  /// whether the screen is visible (a hidden shell tab or a covered route
  /// disables tickers, and must not sound).
  void update(BuildContext context) {
    final settings = MorsePlaybackSettings.of(context, listen: false);
    if (!identical(settings, _settings)) {
      _settings?.removeListener(_onSettings);
      _settings = settings..addListener(_onSettings);
      _autoPlay = settings.autoPlay;
    }
    final bool visible = TickerMode.valuesOf(context).enabled;
    if (_visible && !visible) {
      // Called during build: listeners may not be notified until it is over.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed && !_visible) _playback.stop();
      });
    }
    _visible = visible;
  }

  void _onSettings() {
    final bool on = _settings!.autoPlay;
    if (_autoPlay && !on) {
      _playback.cancel(PlaybackOrigin.auto, includeCurrent: true);
    }
    _autoPlay = on;
  }

  /// `null` only where no lifecycle is reported (tests without a binding
  /// state); `detached` is the engine's seed state before the first frame
  /// and the teardown state after `paused`, never a moment to sound.
  static bool _background(AppLifecycleState? state) =>
      state == AppLifecycleState.hidden ||
      state == AppLifecycleState.paused ||
      state == AppLifecycleState.detached;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_background(state)) {
      _playback.cancel(PlaybackOrigin.auto, includeCurrent: true);
    }
    _playback.holdAutomatic = state == AppLifecycleState.inactive;
  }

  /// A message from someone else just arrived live in this conversation.
  /// While `inactive` it queues like any other; the controller holds the
  /// start until `resumed`.
  void incoming(ChatMessage message) {
    final MorsePlaybackSettings? settings = _settings;
    if (settings == null || !settings.autoPlay || !_visible) return;
    if (_background(WidgetsBinding.instance.lifecycleState)) return;
    _playback.enqueue(
      message.id,
      message.text,
      settings.timing,
      toneHz: settings.toneHz,
    );
  }

  void dispose() {
    _disposed = true;
    // This conversation's queued messages leave with it. The hold itself is
    // released after the unmount: clearing it starts the next clip, which
    // notifies listeners, and the tree is locked right now.
    _playback.cancel(PlaybackOrigin.auto);
    final MorsePlaybackController playback = _playback;
    scheduleMicrotask(() => playback.holdAutomatic = false);
    WidgetsBinding.instance.removeObserver(this);
    _settings?.removeListener(_onSettings);
  }
}

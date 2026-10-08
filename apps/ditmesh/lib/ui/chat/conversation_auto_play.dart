import 'package:flutter/widgets.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'morse_playback_controller.dart';
import 'morse_playback_settings.dart';

/// A conversation screen's link between the auto-play switch and its
/// [MorsePlaybackController]: queues received messages while auto-play is on,
/// and silences playback when the switch goes off, the screen is no longer
/// visible, or the app leaves the foreground.
class ConversationAutoPlay with WidgetsBindingObserver {
  ConversationAutoPlay(this._playback) {
    WidgetsBinding.instance.addObserver(this);
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

  static bool _foreground(AppLifecycleState? state) =>
      state == null ||
      state == AppLifecycleState.resumed ||
      state == AppLifecycleState.inactive;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_foreground(state)) {
      _playback.cancel(PlaybackOrigin.auto, includeCurrent: true);
    }
  }

  /// A message from someone else just arrived live in this conversation.
  void incoming(ChatMessage message) {
    final MorsePlaybackSettings? settings = _settings;
    if (settings == null ||
        !settings.autoPlay ||
        !_visible ||
        !_foreground(WidgetsBinding.instance.lifecycleState)) {
      return;
    }
    _playback.enqueue(
      message.id,
      message.text,
      settings.timing,
      toneHz: settings.toneHz,
    );
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _settings?.removeListener(_onSettings);
  }
}

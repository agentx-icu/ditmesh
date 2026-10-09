import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'input_mode.dart';
import 'morse_playback_settings.dart';

/// Per-account conversation overrides. Old identity models are detached before
/// a new account is hydrated, so a covered route cannot save into its successor.
class ConversationPlaybackPreferences extends ChangeNotifier {
  final Map<String, MorsePlaybackSettings> _models = {};
  final Map<String, Object?> _stored = {};

  static MorsePlaybackSettings settingsFor(
    BuildContext context,
    String id, {
    bool listen = true,
  }) {
    final defaults = MorsePlaybackSettings.of(context, listen: listen);
    final registry = Provider.of<ConversationPlaybackPreferences?>(
      context,
      listen: listen,
    );
    return registry?.forConversation(id, defaults) ?? defaults;
  }

  MorsePlaybackSettings forConversation(
    String id,
    MorsePlaybackSettings defaults,
  ) => _models.putIfAbsent(id, () {
    final saved = _stored[id];
    final values = saved is Map ? saved : defaults.toJson();
    double number(String key, double fallback, double low, double high) {
      final value = values[key];
      return value is num && value.isFinite
          ? value.toDouble().clamp(low, high)
          : fallback;
    }

    bool flag(String key, bool fallback) =>
        values[key] is bool ? values[key] as bool : fallback;
    final wpm = number('wpm', defaults.wpm, 5, 40);
    final settings = MorsePlaybackSettings(
      wpm: wpm,
      farnsworthWpm: number(
        'farnsworthWpm',
        defaults.farnsworthWpm.clamp(5, wpm),
        5,
        wpm,
      ),
      toneHz: number('toneHz', defaults.toneHz, 400, 1000),
      trainingMode: flag('trainingMode', defaults.trainingMode),
      listenOnly: flag('listenOnly', defaults.listenOnly),
      autoPlay: flag('autoPlay', defaults.autoPlay),
      inputMode: InputMode.values.firstWhere(
        (mode) => mode.name == values['inputMode'],
        orElse: () => defaults.inputMode,
      ),
      originalRhythm: flag('originalRhythm', defaults.originalRhythm),
      repeatStart: number('repeatStart', 0, 0, 10000).toInt(),
      repeatEnd: values['repeatEnd'] is num
          ? number('repeatEnd', 0, 0, 10000).toInt()
          : null,
      repeatLoop: flag('repeatLoop', false),
    );
    settings.addListener(notifyListeners);
    return settings;
  });

  Map<String, Object?> toJson() => {
    ..._stored,
    for (final entry in _models.entries) entry.key: entry.value.toJson(),
  };

  void restore(Map<String, Object?> values) {
    for (final settings in _models.values) {
      settings.removeListener(notifyListeners);
    }
    _models.clear();
    _stored
      ..clear()
      ..addAll(values);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final model in _models.values) {
      model.removeListener(notifyListeners);
      model.dispose();
    }
    super.dispose();
  }
}

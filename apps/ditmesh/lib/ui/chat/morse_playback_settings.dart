import 'package:flutter/widgets.dart';
import 'package:morse_core/morse_core.dart';
import 'package:provider/provider.dart';

import 'input_mode.dart';

/// Listener defaults or a conversation's override, including optional actual
/// keyed-rhythm playback when a message carries a matching recording.
///
/// Defaults: 15 wpm characters, Farnsworth 8 wpm overall, 700 Hz sidetone.
/// Provide one instance above the shell with `ChangeNotifierProvider`; until
/// the app does, [MorsePlaybackSettings.of] falls back to [shared] so the chat
/// UI works standalone and in widget tests.
class MorsePlaybackSettings extends ChangeNotifier {
  MorsePlaybackSettings({
    double wpm = 15,
    double farnsworthWpm = 8,
    double toneHz = 700,
    bool trainingMode = false,
    InputMode inputMode = InputMode.straightKey,
    bool autoPlay = false,
    bool listenOnly = false,
    bool originalRhythm = false,
    int repeatStart = 0,
    int? repeatEnd,
    bool repeatLoop = false,
  }) : _originalRhythm = originalRhythm,
       _repeatStart = repeatStart,
       _repeatEnd = repeatEnd,
       _repeatLoop = repeatLoop,
       _listenOnly = listenOnly,
       _wpm = wpm,
       _farnsworthWpm = farnsworthWpm,
       _toneHz = toneHz,
       _trainingMode = trainingMode,
       _inputMode = inputMode,
       _autoPlay = autoPlay;

  static const double minWpm = 5;
  static const double maxWpm = 40;
  static const double minToneHz = 400;
  static const double maxToneHz = 1000;

  /// Process-wide fallback used when no provider is installed.
  static final MorsePlaybackSettings shared = MorsePlaybackSettings();

  /// Nearest provided instance, subscribing when [listen] is true; falls back
  /// to [shared].
  static MorsePlaybackSettings of(BuildContext context, {bool listen = true}) {
    try {
      return Provider.of<MorsePlaybackSettings>(context, listen: listen);
    } on ProviderNotFoundException {
      return shared;
    }
  }

  bool _originalRhythm;
  int _repeatStart;
  int? _repeatEnd;
  bool _repeatLoop;
  bool get originalRhythm => _originalRhythm;
  int get repeatStart => _repeatStart;
  int? get repeatEnd => _repeatEnd;
  bool get repeatLoop => _repeatLoop;
  set originalRhythm(bool value) {
    if (_originalRhythm == value) return;
    _originalRhythm = value;
    notifyListeners();
  }

  set repeatStart(int value) {
    final next = value.clamp(0, 10000);
    if (_repeatStart == next) return;
    _repeatStart = next;
    if (_repeatEnd != null && _repeatEnd! < next) _repeatEnd = next;
    notifyListeners();
  }

  set repeatEnd(int? value) {
    final next = value?.clamp(_repeatStart, 10000);
    if (_repeatEnd == next) return;
    _repeatEnd = next;
    notifyListeners();
  }

  set repeatLoop(bool value) {
    if (_repeatLoop == value) return;
    _repeatLoop = value;
    notifyListeners();
  }

  Map<String, Object?> toJson() => {
    'wpm': wpm,
    'farnsworthWpm': farnsworthWpm,
    'toneHz': toneHz,
    'trainingMode': trainingMode,
    'inputMode': inputMode.name,
    'autoPlay': autoPlay,
    'listenOnly': listenOnly,
    'originalRhythm': originalRhythm,
    'repeatStart': repeatStart,
    'repeatEnd': repeatEnd,
    'repeatLoop': repeatLoop,
  };

  double _wpm;
  double _farnsworthWpm;
  double _toneHz;
  bool _trainingMode;
  bool _autoPlay;
  bool _listenOnly;
  InputMode _inputMode;
  InputMode get inputMode => _inputMode;
  set inputMode(InputMode value) {
    if (value == _inputMode) return;
    _inputMode = value;
    notifyListeners();
  }

  double get wpm => _wpm;
  double get farnsworthWpm => _farnsworthWpm;
  double get toneHz => _toneHz;

  /// Hide plain text until the listener taps "reveal" (plan §5.3).
  bool get trainingMode => _trainingMode;

  /// Play each message received while its conversation is on screen.
  bool get autoPlay => _autoPlay;

  /// Listen-only training (functional spec §6.1): received messages hide
  /// both the plain text and the dots/dashes until revealed. Independent of
  /// [trainingMode].
  bool get listenOnly => _listenOnly;

  set listenOnly(bool value) {
    if (value == _listenOnly) return;
    _listenOnly = value;
    notifyListeners();
  }

  MorseTiming get timing => MorseTiming(
    wpm: _wpm,
    farnsworthWpm: _farnsworthWpm < _wpm ? _farnsworthWpm : null,
  );

  set wpm(double value) {
    final double v = value.clamp(minWpm, maxWpm);
    if (v == _wpm) return;
    _wpm = v;
    if (_farnsworthWpm > _wpm) _farnsworthWpm = _wpm;
    notifyListeners();
  }

  set farnsworthWpm(double value) {
    final double v = value.clamp(minWpm, _wpm);
    if (v == _farnsworthWpm) return;
    _farnsworthWpm = v;
    notifyListeners();
  }

  set toneHz(double value) {
    final double v = value.clamp(minToneHz, maxToneHz);
    if (v == _toneHz) return;
    _toneHz = v;
    notifyListeners();
  }

  set trainingMode(bool value) {
    if (value == _trainingMode) return;
    _trainingMode = value;
    notifyListeners();
  }

  set autoPlay(bool value) {
    if (value == _autoPlay) return;
    _autoPlay = value;
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'package:morse_core/morse_core.dart';

/// Speed and tone used when the reference or translator plays a pattern.
///
/// The app shares and persists these independently of training defaults.
/// Isolated screens can own a default instance: 15 WPM, Farnsworth off, 700 Hz.
class ReferencePlaybackSettings extends ChangeNotifier {
  ReferencePlaybackSettings({
    double wpm = 15,
    double? farnsworthWpm,
    double toneHz = 700,
  }) : _wpm = wpm.clamp(minWpm, maxWpm),
       _toneHz = toneHz.clamp(minToneHz, maxToneHz) {
    _farnsworthWpm = farnsworthWpm?.clamp(minWpm, _wpm);
  }

  static const double minWpm = 5;
  static const double maxWpm = 40;
  static const double minToneHz = 400;
  static const double maxToneHz = 1000;

  double _wpm;
  double? _farnsworthWpm;
  double _toneHz;

  /// Character (element) speed.
  double get wpm => _wpm;

  set wpm(double value) {
    final double next = value.clamp(minWpm, maxWpm);
    if (next == _wpm) return;
    _wpm = next;
    final double? fw = _farnsworthWpm;
    if (fw != null && fw > next) _farnsworthWpm = next;
    notifyListeners();
  }

  /// Whether character and word gaps are stretched to [farnsworthWpm].
  bool get farnsworthEnabled => _farnsworthWpm != null;

  /// Effective speed under Farnsworth spacing; null when disabled.
  double? get farnsworthWpm => _farnsworthWpm;

  set farnsworthWpm(double? value) {
    final double? next = value?.clamp(minWpm, _wpm);
    if (next == _farnsworthWpm) return;
    _farnsworthWpm = next;
    notifyListeners();
  }

  /// Turns Farnsworth spacing on (at a sensible default effective speed)
  /// or off.
  void setFarnsworthEnabled(bool enabled) {
    if (enabled == farnsworthEnabled) return;
    farnsworthWpm = enabled ? (_wpm * 0.6).clamp(minWpm, _wpm) : null;
  }

  /// Sidetone frequency in Hz.
  double get toneHz => _toneHz;

  set toneHz(double value) {
    final double next = value.clamp(minToneHz, maxToneHz);
    if (next == _toneHz) return;
    _toneHz = next;
    notifyListeners();
  }

  /// The timing these settings describe.
  MorseTiming get timing =>
      MorseTiming(wpm: _wpm, farnsworthWpm: _farnsworthWpm);
}

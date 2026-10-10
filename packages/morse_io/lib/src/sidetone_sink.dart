import 'dart:async';

import 'app_foreground.dart';
import 'sink.dart';
import 'soloud_api.dart';

/// Sine-wave sidetone rendered through `flutter_soloud`.
///
/// Approach (chosen for latency, not simplicity): [prepare] starts a
/// looping sine voice at volume 0 and keeps it running for the life of the
/// sink. [on] / [off] then only ramp that voice's volume with the mixer's
/// built-in fader over [ramp] (default 5 ms). Nothing is allocated, decoded
/// or scheduled on the hot path, so keying latency is bounded by the audio
/// buffer size alone, and the short linear ramp removes the click a hard
/// gate would produce at a non-zero sample.
///
/// Mobile lifecycle: the silent looping voice keeps the output device
/// running, and on iOS (playback category) a running device would keep a
/// backgrounded app alive indefinitely under an `audio` background mode
/// (which the app therefore does not declare). So while
/// [AppForeground] reports background the voice is stopped (the engine then
/// idles its device) and key-downs are ignored; back in the foreground a
/// fresh voice is started.
///
/// Recovery: every [on] first asks the engine to restart the device if the
/// OS stopped it (an interruption that never reported its end), and starts a
/// new voice when the old one is gone, so the tone never stays dead.
///
/// All engine access goes through [SoloudApi] so tests can substitute a fake.
final class SidetoneSink implements MorseSink {
  SidetoneSink({
    SoloudApi? api,
    AppForeground? foreground,
    double frequencyHz = 700,
    double volume = 0.8,
    this.ramp = const Duration(milliseconds: 5),
  }) : _api = api ?? FlutterSoloudApi(),
       _foreground = foreground ?? const BindingAppForeground(),
       _frequencyHz = frequencyHz,
       _volume = volume.clamp(0.0, 1.0);

  final SoloudApi _api;
  final AppForeground _foreground;

  /// Attack / release time applied to every on/off transition.
  final Duration ramp;

  double _frequencyHz;
  double _volume;
  SidetoneSource? _source;
  SidetoneVoice? _voice;
  Future<void>? _preparing;
  Future<void>? _disposing;
  bool _prepared = false;
  bool _disposed = false;
  bool _isOn = false;
  Object? _lastOutputError;
  StackTrace? _lastOutputStackTrace;
  bool _background = false;
  void Function()? _stopListening;

  bool get isPrepared => _prepared;
  bool get isOn => _isOn;

  /// The actual API failure when key-down could not produce a tone. Live
  /// keying still retries on its next mark; listening assessments can detect
  /// silent refusal rather than treating timing completion as audibility.
  Object? get lastOutputError => _lastOutputError;
  StackTrace? get lastOutputStackTrace => _lastOutputStackTrace;

  double get frequencyHz => _frequencyHz;

  /// Retunes the running voice immediately (safe while keying).
  set frequencyHz(double hz) {
    _frequencyHz = hz;
    final source = _source;
    if (source != null) {
      _api.setWaveformFrequency(source, hz);
    }
  }

  double get volume => _volume;

  /// 0..1. Applied at the next [on], or right away while the tone is on.
  set volume(double value) {
    _volume = value.clamp(0.0, 1.0);
    final voice = _voice;
    if (voice != null && _isOn) {
      _api.setVolume(voice, _volume);
    }
  }

  @override
  Future<void> prepare() {
    if (_disposed) {
      return Future<void>.error(StateError('SidetoneSink used after dispose'));
    }
    if (_prepared) {
      return Future<void>.value();
    }
    return _preparing ??= _doPrepare();
  }

  /// Bails out after every await once [dispose] has started; [dispose]
  /// waits for this future and then frees whatever it got as far as
  /// creating. On failure it frees its partial state and gives the engine
  /// back itself, so a caller that drops a sink whose prepare threw leaks
  /// nothing, and a later [prepare] may retry. The future stays published
  /// until that cleanup is done, so a [prepare] or [dispose] arriving during
  /// it waits for it instead of overlapping it.
  Future<void> _doPrepare() async {
    try {
      await _api.init();
      if (_disposed) {
        return;
      }
      final source = await _api.loadSineWaveform();
      _source = source;
      if (_disposed) {
        return;
      }
      _api.setWaveformFrequency(source, _frequencyHz);
      _stopListening ??= _foreground.listen(_onForegroundChanged);
      _background = !_foreground.isForeground;
      if (!_background) {
        _voice = _api.playLooping(source, volume: 0);
      }
      _prepared = true;
    } on Object {
      if (!_disposed) {
        try {
          await _release();
        } on Object catch (_) {
          // The original error below is what prepare() reports.
        } finally {
          if (!_disposed) {
            _preparing = null;
          }
        }
      }
      rethrow;
    }
  }

  @override
  void on() {
    if (!_prepared || _isOn || _background) {
      return;
    }
    final voice = _audibleVoice();
    if (voice == null) {
      return;
    }
    try {
      _api.fadeVolume(voice, _volume, ramp);
      _isOn = true;
      _lastOutputError = null;
      _lastOutputStackTrace = null;
    } on Object catch (error, stackTrace) {
      _isOn = false;
      _lastOutputError = error;
      _lastOutputStackTrace = stackTrace;
      rethrow;
    }
  }

  /// The running voice with its device started, replacing a voice the
  /// engine lost; null when the OS refuses output right now (a call is
  /// active), in which case the next [on] tries again.
  SidetoneVoice? _audibleVoice() {
    final voice = _voice;
    if (voice != null) {
      try {
        _api.resumeVoice(voice);
        return voice;
      } on Object catch (error, stackTrace) {
        _lastOutputError = error;
        _lastOutputStackTrace = stackTrace;
        _voice = null;
        _stopQuietly(voice);
      }
    }
    return _startVoice();
  }

  SidetoneVoice? _startVoice() {
    final source = _source;
    if (source == null) {
      return null;
    }
    try {
      return _voice = _api.playLooping(source, volume: 0);
    } on Object catch (error, stackTrace) {
      _lastOutputError = error;
      _lastOutputStackTrace = stackTrace;
      return null;
    }
  }

  void _stopQuietly(SidetoneVoice voice) {
    unawaited(
      Future<void>.sync(() => _api.stop(voice)).catchError((Object _) {}),
    );
  }

  void _onForegroundChanged(bool foreground) {
    if (!_prepared || foreground == !_background) {
      return;
    }
    _background = !foreground;
    if (foreground) {
      _voice ??= _startVoice();
      return;
    }
    _isOn = false;
    final voice = _voice;
    _voice = null;
    if (voice != null) {
      _stopQuietly(voice);
    }
  }

  @override
  void off() {
    final voice = _voice;
    if (voice == null || !_isOn) {
      return;
    }
    _isOn = false;
    _api.fadeVolume(voice, 0, ramp);
  }

  /// Stops the voice, frees the source and returns the engine lease.
  /// Single-flight: concurrent and repeated calls share one teardown. Waits
  /// for an in-flight [prepare] first so it cannot create a voice after the
  /// sink is gone.
  @override
  Future<void> dispose() => _disposing ??= _doDispose();

  Future<void> _doDispose() async {
    _disposed = true;
    _isOn = false;
    _prepared = false;
    final preparing = _preparing;
    _preparing = null;
    if (preparing != null) {
      try {
        await preparing;
      } on Object catch (_) {
        // Reported to whoever awaited prepare(); teardown continues below.
      }
    }
    await _release();
  }

  /// Frees the voice and source (if any) and returns the engine lease even
  /// when freeing them throws.
  Future<void> _release() async {
    _stopListening?.call();
    _stopListening = null;
    final voice = _voice;
    final source = _source;
    _voice = null;
    _source = null;
    try {
      if (voice != null) {
        await _api.stop(voice);
      }
    } finally {
      try {
        if (source != null) {
          await _api.disposeSource(source);
        }
      } finally {
        await _api.deinit();
      }
    }
  }
}

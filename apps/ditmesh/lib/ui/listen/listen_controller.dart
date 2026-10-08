import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_dsp/morse_dsp.dart';

import 'listen_failure.dart';
import 'listen_settings.dart';
import 'pcm_source.dart';

export 'listen_failure.dart';

/// [failed] covers every reason capture is unavailable, permission included;
/// [ListenController.failure] says which.
enum ListenStatus { idle, starting, listening, failed }

/// Per-chunk meter state, kept out of the main notifier so only the meter
/// repaints at audio-chunk rate.
final class ListenMeter {
  const ListenMeter({
    this.level = 0,
    this.toneOn = false,
    this.hasSignal = false,
  });

  final double level;
  final bool toneOn;
  final bool hasSignal;

  @override
  bool operator ==(Object other) =>
      other is ListenMeter &&
      other.level == level &&
      other.toneOn == toneOn &&
      other.hasSignal == hasSignal;

  @override
  int get hashCode => Object.hash(level, toneOn, hasSignal);
}

/// Drives a [PcmSource] into an [AudioMorseDecoder] and exposes the result
/// to the Listen screen.
///
/// Notifies on status changes, decode events, tuning changes and settings;
/// the meter lives in [meter] and updates once per audio chunk.
final class ListenController extends ChangeNotifier {
  ListenController({
    required PcmSource source,
    bool ownsSource = false,
    this.sampleRate = 48000,
    ListenSettings settings = const ListenSettings(),
  }) : _source = source,
       _ownsSource = ownsSource,
       _settings = settings {
    _decoder = _buildDecoder();
  }

  final PcmSource _source;
  final bool _ownsSource;
  final int sampleRate;

  final ValueNotifier<ListenMeter> meter = ValueNotifier<ListenMeter>(
    const ListenMeter(),
  );

  ListenSettings _settings;
  late AudioMorseDecoder _decoder;
  StreamSubscription<DecodeEvent>? _eventSub;
  StreamSubscription<Uint8List>? _pcmSub;
  Future<void>? _stopping;

  /// Bumped by every [start] and [stop]; a start attempt whose number is no
  /// longer current must not touch state when one of its awaits resumes.
  int _attempt = 0;

  /// Number of the most recent [start] attempt.
  int _lastStartAttempt = 0;
  ListenStatus _status = ListenStatus.idle;
  ListenFailure? _failure;
  String _history = '';
  double _shownHz = 0;
  bool _shownLocked = false;
  bool _disposed = false;
  bool _stoppedInBackground = false;

  ListenStatus get status => _status;
  bool get isListening => _status == ListenStatus.listening;
  bool get isBusy => _status == ListenStatus.starting;

  /// Why capture failed; non-null exactly when [status] is
  /// [ListenStatus.failed].
  ListenFailure? get failure => _failure;

  /// True after a lifecycle stop until the next start or clear.
  bool get stoppedInBackground => _stoppedInBackground;

  ListenSettings get settings => _settings;

  /// Everything decoded so far, including text from before a settings
  /// change rebuilt the decoder.
  String get text => _history + _decoder.text;
  String get pendingPattern => _decoder.pendingPattern;
  bool get hasText => text.isNotEmpty;

  double get frequencyHz => _decoder.detectedFrequency;
  bool get isToneLocked => _decoder.isToneLocked;

  /// Speed estimate once at least one mark has been heard, else null.
  double? get wpm => _decoder.text.isEmpty && _decoder.pendingPattern.isEmpty
      ? null
      : _decoder.estimatedWpm;

  // ---------------------------------------------------------------------------
  // Capture

  Future<void> start() async {
    if (_disposed || isBusy || isListening) return;
    final int attempt = _lastStartAttempt = ++_attempt;
    _stoppedInBackground = false;
    _failure = null;
    _setStatus(ListenStatus.starting);
    final bool granted;
    try {
      granted = await _source.hasPermission();
    } catch (error, stack) {
      if (_isStale(attempt)) return;
      // Nothing was started, so there is nothing to stop.
      _fail(ListenFailureKind.startFailed, error, stack, release: false);
      return;
    }
    if (_isStale(attempt)) return;
    if (!granted) {
      _fail(ListenFailureKind.permissionDenied, null, null, release: false);
      return;
    }
    final Stream<Uint8List> stream;
    try {
      stream = await _source.start(sampleRate: sampleRate, channels: 1);
    } catch (error, stack) {
      if (_isStale(attempt)) return;
      // Ask for the device list only now: it costs a platform round trip,
      // and "empty" is the one signal that reliably means "no microphone".
      final bool? hasDevice = await _hasInputDevice();
      if (_isStale(attempt)) return;
      _fail(
        hasDevice == false
            ? ListenFailureKind.noInputDevice
            : ListenFailureKind.startFailed,
        error,
        stack,
      );
      return;
    }
    if (_isStale(attempt)) {
      // stop() or dispose() ran while the platform was starting. Release
      // what this attempt opened, unless a newer start now owns the source.
      if (_disposed || _lastStartAttempt == attempt) {
        unawaited(_source.stop().catchError((Object _) {}));
      }
      return;
    }
    _pcmSub = stream.listen(
      _onChunk,
      onError: (Object error, StackTrace stack) =>
          _fail(ListenFailureKind.streamFailed, error, stack),
      onDone: _onStreamDone,
      cancelOnError: true,
    );
    _setStatus(ListenStatus.listening);
  }

  bool _isStale(int attempt) => _disposed || attempt != _attempt;

  /// [PcmSource.hasInputDevice] must not throw, but a misbehaving source
  /// must not turn a start failure into an uncaught error either.
  Future<bool?> _hasInputDevice() async {
    try {
      return await _source.hasInputDevice();
    } catch (error) {
      debugPrint('[ListenController] hasInputDevice threw: $error');
      return null;
    }
  }

  /// Stops capture and commits a half-received character.
  ///
  /// Re-entrant: the framework delivers `hidden` and `paused` back to back
  /// (and a user can double-tap Stop), so a call made while a stop is in
  /// flight joins it instead of asking the platform to stop twice.
  Future<void> stop({bool fromBackground = false}) =>
      _stopping ??= _stop(fromBackground).whenComplete(() => _stopping = null);

  Future<void> _stop(bool fromBackground) async {
    _attempt++; // Invalidates a start still waiting on the platform.
    final sub = _pcmSub;
    _pcmSub = null;
    // Not awaited: cancelling is synchronous as far as delivery goes (no
    // chunk arrives after this line), and the future it returns is Dart's
    // root-zone `_nullFuture`, which never resumes inside a FakeAsync widget
    // test. Waiting on it would only delay releasing the microphone.
    unawaited(sub?.cancel());
    try {
      await _source.stop();
    } catch (_) {
      // Already stopped or the platform tore the session down; nothing to
      // report beyond the idle state below.
    }
    if (_disposed) return;
    if (_status == ListenStatus.listening || _status == ListenStatus.starting) {
      _decoder.commitPending();
      _stoppedInBackground = fromBackground;
      _setStatus(ListenStatus.idle);
    }
  }

  void _onChunk(Uint8List bytes) {
    if (_disposed) return;
    _decoder.feedBytes(bytes);
    meter.value = ListenMeter(
      level: _decoder.currentLevel,
      toneOn: _decoder.isToneOn,
      hasSignal: _decoder.hasSignal,
    );
    final hz = _decoder.detectedFrequency;
    final locked = _decoder.isToneLocked;
    if ((hz - _shownHz).abs() >= 1 || locked != _shownLocked) {
      _shownHz = hz;
      _shownLocked = locked;
      notifyListeners();
    }
  }

  void _onStreamDone() {
    if (_disposed || _pcmSub == null) return;
    _pcmSub = null;
    _decoder.commitPending();
    _setStatus(ListenStatus.idle);
  }

  /// Records a typed failure. The platform's [error] text is logged for
  /// diagnostics and kept in [ListenFailure.detail]; it is never shown.
  /// [release] stops the source, for failures after `start` was called.
  void _fail(
    ListenFailureKind kind,
    Object? error,
    StackTrace? stack, {
    bool release = true,
  }) {
    if (_disposed) return;
    final String? detail = error?.toString();
    if (detail != null) {
      debugPrint(
        '[ListenController] ${kind.name}: $detail'
        '${stack == null ? '' : '\n$stack'}',
      );
    }
    _failure = ListenFailure(kind, detail: detail);
    if (release) {
      final sub = _pcmSub;
      _pcmSub = null;
      unawaited(sub?.cancel());
      unawaited(_source.stop().catchError((Object _) {}));
    }
    _setStatus(ListenStatus.failed);
  }

  // ---------------------------------------------------------------------------
  // Text and tuning

  void clear() {
    _history = '';
    _decoder.clearText();
    _stoppedInBackground = false;
    notifyListeners();
  }

  /// Drags the tuning slider: fixes the frequency and turns auto-tune off.
  void setManualFrequency(double hz) {
    _settings = _settings.copyWith(autoTune: false, manualHz: hz);
    _decoder.manualFrequencyHz = hz;
    notifyListeners();
  }

  void setAutoTune(bool on) => updateSettings(_settings.copyWith(autoTune: on));

  /// Applies [next]. Block size and debounce need a new decoder; the text
  /// decoded so far is kept in [text].
  void updateSettings(ListenSettings next) {
    if (next == _settings) return;
    final rebuild =
        next.blockSize != _settings.blockSize ||
        next.minElementMs != _settings.minElementMs;
    _settings = next;
    if (rebuild) {
      _decoder.commitPending();
      _history = text;
      _eventSub?.cancel().ignore();
      _decoder.dispose();
      _decoder = _buildDecoder();
    } else {
      _decoder.autoTune = next.autoTune;
      if (!next.autoTune) _decoder.manualFrequencyHz = next.manualHz;
    }
    notifyListeners();
  }

  AudioMorseDecoder _buildDecoder() {
    final debounce = Duration(milliseconds: _settings.minElementMs);
    final decoder = AudioMorseDecoder(
      sampleRate: sampleRate,
      blockSize: _settings.blockSize,
      gateConfig: EnvelopeGateConfig(minOn: debounce, minOff: debounce),
      autoTune: _settings.autoTune,
      manualFrequencyHz: _settings.manualHz,
    );
    _eventSub = decoder.events.listen((_) => notifyListeners());
    return decoder;
  }

  void _setStatus(ListenStatus next) {
    if (_disposed) return;
    _status = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_pcmSub?.cancel());
    _pcmSub = null;
    unawaited(_eventSub?.cancel());
    _decoder.dispose();
    meter.dispose();
    unawaited(_shutdownSource());
    super.dispose();
  }

  Future<void> _shutdownSource() async {
    try {
      await _source.stop();
    } catch (_) {
      // Nothing was recording; fall through to dispose.
    }
    if (!_ownsSource) return;
    try {
      await _source.dispose();
    } catch (_) {
      // Plugin already torn down (e.g. engine shutdown); nothing to free.
    }
  }
}

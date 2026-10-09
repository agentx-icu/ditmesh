part of 'morse_playback_controller.dart';

extension _PlaybackQueue on MorsePlaybackController {
  /// Starts the oldest queued clip when nothing sounds and hand keying is
  /// neither down nor within its hold-off (then a timer retries).
  Future<void> _advance() {
    if (_disposed || _background || _keyDown) return Future<void>.value();
    final quietAt = _quietAt;
    final left = quietAt == null ? Duration.zero : quietAt - clock.now();
    final current = _current;
    if (current != null) {
      if (!_manualPaused && _player.isPaused) {
        if (left > Duration.zero) {
          _holdTimer ??= clock.schedule(left, () {
            _holdTimer = null;
            unawaited(_advance());
          });
        } else {
          final toneHz = current.toneHz;
          if (toneHz != null && _sidetone != null) {
            _sidetone.frequencyHz = toneHz;
          }
          _player.resume();
          _scheduleProgress();
          _notify();
        }
      }
      return Future<void>.value();
    }
    if (_queue.isEmpty ||
        (_holdAuto && _queue.first.origin == PlaybackOrigin.auto)) {
      return Future<void>.value();
    }
    if (left > Duration.zero) {
      _holdTimer ??= clock.schedule(left, () {
        _holdTimer = null;
        unawaited(_advance());
      });
      return Future<void>.value();
    }
    return _start(_queue.removeFirst());
  }

  /// Enforces [maxQueuedAuto] on every insertion: drops the oldest waiting
  /// auto clip other than [keep] (an interrupted message going back to the
  /// head). Manual clips are never dropped.
  void _trimAuto({_Clip? keep}) {
    while (_queue.where((c) => c.origin == PlaybackOrigin.auto).length >
        MorsePlaybackController.maxQueuedAuto) {
      _queue.remove(
        _queue.firstWhere(
          (c) => c.origin == PlaybackOrigin.auto && !identical(c, keep),
        ),
      );
    }
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  /// Reserves [clip] as current, then plays it after `prepare()` unless a
  /// newer start or a stop superseded it. Always crosses an async boundary,
  /// so a completion event never re-enters the player synchronously.
  Future<void> _start(_Clip clip) async {
    final int token = ++_startToken;
    if (_player.isPlaying) _player.stop();
    _current = clip;
    _activeMark = -1;
    _marksBefore = clip.timeline.markStarts.isEmpty
        ? 0
        : clip.timeline.markStarts[clip.first];
    _activeWord = clip.first;
    _manualPaused = clip.paused;
    _notify();
    await prepare();
    if (_disposed || token != _startToken) return;
    if (_holdAuto && clip.origin == PlaybackOrigin.auto) {
      // The app went `inactive` while the sink prepared: back to the head of
      // the queue until the hold is cleared.
      _queue.addFirst(clip);
      _trimAuto(keep: clip);
      _reset();
      return;
    }
    // Keying may have begun and ended while prepare awaited the device. The
    // reservation survives a manual pause, so recheck its live priority here.
    final quietAt = _quietAt;
    final waitForKeying =
        _keyDown || (quietAt != null && quietAt > clock.now());
    final double? toneHz = clip.toneHz;
    if (!waitForKeying && toneHz != null && _sidetone != null) {
      _sidetone.frequencyHz = toneHz;
    }
    // Starting paused never keys the sink briefly before muting it.
    _player.play(
      _timeline(clip),
      paused: _background || _manualPaused || waitForKeying,
    );
    // A key-up may already have happened during preparation; arrange its
    // remaining holdoff now. A held key will wake this from _keyingOff.
    unawaited(_advance());
    _scheduleProgress();
  }

  /// An auto-played clip waits for whatever part of a word gap has not
  /// already passed since the last key-up; a tapped bubble starts at once.
  List<MorseElement> _timeline(_Clip clip) {
    final elements = clip.timeline.range(clip.first, clip.last);
    _elementOffset = clip.timeline.wordStarts.isEmpty
        ? 0
        : clip.timeline.wordStarts[clip.first];
    if (clip.repeated && elements.isNotEmpty) {
      _elementOffset--;
      return [
        MorseElement(MorseElementKind.wordGap, clip.timing.wordGap),
        ...elements,
      ];
    }
    final Duration? last = _lastKeyUp;
    if (clip.origin == PlaybackOrigin.manual || last == null) return elements;
    final Duration owed = clip.timing.wordGap - (clock.now() - last);
    if (owed <= Duration.zero || elements.isEmpty) return elements;
    _elementOffset--;
    return [MorseElement(MorseElementKind.wordGap, owed), ...elements];
  }

  /// Cuts the current clip. An idle player emits nothing, so a clip cancelled
  /// while preparing is cleared here.
  void _halt() {
    _startToken++;
    if (_player.isPlaying) {
      _player.stop();
    } else if (_current != null) {
      _reset();
    }
  }

  void _reset() {
    _current = null;
    _manualPaused = false;
    _progressTimer?.cancel();
    _progressTimer = null;
    _activeMark = -1;
    _notify();
  }

  void _keyingOn({bool audible = true}) {
    if (_disposed) return;
    _keyDown = true;
    _cancelHold();
    final _Clip? current = _current;
    if (current != null &&
        !(current.origin == PlaybackOrigin.manual && _manualPaused)) {
      // The operator takes the key: put an automatic clip back.
      if (current.origin == PlaybackOrigin.auto) {
        _queue.addFirst(current);
        _trimAuto(keep: current);
      }
      _halt();
    }
    final double? toneHz = keyingToneHz;
    if (toneHz != null && _sidetone != null) _sidetone.frequencyHz = toneHz;
    if (audible) sink.on();
  }

  void _keyingOff() {
    if (_disposed) return;
    sink.off();
    if (!_keyDown) return;
    _keyDown = false;
    final Duration now = clock.now();
    _lastKeyUp = now;
    _quietAt = now + MorsePlaybackController.keyingHoldoff;
    // Only schedules (the hold-off is still running): never starts playback
    // from inside the keyer's callback.
    unawaited(_advance());
  }

  void _onForegroundChanged(bool foreground) {
    if (_disposed || foreground == !_background) return;
    _background = !foreground;
    if (_background) {
      _player.pause();
      _progressTimer?.cancel();
      _progressTimer = null;
      _notify();
      return;
    }
    // The sinks that gate themselves on the lifecycle (sidetone, haptics)
    // subscribed after this controller, so they hear the change after it:
    // resume on a microtask, once their listeners have run, or the player
    // would re-key sinks that still believe they are in the background.
    scheduleMicrotask(() {
      if (_disposed || _background) return;
      unawaited(_advance());
      _scheduleProgress();
      _notify();
    });
  }

  void _onEvent(PlayerEvent event) {
    switch (event) {
      case PlayerElementStarted(:final index, :final element):
        final current = _current;
        if (current != null) {
          _activeWord = current.timeline
              .wordAtElement(index + _elementOffset)
              .clamp(current.first, current.last);
        }
        if (element.on) {
          _soundOn = true;
          _activeMark = _marksBefore;
          _marksBefore++;
          _notify();
        } else {
          _keyReleased();
          _notify();
        }
      case PlayerCompleted():
        final current = _current;
        if (current != null &&
            current.loop &&
            current.origin == PlaybackOrigin.manual) {
          current.repeated = true;
          _queue.addFirst(current);
        }
        _keyReleased();
        _reset();
        unawaited(_advance());
      case PlayerStopped():
        // Cut during a gap: the key-up that counts is the one already noted.
        _keyReleased();
        if (_current != null) _reset();
    }
  }

  void _keyReleased() {
    if (_soundOn) _lastKeyUp = clock.now();
    _soundOn = false;
  }
}

final class _Clip {
  _Clip(
    this.id,
    this.text,
    this.timing,
    this.toneHz,
    this.origin, {
    KeyedRecording? recording,
    bool original = false,
    int first = 0,
    int? last,
    this.loop = false,
  }) : timeline = PlaybackTimeline(
         text,
         timing,
         recording: recording,
         original: original,
       ) {
    final max = timeline.words.length - 1;
    this.first = max < 0 ? 0 : first.clamp(0, max);
    this.last = max < 0 ? 0 : (last ?? max).clamp(this.first, max);
  }
  final PlaybackTimeline timeline;
  late int first;
  late int last;
  bool loop;
  bool repeated = false;
  bool paused = false;

  final String id;
  final String text;
  final MorseTiming timing;
  final double? toneHz;
  final PlaybackOrigin origin;
}

/// [MorsePlaybackController.keyingSink]: the keyers' view of the shared sink.
final class _KeyingSink implements LiveKeyingSink {
  _KeyingSink(this._owner, [this._enabled]);
  final bool Function()? _enabled;

  @override
  MorseSink withSidetone(bool Function() enabled) =>
      _KeyingSink(_owner, enabled);

  final MorsePlaybackController _owner;

  @override
  Future<void> prepare() => _owner.prepare();

  @override
  void on() => _owner._keyingOn(audible: _enabled?.call() ?? true);

  @override
  void off() => _owner._keyingOff();

  // The owner disposes the real sink.
  @override
  Future<void> dispose() async {}
}

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';

/// Why a clip is sounding: a tapped bubble or auto-play of a received
/// message. Decides what hand keying puts back and what auto-play cancels.
enum PlaybackOrigin { manual, auto }

/// Plays Morse one clip at a time through `morse_io` and exposes what is
/// sounding so bubbles can highlight the active mark.
///
/// [play] / [toggle] (a tapped bubble) replace everything, queue included;
/// [enqueue] (auto-play of received messages) waits its turn, FIFO, a word
/// gap after whatever sounded last.
///
/// Hand keying uses [keyingSink]: while the operator keys (and for
/// [keyingHoldoff] after the last key-up) nothing plays, not even a tapped
/// bubble, so the keyer and the player never fight over the sink; an
/// interrupted auto-played message goes back to the head of the queue. Tests inject a [NullSink] and a `FakeClock`.
///
/// Mobile lifecycle ([AppForeground], mobile only): while the app is in the
/// background the clip sounding is paused and nothing queued starts; the
/// foreground resumes the clip where it stopped. Without this the timeline
/// runs on silently (the sinks mute themselves) and a tapped message is
/// gone when the phone is unlocked, or, on iOS, the elements missed while
/// suspended are raced through on return. [holdAutomatic] is the finer gate
/// for `inactive`, where the sinks keep sounding but nothing new may start.
class MorsePlaybackController extends ChangeNotifier {
  MorsePlaybackController({
    MorseSink? sink,
    Clock? clock,
    AppForeground? foreground,
    @visibleForTesting SidetoneSink? sidetone,
  }) : _sidetone = sidetone ?? (sink == null ? SidetoneSink() : null),
       _foreground = foreground ?? const BindingAppForeground(),
       clock = clock ?? SystemClock.shared {
    this.sink = sink ?? CompositeSink(<MorseSink>[_sidetone!, HapticSink()]);
    keyingSink = _KeyingSink(this);
    _player = MorsePlayer(sink: this.sink, clock: this.clock);
    _subscription = _player.events.listen(_onEvent);
    _background = !_foreground.isForeground;
    _stopListening = _foreground.listen(_onForegroundChanged);
  }

  /// Quiet time after the last hand-keyed element before playback resumes.
  static const Duration keyingHoldoff = Duration(milliseconds: 1500);

  /// Auto-play skips a received message longer than this to sound (a tap on
  /// its bubble still plays it): one peer must not tie up the speaker for
  /// tens of minutes with a single maximum-size message.
  static const Duration maxAutoClip = Duration(minutes: 2);

  /// At most this many received messages wait for auto-play; when a busy
  /// net sends more, the oldest waiting one is dropped for the newest.
  static const int maxQueuedAuto = 8;

  /// Tone for hand keying through [keyingSink] (the listener's setting);
  /// playback clips carry their own. Null keeps the sink's current tone.
  double? keyingToneHz;

  /// Created here only when the caller did not inject a sink; lets
  /// [play] retune the tone to the listener's settings.
  final SidetoneSink? _sidetone;

  /// Shared output device for playback and live keying.
  late final MorseSink sink;

  /// What hand keyers must key into: forwards to [sink] and pauses playback.
  late final MorseSink keyingSink;
  final Clock clock;
  final AppForeground _foreground;
  late final MorsePlayer _player;
  late final StreamSubscription<PlayerEvent> _subscription;
  late final void Function() _stopListening;
  Future<void>? _prepared;
  bool _disposed = false;
  bool _background = false;
  bool _holdAuto = false;

  /// While true no automatic clip starts (a tapped bubble still plays). The
  /// conversation sets it while the app is `inactive` (a call banner,
  /// control centre, a permission dialog), so a received message never
  /// begins sounding over an overlay; queued clips stay queued, under
  /// [maxQueuedAuto]. Clearing it starts the next one, hold-off permitting.
  bool get holdAutomatic => _holdAuto;
  set holdAutomatic(bool hold) {
    if (_disposed || _holdAuto == hold) return;
    _holdAuto = hold;
    if (!hold) unawaited(_advance());
  }

  final Queue<_Clip> _queue = Queue<_Clip>();

  /// The clip sounding or being prepared; reserved synchronously so a second
  /// request during `prepare()` queues behind it instead of racing it.
  _Clip? _current;
  int _startToken = 0;
  int _activeMark = -1;
  int _marksBefore = 0;

  /// When the key was last released (by playback or by hand), so the next
  /// queued clip only waits for the part of the word gap still missing.
  Duration? _lastKeyUp;
  bool _soundOn = false;
  bool _keyDown = false;

  /// End of hand keying's hold-off, and the timer that resumes the queue
  /// then. The deadline outlives queue changes; the timer is just a wake-up.
  Duration? _quietAt;
  Timer? _holdTimer;

  /// Id of the clip being played, or null when idle.
  String? get playingId => _current?.id;

  bool get isPlaying => _current != null;

  /// Index among the marks (`.`/`-`) of the current timeline, -1 when idle
  /// or before the first mark.
  int get activeMark => _activeMark;

  /// Index among the marks for [messageId], or null when that message is not
  /// the one playing. Bubbles call this from `build`.
  int? activeMarkFor(String messageId) =>
      playingId == messageId && _activeMark >= 0 ? _activeMark : null;

  /// Ids waiting to play, in order (diagnostics and tests).
  List<String> get queuedIds => [for (final c in _queue) c.id];

  /// Prepares the sink (audio engine, vibrator probe) once.
  Future<void> prepare() => _prepared ??= sink.prepare().catchError((Object e) {
    // No audio device (CI, headless): keep going silently; the pattern
    // highlight still shows playback progress.
    debugPrint('ditmesh: sink.prepare failed: $e');
  });

  /// Plays [text] now (or once hand keying rests), replacing anything
  /// playing or queued.
  Future<void> play(
    String messageId,
    String text,
    MorseTiming timing, {
    double? toneHz,
  }) {
    if (_disposed) return Future<void>.value();
    _queue
      ..clear()
      ..add(_Clip(messageId, text, timing, toneHz, PlaybackOrigin.manual));
    _halt();
    return _advance();
  }

  /// Stops playback and drops everything queued or held.
  void stop() {
    if (_disposed) return;
    _queue.clear();
    _cancelHold();
    _halt();
  }

  /// Toggles playback of [messageId].
  Future<void> toggle(
    String messageId,
    String text,
    MorseTiming timing, {
    double? toneHz,
  }) {
    if (playingId == messageId) {
      stop();
      return Future<void>.value();
    }
    return play(messageId, text, timing, toneHz: toneHz);
  }

  /// Queues a received message for auto-play behind anything already
  /// waiting. A message already sounding or queued is not added twice;
  /// text with nothing Morse can sound is skipped.
  void enqueue(
    String messageId,
    String text,
    MorseTiming timing, {
    double? toneHz,
  }) {
    if (_disposed || MorseEncoder.toPattern(text).isEmpty) return;
    if (playingId == messageId || _queue.any((c) => c.id == messageId)) return;
    final Duration length = MorseEncoder.encode(
      text,
      timing,
    ).fold(Duration.zero, (sum, e) => sum + e.duration);
    if (length > maxAutoClip) return;
    _queue.add(_Clip(messageId, text, timing, toneHz, PlaybackOrigin.auto));
    _trimAuto();
    unawaited(_advance());
  }

  /// Drops queued clips of [origin]; the clip sounding finishes unless
  /// [includeCurrent].
  void cancel(PlaybackOrigin origin, {bool includeCurrent = false}) {
    if (_disposed) return;
    _queue.removeWhere((c) => c.origin == origin);
    if (_queue.isEmpty) _cancelHold();
    if (includeCurrent && _current?.origin == origin) {
      _halt();
      unawaited(_advance());
    }
  }

  /// Drops every queued or sounding clip whose message id is in [ids] (their
  /// messages were deleted); other clips keep their place.
  void cancelMessages(Set<String> ids) {
    if (_disposed) return;
    _queue.removeWhere((c) => ids.contains(c.id));
    if (_queue.isEmpty) _cancelHold();
    if (ids.contains(_current?.id)) {
      _halt();
      unawaited(_advance());
    }
  }

  /// Starts the oldest queued clip when nothing sounds and hand keying is
  /// neither down nor within its hold-off (then a timer retries).
  Future<void> _advance() {
    if (_disposed ||
        _background ||
        _current != null ||
        _keyDown ||
        _queue.isEmpty) {
      return Future<void>.value();
    }
    if (_holdAuto && _queue.first.origin == PlaybackOrigin.auto) {
      return Future<void>.value();
    }
    final Duration? quietAt = _quietAt;
    final Duration left = quietAt == null
        ? Duration.zero
        : quietAt - clock.now();
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
        maxQueuedAuto) {
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
    _marksBefore = 0;
    notifyListeners();
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
    final double? toneHz = clip.toneHz;
    if (toneHz != null && _sidetone != null) _sidetone.frequencyHz = toneHz;
    _player.play(_timeline(clip));
    // The app left the foreground while the sink prepared: hold the clip at
    // its first element until it is back.
    if (_background) _player.pause();
  }

  /// An auto-played clip waits for whatever part of a word gap has not
  /// already passed since the last key-up; a tapped bubble starts at once.
  List<MorseElement> _timeline(_Clip clip) {
    final List<MorseElement> elements = MorseEncoder.encode(
      clip.text,
      clip.timing,
    );
    final Duration? last = _lastKeyUp;
    if (clip.origin == PlaybackOrigin.manual || last == null) return elements;
    final Duration owed = clip.timing.wordGap - (clock.now() - last);
    if (owed <= Duration.zero || elements.isEmpty) return elements;
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
    _activeMark = -1;
    notifyListeners();
  }

  void _keyingOn() {
    if (_disposed) return;
    _keyDown = true;
    _cancelHold();
    final _Clip? current = _current;
    if (current != null) {
      // The operator takes the key: put an automatic clip back.
      if (current.origin == PlaybackOrigin.auto) {
        _queue.addFirst(current);
        _trimAuto(keep: current);
      }
      _halt();
    }
    final double? toneHz = keyingToneHz;
    if (toneHz != null && _sidetone != null) _sidetone.frequencyHz = toneHz;
    sink.on();
  }

  void _keyingOff() {
    if (_disposed) return;
    sink.off();
    if (!_keyDown) return;
    _keyDown = false;
    final Duration now = clock.now();
    _lastKeyUp = now;
    _quietAt = now + keyingHoldoff;
    // Only schedules (the hold-off is still running): never starts playback
    // from inside the keyer's callback.
    unawaited(_advance());
  }

  void _onForegroundChanged(bool foreground) {
    if (_disposed || foreground == !_background) return;
    _background = !foreground;
    if (_background) {
      _player.pause();
      return;
    }
    // The sinks that gate themselves on the lifecycle (sidetone, haptics)
    // subscribed after this controller, so they hear the change after it:
    // resume on a microtask, once their listeners have run, or the player
    // would re-key sinks that still believe they are in the background.
    scheduleMicrotask(() {
      if (_disposed || _background) return;
      _player.resume();
      unawaited(_advance());
    });
  }

  void _onEvent(PlayerEvent event) {
    switch (event) {
      case PlayerElementStarted(:final index, :final element):
        if (element.on) {
          _soundOn = true;
          _activeMark = _marksBefore;
          _marksBefore++;
          notifyListeners();
        } else {
          _keyReleased();
          if (index == 0) notifyListeners();
        }
      case PlayerCompleted():
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

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _queue.clear();
    _cancelHold();
    _stopListening();
    unawaited(_subscription.cancel());
    unawaited(_player.dispose());
    unawaited(sink.dispose());
    super.dispose();
  }
}

final class _Clip {
  const _Clip(this.id, this.text, this.timing, this.toneHz, this.origin);

  final String id;
  final String text;
  final MorseTiming timing;
  final double? toneHz;
  final PlaybackOrigin origin;
}

/// [MorsePlaybackController.keyingSink]: the keyers' view of the shared sink.
final class _KeyingSink implements MorseSink {
  _KeyingSink(this._owner);

  final MorsePlaybackController _owner;

  @override
  Future<void> prepare() => _owner.prepare();

  @override
  void on() => _owner._keyingOn();

  @override
  void off() => _owner._keyingOff();

  // The owner disposes the real sink.
  @override
  Future<void> dispose() async {}
}

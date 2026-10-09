import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'playback_timeline.dart';

part 'morse_playback_queue.dart';
part 'morse_playback_controls.dart';

/// A live keying sink keeps priority even when the local sidetone is disabled.
abstract interface class LiveKeyingSink implements MorseSink {
  MorseSink withSidetone(bool Function() enabled);
}

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
  bool _manualPaused = false;
  Timer? _progressTimer;
  int _elementOffset = 0;
  int _activeWord = 0;

  void _notify() => notifyListeners();

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

  bool get isPaused =>
      _current != null && (_manualPaused || _background || _player.isPaused);
  bool get manuallyPaused => _manualPaused;
  bool get usingOriginal => _current?.timeline.isOriginal ?? false;
  int get activeWord => _activeWord;
  int get wordCount => _current?.timeline.words.length ?? 0;
  List<String> get words =>
      List.unmodifiable(_current?.timeline.words ?? const <String>[]);
  int get rangeStart => _current?.first ?? 0;
  int get rangeEnd => _current?.last ?? 0;
  bool get looping => _current?.loop ?? false;
  Duration get elapsed => _current == null ? Duration.zero : _player.elapsed;
  Duration get total =>
      _current == null ? Duration.zero : _player.totalDuration;

  void pause() {
    if (_disposed || _current == null || _manualPaused) return;
    _manualPaused = true;
    _current?.paused = true;
    _player.pause();
    _progressTimer?.cancel();
    _progressTimer = null;
    _notify();
  }

  void resume() {
    if (_disposed || !_manualPaused) return;
    _manualPaused = false;
    _current?.paused = false;
    unawaited(_advance());
    _scheduleProgress();
    _notify();
  }

  Future<void> seekWord(int word) {
    final clip = _current;
    if (_disposed || clip == null || clip.timeline.words.isEmpty) {
      return Future.value();
    }
    clip.first = word.clamp(0, clip.timeline.words.length - 1);
    clip.last = clip.timeline.words.length - 1;
    clip.loop = false;
    return _restartRange(clip);
  }

  Future<void> previousWord() => seekWord(activeWord - 1);
  Future<void> nextWord() => seekWord(activeWord + 1);

  Future<void> setWordRange(int first, int last, {bool loop = false}) {
    final clip = _current;
    if (_disposed || clip == null || clip.timeline.words.isEmpty) {
      return Future.value();
    }
    clip.first = first.clamp(0, clip.timeline.words.length - 1);
    clip.last = last.clamp(clip.first, clip.timeline.words.length - 1);
    clip.loop = loop;
    return _restartRange(clip);
  }

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
    KeyedRecording? recording,
    bool original = false,
    int firstWord = 0,
    int? lastWord,
    bool loop = false,
  }) {
    if (_disposed) return Future<void>.value();
    _queue
      ..clear()
      ..add(
        _Clip(
          messageId,
          text,
          timing,
          toneHz,
          PlaybackOrigin.manual,
          recording: recording,
          original: original,
          first: firstWord,
          last: lastWord,
          loop: loop,
        ),
      );
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
    KeyedRecording? recording,
    bool original = false,
    int firstWord = 0,
    int? lastWord,
    bool loop = false,
  }) {
    if (playingId == messageId) {
      stop();
      return Future<void>.value();
    }
    return play(
      messageId,
      text,
      timing,
      toneHz: toneHz,
      recording: recording,
      original: original,
      firstWord: firstWord,
      lastWord: lastWord,
      loop: loop,
    );
  }

  /// Queues a received message for auto-play behind anything already
  /// waiting. A message already sounding or queued is not added twice;
  /// text with nothing Morse can sound is skipped.
  void enqueue(
    String messageId,
    String text,
    MorseTiming timing, {
    double? toneHz,
    KeyedRecording? recording,
    bool original = false,
  }) {
    if (_disposed || PlaybackTimeline(text, timing).elements.isEmpty) return;
    if (playingId == messageId || _queue.any((c) => c.id == messageId)) return;
    final Duration length = PlaybackTimeline(
      text,
      timing,
      recording: recording,
      original: original,
    ).elements.fold(Duration.zero, (sum, e) => sum + e.duration);
    if (length > maxAutoClip) return;
    _queue.add(
      _Clip(
        messageId,
        text,
        timing,
        toneHz,
        PlaybackOrigin.auto,
        recording: recording,
        original: original,
      ),
    );
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

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _queue.clear();
    _cancelHold();
    _progressTimer?.cancel();
    _stopListening();
    unawaited(_subscription.cancel());
    unawaited(_player.dispose());
    unawaited(sink.dispose());
    super.dispose();
  }
}

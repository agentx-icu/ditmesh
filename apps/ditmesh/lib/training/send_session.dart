import 'dart:async';
import 'dart:math';

import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_trainer/morse_trainer.dart';

/// A send-practice exercise in progress.
///
/// Sits behind the keyers as their [KeyTarget]: every key-down / key-up is
/// timestamped by the caller's `Clock`, forwarded to the streaming
/// [MorseDecoder] and remembered as a mark or gap so [finish] can hand the
/// raw measurements to `SendAttempt` / `SendDiagnostics`. Pure logic: the UI
/// owns the clock, the periodic [tick] and the sidetone.
final class SendSession implements KeyTarget {
  SendSession({
    required this.target,
    required MorseTiming timing,
    required DateTime Function() now,
    this.lesson,
    this.drillKind = 'send',
    this.planStepId,
    String? id,
  }) : decoder = MorseDecoder(config: DecoderConfig(initialDit: timing.dit)),
       nominalTiming = timing,
       _now = now,
       startedAt = now() {
    this.id = id ?? ExerciseIds.next(startedAt, Random());
  }

  /// Stable exercise id of this attempt (see `ReceiveSession.id`).
  late final String id;

  /// Daily-plan step this attempt belongs to, if any.
  final String? planStepId;

  /// Text the operator is asked to send.
  final String target;

  /// Speed the operator is aiming for; seeds the decoder's dit estimate and
  /// the paddle keyer's element lengths.
  final MorseTiming nominalTiming;

  final MorseDecoder decoder;
  final DateTime Function() _now;
  final DateTime startedAt;
  final int? lesson;

  /// Stored as `SessionScore.drillKind` / history label.
  final String drillKind;

  final List<Duration> _marks = <Duration>[];
  final List<Duration> _gaps = <Duration>[];
  final StreamController<void> _changes = StreamController<void>.broadcast(
    sync: true,
  );
  Duration? _downAt;
  Duration? _lastUpAt;

  /// Whether the key-down now held appended a gap to [_gaps]; a cancelled
  /// press takes its gap back out.
  bool _heldAddedGap = false;
  StreamSubscription<DecodeEvent>? _decodeSub;
  SendDiagnostics? _result;

  /// Fires after every accepted key transition and every decoder event so a
  /// widget can rebuild its live view without polling.
  Stream<void> get changes => _changes.stream;

  /// Pattern of [target] as `.`/`-`, for the on-screen hint.
  String get targetPattern => MorseEncoder.toPattern(target);

  /// Live decoded text (characters and spaces committed so far).
  String get decodedText => _inTargetTerms(decoder.text);

  /// Several prosigns are keyed exactly like a punctuation mark (`<AR>` and
  /// `+`, `<BT>` and `=`, `<KN>` and `(`, `<AS>` and `&`), and the decoder
  /// reads them as punctuation. When the target asks for such a prosign and
  /// not for the look-alike mark, the mark is read as the prosign, so a
  /// perfectly keyed prosign scores as correct.
  String _inTargetTerms(String decoded) {
    final wanted = MorseText.charSet(target);
    final aliases = <String, String>{};
    for (final symbol in wanted) {
      final pattern = symbol.startsWith('<')
          ? MorseAlphabet.encodeProsign(symbol)
          : null;
      final mark = pattern == null
          ? null
          : MorseAlphabet.decodePattern(pattern);
      if (mark != null && !wanted.contains(mark)) {
        aliases[mark] = symbol;
      }
    }
    if (aliases.isEmpty) {
      return decoded;
    }
    return MorseText.tokenize(decoded).map((t) => aliases[t] ?? t).join();
  }

  /// Elements of the character being keyed right now.
  String get pendingPattern => decoder.pendingPattern;

  /// `1200 / dit`, 0 before the first mark.
  double get estimatedWpm {
    if (_marks.isEmpty) {
      return 0;
    }
    final ditMs = decoder.estimatedDit.inMicroseconds / 1000;
    return ditMs <= 0 ? 0 : 1200 / ditMs;
  }

  bool get isKeyDown => _downAt != null;
  int get markCount => _marks.length;
  bool get hasInput => _marks.isNotEmpty;
  bool get isFinished => _result != null;
  Duration get elapsed => _now().difference(startedAt);

  Duration _paused = Duration.zero;
  DateTime? _pausedAt;
  Duration? _activeAtFinish;

  /// Background: excluded from [activeElapsed].
  void pause() => _pausedAt ??= _now();

  void resume() {
    final at = _pausedAt;
    if (at == null) return;
    _paused += _now().difference(at);
    _pausedAt = null;
  }

  /// Time spent keying: pauses excluded, frozen when the attempt finishes
  /// (saving the result afterwards does not count).
  Duration get activeElapsed {
    final frozen = _activeAtFinish;
    if (frozen != null) return frozen;
    final open = _pausedAt == null
        ? Duration.zero
        : _now().difference(_pausedAt!);
    final active = elapsed - _paused - open;
    return active.isNegative ? Duration.zero : active;
  }

  /// Marks (key-down durations) in order; a defensive copy.
  List<Duration> get marks => List<Duration>.unmodifiable(_marks);

  /// Gaps between consecutive marks; a defensive copy.
  List<Duration> get gaps => List<Duration>.unmodifiable(_gaps);

  /// Subscribes to decoder events so [changes] fires on commits too. Called
  /// lazily by the UI; safe to call more than once.
  void listenToDecoder() {
    _decodeSub ??= decoder.events.listen((_) => _notify());
  }

  @override
  void keyDown(Duration at) {
    if (_downAt != null || isFinished) {
      return;
    }
    final lastUp = _lastUpAt;
    _heldAddedGap = false;
    if (lastUp != null) {
      final gap = at - lastUp;
      if (gap > Duration.zero) {
        _gaps.add(gap);
        _heldAddedGap = true;
      }
    }
    _downAt = at;
    decoder.keyDown(at);
    _notify();
  }

  @override
  void keyUp(Duration at) {
    final downAt = _downAt;
    if (downAt == null) {
      return;
    }
    _downAt = null;
    final mark = at - downAt;
    if (mark > Duration.zero) {
      _marks.add(mark);
    }
    _lastUpAt = at;
    decoder.keyUp(at);
    _notify();
  }

  /// Lets the decoder resolve pending gaps into character / word boundaries.
  /// Drive it from a periodic timer on the same clock as the key events.
  void tick(Duration now) {
    if (isFinished) {
      return;
    }
    decoder.tick(now);
  }

  /// Drops a key-down that will never see its key-up (the keyer was replaced
  /// or the app went to the background while the key was held). The open
  /// mark is discarded, not measured.
  void cancelHeld() {
    if (_downAt == null) {
      return;
    }
    _downAt = null;
    if (_heldAddedGap) {
      // The gap before a mark that never happened is not a real gap; the
      // next press measures from the last real key-up again.
      _gaps.removeLast();
      _heldAddedGap = false;
    }
    decoder.cancelMark();
    _notify();
  }

  /// Wipes the decoded text and measurements to retry the same target; the
  /// decoder keeps what it learnt about the operator's dit.
  void restart() {
    if (isFinished) {
      throw StateError('session already finished');
    }
    decoder.clearText();
    _marks.clear();
    _gaps.clear();
    _downAt = null;
    _lastUpAt = null;
    _notify();
  }

  /// Commits the pending character and evaluates the attempt. Idempotent.
  SendDiagnostics finish() {
    final existing = _result;
    if (existing != null) {
      return existing;
    }
    final downAt = _downAt;
    if (downAt != null) {
      // Key still held when the operator hit "done": close the mark now.
      keyUp(downAt + decoder.estimatedDit);
    }
    _activeAtFinish = activeElapsed;
    final decoded = _inTargetTerms(decoder.flush());
    final attempt = SendAttempt(
      target: target,
      decoded: decoded,
      marks: List<Duration>.unmodifiable(_marks),
      gaps: List<Duration>.unmodifiable(_gaps),
      estimatedDit: _marks.isEmpty ? Duration.zero : decoder.estimatedDit,
    );
    final result = attempt.evaluate();
    _result = result;
    _notify();
    return result;
  }

  /// The copy score of the finished attempt, stamped with this session's
  /// bookkeeping so it can go into progress history.
  SessionScore scoreForHistory() {
    final result = finish();
    return SessionScore.evaluate(
      result.attempt.target,
      result.attempt.decoded,
      at: _now(),
      elapsed: elapsed,
      lesson: lesson,
      drillKind: drillKind,
    );
  }

  void dispose() {
    unawaited(_decodeSub?.cancel());
    _decodeSub = null;
    decoder.dispose();
    unawaited(_changes.close());
  }

  void _notify() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';

import '../../i18n/l10n_extension.dart';
import '../../keying/key_profile.dart';
import '../../keying/key_profiles.dart';
import '../../training/training_settings.dart';
import 'morse_pattern_text.dart';
import 'keyed_draft_recording.dart';
import 'morse_playback_controller.dart';

/// Which hand-keying widget the input area shows.
enum KeyingMode { straightKey, paddles }

/// Lets the owner of a [KeyingInput] finish what the operator is keying
/// before it acts on the draft (send, mode switch).
class KeyingInputController {
  _KeyingInputState? _state;

  /// A character is half keyed: a mark is held, the keyer is mid-element,
  /// or elements wait for the character gap.
  bool get hasPending => _state?._hasPending ?? false;

  /// Ends a held mark or in-flight paddle element and commits the pending
  /// character now; its text reaches `onText` before this returns.
  void complete() => _state?._complete();
}

/// Straight key or iambic paddles wired to a [MorseDecoder]; decoded
/// characters are handed to [onText] so the owner can append them to the
/// draft. Both modalities work by touch (on-screen pads, ≥ 48 dp) and by
/// keyboard, with the device's active [KeyProfile] (F12): its bindings,
/// paddle orientation and iambic mode; an adapter that times its own
/// elements keys through the straight-key path; its sidetone switch gates
/// the local echo (decoding is unaffected).
///
/// The decoder is seeded with the listener's own dit length so the first
/// characters decode sensibly before it adapts to the operator's fist.
class KeyingInput extends StatefulWidget {
  const KeyingInput({
    super.key,
    required this.mode,
    required this.timing,
    required this.sink,
    required this.clock,
    required this.onText,
    this.controller,
    this.onRecordedText,
    this.onPendingChanged,
    this.height = 132,
    this.showHint = true,
  });

  final KeyingMode mode;
  final MorseTiming timing;
  final MorseSink sink;
  final Clock clock;
  final ValueChanged<String> onText;
  final ValueChanged<KeyedChunk>? onRecordedText;
  final KeyingInputController? controller;

  /// Fires when [KeyingInputController.hasPending] flips.
  final ValueChanged<bool>? onPendingChanged;
  final double height;

  /// The one-line "Space / Ctrl" hint above the pad (hidden when compact).
  final bool showHint;

  @override
  State<KeyingInput> createState() => _KeyingInputState();
}

class _KeyingInputState extends State<KeyingInput> {
  KeyProfile _profile = KeyProfile.defaults;
  late MorseSink _echo = _gatedSink();
  MorseSink _gatedSink() {
    final sink = widget.sink;
    return sink is LiveKeyingSink
        ? sink.withSidetone(() => _profile.appSidetone)
        : GatedSink(sink, () => _profile.appSidetone);
  }

  /// Paddles unless the profile's adapter keys its own elements.
  KeyingMode get _mode =>
      _profile.adapterKeyer ? KeyingMode.straightKey : widget.mode;
  late MorseDecoder _decoder;
  late RecordingKeyTarget _recording;
  late StreamSubscription<DecodeEvent> _events;
  StraightKey? _straight;
  IambicKeyer? _keyer;
  Timer? _tick;
  bool _reportedPending = false;
  bool _disposing = false;

  bool get _hasPending =>
      _decoder.pendingPattern.isNotEmpty ||
      (_straight?.isDown ?? false) ||
      (_keyer?.isKeying ?? false);

  void _complete() {
    final Duration now = widget.clock.now();
    final StraightKey? straight = _straight;
    if (straight != null && straight.isDown) straight.release(now);
    // A paddle element in flight is finished at its full length, so a dah
    // being keyed is not cut down to a dit.
    final IambicKeyer? keyer = _keyer;
    if (keyer != null && keyer.isKeying) keyer.finish();
    _decoder.flush();
    _reportPending();
  }

  void _reportPending() {
    final bool pending = _hasPending;
    if (pending == _reportedPending) return;
    _reportedPending = pending;
    widget.onPendingChanged?.call(pending);
  }

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _decoder = MorseDecoder(
      config: DecoderConfig(initialDit: widget.timing.dit),
    );
    _recording = RecordingKeyTarget(MorseDecoderTarget(_decoder), widget.clock);
    _events = _decoder.events.listen(_onDecode);
    // A sink sounds nothing until prepared (the audio engine starts here).
    unawaited(widget.sink.prepare());
    _tick = Timer.periodic(const Duration(milliseconds: 40), (_) {
      final String before = _decoder.pendingPattern;
      _decoder.tick(widget.clock.now());
      if (before != _decoder.pendingPattern && mounted) setState(() {});
      _reportPending();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = KeyProfiles.of(context);
    final first = _straight == null && _keyer == null;
    final rebuild =
        first ||
        next.adapterKeyer != _profile.adapterKeyer ||
        next.keyerMode != _profile.keyerMode;
    _profile = next;
    if (!rebuild) return;
    // Disposing the old keyer releases anything held: no stuck tone.
    _disposeKeyer();
    _buildKeyer();
  }

  @override
  void didUpdateWidget(KeyingInput old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      if (identical(old.controller?._state, this)) {
        old.controller?._state = null;
      }
      widget.controller?._state = this;
    }
    if (old.mode != widget.mode ||
        old.sink != widget.sink ||
        old.clock != widget.clock) {
      if (old.clock != widget.clock) {
        _decoder.clearText();
        _recording = RecordingKeyTarget(
          MorseDecoderTarget(_decoder),
          widget.clock,
        );
      }
      if (old.sink != widget.sink) {
        _echo = _gatedSink();
      }
      _disposeKeyer();
      _buildKeyer();
      if (old.sink != widget.sink) unawaited(widget.sink.prepare());
    } else if (old.timing != widget.timing) {
      _keyer?.timing = KeyerTiming.fromMorseTiming(widget.timing);
    }
  }

  void _buildKeyer() {
    final KeyTarget target = _recording;
    switch (_mode) {
      case KeyingMode.straightKey:
        _straight = StraightKey(target: target, sink: _echo);
      case KeyingMode.paddles:
        _keyer = IambicKeyer(
          timing: KeyerTiming.fromMorseTiming(widget.timing),
          target: target,
          sink: _echo,
          clock: widget.clock,
          mode: _profile.keyerMode == KeyerMode.iambicA
              ? IambicMode.a
              : IambicMode.b,
        );
    }
  }

  void _disposeKeyer() {
    final StraightKey? s = _straight;
    final IambicKeyer? k = _keyer;
    _straight = null;
    _keyer = null;
    if (s != null) {
      // StraightKey.dispose cannot see the decoder through our recording
      // target. Cancel a held mark explicitly before rebuilding its input.
      if (s.isDown) {
        _decoder.cancelMark();
        _recording.cancelMark();
      }
      unawaited(s.dispose());
    }
    if (k != null) unawaited(k.dispose());
  }

  void _onDecode(DecodeEvent event) {
    switch (event.kind) {
      case DecodeEventKind.character:
      case DecodeEventKind.word:
      case DecodeEventKind.unknownPattern:
        final String? text = event.text;
        if (text != null && text.isNotEmpty) {
          final chunk = _recording.consume(text);
          if (widget.onRecordedText != null) {
            widget.onRecordedText!(chunk);
          } else {
            widget.onText(text);
          }
        }
      case DecodeEventKind.element:
        break;
    }
    if (mounted && !_disposing) setState(() {});
    _reportPending();
  }

  @override
  void dispose() {
    if (identical(widget.controller?._state, this)) {
      widget.controller?._state = null;
    }
    _tick?.cancel();
    // Leaving with a character half keyed: commit it, as send and the mode
    // switch do, instead of dropping it silently. The decoder's event stream
    // is synchronous, so the text reaches the owner before it is released;
    // the owner records it for its own dispose-time draft flush.
    _disposing = true;
    _complete();
    unawaited(_events.cancel());
    _disposeKeyer();
    _decoder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String pending = _decoder.pendingPattern;
    final KeyboardKeyBinding binding = _profile.binding;
    final Widget pad = switch (_mode) {
      KeyingMode.straightKey => Center(
        child: StraightKeyButton(
          input: _straight!,
          binding: binding,
          clock: widget.clock,
          size: widget.height - 12,
          autofocus: true,
          label: context.s.learnStraightKeyLabel,
          // Screen readers intercept raw pointer timing: offer one dit / one
          // dah as custom actions, like the Learn keyer does.
          semanticDit: widget.timing.dit,
          semanticDitLabel: context.s.learnDitLabel,
          semanticDahLabel: context.s.learnDahLabel,
        ),
      ),
      KeyingMode.paddles => PaddleButtons(
        input: _keyer!,
        binding: binding,
        swapPaddles: _profile.swapPaddles,
        clock: widget.clock,
        height: widget.height - 12,
        autofocus: true,
        ditLabel: context.s.learnDitLabel,
        dahLabel: context.s.learnDahLabel,
      ),
    };
    final Widget pattern = MorsePatternText(
      pending.isEmpty ? ' ' : pending,
      style: theme.textTheme.titleMedium,
      color: theme.colorScheme.primary,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: widget.showHint
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        !_profile.isDefault
                            ? context.s.keysHintCustom(
                                keyLabels(
                                  _profile.keysFor(
                                    _mode == KeyingMode.straightKey
                                        ? KeyerMode.straight
                                        : _profile.keyerMode,
                                  ),
                                ),
                              )
                            : _mode == KeyingMode.straightKey
                            ? context.s.chatKeyHint
                            : context.s.chatPaddleHint,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    pattern,
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(height: widget.height, child: pad),
              ],
            )
          // Compact (short screens): the pending pattern sits beside the pad
          // instead of on a row of its own.
          : Row(
              children: [
                Expanded(
                  child: SizedBox(height: widget.height, child: pad),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 72, child: Center(child: pattern)),
              ],
            ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/receive_session.dart';
import '../../../training/training_controller.dart';
import '../../../training/training_settings.dart';
import '../conditions/conditions_playback.dart';
import '../conditions/conditions_widgets.dart';
import '../drill_session_guard.dart';
import '../learn_platform.dart';
import '../learn_playback.dart';
import '../progress_save_snack.dart';
import 'answer_keypad.dart';
import 'receive_summary_view.dart';
import 'round_result_view.dart';

enum _Phase { listen, result, summary }

/// Plays each round of a [ReceiveSession], collects the copy (text field on
/// desktop, restricted keypad everywhere), scores it, and on completion
/// records the session through the controller.
///
/// Leaving after the first answered round asks first (the rounds are only
/// saved on finish), and the screen is kept on ([screenWake]) until the
/// summary so a phone's auto-lock cannot background the app mid-drill.
class ReceiveDrillScreen extends StatefulWidget {
  const ReceiveDrillScreen({
    super.key,
    required this.controller,
    required this.playback,
    required this.session,
    this.title,
    this.screenWake = const WakelockScreenWake(),
    this.conditionsPlayback,
  });

  final TrainingController controller;
  final LearnPlaybackFactory playback;
  final ReceiveSession session;
  final String? title;
  final ScreenWakeApi screenWake;

  /// Player for a session under radio conditions (F11); one is created when
  /// the session has conditions and none is given. Owned by the screen.
  final ConditionsPlayback? conditionsPlayback;

  @override
  State<ReceiveDrillScreen> createState() => _ReceiveDrillScreenState();
}

class _ReceiveDrillScreenState extends State<ReceiveDrillScreen>
    with WidgetsBindingObserver {
  final TextEditingController _answer = TextEditingController();
  final FocusNode _answerFocus = FocusNode();
  LearnPlayback? _playback;
  StreamSubscription<PlayerEvent>? _playerSub;
  _Phase _phase = _Phase.listen;
  bool _playing = false;
  bool _recording = false;
  ReceiveRound? _lastRound;
  ReceiveOutcome? _outcome;
  String? _unlockedChar;
  late final DrillScreenWake _wake = DrillScreenWake(widget.screenWake);

  /// Radio-condition audio (F11), only for a session that has conditions.
  late final ConditionsPlayback? _conditions = _session.conditions == null
      ? null
      : widget.conditionsPlayback ?? ConditionsPlayback();
  StreamSubscription<bool>? _conditionsSub;

  /// Set right before we stop the conditions audio ourselves, so that stop
  /// does not count as having heard the round.
  bool _stopping = false;

  ReceiveSession get _session => widget.session;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wake.setActive(true);
    unawaited(_setup());
  }

  /// Set while the app is in the background on a phone: the sidetone is
  /// silenced there, so playback must not run (or start) unheard. The round
  /// is replayed with the Replay button on return.
  bool _backgrounded = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _wake.onLifecycle(state);
    _backgrounded = isDrillBackground(state);
    if (_backgrounded) {
      _playback?.player.stop();
      _stopConditions();
      _session.pause();
    } else if (state == AppLifecycleState.resumed) {
      _session.resume();
    }
  }

  /// Answered rounds that leaving now would throw away.
  bool get _hasUnsavedRounds =>
      _session.roundCount > 0 && !_recording && _phase != _Phase.summary;

  Future<void> _setup() async {
    final playback = await widget.playback.create(widget.controller.settings);
    if (!mounted) {
      await playback.dispose();
      return;
    }
    _playerSub = playback.player.events.listen(_onPlayerEvent);
    _conditionsSub = _conditions?.playing.listen(_onConditionsPlaying);
    setState(() => _playback = playback);
    _play();
  }

  /// The current round was heard to the end once. A replay of an
  /// interrupted round (background, stop) is not assistance.
  bool _heard = false;

  void _onPlayerEvent(PlayerEvent event) {
    if (event is PlayerCompleted) _heard = true;
    if (event is PlayerCompleted || event is PlayerStopped) {
      if (mounted && _playing) {
        setState(() => _playing = false);
      }
    }
  }

  void _onConditionsPlaying(bool playing) {
    if (!playing && !_stopping) _heard = true;
    _stopping = false;
    if (mounted && _playing != playing) setState(() => _playing = playing);
  }

  /// Always stops: a clip still rendering or loading is not "playing" yet
  /// but must not start once the round is over or the app is hidden.
  void _stopConditions() {
    final c = _conditions;
    if (c == null) return;
    // Set even when nothing plays yet: a clip in its loading window still
    // emits start and stop, and that stop is ours, not "heard". The next
    // round's start event clears the flag.
    _stopping = true;
    unawaited(c.stop());
  }

  /// The audio engine could not play the rendering: the round says so
  /// instead of "listening" forever.
  bool _conditionsFailed = false;

  /// Radio conditions are an audio effect: without sound there is nothing
  /// realistic to hear, and an unaffected flash would give the copy away.
  bool get _conditionsBlocked =>
      _conditions != null && !widget.controller.settings.soundEnabled;

  void _play() {
    final playback = _playback;
    if (playback == null || _phase != _Phase.listen || _backgrounded) {
      return;
    }
    final conditions = _conditions;
    if (conditions != null) {
      if (_conditionsBlocked) return;
      setState(() {
        _playing = true;
        _conditionsFailed = false;
      });
      conditions
          .play(_session.currentDrill.text, _session.currentConditions!)
          .then((started) {
            // Dropped by a stop during rendering: no event will reset it.
            if (!started && mounted) setState(() => _playing = false);
          })
          .catchError((Object _) {
            if (mounted) {
              setState(() {
                _playing = false;
                _conditionsFailed = true;
              });
            }
          });
      return;
    }
    setState(() => _playing = true);
    playback.player.play(_session.currentTimeline);
  }

  /// After answering: the same round without any effect, as a reference.
  /// The answer is already in, so this is not assistance.
  void _playCleanReference(ReceiveRound round) {
    _playback?.player.play(
      MorseEncoder.encode(round.drill.text, _session.timing),
    );
  }

  /// Playing the round again is assistance (functional spec §3.3): the
  /// session still counts as practice but no longer unlocks or feeds SRS.
  void _replay() {
    if (_heard) _session.markReplay();
    _play();
  }

  void _submit() {
    if (_phase != _Phase.listen || _session.isFinished) {
      return;
    }
    _playback?.player.stop();
    _stopConditions();
    final round = _session.submit(_answer.text);
    _heard = false;
    _answer.clear();
    setState(() {
      _lastRound = round;
      _phase = _Phase.result;
    });
  }

  Future<void> _next() async {
    if (_session.isComplete) {
      await _finish();
      return;
    }
    setState(() => _phase = _Phase.listen);
    _play();
    if (hasPhysicalKeyboardByDefault) {
      _answerFocus.requestFocus();
    }
  }

  Future<void> _finish() async {
    if (_recording) {
      return;
    }
    _recording = true;
    setState(() {});
    final outcome = await widget.controller.recordReceiveSession(_session);
    if (!mounted) {
      return;
    }
    _wake.setActive(false);
    setState(() {
      _outcome = outcome;
      _unlockedChar = outcome.advanced ? widget.controller.newestChar : null;
      _phase = _Phase.summary;
    });
    if (!outcome.saved) {
      showProgressSaveFailed(context, widget.controller);
    }
  }

  static bool _perceivable(TrainingSettings settings) =>
      settings.soundEnabled ||
      settings.flashEnabled ||
      (settings.hapticEnabled && isTouchPlatform);

  void _appendChar(String c) {
    _answer.text = '${_answer.text}$c';
  }

  void _backspace() {
    final text = _answer.text;
    if (text.isEmpty) {
      return;
    }
    // Remove a whole `<XX>` prosign token if that is what ends the text.
    if (text.endsWith('>')) {
      final open = text.lastIndexOf('<');
      if (open >= 0) {
        _answer.text = text.substring(0, open);
        return;
      }
    }
    _answer.text = text.substring(0, text.length - 1);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _wake.dispose();
    unawaited(_playerSub?.cancel());
    unawaited(_conditionsSub?.cancel());
    unawaited(_conditions?.dispose());
    unawaited(_playback?.dispose());
    _answer.dispose();
    _answerFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final title =
        widget.title ??
        (_session.kind == ReceiveDrillKind.review
            ? s.learnReviewTitle
            : s.learnReceiveTitle);
    final body = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: switch (_phase) {
              _Phase.listen => _buildListen(context),
              _Phase.result => _buildResult(context),
              _Phase.summary => _buildSummary(context),
            },
          ),
        ),
      ),
    );
    final flash = _playback?.flash;
    return DrillLeaveGuard(
      guard: _hasUnsavedRounds,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: _session.progress,
              minHeight: 4,
            ),
          ),
        ),
        body: flash == null ? body : FlashOverlay(isOn: flash, child: body),
      ),
    );
  }

  Widget _buildListen(BuildContext context) {
    final theme = Theme.of(context);
    final s = context.s;
    final ready = _playback != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          s.learnRoundOf(_session.roundCount + 1),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (_session.conditions case final RadioScenario c)
          ConditionsChip(scenario: c),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              _playing ? Icons.volume_up : Icons.volume_off_outlined,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _playing ? s.learnListen : s.learnReady,
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: ready && !_playing ? _replay : null,
              icon: const Icon(Icons.replay),
              label: Text(s.learnReplay),
            ),
          ],
        ),
        if (_conditionsBlocked || _conditionsFailed)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _conditionsFailed ? s.conditionsAudioFailed : s.conditionsNeedSound,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          )
        // Haptics only count on phones; elsewhere the flash fallback runs.
        else if (!_perceivable(widget.controller.settings))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              s.learnNoFeedbackWarning,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        if (_session.isAssisted)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              s.learnReplayAssistedNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _answer,
          focusNode: _answerFocus,
          autofocus: hasPhysicalKeyboardByDefault,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: isTouchPlatform ? TextInputType.none : null,
          style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 2),
          decoration: InputDecoration(
            hintText: s.learnAnswerHint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 12),
        AnswerKeypad(
          chars: _session.chars,
          onChar: _appendChar,
          onBackspace: _backspace,
          onSpace: () => _appendChar(' '),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(s.learnSubmit),
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context) {
    final round = _lastRound!;
    final isLast = _session.isComplete;
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        RoundResultView(round: round),
        if (_session.conditions != null)
          CleanReferenceButton(onPressed: () => _playCleanReference(round)),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _next,
          autofocus: true,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(isLast ? s.learnFinish : s.learnNext),
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    final outcome = _outcome;
    if (outcome == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ReceiveSummaryView(
          session: _session,
          outcome: outcome,
          unlockedChar: _unlockedChar,
        ),
        if (_session.conditions case final RadioScenario c)
          ConditionsSummary(
            scenario: c,
            history: widget.controller.progress.history,
          ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(outcome),
          autofocus: true,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(context.s.learnDone),
        ),
      ],
    );
  }
}

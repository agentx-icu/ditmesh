import 'dart:async';

import 'package:flutter/material.dart';
import 'package:morse_io/morse_io.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/receive_session.dart';
import '../../../training/training_controller.dart';
import '../../../training/training_settings.dart';
import '../../common/app_bar_title.dart';
import '../drill_session_guard.dart';
import '../learn_platform.dart';
import '../learn_playback.dart';
import '../progress_save_snack.dart';
import 'answer_keypad.dart';
import 'receive_summary_view.dart';
import 'receive_widgets.dart';
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
    this.screenWake = const WakelockScreenWake(),
  });

  final TrainingController controller;
  final LearnPlaybackFactory playback;
  final ReceiveSession session;
  final ScreenWakeApi screenWake;

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
  late final DrillScreenWake _wake = DrillScreenWake(widget.screenWake);

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

  void _play() {
    final playback = _playback;
    if (playback == null || _phase != _Phase.listen || _backgrounded) {
      return;
    }
    setState(() => _playing = true);
    playback.player.play(_session.currentTimeline);
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
    unawaited(_playback?.dispose());
    _answer.dispose();
    _answerFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final title = s.learnReceiveTitle;
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
          title: AppBarTitle(title),
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
        const SizedBox(height: 8),
        PlaybackStatusRow(
          playing: _playing,
          onReplay: ready && !_playing ? _replay : null,
          replayLabel: s.learnReplay,
        ),
        // Haptics only count on phones; elsewhere the flash fallback runs.
        if (!_perceivable(widget.controller.settings))
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
            // Smaller than the typed answer and wrapping, never clipped.
            hintStyle: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            hintMaxLines: 3,
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
        ReceiveSummaryView(session: _session, outcome: outcome),
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

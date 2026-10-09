import 'dart:async';

import 'package:flutter/material.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../keying/key_profiles.dart';
import '../../../keying/profile_keyer.dart';
import '../../../training/send_detail_store.dart';
import '../../../training/send_session.dart';
import '../../../training/training_controller.dart';
import '../../../training/training_settings.dart';
import '../../common/app_bar_title.dart';
import '../drill_session_guard.dart';
import '../learn_platform.dart';
import '../learn_playback.dart';
import '../progress_save_snack.dart';
import 'copy_from_memory_switch.dart';
import 'keyer_legend.dart';
import 'send_live_view.dart';
import 'send_result_view.dart';
import 'send_targeted_practice.dart';
import 'send_timeline_view.dart';

/// Send practice: a target to key, an on-screen straight key or paddles (also
/// driven by Space / left Ctrl / right Ctrl when focused), live decode, and
/// rhythm diagnostics with tips when the operator hits Done.
///
/// Leaving with keyed input that was not evaluated yet asks first, and the
/// screen is kept on ([screenWake]) while practising so a phone's auto-lock
/// cannot background the app mid-attempt.
class SendPracticeScreen extends StatefulWidget {
  const SendPracticeScreen({
    super.key,
    required this.controller,
    required this.playback,
    this.session,
    this.nextSession,
    this.maxAttempts,
    this.screenWake = const WakelockScreenWake(),
  });

  /// Targeted practice offers this many attempts, then only Done.
  final int? maxAttempts;

  /// Makes the session for "Try another" (daily-plan send steps); defaults
  /// to `controller.startSendSession()`.
  final Future<SendSession> Function()? nextSession;

  final TrainingController controller;
  final LearnPlaybackFactory playback;

  /// Initial session; defaults to `controller.startSendSession()`.
  final SendSession? session;

  /// Held while practising; released on the result view and in background.
  final ScreenWakeApi screenWake;

  /// Decoder tick period on the playback clock.
  static const Duration tickPeriod = Duration(milliseconds: 40);

  @override
  State<SendPracticeScreen> createState() => _SendPracticeScreenState();
}

class _SendPracticeScreenState extends State<SendPracticeScreen>
    with WidgetsBindingObserver {
  late SendSession _session;
  late KeyerMode _mode;
  LearnPlayback? _playback;
  ProfileKeyer? _keyer;

  /// Bumped whenever the keyer is rebuilt; part of the key widgets' keys so
  /// a fresh keyer never inherits a pointer or key the old widget held.
  int _keyerGeneration = 0;
  Timer? _tick;
  SendDiagnostics? _result;
  SendTimeline? _timeline;
  int _attempts = 0;
  bool _hideTarget = false;
  bool _recording = false;
  bool _disposed = false;
  late final DrillScreenWake _wake = DrillScreenWake(widget.screenWake);
  StreamSubscription<void>? _changesSub;

  /// Mirrors `_session.hasInput` so the leave guard follows key events
  /// (which do not rebuild this widget) without a rebuild per event.
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session ?? widget.controller.startSendSession();
    _watchSession();
    _mode = widget.controller.settings.keyerMode;
    WidgetsBinding.instance.addObserver(this);
    _wake.setActive(true);
    unawaited(_setup());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A key profile edited meanwhile applies to the next key press.
    // Always read (and so subscribe), even before the keyer exists.
    final profile = KeyProfiles.of(context);
    final keyer = _keyer;
    if (keyer != null && profile != keyer.profile) _buildKeyer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _wake.onLifecycle(state);
    // The sidetone stops in the background; drop whatever is held so the
    // keyer stops sending and no key is stuck down on return.
    if (isDrillBackground(state) && _result == null && !_disposed) {
      _session.pause();
      _buildKeyer();
      setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      _session.resume();
    }
  }

  void _watchSession() {
    _session.listenToDecoder();
    unawaited(_changesSub?.cancel());
    _hasInput = _session.hasInput;
    _changesSub = _session.changes.listen((_) {
      if (_disposed || _session.hasInput == _hasInput) {
        return;
      }
      setState(() => _hasInput = _session.hasInput);
    });
  }

  Future<void> _setup() async {
    final playback = await widget.playback.create(widget.controller.settings);
    if (_disposed) {
      await playback.dispose();
      return;
    }
    _playback = playback;
    _buildKeyer();
    _scheduleTick();
    setState(() {});
  }

  void _buildKeyer() {
    final playback = _playback;
    if (playback == null) {
      return;
    }
    // Release any held key first: neither the old keyer nor its widget will
    // deliver the key-up any more.
    _session.cancelHeld();
    _keyer?.dispose();
    _keyerGeneration++;
    // The device key profile (F12): bindings, orientation, adapter, echo.
    _keyer = ProfileKeyer.build(
      profile: KeyProfiles.of(context, listen: false),
      mode: _mode,
      target: _session,
      sink: playback.sink,
      sidetone: playback.sidetone,
      clock: playback.clock,
      timing: _session.nominalTiming,
    );
  }

  void _scheduleTick() {
    final playback = _playback;
    if (playback == null || _disposed) {
      return;
    }
    _tick = playback.clock.schedule(SendPracticeScreen.tickPeriod, () {
      if (_disposed) {
        return;
      }
      _session.tick(playback.clock.now());
      _scheduleTick();
    });
  }

  void _setMode(KeyerMode mode) {
    if (mode == _mode) {
      return;
    }
    setState(() => _mode = mode);
    _buildKeyer();
    unawaited(
      widget.controller.updateSettings(
        widget.controller.settings.copyWith(keyerMode: mode),
      ),
    );
  }

  Future<void> _finish() async {
    if (_recording || _result != null) {
      return;
    }
    setState(() => _recording = true);
    _wake.setActive(false);
    final result = _session.finish();
    String? detailRef;
    try {
      // The detail is written before the summary refers to it.
      detailRef = await widget.controller.saveSendDetail(_session, result);
    } on Object {
      detailRef = null;
    }
    final outcome = await widget.controller.recordSendSession(
      _session,
      detailRef: detailRef,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _result = result;
      _attempts++;
      _timeline = SendTimeline.build(
        target: _session.target,
        marks: _session.marks,
        gaps: _session.gaps,
        timing: _session.nominalTiming,
        estimatedDit: result.attempt.estimatedDit,
      );
    });
    if (!outcome.saved) {
      showProgressSaveFailed(context, widget.controller);
    }
  }

  void _restart() {
    _session.restart();
    // A key held through the restart belongs to the old attempt.
    _buildKeyer();
    setState(() {});
  }

  Future<void> _another() async {
    // A rhythm replay must not keep driving the sink the new keyer uses.
    _playback?.player.stop();
    final factory = widget.nextSession;
    final next = factory == null
        ? widget.controller.startSendSession()
        : await factory();
    if (_disposed) {
      next.dispose();
      return;
    }
    _session.dispose();
    _session = next;
    _watchSession();
    _result = null;
    _recording = false;
    _wake.setActive(true);
    _buildKeyer();
    setState(() {});
  }

  /// Three new attempts at [text] (one symbol or the whole target); the
  /// standard can be heard first and playback never counts as an attempt.
  Future<void> _practisePart(String text) {
    _playback?.player.stop();
    return openTargetedSendPractice(
      context,
      controller: widget.controller,
      playback: widget.playback,
      template: _session,
      text: text,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _wake.dispose();
    unawaited(_changesSub?.cancel());
    _tick?.cancel();
    _keyer?.dispose();
    _session.dispose();
    unawaited(_playback?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final body = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _result == null
                ? _buildPractice(context)
                : _buildResult(context),
          ),
        ),
      ),
    );
    return DrillLeaveGuard(
      guard: _hasInput && _result == null && !_recording,
      child: _scaffold(s, body),
    );
  }

  Widget _scaffold(S s, Widget body) {
    final flash = _playback?.flash;
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(s.learnSendTitle),
        actions: <Widget>[
          if (_result == null && _playback != null)
            IconButton(
              tooltip: s.learnRhythmPlayStandard,
              icon: const Icon(Icons.hearing),
              // Hearing the standard first never counts as an attempt.
              onPressed: () => _playback?.player.play(
                MorseEncoder.encode(_session.target, _session.nominalTiming),
              ),
            ),
          CopyFromMemorySwitch(
            showLabel: CopyFromMemorySwitch.labelFits(
              context,
              title: s.learnSendTitle,
              // The "hear the standard" button takes room too.
              extraActions: _result == null && _playback != null ? 1 : 0,
            ),
            value: _hideTarget,
            onChanged: _result == null
                ? (v) => setState(() => _hideTarget = v)
                : null,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: flash == null ? body : FlashOverlay(isOn: flash, child: body),
    );
  }

  Widget _buildPractice(BuildContext context) {
    final playback = _playback;
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SegmentedButton<KeyerMode>(
          segments: <ButtonSegment<KeyerMode>>[
            ButtonSegment(
              value: KeyerMode.straight,
              label: Text(s.learnKeyerStraight),
            ),
            ButtonSegment(
              value: KeyerMode.iambicA,
              label: Text(s.learnKeyerIambicA),
            ),
            ButtonSegment(
              value: KeyerMode.iambicB,
              label: Text(s.learnKeyerIambicB),
            ),
          ],
          selected: <KeyerMode>{_mode},
          onSelectionChanged: (s) => _setMode(s.first),
          showSelectedIcon: false,
        ),
        const SizedBox(height: 16),
        SendLiveView(session: _session, hideTarget: _hideTarget),
        const SizedBox(height: 20),
        if (playback == null)
          const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          )
        else
          _buildKey(playback, s),
        if (hasPhysicalKeyboardByDefault) ...<Widget>[
          const SizedBox(height: 8),
          KeyerLegend(mode: _keyer?.mode ?? _mode),
        ],
        const SizedBox(height: 20),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.refresh),
                label: Text(s.learnRestart),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              // Enabled once there is something to evaluate; follows the
              // session stream because key events do not rebuild this widget.
              child: StreamBuilder<void>(
                stream: _session.changes,
                builder: (context, _) => FilledButton.icon(
                  onPressed: _session.hasInput ? _finish : null,
                  icon: const Icon(Icons.check),
                  label: Text(s.learnDone),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(LearnPlayback playback, S s) =>
      // A key per rebuild so Flutter never reuses a paddle state for a
      // straight key.
      _keyer!.widget(
        key: ValueKey<String>('key-$_keyerGeneration'),
        clock: playback.clock,
        size: 180,
        s: s,
        semanticDit: _session.nominalTiming.dit,
      );

  Widget _buildResult(BuildContext context) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SendResultView(diagnostics: _result!),
        if (_timeline != null) ...<Widget>[
          const SizedBox(height: 16),
          SendTimelineView(
            timeline: _timeline!,
            onPlayMine: (i) => _playback?.player.play(
              i == null ? _timeline!.myElements : _timeline!.myElementsFor(i),
            ),
            onPlayStandard: (i) => _playback?.player.play(
              i == null
                  ? _timeline!.standardElements
                  : _timeline!.standardElementsFor(i),
            ),
            onPractice: _practisePart,
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(_result),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(s.learnDone),
              ),
            ),
            const SizedBox(width: 12),
            if (widget.maxAttempts == null || _attempts < widget.maxAttempts!)
              Expanded(
                child: FilledButton(
                  onPressed: _another,
                  autofocus: true,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: Text(s.learnTryAnother),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

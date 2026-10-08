import 'dart:async';

import 'package:flutter/material.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/qso_practice.dart';
import '../../../training/send_session.dart';
import '../../../training/training_controller.dart';
import '../drill_session_guard.dart';
import '../keying/keyer_panel.dart';
import '../learn_platform.dart';
import '../learn_playback.dart';
import '../progress_save_snack.dart';
import 'qso_labels.dart';
import 'qso_log_view.dart';
import 'qso_summary_view.dart';

/// A running simulated QSO (functional spec §5.2): the remote station's
/// complete text snapshots are played at the learner's speed; the learner
/// keys a reply (touch or keyboard) and submits it explicitly. Pausing,
/// backgrounding and leaving stop playback; the text state is kept as a
/// draft and can be resumed.
class QsoScreen extends StatefulWidget {
  const QsoScreen({
    super.key,
    required this.controller,
    required this.playback,
    required this.session,
    this.resumed,
    this.screenWake = const WakelockScreenWake(),
  });

  /// The draft this QSO was resumed from (null for a fresh QSO): its
  /// unsent keyed reply is kept, and nothing plays until asked.
  final QsoDraft? resumed;

  final TrainingController controller;
  final LearnPlaybackFactory playback;
  final QsoSession session;
  final ScreenWakeApi screenWake;

  @override
  State<QsoScreen> createState() => _QsoScreenState();
}

class _QsoScreenState extends State<QsoScreen> with WidgetsBindingObserver {
  final GlobalKey<KeyerPanelState> _panel = GlobalKey<KeyerPanelState>();
  final Set<int> _revealed = <int>{};
  final List<double> _wpms = <double>[];
  final Stopwatch _active = Stopwatch();
  late final Duration _activeBefore = widget.resumed?.active ?? Duration.zero;

  /// A keyed but unsent reply restored from the draft, and its id.
  late String _carry = widget.resumed?.pendingText ?? '';
  late String? _carryId = widget.resumed?.pendingId;

  Duration get _activeTotal => _activeBefore + _active.elapsed;

  /// Restored and newly keyed text joined as keyed: the decoder decides
  /// where word gaps are, so a reply resumed mid-word stays one word.
  String get _pendingText => '$_carry${_keying.decodedText}';
  late final DrillScreenWake _wake = DrillScreenWake(widget.screenWake);
  LearnPlayback? _playback;
  StreamSubscription<PlayerEvent>? _playerSub;
  late SendSession _keying;
  StreamSubscription<void>? _keyingSub;
  bool _remotePlaying = false;
  bool _recorded = false;
  bool _disposed = false;
  QsoHint? _hint;
  List<QsoIssue> _issues = const <QsoIssue>[];

  QsoSession get _session => widget.session;
  TrainingController get _c => widget.controller;

  MorseTiming get _remoteTiming => MorseTiming(
    wpm: _session.characterWpm,
    farnsworthWpm: _session.effectiveWpm < _session.characterWpm
        ? _session.effectiveWpm
        : null,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _newKeying();
    _active.start();
    _wake.setActive(true);
    unawaited(_setup());
  }

  Future<void> _setup() async {
    final playback = await widget.playback.create(_c.settings);
    if (_disposed) {
      await playback.dispose();
      return;
    }
    _playerSub = playback.player.events.listen((event) {
      if ((event is PlayerCompleted || event is PlayerStopped) &&
          _remotePlaying &&
          !_disposed) {
        setState(() => _remotePlaying = false);
      }
    });
    setState(() => _playback = playback);
    // A fresh QSO starts with the remote's call; a resumed one never
    // restarts playback on its own.
    if (widget.resumed == null && _session.learnerTurns == 0) {
      _playRemote(_session.lastRemoteText);
    }
  }

  void _newKeying() {
    unawaited(_keyingSub?.cancel());
    _keying = SendSession(target: '', timing: _remoteTiming, now: _c.now);
    _keying.listenToDecoder();
    var marks = _keying.markCount;
    _keyingSub = _keying.changes.listen((_) {
      // Real keying is practice even after Pause stopped the clock; a
      // decoder committing a pending gap is not.
      final keyed = _keying.isKeyDown || _keying.markCount != marks;
      marks = _keying.markCount;
      if (keyed && !_active.isRunning && !_session.isDone) _active.start();
      if (!_disposed) setState(() {});
    });
  }

  void _playRemote(String? text) {
    final playback = _playback;
    if (text == null || playback == null || _disposed) return;
    _panel.currentState?.releaseHeld();
    _active.start();
    setState(() => _remotePlaying = true);
    playback.player.play(MorseEncoder.encode(text, _remoteTiming));
  }

  void _pause() {
    _playback?.player.stop();
    // A paused QSO is not active practice.
    _active.stop();
    _panel.currentState?.releaseHeld();
    if (mounted) setState(() => _remotePlaying = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _wake.onLifecycle(state);
    if (isDrillBackground(state)) {
      _pause();
      _active.stop();
      unawaited(_saveDraft());
    } else if (state == AppLifecycleState.resumed && !_session.isDone) {
      _active.start();
    }
  }

  Future<void> _saveDraft() async {
    // Let the decoder commit a pending character / word gap first, so a
    // restored reply keeps its word boundaries.
    final playback = _playback;
    if (playback != null) _keying.tick(playback.clock.now());
    try {
      await _c.saveQsoDraft(
        _session,
        pendingText: _pendingText,
        pendingId: _carryId ?? _keying.id,
        active: _activeTotal,
      );
    } on Object {
      // A lost draft only costs the resume option.
    }
  }

  Future<void> _submitText(String id, String text) async {
    if (_session.isDone) return;
    final reply = _session.submit(id, text);
    if (reply.duplicate) return;
    setState(() {
      _issues = reply.evaluation.issues;
      if (reply.advanced) _hint = null;
    });
    unawaited(_saveDraft());
    if (_session.isDone) {
      await _finish();
    }
    _playRemote(reply.remoteText);
  }

  Future<void> _send() async {
    final keying = _keying;
    final result = keying.finish();
    if (result.attempt.marks.length >= 3 && result.measuredWpm > 0) {
      _wpms.add(result.measuredWpm);
    }
    final text = '$_carry${result.attempt.decoded}';
    final id = _carryId ?? keying.id;
    _carry = '';
    _carryId = null;
    _newKeying();
    keying.dispose();
    _active.start();
    await _submitText(id, text);
  }

  void _clear() {
    setState(() {
      _carry = '';
      _carryId = null;
    });
    _keying.restart();
    _panel.currentState?.releaseHeld();
  }

  void _request(String intent) =>
      unawaited(_submitText('${_keying.id}-${_session.turns.length}', intent));

  void _showHint() {
    setState(() => _hint = _session.hint());
    unawaited(_saveDraft());
  }

  void _reveal(int index) {
    if (_revealed.add(index)) _session.hints++;
    setState(() {});
    unawaited(_saveDraft());
  }

  Future<void> _finish() async {
    if (_recorded) return;
    _recorded = true;
    _active.stop();
    _wake.setActive(false);
    var saved = false;
    try {
      saved = await _c.finishQso(_session, _activeTotal);
    } on Object {
      saved = false;
    }
    // The draft stays until the result is saved; reopening the simulator
    // commits it again (idempotent), and Retry writes the progress now.
    if (!saved && mounted) showProgressSaveFailed(context, _c);
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    if (!_session.isDone && !_recorded) unawaited(_saveDraft());
    _wake.dispose();
    unawaited(_playerSub?.cancel());
    unawaited(_keyingSub?.cancel());
    _keying.dispose();
    unawaited(_playback?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final playback = _playback;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.learnQsoTitle),
        actions: <Widget>[
          if (_remotePlaying)
            IconButton(
              tooltip: s.learnQsoPause,
              icon: const Icon(Icons.pause),
              onPressed: _pause,
            ),
        ],
      ),
      body: _withFlash(
        playback,
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _session.isDone
                    ? QsoSummaryView(
                        session: _session,
                        sendingWpm: _wpms.isEmpty
                            ? null
                            : _wpms.reduce((a, b) => a + b) / _wpms.length,
                        onDone: () => Navigator.of(context).pop(),
                      )
                    : _running(context, s, playback),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Flash-only settings (or the fallback when audio fails) must still
  /// show the remote's transmission.
  static Widget _withFlash(LearnPlayback? playback, Widget body) {
    final flash = playback?.flash;
    return flash == null ? body : FlashOverlay(isOn: flash, child: body);
  }

  Widget _running(BuildContext context, S s, LearnPlayback? playback) {
    final theme = Theme.of(context);
    final decoded = _pendingText;
    final canKey = playback != null && !_remotePlaying;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          QsoLabels.stage(s, _session.stage),
          style: theme.textTheme.titleMedium,
        ),
        Text(
          s.learnQsoSpeed(_session.effectiveWpm.round()),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        QsoLogView(
          session: _session,
          revealed: _revealed,
          onReveal: _reveal,
          // Hearing a transmission again is a repeat, like AGN.
          onPlay: _remotePlaying
              ? null
              : (text) {
                  _session.repeats++;
                  _playRemote(text);
                  unawaited(_saveDraft());
                },
        ),
        if (_issues.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final issue in _issues)
                  Row(
                    children: <Widget>[
                      Icon(Icons.error_outline, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(child: Text(QsoLabels.issue(s, issue))),
                    ],
                  ),
              ],
            ),
          ),
        if (_hint != null)
          Card(
            key: const ValueKey('qso-hint'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(s.learnQsoHintLabel(_hint!.example)),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          _remotePlaying ? s.learnQsoRemoteSending : s.learnQsoYourTurn,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          label: s.learnQsoDecoded,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              decoded.trim().isEmpty ? s.learnQsoNothingKeyed : decoded,
              key: const ValueKey('qso-decoded'),
              style: theme.textTheme.titleMedium?.copyWith(letterSpacing: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (playback == null)
          const Center(child: CircularProgressIndicator())
        else
          KeyerPanel(
            key: _panel,
            session: _keying,
            playback: playback,
            mode: _c.settings.keyerMode,
            enabled: canKey,
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            OutlinedButton(
              onPressed: canKey ? () => _request('PSE AGN') : null,
              child: Text(s.learnQsoPlayAgain),
            ),
            OutlinedButton(
              onPressed: canKey ? () => _request('QRS') : null,
              child: Text(s.learnQsoSlower),
            ),
            OutlinedButton.icon(
              onPressed: _showHint,
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(s.learnQsoHint),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: _keying.hasInput || _carry.isNotEmpty
                    ? _clear
                    : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(s.learnQsoClear),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('qso-send'),
                onPressed: canKey && (_keying.hasInput || _carry.isNotEmpty)
                    ? _send
                    : null,
                icon: const Icon(Icons.send),
                label: Text(s.learnQsoSend),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

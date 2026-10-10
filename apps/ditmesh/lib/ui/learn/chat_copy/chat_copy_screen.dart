import 'dart:async';

import 'package:flutter/material.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/chat_copy_session.dart';
import '../../../training/training_controller.dart';
import '../../common/app_bar_title.dart';
import '../drill_session_guard.dart';
import '../learn_platform.dart';
import '../learn_playback.dart';
import '../progress_save_snack.dart';
import '../receive/answer_keypad.dart';
import '../receive/receive_drill_screen.dart';
import '../receive/round_result_view.dart';

enum _Phase { confirm, answer, result }

/// Copy one received message by ear (functional spec §6.2): listen,
/// answer, submit, see the alignment. Answers stay on this screen: they are
/// never sent to the peer and never touch the conversation's draft.
class ChatCopyScreen extends StatefulWidget {
  const ChatCopyScreen({
    super.key,
    required this.controller,
    required this.playback,
    required this.session,
  });

  final TrainingController controller;
  final LearnPlaybackFactory playback;
  final ChatCopySession session;

  @override
  State<ChatCopyScreen> createState() => _ChatCopyScreenState();
}

class _ChatCopyScreenState extends State<ChatCopyScreen> {
  final TextEditingController _answer = TextEditingController();
  LearnPlayback? _playback;
  StreamSubscription<PlayerEvent>? _sub;
  bool _playing = false;
  bool _disposed = false;
  bool _recording = false;
  ReceiveOutcome? _outcome;
  late _Phase _phase = widget.session.analysis.unsupported.isEmpty
      ? _Phase.answer
      : _Phase.confirm;

  ChatCopySession get _session => widget.session;

  @override
  void initState() {
    super.initState();
    // Submit follows whether the copy holds any Morse symbol.
    _answer.addListener(_onAnswer);
    unawaited(_setup());
  }

  Future<void> _setup() async {
    final playback = await widget.playback.create(
      widget.controller.settings.copyWith(
        trainer: widget.controller.trainerSettings.copyWith(
          toneHz: _session.toneHz,
        ),
      ),
    );
    if (_disposed) {
      await playback.dispose();
      return;
    }
    _sub = playback.player.events.listen((e) {
      if ((e is PlayerCompleted || e is PlayerStopped) && !_disposed) {
        setState(() => _playing = false);
      }
    });
    setState(() => _playback = playback);
  }

  void _play() {
    final playback = _playback;
    if (playback == null || _playing || !_session.canPractise) return;
    _session.markPlayed();
    setState(() => _playing = true);
    playback.player.play(_session.timeline);
  }

  void _onAnswer() {
    if (mounted) setState(() {});
  }

  /// An empty (or symbol-free) copy is no answer: no submit, no credit.
  bool get _hasAnswer => MorseSupport.hasSymbols(_answer.text);

  Future<void> _submit() async {
    if (_recording || _session.score != null || !_hasAnswer) return;
    _playback?.player.stop();
    final c = widget.controller;
    final score = _session.submit(_answer.text, c.now());
    setState(() {
      _recording = true;
      _phase = _Phase.result;
    });
    ReceiveOutcome? outcome;
    try {
      outcome = await c.recordExercise(
        score: score,
        id: _session.id,
        source: ExerciseSource.chat,
        assistance: _session.assistance,
        answered: _hasAnswer,
        timing: _session.timing,
        sourceRef: _session.sourceRef,
        learned: c.learnedChars.toSet(),
      );
    } on Object {
      outcome = null;
    }
    if (!mounted) return;
    setState(() {
      _outcome = outcome;
      _recording = false;
    });
    if (outcome == null || !outcome.saved) {
      showProgressSaveFailed(context, c);
    }
  }

  Future<void> _practiseErrors(List<String> weak) async {
    final session = widget.controller.startFocusSession(weak);
    if (session == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<Object?>(
        builder: (_) => ReceiveDrillScreen(
          controller: widget.controller,
          playback: widget.playback,
          session: session,
        ),
      ),
    );
  }

  void _backspace() {
    final text = _answer.text;
    if (text.isEmpty) return;
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
    _disposed = true;
    _answer.removeListener(_onAnswer);
    unawaited(_sub?.cancel());
    // Releases the audio lease on every exit path.
    unawaited(_playback?.dispose());
    _answer.dispose();
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
            child: switch (_phase) {
              _Phase.confirm => _confirm(context),
              _Phase.answer => _answerView(context),
              _Phase.result => _result(context),
            },
          ),
        ),
      ),
    );
    // With sound off (or unavailable) the flash fallback is the question.
    final flash = _playback?.flash;
    // Android back / predictive back mid-copy would drop the typed answer
    // (and, from group practice, the round's attempt) silently: ask first,
    // like the receive and send drills.
    return DrillLeaveGuard(
      guard: _phase == _Phase.answer && _answer.text.isNotEmpty,
      child: Scaffold(
        appBar: AppBar(title: AppBarTitle(s.chatPracticeTitle)),
        body: flash == null ? body : FlashOverlay(isOn: flash, child: body),
      ),
    );
  }

  Widget _confirm(BuildContext context) {
    final s = context.s;
    final a = _session.analysis;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(s.chatPracticeUnsupported(a.unsupported.join(' '))),
        const SizedBox(height: 8),
        // The trainable text itself is not previewed: it is the answer.
        Text(
          _session.canPractise
              ? s.chatPracticeTrainableCount(a.symbolCount)
              : s.chatPracticeNothingTrainable,
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('chat-practice-confirm'),
          onPressed: _session.canPractise
              ? () => setState(() => _phase = _Phase.answer)
              : null,
          child: Text(s.chatPracticeConfirm),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.actionCancel),
        ),
      ],
    );
  }

  Widget _answerView(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final hinted = _session.hintedSymbols;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: <Widget>[
            FilledButton.tonalIcon(
              key: const ValueKey('chat-practice-play'),
              onPressed: _playback != null && !_playing ? _play : null,
              icon: Icon(_playing ? Icons.volume_up : Icons.play_arrow),
              label: Text(_playing ? s.learnListen : s.chatPlay),
            ),
            OutlinedButton.icon(
              onPressed: () => setState(() => _session.hint()),
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(s.chatPracticeHint),
            ),
            OutlinedButton.icon(
              onPressed: () => setState(_session.revealAll),
              icon: const Icon(Icons.visibility_outlined),
              label: Text(s.chatReveal),
            ),
          ],
        ),
        if (_session.isRevealed)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SelectableText(_session.target, textAlign: TextAlign.center),
          )
        else if (hinted.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              s.chatPracticeHintShown(hinted.join(' ')),
              textAlign: TextAlign.center,
            ),
          ),
        if (_session.assistance.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              s.chatPracticeAssisted,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _answer,
          autofocus: hasPhysicalKeyboardByDefault,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: isTouchPlatform ? TextInputType.none : null,
          decoration: InputDecoration(
            hintText: s.learnAnswerHint,
            // Wraps rather than being cut, as in the receive drill.
            hintMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => unawaited(_submit()),
        ),
        const SizedBox(height: 12),
        AnswerKeypad(
          chars: _session.keypadChars(widget.controller.course.order),
          onChar: (c) => _answer.text = '${_answer.text}$c',
          onBackspace: _backspace,
          onSpace: () => _answer.text = '${_answer.text} ',
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('chat-practice-submit'),
          onPressed: _hasAnswer ? () => unawaited(_submit()) : null,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(s.learnSubmit),
        ),
      ],
    );
  }

  Widget _result(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final score = _session.score!;
    final learned = widget.controller.learnedChars.toSet();
    final weak = score.weakChars().where(learned.contains).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          s.learnAccuracyPercent((score.strictAccuracy * 100).round()),
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        AlignedSymbols(alignment: score.alignment, showTarget: true),
        const SizedBox(height: 8),
        Text(
          s.chatPracticeErrors(
            score.substitutions,
            score.deletions,
            score.insertions,
          ),
          textAlign: TextAlign.center,
        ),
        if (_outcome?.assisted ?? _session.assistance.isNotEmpty)
          Text(
            s.chatPracticeAssisted,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 16),
        if (weak.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => unawaited(_practiseErrors(weak)),
            icon: const Icon(Icons.center_focus_strong_outlined),
            label: Text(s.chatPracticeErrorsAction(weak.join(' '))),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _recording ? null : () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(s.learnDone),
        ),
      ],
    );
  }
}

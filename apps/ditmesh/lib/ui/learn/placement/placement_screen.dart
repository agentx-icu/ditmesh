import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_io/morse_io.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/training_controller.dart';
import '../../common/app_bar_title.dart';
import '../drill_session_guard.dart';
import '../learn_platform.dart';
import '../learn_playback.dart';
import '../receive/answer_keypad.dart';

enum _Phase { intro, round, tierResult, result }

/// "Check my current level" (functional spec §8.3): a rough 3–5 minute
/// receive check over the Koch order. It suggests a starting lesson and
/// changes nothing until the learner adopts it; lesson one stays available.
class PlacementScreen extends StatefulWidget {
  const PlacementScreen({
    super.key,
    required this.controller,
    required this.playback,
    this.seed,
  });

  final TrainingController controller;
  final LearnPlaybackFactory playback;
  final int? seed;

  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends State<PlacementScreen> {
  late final PlacementAssessment _assessment = PlacementAssessment(
    course: widget.controller.course,
    seed: widget.seed ?? widget.controller.random.nextInt(1 << 30),
  );
  final TextEditingController _answer = TextEditingController();
  final List<String> _answers = <String>[];

  /// Every round played so far with what was actually typed.
  final List<(String, String)> _copies = <(String, String)>[];
  final Set<int> _assisted = <int>{};

  /// Any replay in any tier (the per-tier set is cleared between tiers).
  bool _anyAssisted = false;
  LearnPlayback? _playback;
  StreamSubscription<PlayerEvent>? _sub;
  _Phase _phase = _Phase.intro;
  int _round = 0;
  bool _playing = false;
  bool _heard = false;
  bool _lastPassed = false;
  bool _disposed = false;
  final String _id = ExerciseIds.next(DateTime.now(), Random());

  PlacementTier get _tier => _assessment.currentTier!;

  @override
  void initState() {
    super.initState();
    unawaited(_setup());
  }

  Future<void> _setup() async {
    final playback = await widget.playback.create(widget.controller.settings);
    if (_disposed) {
      await playback.dispose();
      return;
    }
    _sub = playback.player.events.listen((e) {
      if (e is PlayerCompleted) _heard = true;
      if ((e is PlayerCompleted || e is PlayerStopped) && !_disposed) {
        setState(() => _playing = false);
      }
    });
    setState(() => _playback = playback);
  }

  void _play({bool replay = false}) {
    final playback = _playback;
    if (playback == null || _playing) return;
    if (replay && _heard) {
      _assisted.add(_round);
      _anyAssisted = true;
    }
    setState(() => _playing = true);
    playback.player.play(
      MorseEncoder.encode(_tier.rounds[_round], _assessment.timingFor(_tier)),
    );
  }

  void _startTier() {
    _answers.clear();
    _assisted.clear();
    _round = 0;
    _heard = false;
    setState(() => _phase = _Phase.round);
    _play();
  }

  void _submit() {
    _playback?.player.stop();
    _answers.add(_answer.text);
    _copies.add((_tier.rounds[_round], _answer.text));
    _answer.clear();
    _heard = false;
    if (_round + 1 < _tier.rounds.length) {
      setState(() => _round++);
      _play();
      return;
    }
    final passed = _assessment.recordTier(_answers, assisted: _assisted);
    setState(() {
      _lastPassed = passed;
      _phase = _assessment.isFinished ? _Phase.result : _Phase.tierResult;
    });
    if (_assessment.isFinished) unawaited(_record());
  }

  void _stopEarly() {
    _playback?.player.stop();
    _assessment.stop();
    setState(() => _phase = _Phase.result);
    unawaited(_record());
  }

  /// One activity-only exercise; placement never feeds SRS or speed advice.
  Future<void> _record() async {
    if (_copies.isEmpty) return;
    // Each round scored on its own (a copy cannot borrow symbols from the
    // next round); blank runs earn nothing.
    final score = SessionScore.combine([
      for (final (target, answer) in _copies)
        SessionScore.evaluate(target, answer),
    ], drillKind: 'placement');
    try {
      await widget.controller.recordExercise(
        score: score,
        id: _id,
        source: ExerciseSource.placement,
        assistance: <Assistance>{if (_anyAssisted) Assistance.replay},
        answered: _copies.any((c) => MorseSupport.hasSymbols(c.$2)),
      );
    } on Object {
      // The suggestion still shows; activity credit is not essential.
    }
  }

  Future<void> _adopt(int lesson) async {
    await widget.controller.setLesson(lesson);
    if (mounted) Navigator.of(context).pop(lesson);
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_sub?.cancel());
    unawaited(_playback?.dispose());
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    // Android back / predictive back / the iOS swipe mid-assessment would drop
    // every tier answered so far silently (nothing is recorded until the
    // assessment finishes or is stopped early): ask first, like the drills.
    return DrillLeaveGuard(
      guard: _phase == _Phase.round || _phase == _Phase.tierResult,
      child: Scaffold(
        appBar: AppBar(
          title: AppBarTitle(s.placementTitle),
          actions: <Widget>[
            if (_phase == _Phase.round || _phase == _Phase.tierResult)
              TextButton(onPressed: _stopEarly, child: Text(s.placementStop)),
          ],
        ),
        body: _flash(
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: switch (_phase) {
                    _Phase.intro => _intro(context),
                    _Phase.round => _roundView(context),
                    _Phase.tierResult => _tierResult(context),
                    _Phase.result => _result(context),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The visual fallback when sound is off or unavailable.
  Widget _flash(Widget body) {
    final flash = _playback?.flash;
    return flash == null ? body : FlashOverlay(isOn: flash, child: body);
  }

  Widget _intro(BuildContext context) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(s.placementIntro),
        const SizedBox(height: 24),
        FilledButton(
          key: const ValueKey('placement-start'),
          onPressed: _playback == null ? null : _startTier,
          child: Text(s.placementStart),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.placementSkip),
        ),
      ],
    );
  }

  Widget _roundView(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final tier = _tier;
    final chars = tier.symbols.isEmpty
        ? widget.controller.course.order
        : tier.symbols;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          s.placementTierProgress(
            tier.index + 1,
            _assessment.tiers.length,
            tier.effectiveWpm.round(),
          ),
          style: theme.textTheme.labelLarge,
        ),
        LinearProgressIndicator(value: _round / tier.rounds.length),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _playback != null && !_playing
              ? () => _play(replay: true)
              : null,
          icon: Icon(_playing ? Icons.volume_up : Icons.replay),
          label: Text(_playing ? s.learnListen : s.learnReplay),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _answer,
          autofocus: hasPhysicalKeyboardByDefault,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          keyboardType: isTouchPlatform ? TextInputType.none : null,
          decoration: InputDecoration(
            hintText: s.learnAnswerHint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 8),
        AnswerKeypad(
          chars: chars,
          onChar: (c) => _answer.text = '${_answer.text}$c',
          onBackspace: () {
            final t = _answer.text;
            if (t.isNotEmpty) _answer.text = t.substring(0, t.length - 1);
          },
          onSpace: () => _answer.text = '${_answer.text} ',
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const ValueKey('placement-submit'),
          onPressed: _submit,
          child: Text(s.learnSubmit),
        ),
      ],
    );
  }

  Widget _tierResult(BuildContext context) {
    final s = context.s;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(_lastPassed ? s.placementTierPassed : s.placementTierStopped),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('placement-next-tier'),
          onPressed: _startTier,
          child: Text(s.placementNextTier),
        ),
      ],
    );
  }

  Widget _result(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final r = _assessment.result();
    final course = widget.controller.course;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          s.placementSuggestion(r.suggestedLesson),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(s.placementVerified(r.verifiedPrefix, course.order.length)),
        const SizedBox(height: 8),
        Text(s.placementLimits, style: theme.textTheme.bodySmall),
        const SizedBox(height: 24),
        FilledButton(
          key: const ValueKey('placement-adopt'),
          onPressed: () => unawaited(_adopt(r.suggestedLesson)),
          child: Text(s.placementAdopt(r.suggestedLesson)),
        ),
        TextButton(
          onPressed: () => unawaited(_adopt(1)),
          child: Text(s.placementFromZero),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/telegraph_sessions.dart';
import '../../../training/training_controller.dart';
import '../../telegraph/telegraph_labels.dart';
import '../drill_session_guard.dart';

/// Codebook recall (F13): a round of cards, character → code and code →
/// character, in one codebook. Revealing the answer marks the card
/// assisted. Results go to the separate mapping statistics only.
class TelegraphRecallScreen extends StatefulWidget {
  const TelegraphRecallScreen({
    super.key,
    required this.controller,
    required this.codebook,
    this.random,
    this.cards = 10,
  });

  final TrainingController controller;
  final TelegraphCodebook codebook;
  final Random? random;
  final int cards;

  @override
  State<TelegraphRecallScreen> createState() => _TelegraphRecallScreenState();
}

class _TelegraphRecallScreenState extends State<TelegraphRecallScreen> {
  late final Random _random = widget.random ?? Random();
  late final List<String> _pool = TelegraphCurriculum.introductoryFor(
    widget.codebook,
  );
  late final List<TelegraphRecallCard> _deck = [
    for (var i = 0; i < widget.cards; i++)
      TelegraphRecallCard.make(
        _pool[_random.nextInt(_pool.length)],
        i.isEven
            ? TelegraphRecallDirection.charToCode
            : TelegraphRecallDirection.codeToChar,
        widget.codebook,
        _random,
        distractors: _pool,
      ),
  ];
  final List<(String, bool, bool)> _answers = [];
  final TextEditingController _code = TextEditingController();
  bool _revealed = false;
  bool? _lastCorrect;
  bool _saving = false;
  TelegraphRecallStats? _saved;

  int get _index => _answers.length;
  bool get _done => _index >= _deck.length;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _answer(String value) {
    if (_done || _lastCorrect != null) return;
    final card = _deck[_index];
    setState(() => _lastCorrect = card.isCorrect(value));
  }

  Future<void> _next() async {
    final card = _deck[_index];
    setState(() {
      _answers.add((card.char, _lastCorrect ?? false, _revealed));
      _lastCorrect = null;
      _revealed = false;
      _code.clear();
    });
    if (_done) await _save();
  }

  @override
  void initState() {
    super.initState();
    // Check needs four digits: an empty submit is no answer.
    _code.addListener(() {
      if (mounted) setState(() {});
    });
  }

  /// Saves the round; on failure the result stays on screen with a retry.
  Future<void> _save() async {
    // The snackbar's Retry may outlive this screen.
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      final stats = await widget.controller.recordTelegraphRecall(
        widget.codebook,
        _answers,
      );
      if (mounted) {
        setState(() {
          _saving = false;
          _saved = stats;
        });
      }
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(context.s.learnProgressSaveFailed),
          action: SnackBarAction(
            label: context.s.actionRetry,
            onPressed: () => unawaited(_save()),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    // Leaving mid-deck loses the cards answered so far and whatever is typed
    // or revealed on the current card (the session is only recorded once the
    // deck is done): ask first, like the drills.
    return DrillLeaveGuard(
      guard:
          !_done &&
          (_index > 0 ||
              _lastCorrect != null ||
              _revealed ||
              _code.text.isNotEmpty),
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.telegraphRecallTitle),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: _index / _deck.length,
              minHeight: 4,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: _done ? _summary(context) : _card(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _card(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final card = _deck[_index];
    final toCode = card.direction == TelegraphRecallDirection.charToCode;
    final answered = _lastCorrect != null;
    return [
      Text(
        codebookLabel(s, widget.codebook),
        style: theme.textTheme.labelLarge,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(
        toCode ? s.telegraphRecallCharPrompt : s.telegraphRecallCodePrompt,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      Text(
        toCode ? card.char : card.code,
        key: const Key('telegraph-prompt'),
        textAlign: TextAlign.center,
        style: theme.textTheme.displayMedium,
      ),
      const SizedBox(height: 16),
      if (toCode)
        TextField(
          key: const Key('telegraph-code-field'),
          controller: _code,
          enabled: !answered,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(letterSpacing: 6),
          onSubmitted: (v) {
            if (v.length == 4) _answer(v);
          },
          decoration: const InputDecoration(border: OutlineInputBorder()),
        )
      else
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final c in card.choices)
              OutlinedButton(
                key: Key('telegraph-choice-$c'),
                onPressed: answered ? null : () => _answer(c),
                child: Text(c, style: theme.textTheme.headlineSmall),
              ),
          ],
        ),
      const SizedBox(height: 16),
      if (!answered) ...[
        if (toCode)
          FilledButton(
            key: const Key('telegraph-check'),
            onPressed: _code.text.length == 4
                ? () => _answer(_code.text)
                : null,
            child: Text(s.learnSubmit),
          ),
        TextButton(
          key: const Key('telegraph-reveal'),
          onPressed: _revealed ? null : () => setState(() => _revealed = true),
          child: Text(s.telegraphReveal),
        ),
      ],
      if (_revealed || answered)
        Text(
          '${card.char} = ${card.code}'
          '${card.accepted.length > 1 && !toCode ? ' (${card.accepted.join(' / ')})' : ''}',
          key: const Key('telegraph-answer'),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
      if (_revealed && !answered)
        Text(
          s.telegraphRevealAssisted,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      if (answered) ...[
        const SizedBox(height: 8),
        Text(
          _lastCorrect! ? s.telegraphCorrect : s.telegraphIncorrect,
          key: const Key('telegraph-verdict'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _lastCorrect!
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('telegraph-next'),
          onPressed: _next,
          child: Text(_index == _deck.length - 1 ? s.learnFinish : s.learnNext),
        ),
      ],
    ];
  }

  List<Widget> _summary(BuildContext context) {
    final s = context.s;
    final correct = _answers.where((a) => a.$2 && !a.$3).length;
    final assisted = _answers.where((a) => a.$3).length;
    return [
      Text(
        s.telegraphRecallSummary(correct, _answers.length),
        key: const Key('telegraph-summary'),
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
      if (assisted > 0)
        Text(s.telegraphRecallAssisted(assisted), textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(s.telegraphSeparateNote, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      if (_saved == null && !_saving)
        OutlinedButton(
          key: const Key('telegraph-save-retry'),
          onPressed: _save,
          child: Text(s.actionRetry),
        ),
      FilledButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: Text(s.learnDone),
      ),
    ];
  }
}

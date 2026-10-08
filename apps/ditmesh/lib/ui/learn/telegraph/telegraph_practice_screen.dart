import 'package:flutter/material.dart';
import 'package:morse_core/morse_core.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/telegraph_sessions.dart';
import '../../../training/training_controller.dart';
import '../../telegraph/telegraph_labels.dart';
import '../learn_playback.dart';
import '../receive/receive_drill_screen.dart';
import 'telegraph_recall_screen.dart';

/// Chinese telegraph code (F13): the codebook choice (always visible and
/// saved with every attempt) and the two separate skills — copying
/// four-digit groups by ear, and recalling which code is which character —
/// each with its own results.
class TelegraphPracticeScreen extends StatefulWidget {
  const TelegraphPracticeScreen({
    super.key,
    required this.controller,
    required this.playback,
  });

  final TrainingController controller;
  final LearnPlaybackFactory playback;

  @override
  State<TelegraphPracticeScreen> createState() =>
      _TelegraphPracticeScreenState();
}

class _TelegraphPracticeScreenState extends State<TelegraphPracticeScreen> {
  TelegraphCodebook _book = TelegraphCodebook.mainland;
  TelegraphRecallStats _recall = TelegraphRecallStats.empty;

  @override
  void initState() {
    super.initState();
    _loadRecall();
  }

  Future<void> _loadRecall() async {
    final stats = await widget.controller.readTelegraphRecall();
    if (mounted) setState(() => _recall = stats);
  }

  Future<void> _copyDigits() async {
    await Navigator.of(context).push(
      MaterialPageRoute<Object?>(
        builder: (_) => ReceiveDrillScreen(
          controller: widget.controller,
          playback: widget.playback,
          title: context.s.telegraphDigitsTitle,
          session: widget.controller.startTelegraphDigitsSession(_book),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _recallCodes() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TelegraphRecallScreen(
          controller: widget.controller,
          codebook: _book,
        ),
      ),
    );
    await _loadRecall();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final (attempts, digitAcc) = widget.controller.telegraphDigitsResults(
      _book,
    );
    final answered = _recall.answered(_book);
    final sample = TelegraphCurriculum.introductoryFor(_book).take(5);
    return Scaffold(
      appBar: AppBar(title: Text(s.telegraphTitle)),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(s.telegraphIntro),
                const SizedBox(height: 8),
                Text(
                  [
                    for (final c in sample)
                      '$c ${ChineseTelegraphCode.codeOf(c, codebook: _book)}',
                  ].join('   '),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TelegraphCodebookPicker(
                  value: _book,
                  onChanged: (b) => setState(() => _book = b),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    key: const Key('telegraph-digits'),
                    leading: const Icon(Icons.hearing),
                    title: Text(s.telegraphDigitsTitle),
                    subtitle: Text(
                      [
                        s.telegraphDigitsHint,
                        if (attempts > 0)
                          s.telegraphDigitsResults(
                            attempts,
                            (digitAcc * 100).round(),
                          ),
                      ].join('\n'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _copyDigits,
                  ),
                ),
                Card(
                  child: ListTile(
                    key: const Key('telegraph-recall'),
                    leading: const Icon(Icons.translate),
                    title: Text(s.telegraphRecallTitle),
                    subtitle: Text(
                      [
                        s.telegraphRecallHint,
                        if (answered > 0)
                          s.telegraphRecallResults(
                            answered,
                            (_recall.accuracy(_book) * 100).round(),
                          ),
                      ].join('\n'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _recallCodes,
                  ),
                ),
                const SizedBox(height: 8),
                Text(s.telegraphSeparateNote, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

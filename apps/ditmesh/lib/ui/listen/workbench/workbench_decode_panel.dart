import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:morse_dsp/morse_dsp.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/training_controller.dart';
import '../../learn/progress_save_snack.dart';
import '../../learn/receive/answer_keypad.dart';
import '../../learn/receive/round_result_view.dart';
import 'workbench_controller.dart';

/// Tuning, decoding and the two ways of using the result: read the decoder
/// output, or copy it yourself with the decoder text hidden by default
/// (seeing it makes the attempt assisted).
class WorkbenchDecodePanel extends StatefulWidget {
  const WorkbenchDecodePanel({
    super.key,
    required this.controller,
    required this.training,
  });

  final WorkbenchController controller;

  /// The shared per-profile training controller; null when unavailable
  /// (copy attempts are then scored but not recorded).
  final TrainingController? training;

  @override
  State<WorkbenchDecodePanel> createState() => _WorkbenchDecodePanelState();
}

class _WorkbenchDecodePanelState extends State<WorkbenchDecodePanel> {
  final _answer = TextEditingController();
  final _reference = TextEditingController();

  /// Copy-it-myself is the default: the decoder output stays hidden until
  /// the learner asks for it (spec §11.2.4).
  bool _copyMode = true;

  /// Decoder answers the learner has seen, keyed by recording, selection
  /// and tuning: decoding the same selection again does not make its
  /// answer unseen.
  final Set<String> _exposed = <String>{};

  String get _exposureKey =>
      '${_c.file}#${_c.start}-${_c.end}#${_c.autoTune}#${_c.manualHz}';

  bool get _decoderShown => _exposed.contains(_exposureKey);

  void _expose() => _exposed.add(_exposureKey);
  SessionScore? _score;
  bool _againstDecoder = false;
  SegmentDecodeResult? _scoredFor;
  String? _attemptId;

  WorkbenchController get _c => widget.controller;

  @override
  void dispose() {
    _answer.dispose();
    _reference.dispose();
    super.dispose();
  }

  void _resetAttemptIfStale() {
    if (!identical(_scoredFor, _c.result)) {
      _score = null;
      // A new result in decoder mode is exposed the moment it is shown.
      if (!_copyMode && _c.result != null) _expose();
      _scoredFor = _c.result;
      _attemptId = null;
    }
  }

  Future<void> _submit() async {
    final result = _c.result;
    if (result == null || _score != null) return;
    final ref = _reference.text.trim();
    final target = ref.isNotEmpty ? ref : result.text;
    final score = SessionScore.evaluate(
      target,
      _answer.text,
      at: widget.training?.now(),
      drillKind: 'recording',
    );
    setState(() {
      _score = score;
      _againstDecoder = ref.isEmpty;
    });
    final training = widget.training;
    if (training == null) return;
    // One id per attempt: a retried save never credits it twice.
    final id = _attemptId ??= ExerciseIds.next(training.now(), Random());
    var saved = false;
    try {
      final outcome = await training.recordExercise(
        score: score,
        id: id,
        source: ExerciseSource.recording,
        assistance: <Assistance>{if (_decoderShown) Assistance.decoder},
        answered: MorseSupport.hasSymbols(_answer.text),
        sourceRef: 'recording:${_c.file}#${_c.start}-${_c.end}',
      );
      saved = outcome.saved;
    } on Object {
      saved = false;
    }
    // The score stays on screen either way; Retry writes the same result.
    if (!saved && mounted) showProgressSaveFailed(context, training);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    _resetAttemptIfStale();
    final result = _c.result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(s.workbenchAutoTune),
          value: _c.autoTune,
          onChanged: (v) => _c.setTuning(auto: v),
        ),
        if (!_c.autoTune) ...<Widget>[
          Text(s.workbenchManualTone(_c.manualHz.round())),
          Slider(
            min: 300,
            max: 1200,
            divisions: 90,
            value: _c.manualHz.clamp(300, 1200),
            label: s.workbenchManualTone(_c.manualHz.round()),
            onChanged: (v) => _c.setTuning(hz: v),
          ),
        ],
        const SizedBox(height: 8),
        if (_c.decoding)
          Row(
            children: <Widget>[
              Expanded(
                child: Semantics(
                  label: s.workbenchDecoding(
                    ((_c.progress ?? 0) * 100).round(),
                  ),
                  child: LinearProgressIndicator(value: _c.progress),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                key: const ValueKey('workbench-cancel'),
                onPressed: _c.cancelDecode,
                child: Text(s.workbenchCancel),
              ),
            ],
          )
        else
          FilledButton.icon(
            key: const ValueKey('workbench-decode'),
            onPressed: _c.end > _c.start ? () => unawaited(_c.decode()) : null,
            icon: const Icon(Icons.graphic_eq),
            label: Text(s.workbenchDecode),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        if (result != null) ...<Widget>[
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: <ButtonSegment<bool>>[
              ButtonSegment(value: false, label: Text(s.workbenchModeDecoder)),
              ButtonSegment(value: true, label: Text(s.workbenchModeCopy)),
            ],
            selected: <bool>{_copyMode},
            showSelectedIcon: false,
            onSelectionChanged: (v) => setState(() {
              _copyMode = v.first;
              // Viewing the decoder output exposes the answer for good.
              if (!_copyMode) _expose();
            }),
          ),
          const SizedBox(height: 12),
          if (!_copyMode || _decoderShown) _decoderView(context, result),
          if (_copyMode) _copyView(context, result, theme),
        ],
      ],
    );
  }

  Widget _decoderView(BuildContext context, SegmentDecodeResult r) {
    final s = context.s;
    final theme = Theme.of(context);
    final unknown = r.unknownPatterns.map((e) => e.pattern).toSet();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              s.workbenchResultStats(r.toneHz.round(), r.estimatedWpm.round()),
              style: theme.textTheme.labelLarge,
            ),
            if (!r.toneLocked) Text(s.workbenchToneNotLocked),
            const SizedBox(height: 8),
            SelectableText(
              r.text.isEmpty ? s.workbenchNoText : r.text,
              key: const ValueKey('workbench-text'),
              style: theme.textTheme.titleMedium?.copyWith(letterSpacing: 2),
            ),
            if (unknown.isNotEmpty) Text(s.workbenchUnknown(unknown.join(' '))),
            if (r.edgeAtStart || r.edgeAtEnd)
              Text(s.workbenchEdgeCut, style: theme.textTheme.bodySmall),
            Text(s.workbenchToneNote, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _copyView(
    BuildContext context,
    SegmentDecodeResult r,
    ThemeData theme,
  ) {
    final s = context.s;
    final score = _score;
    // Every course symbol, never derived from the hidden decoder output.
    final keys = KochCourse().order;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!_decoderShown)
          // Wrap: on a 320 px phone with large text the button goes below.
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(s.workbenchDecoderHidden),
              TextButton(
                key: const ValueKey('workbench-show-decoder'),
                onPressed: () => setState(_expose),
                child: Text(s.workbenchShowDecoder),
              ),
            ],
          ),
        TextField(
          controller: _reference,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: s.workbenchReference,
            helperText: s.workbenchReferenceHelp,
            helperMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('workbench-answer'),
          controller: _answer,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: s.learnAnswerHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        AnswerKeypad(
          chars: keys,
          onChar: (c) => _answer.text = '${_answer.text}$c',
          onBackspace: () {
            final t = _answer.text;
            if (t.isNotEmpty) _answer.text = t.substring(0, t.length - 1);
          },
          onSpace: () => _answer.text = '${_answer.text} ',
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const ValueKey('workbench-submit'),
          onPressed: score == null ? () => unawaited(_submit()) : null,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: Text(s.learnSubmit),
        ),
        if (score != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            s.learnAccuracyPercent((score.strictAccuracy * 100).round()),
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          AlignedSymbols(alignment: score.alignment, showTarget: true),
          if (_againstDecoder)
            Text(s.workbenchAgainstDecoder, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}

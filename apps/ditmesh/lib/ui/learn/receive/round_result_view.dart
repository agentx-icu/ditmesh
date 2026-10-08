import 'package:flutter/material.dart';
import 'package:morse_trainer/morse_trainer.dart';

import '../../../i18n/l10n_extension.dart';
import '../../../training/receive_session.dart';

/// Shows one answered round: the sent text against the copy, column by
/// column from the alignment, with misses and substitutions highlighted.
class RoundResultView extends StatelessWidget {
  const RoundResultView({super.key, required this.round});

  final ReceiveRound round;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = context.s;
    final score = round.score;
    final headline = score.isPerfect
        ? s.learnRoundPerfect
        : s.learnRoundScore(score.correctChars, score.totalChars);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          headline,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _LabelledRow(
          label: s.learnSent,
          child: AlignedSymbols(alignment: score.alignment, showTarget: true),
        ),
        const SizedBox(height: 8),
        _LabelledRow(
          label: s.learnYourCopy,
          child: AlignedSymbols(alignment: score.alignment, showTarget: false),
        ),
      ],
    );
  }
}

/// One row of aligned symbols: target or answer side of each column.
///
/// Colours: match = plain, substitution = error container, missing symbol
/// (deletion on the answer side / insertion on the target side) = a dotted
/// placeholder.
class AlignedSymbols extends StatelessWidget {
  const AlignedSymbols({
    super.key,
    required this.alignment,
    required this.showTarget,
  });

  final List<AlignedPair> alignment;
  final bool showTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.titleLarge?.copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    final scaler = MediaQuery.textScalerOf(context);
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: <Widget>[
        for (final pair in alignment)
          _cell(pair, style, scheme, width: cellWidth(pair, style, scaler)),
      ],
    );
  }

  /// Width of the column for [pair], the same on the target and the answer
  /// row: wide enough for either side, so both rows wrap at the same places
  /// and each copied symbol sits under the one that was sent.
  static double cellWidth(
    AlignedPair pair,
    TextStyle? style,
    TextScaler scaler,
  ) {
    var widest = 0.0;
    for (final text in <String>[pair.target ?? '·', pair.answer ?? '·']) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      if (painter.width > widest) {
        widest = painter.width;
      }
      painter.dispose();
    }
    return widest + 12 < 32 ? 32 : widest + 12;
  }

  Widget _cell(
    AlignedPair pair,
    TextStyle? style,
    ColorScheme scheme, {
    required double width,
  }) {
    final symbol = showTarget ? pair.target : pair.answer;
    final Color background;
    final Color foreground;
    switch (pair.op) {
      case AlignmentOp.match:
        background = scheme.surfaceContainerHighest;
        foreground = scheme.onSurface;
      case AlignmentOp.substitution:
        background = scheme.errorContainer;
        foreground = scheme.onErrorContainer;
      case AlignmentOp.deletion:
      case AlignmentOp.insertion:
        background = symbol == null ? scheme.surface : scheme.errorContainer;
        foreground = symbol == null
            ? scheme.onSurfaceVariant
            : scheme.onErrorContainer;
    }
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 36),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: symbol == null
            ? Border.all(color: scheme.outlineVariant, width: 1)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(symbol ?? '·', style: style?.copyWith(color: foreground)),
    );
  }
}

class _LabelledRow extends StatelessWidget {
  const _LabelledRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

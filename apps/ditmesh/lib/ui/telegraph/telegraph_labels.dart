import 'package:flutter/material.dart';
import 'package:morse_core/morse_core.dart';

import '../../i18n/l10n_extension.dart';

/// Name of a codebook in the current UI language.
String codebookLabel(S s, TelegraphCodebook book) => switch (book) {
  TelegraphCodebook.mainland => s.telegraphCodebookMainland,
  TelegraphCodebook.taiwan => s.telegraphCodebookTaiwan,
};

/// The always-visible mainland / Taiwan choice.
class TelegraphCodebookPicker extends StatelessWidget {
  const TelegraphCodebookPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TelegraphCodebook value;
  final ValueChanged<TelegraphCodebook> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(s.telegraphCodebook),
        for (final b in TelegraphCodebook.values)
          ChoiceChip(
            key: ValueKey('codebook-${b.name}'),
            label: Text(codebookLabel(s, b)),
            selected: value == b,
            onSelected: (_) => onChanged(b),
          ),
      ],
    );
  }
}

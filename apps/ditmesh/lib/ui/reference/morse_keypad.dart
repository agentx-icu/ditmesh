import 'package:flutter/material.dart';

import '../../i18n/l10n_extension.dart';
import 'morse_pattern_text.dart';

/// On-screen dit / dah / gap keypad for typing a pattern on a phone, where
/// `.` and `-` are awkward to reach and `/` is on a second keyboard page.
///
/// Every key is at least 48 x 48 logical pixels.
class MorseKeypad extends StatelessWidget {
  const MorseKeypad({
    super.key,
    required this.onInsert,
    required this.onBackspace,
    required this.onClear,
  });

  final ValueChanged<String> onInsert;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  static const Key ditKey = Key('keypad-dit');
  static const Key dahKey = Key('keypad-dah');
  static const Key charGapKey = Key('keypad-char-gap');
  static const Key wordGapKey = Key('keypad-word-gap');
  static const Key backspaceKey = Key('keypad-backspace');
  static const Key clearKey = Key('keypad-clear');

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final S s = context.s;
    final TextStyle glyph = theme.textTheme.headlineSmall!.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const <String>['Menlo', 'Consolas'],
      fontWeight: FontWeight.bold,
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: <Widget>[
        _KeypadButton(
          key: ditKey,
          tooltip: s.referenceKeypadDit,
          onPressed: () => onInsert('.'),
          child: Text(kDitGlyph, style: glyph),
        ),
        _KeypadButton(
          key: dahKey,
          tooltip: s.referenceKeypadDah,
          onPressed: () => onInsert('-'),
          child: Text(kDahGlyph, style: glyph),
        ),
        _KeypadButton(
          key: charGapKey,
          tooltip: s.referenceKeypadCharGap,
          onPressed: () => onInsert(' '),
          child: const Icon(Icons.space_bar),
        ),
        _KeypadButton(
          key: wordGapKey,
          tooltip: s.referenceKeypadWordGap,
          onPressed: () => onInsert(' / '),
          child: Text('/', style: glyph),
        ),
        _KeypadButton(
          key: backspaceKey,
          tooltip: s.referenceKeypadBackspace,
          onPressed: onBackspace,
          child: const Icon(Icons.backspace_outlined),
        ),
        _KeypadButton(
          key: clearKey,
          tooltip: s.referenceClear,
          onPressed: onClear,
          child: const Icon(Icons.clear_all),
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: FilledButton.tonal(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 52),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: child,
        ),
      ),
    );
  }
}

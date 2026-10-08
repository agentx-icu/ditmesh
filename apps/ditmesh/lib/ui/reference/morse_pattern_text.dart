import 'package:flutter/material.dart';

/// Display glyph for a dit.
const String kDitGlyph = '·'; // ·

/// Display glyph for a dah.
const String kDahGlyph = '−'; // −

/// Converts a `.`/`-` pattern (as produced by `MorseEncoder.toPattern`) into
/// the display form: dits as `·`, dahs as `−`, character gaps as a space and
/// word gaps as ` / `.
String displayMorsePattern(String pattern) {
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < pattern.length; i++) {
    final String ch = pattern[i];
    switch (ch) {
      case '.':
        out.write(kDitGlyph);
      case '-':
        out.write(kDahGlyph);
      default:
        out.write(ch);
    }
  }
  return out.toString();
}

/// The display font and spacing, shared by rendering and layout measurement.
TextStyle morsePatternTextStyle(
  BuildContext context, {
  TextStyle? style,
  Color? color,
}) {
  final ThemeData theme = Theme.of(context);
  return (style ?? theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
    fontFamily: 'monospace',
    fontFamilyFallback: const <String>['Menlo', 'Consolas', 'Courier New'],
    letterSpacing: 2,
    color: color ?? theme.colorScheme.onSurfaceVariant,
  );
}

/// Renders a Morse pattern in monospace using [displayMorsePattern].
///
/// When [activeMark] is set (0-based index among the marks of the pattern),
/// marks before it are shown as already played, that mark is emphasised as
/// the one sounding now, and the rest keep the base colour, so a listener
/// can follow playback with their eyes.
class MorsePatternText extends StatelessWidget {
  const MorsePatternText(
    this.pattern, {
    super.key,
    this.activeMark,
    this.style,
    this.maxLines,
    this.textAlign,
    this.color,
    this.highlightColor,
  });

  /// Raw `.`/`-` pattern; may already contain display glyphs.
  final String pattern;

  /// Index among the marks (`.`/`-`) currently sounding; null when idle.
  final int? activeMark;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;
  final Color? color;
  final Color? highlightColor;

  static bool _isMark(String ch) =>
      ch == '.' || ch == '-' || ch == kDitGlyph || ch == kDahGlyph;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle base = morsePatternTextStyle(
      context,
      style: style,
      color: color,
    );
    final String display = displayMorsePattern(pattern);
    final int? active = activeMark;
    if (active == null || active < 0) {
      return Text(
        display,
        style: base,
        maxLines: maxLines,
        textAlign: textAlign,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
      );
    }

    final Color hot = highlightColor ?? theme.colorScheme.primary;
    final TextStyle played = base.copyWith(color: hot);
    final TextStyle current = base.copyWith(
      color: theme.colorScheme.onPrimary,
      backgroundColor: hot,
      fontWeight: FontWeight.bold,
    );

    // Find the character boundaries of the active mark.
    int marks = -1;
    int start = display.length;
    int end = display.length;
    for (int i = 0; i < display.length; i++) {
      if (!_isMark(display[i])) continue;
      marks++;
      if (marks == active) {
        start = i;
        end = i + 1;
        break;
      }
    }

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(text: display.substring(0, start), style: played),
          TextSpan(text: display.substring(start, end), style: current),
          TextSpan(text: display.substring(end)),
        ],
      ),
      style: base,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

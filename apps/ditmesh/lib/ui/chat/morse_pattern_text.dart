import 'package:flutter/material.dart';

/// Renders a `.- / ...` pattern in monospace. When [activeMark] is set, the
/// marks (`.` and `-`) up to and including that index are highlighted so the
/// listener can follow playback with their eyes.
class MorsePatternText extends StatelessWidget {
  const MorsePatternText(
    this.pattern, {
    super.key,
    this.activeMark,
    this.style,
    this.maxLines,
    this.color,
    this.highlightColor,
  });

  final String pattern;

  /// Index (0-based) among the pattern's marks of the one currently sounding;
  /// null when idle.
  final int? activeMark;
  final TextStyle? style;
  final int? maxLines;
  final Color? color;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle base =
        (style ?? theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Menlo', 'Consolas', 'Courier New'],
          letterSpacing: 1.5,
          color: color ?? theme.colorScheme.onSurfaceVariant,
        );
    final int? active = activeMark;
    if (active == null || active < 0) {
      return Text(
        pattern,
        style: base,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
      );
    }
    final TextStyle hot = base.copyWith(
      color: highlightColor ?? theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );
    // Split at the boundary after the active mark.
    int marks = -1;
    int cut = pattern.length;
    for (int i = 0; i < pattern.length; i++) {
      final String ch = pattern[i];
      if (ch == '.' || ch == '-') {
        marks++;
        if (marks == active) {
          cut = i + 1;
          break;
        }
      }
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: pattern.substring(0, cut), style: hot),
          TextSpan(text: pattern.substring(cut)),
        ],
      ),
      style: base,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

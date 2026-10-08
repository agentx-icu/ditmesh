import 'package:flutter/material.dart';
import 'package:morse_core/morse_core.dart';

import '../../i18n/l10n_extension.dart';
import '../theme.dart';
import 'radio_mascot.dart';
import 'style_tokens.dart';
import 'ui_style.dart';

/// A local Theme: choosing a thumbnail never changes the live application.
class StylePreview extends StatelessWidget {
  const StylePreview({
    super.key,
    required this.style,
    required this.brightness,
    this.miniature = false,
  });
  final UiStyle style;
  final Brightness brightness;
  final bool miniature;

  @override
  Widget build(BuildContext context) => Theme(
    data: brightness == Brightness.dark
        ? DitmeshTheme.dark(style: style)
        : DitmeshTheme.light(style: style),
    child: _PreviewBody(miniature: miniature),
  );
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({required this.miniature});
  final bool miniature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<StyleTokens>()!;
    final s = context.s;
    final scale = miniature ? 0.7 : 1.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(tokens.panelRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(miniature ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.learnLessonOf(4, 42),
                    maxLines: 2,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16 * scale,
                    ),
                  ),
                ),
                if (tokens.style == UiStyle.cartoon)
                  RadioMascot(size: miniature ? 28 : 48),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final char in ['K', 'M', 'R', 'S', 'U'])
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: EdgeInsets.symmetric(
                        vertical: miniature ? 4 : 10,
                      ),
                      decoration: BoxDecoration(
                        color: char == 'U'
                            ? tokens.newest
                            : theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(tokens.chipRadius),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            char,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontSize: 14 * scale,
                              color: char == 'U'
                                  ? tokens.onNewest
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          if (!miniature)
                            Text(
                              MorseEncoder.toPattern(char),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: char == 'U'
                                    ? tokens.onNewest
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(vertical: miniature ? 6 : 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(tokens.controlRadius),
              ),
              child: Text(
                s.learnContinueLesson,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

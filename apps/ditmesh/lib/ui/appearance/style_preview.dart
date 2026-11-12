import 'package:flutter/material.dart';

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
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(miniature ? 8 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: miniature ? 28 : 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.navChat,
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
            ),
            const SizedBox(height: 8),
            _PreviewMessage(text: 'CQ CQ', mine: false, scale: scale),
            const SizedBox(height: 8),
            _PreviewMessage(text: 'DE DITMESH', mine: true, scale: scale),
            const SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: miniature ? 6 : 10,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(tokens.controlRadius),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      s.chatSend,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.send,
                    size: 16 * scale,
                    color: theme.colorScheme.onPrimary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Static Morse chat examples; no real conversation or playback is started.
class _PreviewMessage extends StatelessWidget {
  const _PreviewMessage({
    required this.text,
    required this.mine,
    required this.scale,
  });

  final String text;
  final bool mine;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = StyleTokens.of(context)!.bubbleRadius;
    return Padding(
      padding: EdgeInsets.only(left: mine ? 16 : 0, right: mine ? 0 : 16),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: mine ? scheme.primaryContainer : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(radius),
              topRight: Radius.circular(radius),
              bottomLeft: Radius.circular(mine ? radius : radius.clamp(0, 4)),
              bottomRight: Radius.circular(mine ? radius.clamp(0, 4) : radius),
            ),
          ),
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: mine ? scheme.onPrimaryContainer : scheme.onSurface,
              fontSize: 12 * scale,
            ),
          ),
        ),
      ),
    );
  }
}

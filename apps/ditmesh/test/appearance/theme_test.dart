import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/appearance/style_tokens.dart';
import 'package:ditmesh/ui/appearance/ui_style.dart';
import 'package:ditmesh/ui/theme.dart';

double contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

void main() {
  for (final style in UiStyle.values) {
    for (final dark in [false, true]) {
      test(
        '$style ${dark ? 'dark' : 'light'} keeps content and actions readable',
        () {
          final theme = dark
              ? DitmeshTheme.dark(style: style)
              : DitmeshTheme.light(style: style);
          final scheme = theme.colorScheme;
          final tokens = theme.extension<StyleTokens>()!;
          expect(
            contrast(scheme.onSurface, scheme.surface),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrast(scheme.onSurfaceVariant, scheme.surfaceContainerLow),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrast(scheme.onPrimary, scheme.primary),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrast(tokens.onNewest, tokens.newest),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrast(scheme.onSurface, tokens.receiveSurface),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrast(scheme.onSurface, tokens.sendSurface),
            greaterThanOrEqualTo(4.5),
          );
          // Secondary labels sit on the canvas and pastel goal/action cards,
          // not just the theme's default card background.
          for (final background in [
            scheme.surface,
            tokens.receiveSurface,
            tokens.sendSurface,
          ]) {
            expect(
              contrast(scheme.onSurfaceVariant, background),
              greaterThanOrEqualTo(4.5),
            );
          }
          if (style == UiStyle.cartoon) {
            expect(
              contrast(scheme.primary, tokens.receiveSurface),
              greaterThanOrEqualTo(4.5),
            );
          }
        },
      );
    }
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// [hint] when it fits [maxLines] of a field [width] wide in [style]
/// (`bodyLarge` by default), else the platform's short "Search": a cut hint
/// in a one-line field reads as a broken interface (narrow phones, long
/// languages, large text).
String fittingHint(
  BuildContext context,
  String hint, {
  required double width,
  TextStyle? style,
  int maxLines = 1,
}) {
  final TextPainter painter = TextPainter(
    text: TextSpan(
      text: hint,
      style: style ?? Theme.of(context).textTheme.bodyLarge,
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: maxLines,
  )..layout(maxWidth: math.max(1, width));
  final bool fits = !painter.didExceedMaxLines;
  painter.dispose();
  return fits ? hint : MaterialLocalizations.of(context).searchFieldLabel;
}

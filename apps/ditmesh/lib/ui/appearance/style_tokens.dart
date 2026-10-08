import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'ui_style.dart';

/// Geometry and a few domain surfaces shared by every screen.
class StyleTokens extends ThemeExtension<StyleTokens> {
  const StyleTokens({
    required this.style,
    required this.panelRadius,
    required this.controlRadius,
    required this.bubbleRadius,
    required this.chipRadius,
    required this.newest,
    required this.onNewest,
    required this.receiveSurface,
    required this.sendSurface,
  });

  final UiStyle style;
  final double panelRadius;
  final double controlRadius;
  final double bubbleRadius;
  final double chipRadius;
  final Color newest;
  final Color onNewest;
  final Color receiveSurface;
  final Color sendSurface;

  static StyleTokens? of(BuildContext context) =>
      Theme.of(context).extension<StyleTokens>();

  @override
  StyleTokens copyWith({
    UiStyle? style,
    double? panelRadius,
    double? controlRadius,
    double? bubbleRadius,
    double? chipRadius,
    Color? newest,
    Color? onNewest,
    Color? receiveSurface,
    Color? sendSurface,
  }) => StyleTokens(
    style: style ?? this.style,
    panelRadius: panelRadius ?? this.panelRadius,
    controlRadius: controlRadius ?? this.controlRadius,
    bubbleRadius: bubbleRadius ?? this.bubbleRadius,
    chipRadius: chipRadius ?? this.chipRadius,
    newest: newest ?? this.newest,
    onNewest: onNewest ?? this.onNewest,
    receiveSurface: receiveSurface ?? this.receiveSurface,
    sendSurface: sendSurface ?? this.sendSurface,
  );

  @override
  StyleTokens lerp(covariant StyleTokens? other, double t) {
    if (other == null) return this;
    return StyleTokens(
      style: t < 0.5 ? style : other.style,
      panelRadius: lerpDouble(panelRadius, other.panelRadius, t)!,
      controlRadius: lerpDouble(controlRadius, other.controlRadius, t)!,
      bubbleRadius: lerpDouble(bubbleRadius, other.bubbleRadius, t)!,
      chipRadius: lerpDouble(chipRadius, other.chipRadius, t)!,
      newest: Color.lerp(newest, other.newest, t)!,
      onNewest: Color.lerp(onNewest, other.onNewest, t)!,
      receiveSurface: Color.lerp(receiveSurface, other.receiveSurface, t)!,
      sendSurface: Color.lerp(sendSurface, other.sendSurface, t)!,
    );
  }
}

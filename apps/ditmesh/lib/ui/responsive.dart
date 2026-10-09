import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Layout breakpoint (logical pixels). Below it the shell uses a bottom
/// [NavigationBar]; at or above it, a side [NavigationRail]. 600 is the
/// Material "compact / medium" boundary, so phones in portrait are compact and
/// tablets, foldables and desktop windows are not.
const double kCompactMaxWidth = 600;

/// Coarse layout class used by the shell. Deliberately two-valued: the
/// product only distinguishes "phone-like" from "everything wider" today.
enum LayoutClass { compact, expanded }

LayoutClass layoutClassForWidth(double width) =>
    width < kCompactMaxWidth ? LayoutClass.compact : LayoutClass.expanded;

/// Reads the layout class from the nearest [MediaQuery]. Keep this the single
/// place that inspects width so the breakpoint cannot drift between widgets.
LayoutClass layoutClassOf(BuildContext context) =>
    layoutClassForWidth(MediaQuery.sizeOf(context).width);

/// The text scale Material's AppBar clamps its title to (Flutter's private
/// `_kMaxTitleTextScaleFactor`). Code that measures whether a title fits the
/// bar must clamp the same way, or large text over-estimates the title.
const double kAppBarTitleMaxTextScale = 1.34;

/// Bars and badges clamp their labels like the AppBar title: a 2x
/// "Reference" is wider than a quarter of a phone, and the navigation bar
/// and rail (like iOS tab bars) keep a fixed height for their labels.
const double kBarLabelMaxTextScale = kAppBarTitleMaxTextScale;

/// The text scaler for a label pinned to a screen edge (an extended floating
/// action button): at 2x a long translation was wider than a phone.
TextScaler edgeLabelTextScaler(BuildContext context) => MediaQuery.textScalerOf(
  context,
).clamp(maxScaleFactor: kBarLabelMaxTextScale);

/// Largest text scale, between [min] and [max], at which every one of
/// [labels] fits on one line [width] wide in [style]. A bottom navigation
/// label that wraps (a German "Nachschlagen" on a quarter of a phone at
/// large text) grows the fixed-height bar into the home indicator.
double fitLabelsTextScale(
  BuildContext context, {
  required Iterable<String> labels,
  required TextStyle? style,
  required double width,
  double min = 0.8,
  double max = kBarLabelMaxTextScale,
}) {
  var fit = max;
  for (final String label in labels) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    if (painter.width > 0) fit = math.min(fit, width / painter.width);
    painter.dispose();
  }
  return fit.clamp(min, max);
}

/// [scaler] as an AppBar applies it to the title.
TextScaler appBarTitleTextScaler(TextScaler scaler) =>
    scaler.clamp(maxScaleFactor: kAppBarTitleMaxTextScale);

/// Gives a `Column` with an `Expanded` region between fixed controls at least
/// [minHeight] logical pixels (scaled with the text size) and scrolls it when
/// the viewport is shorter.
///
/// A phone in landscape (~320-430 px tall), the soft keyboard covering the
/// bottom half of a portrait phone, an Android split-screen half or a large
/// text scale leaves less height than the fixed controls need, and such a
/// column overflowed. Here the column keeps its layout and the page scrolls
/// instead (the focused field is scrolled into view by the framework).
///
/// The widget tree is the same whether or not the column fits: the child is
/// always inside the scroll view and only its height changes (the viewport
/// height when that is enough, [minHeight] otherwise; a column that fits has
/// no scroll extent). Swapping between a bare child and a scroll wrapper
/// would remount the child whenever the soft keyboard pushed the height
/// across the threshold, disposing the focused field's `EditableText` and
/// closing the keyboard it had just opened.
class MinHeightScrollView extends StatelessWidget {
  const MinHeightScrollView({
    super.key,
    required this.minHeight,
    required this.child,
  });

  /// Height the column needs at text scale 1.0.
  final double minHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double need = MediaQuery.textScalerOf(context).scale(minHeight);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double height = box.hasBoundedHeight && box.maxHeight > need
            ? box.maxHeight
            : need;
        return SingleChildScrollView(
          child: SizedBox(height: height, child: child),
        );
      },
    );
  }
}

/// Widest a page's content column grows on a tablet or desktop window. List
/// rows wider than this put a title and its trailing control a screen apart.
const double kReadableMaxWidth = 720;

/// Body of a list or form page: keeps the content clear of a landscape
/// phone's notch and rounded corners (a `ListView` only pads along its
/// scroll axis, so rows ran under the sensor housing) and centres it in at
/// most [maxWidth] on a wide window. The background still fills the page.
class ReadableBody extends StatelessWidget {
  const ReadableBody({
    super.key,
    this.maxWidth = kReadableMaxWidth,
    this.alignment = Alignment.topCenter,
    required this.child,
  });

  final double maxWidth;

  /// Where the column sits when the window is wider (a pane next to a side
  /// list starts beside it instead of centring).
  final AlignmentGeometry alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      // Tight like the body slot it replaces, only narrower, so a child that
      // centres or stretches itself lays out exactly as before.
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) => Align(
          alignment: alignment,
          child: SizedBox(
            width: box.maxWidth < maxWidth ? box.maxWidth : maxWidth,
            height: box.hasBoundedHeight ? box.maxHeight : null,
            child: child,
          ),
        ),
      ),
    );
  }
}

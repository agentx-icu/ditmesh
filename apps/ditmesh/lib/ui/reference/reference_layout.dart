import 'package:flutter/widgets.dart';

/// Width (logical pixels) at or above which the reference and translator
/// use two panes side by side. Below it they are a single column, which is
/// what every phone and small tablet gets.
const double kReferenceTwoPaneMinWidth = 900;

bool referenceTwoPaneForWidth(double width) =>
    width >= kReferenceTwoPaneMinWidth;

/// Reads the two-pane decision from the nearest [MediaQuery].
bool referenceTwoPaneOf(BuildContext context) =>
    referenceTwoPaneForWidth(MediaQuery.sizeOf(context).width);

/// Horizontal page padding shared by both screens (16 on phones).
const EdgeInsets kReferencePagePadding = EdgeInsets.symmetric(horizontal: 16);

/// Gives a single-column translator pane at least [minHeight] logical pixels
/// (scaled with the text size) and scrolls it when the viewport is shorter.
///
/// The compact panes are a `Column` with one `Expanded` output region between
/// fixed controls. A phone in landscape (~320-430 px tall), the soft keyboard
/// covering the bottom half of a portrait phone, or a large text scale leaves
/// less height than the fixed controls need, and the column overflowed. Here
/// the column keeps its layout and the page scrolls instead (the focused
/// field is scrolled into view by the framework).
///
/// The widget tree is the same whether or not the pane fits: the child is
/// always inside the scroll view and only its height changes (the viewport
/// height when that is enough, [minHeight] otherwise; a pane that fits has
/// no scroll extent). Swapping between a bare child and a scroll wrapper
/// would remount the child whenever the soft keyboard pushed the height
/// across the threshold, disposing the focused field's `EditableText` and
/// closing the keyboard it had just opened.
class ReferenceMinHeight extends StatelessWidget {
  const ReferenceMinHeight({
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

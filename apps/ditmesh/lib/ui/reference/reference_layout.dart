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

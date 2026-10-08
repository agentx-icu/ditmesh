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

/// [scaler] as an AppBar applies it to the title.
TextScaler appBarTitleTextScaler(TextScaler scaler) =>
    scaler.clamp(maxScaleFactor: kAppBarTitleMaxTextScale);

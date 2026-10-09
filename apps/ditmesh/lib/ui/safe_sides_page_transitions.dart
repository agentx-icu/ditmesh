import 'package:flutter/material.dart';

/// The platform's default page transitions, each keeping a pushed page clear
/// of the sideways safe-area insets: a phone in landscape puts its notch or
/// Dynamic Island on one side and rounded corners on both, and a `Scaffold`
/// body (unlike its `AppBar`) does not avoid them, so list rows, the chat
/// timeline and form fields ran under the sensor housing.
///
/// Every page pushed on a navigator gets the inset; the first route (the
/// shell, whose navigation rail and bar handle the insets themselves and run
/// their surfaces under the notch) does not. The strips beside an inset page
/// are painted in the scaffold colour, which is also the app bars' colour.
final PageTransitionsTheme kSafeSidesPageTransitions = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    for (final MapEntry<TargetPlatform, PageTransitionsBuilder> entry
        in const PageTransitionsTheme().builders.entries)
      entry.key: SafeSidesPageTransitionsBuilder(entry.value),
  },
);

/// Wraps [inner] (the platform transition, back gestures included) and only
/// changes the page it animates.
class SafeSidesPageTransitionsBuilder extends PageTransitionsBuilder {
  const SafeSidesPageTransitionsBuilder(this.inner);

  final PageTransitionsBuilder inner;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      inner.delegatedTransition;

  @override
  Duration get transitionDuration => inner.transitionDuration;

  @override
  Duration get reverseTransitionDuration => inner.reverseTransitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => inner.buildTransitions<T>(
    route,
    context,
    animation,
    secondaryAnimation,
    // Same tree either way: a route that becomes the first one (the routes
    // below it removed) must not remount its page.
    SafeSides(enabled: !route.isFirst, child: child),
  );
}

/// [child] inside the sideways safe area, the strips in the scaffold colour.
class SafeSides extends StatelessWidget {
  const SafeSides({super.key, this.enabled = true, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: enabled
        ? Theme.of(context).scaffoldBackgroundColor
        : Colors.transparent,
    child: SafeArea(
      top: false,
      bottom: false,
      left: enabled,
      right: enabled,
      child: child,
    ),
  );
}

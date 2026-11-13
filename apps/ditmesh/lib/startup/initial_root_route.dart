import 'package:flutter/material.dart';

/// Starts on the local root even if Android supplies a named intent route.
/// Named settings routes remain available for navigation within the app.
List<Route<void>> initialRootRoute(WidgetBuilder builder) => [
  MaterialPageRoute<void>(
    settings: const RouteSettings(name: Navigator.defaultRouteName),
    builder: builder,
  ),
];

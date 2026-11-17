import 'package:flutter/widgets.dart';

/// Route name of the training-defaults page (filled in by the learn UI).
const String kTrainingSettingsRoute = '/settings/training';

/// Public repository, shown (and copied) from the About section.
const String kAboutSourceUrl = 'https://github.com/agentx-icu/ditmesh';

/// Completes the route that started an account operation, even if another
/// page opened while the operation was pending.
void closeAccountRoute<T>(Route<T>? route, [T? result]) {
  if (route == null || !route.isActive) return;
  final navigator = route.navigator!;
  if (route.isCurrent) {
    navigator.pop(result);
  } else {
    navigator.removeRoute(route, result);
  }
}

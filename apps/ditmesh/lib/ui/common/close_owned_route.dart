import 'package:flutter/widgets.dart';

/// Completes the route that started an asynchronous operation, even if another
/// page opened while the operation was pending.
void closeOwnedRoute<T>(Route<T>? route, [T? result]) {
  if (route == null || !route.isActive) return;
  final navigator = route.navigator!;
  if (route.isCurrent) {
    navigator.pop(result);
  } else {
    navigator.removeRoute(route, result);
  }
}

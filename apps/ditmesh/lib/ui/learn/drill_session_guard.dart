import 'dart:async';

import 'package:flutter/material.dart';
import 'package:morse_io/morse_io.dart';

import '../../i18n/l10n_extension.dart';

/// Keeps the screen on while a drill session is running in the foreground.
///
/// A receive drill is mostly listening with no touch, so a phone's auto-lock
/// would background the app (and silence the sidetone) mid-round. The owner
/// reports whether its session is active ([setActive]) and forwards app
/// lifecycle changes ([onLifecycle]); the hold is released whenever either is
/// false and taken again on resume while the session still runs.
final class DrillScreenWake {
  DrillScreenWake(this._api);

  final ScreenWakeApi _api;
  bool _active = false;
  bool _foreground = true;
  bool _held = false;

  void setActive(bool active) {
    _active = active;
    _sync();
  }

  void onLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _foreground = false;
      case AppLifecycleState.resumed:
        _foreground = true;
      case AppLifecycleState.inactive:
        // iOS reports `inactive` for Control Center and call banners; the UI
        // is still there, so keep whatever we hold.
        return;
    }
    _sync();
  }

  /// Releases the hold for good (screen disposed).
  void dispose() {
    _active = false;
    _sync();
  }

  void _sync() {
    final bool want = _active && _foreground;
    if (want == _held) {
      return;
    }
    _held = want;
    unawaited(_api.keepOn(want));
  }
}

/// Asks before leaving a drill whose progress would be lost.
///
/// While [guard] is true the route cannot be popped by the Android system
/// back button, Android predictive back or the AppBar back button (all go
/// through `maybePop`); instead a confirmation dialog is shown and the route
/// is popped only if the operator confirms.
///
/// The iOS edge swipe does not show the dialog: a Cupertino route disables
/// its back-swipe gesture altogether while the pop disposition is
/// `doNotPop`, so the swipe simply does nothing and the operator leaves
/// through the back button (which asks). Nothing is lost silently either way;
/// once [guard] is false the swipe works again.
class DrillLeaveGuard extends StatelessWidget {
  const DrillLeaveGuard({super.key, required this.guard, required this.child});

  final bool guard;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: !guard,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop) {
        return;
      }
      final navigator = Navigator.of(context);
      if (await confirmLeaveDrill(context) && context.mounted) {
        navigator.pop();
      }
    },
    child: child,
  );
}

/// The leave-drill dialog; resolves to true when the operator confirms.
Future<bool> confirmLeaveDrill(BuildContext context) async {
  final s = context.s;
  final bool? leave = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      scrollable: true,
      title: Text(s.learnLeaveDrillTitle),
      content: Text(s.learnLeaveDrillBody),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(s.actionCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(s.learnLeaveDrillConfirm),
        ),
      ],
    ),
  );
  return leave ?? false;
}

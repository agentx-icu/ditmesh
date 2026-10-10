import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Touch-first platforms: big on-screen keys are the primary input and
/// haptics exist. Everything else is keyboard-first (Space / Ctrl keying).
///
/// Uses [defaultTargetPlatform] so widget tests can flip it with
/// `debugDefaultTargetPlatformOverride` and exercise both branches.
bool get isTouchPlatform =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// Whether [state] means a drill should stop sounding and drop held keys:
/// the app went to the background on a phone. `inactive` (Control Center,
/// call banners) does not count, and desktop windows keep running when
/// minimised, matching `BindingAppForeground` in morse_io.
bool isDrillBackground(AppLifecycleState state) =>
    isTouchPlatform &&
    (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached);

/// Whether to surface keyboard shortcuts and autofocus keyable widgets.
bool get hasPhysicalKeyboardByDefault => !isTouchPlatform;

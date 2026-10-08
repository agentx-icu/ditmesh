import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:morse_io/morse_io.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

/// Connection-state notification policy: **no OS notifications**, ever.
///
/// Tox flaps between online and offline routinely (DHT churn, network
/// switches, the OS suspending the app), so alerting on each change would be
/// spam. Instead this exposes one boolean, [offlineBannerVisible], that turns
/// on after the node has been continuously not-online for [threshold]
/// (default two minutes) and off the moment it is online again. The shell
/// renders it as an in-app banner with a reconnect action.
///
/// `connecting` counts as not-online: a bootstrap that has been "connecting"
/// for two minutes is, to the user, offline.
class ConnectionBannerPolicy {
  ConnectionBannerPolicy({
    required IdentityService identity,
    Clock? clock,
    this.threshold = const Duration(minutes: 2),
  }) : _identity = identity,
       _clock = clock ?? SystemClock.shared;

  final IdentityService _identity;
  final Clock _clock;
  final Duration threshold;

  final ValueNotifier<bool> _visible = ValueNotifier<bool>(false);
  StreamSubscription<ConnectionStatus>? _sub;
  Timer? _timer;

  ValueListenable<bool> get offlineBannerVisible => _visible;

  /// Applies the current status and follows changes. Idempotent.
  void start() {
    if (_sub != null) return;
    _apply(_identity.connectionStatus);
    _sub = _identity.connectionChanges.listen(_apply);
  }

  void _apply(ConnectionStatus status) {
    if (status == ConnectionStatus.online) {
      _timer?.cancel();
      _timer = null;
      _visible.value = false;
      return;
    }
    if (_visible.value || _timer != null) return;
    _timer = _clock.schedule(threshold, () {
      _timer = null;
      _visible.value = true;
    });
  }

  /// Releases the timer and the listener SYNCHRONOUSLY, before the first
  /// `await`. The owning scope's `dispose()` cannot wait for us, and the
  /// future a cancelled broadcast subscription returns may complete in the
  /// root zone (under FakeAsync it never runs before the test ends), so
  /// anything after the `await` would leave the threshold timer alive past
  /// [_visible]'s disposal.
  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    final cancelled = _sub?.cancel();
    _sub = null;
    _visible.dispose();
    await cancelled;
  }
}

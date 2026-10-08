import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../ui/learn/learn_scope.dart';
import 'guest_profile.dart';
import 'training_controller.dart';

/// One [TrainingController] per identity for the whole app.
///
/// The Learn tab and the "training defaults" page reached from the Me page
/// must share the same controller: two instances writing the same
/// `progress.json` / `settings.json` would silently overwrite each other.
/// The host caches the controller by identity public key and rebuilds it
/// when the identity changes (logout / restore / delete).
class TrainingControllerHost implements IdentityDataStore {
  TrainingControllerHost(
    this._identity, {
    Future<TrainingController> Function(IdentityService identity)? factory,
    ValueListenable<bool>? guestMode,
    Future<TrainingController> Function()? guestFactory,
  }) : _factory = factory ?? LearnScope.controllerForIdentity,
       _guestMode = guestMode,
       _guestFactory = guestFactory {
    _sub = _identity.identityChanges.listen(_onIdentity);
    _guestMode?.addListener(_onGuestMode);
    final identity = _identity;
    if (identity is PersistentIdentityService) identity.registerDataStore(this);
  }

  final IdentityService _identity;
  final Future<TrainingController> Function(IdentityService identity) _factory;

  /// Guest learning (functional spec §8): while on and no identity is open,
  /// the host serves the guest profile's controller from [_guestFactory].
  final ValueListenable<bool>? _guestMode;
  final Future<TrainingController> Function()? _guestFactory;

  bool get _guestActive =>
      _identity.current == null &&
      (_guestMode?.value ?? false) &&
      _guestFactory != null;
  StreamSubscription<Identity?>? _sub;
  String? _key;
  Future<TrainingController>? _pending;
  Future<TrainingController>? _loading;
  TrainingController? _current;
  // Bumped whenever the cached identity is dropped (switch / dispose). A
  // load that completes for an older generation must not be cached: nobody
  // owns a factory-supplied controller but this host, so it is disposed here.
  int _generation = 0;
  bool _disposed = false;
  bool _replacing = false;

  /// Learning data is being moved (guest migration): no controller is
  /// served until [resumeLearning]. Unlike [_replacing], identity events
  /// do not lift it.
  bool _suspended = false;
  Future<void>? _guestRelease;

  final ValueNotifier<int> _reloads = ValueNotifier<int>(0);

  /// Bumped when the learning files under a cached controller were
  /// replaced; mounted learning screens reload their controller.
  ValueListenable<int> get reloads => _reloads;

  /// Resolves (and caches) the controller for the current identity. Matches
  /// `LearnPage.controllerFactory`'s signature so it can be handed straight
  /// to the Learn tab.
  Future<TrainingController> controllerFor(BuildContext context) =>
      controller();

  Future<TrainingController> controller() {
    final identity = _identity.current;
    final guest = _guestActive;
    if ((identity == null && !guest) || _disposed || _replacing || _suspended) {
      return Future<TrainingController>.error(
        StateError(
          _disposed
              ? 'training host disposed'
              : _replacing
              ? 'identity data is being replaced'
              : 'training requires an identity',
        ),
      );
    }
    final key = identity?.publicKey ?? GuestProfile.profileKey;
    if (_key == key && _pending != null) return _pending!;
    _dropCurrent();
    _key = key;
    final generation = _generation;
    final loading = identity == null ? _guestFactory!() : _factory(_identity);
    _loading = loading;
    final future = loading.then(
      (c) {
        if (_disposed || generation != _generation) {
          c.dispose();
          throw StateError('identity changed while training data loaded');
        }
        _current = c;
        return c;
      },
      onError: (Object error, StackTrace stack) {
        if (generation == _generation) _dropCurrent();
        Error.throwWithStackTrace(error, stack);
      },
    );
    _pending = future;
    return future;
  }

  /// Reads the host from the widget tree when one is provided, else falls
  /// back to a fresh per-identity controller (tests, isolated screens).
  static Future<TrainingController> fromContext(BuildContext context) {
    final host = context.read<TrainingControllerHost?>();
    if (host != null) return host.controllerFor(context);
    return LearnScope.controllerForIdentity(context.read<IdentityService>());
  }

  void _onGuestMode() {
    if (_key == GuestProfile.profileKey && !_guestActive) {
      unawaited(releaseGuest().catchError((Object _) {}));
    }
  }

  /// Closes the guest controller and completes once its pending writes are
  /// on disk, so no late guest write can land after a migration. Repeated
  /// calls (mode switch, identity event, migration) share one release.
  Future<void> releaseGuest() {
    if (_key == GuestProfile.profileKey) {
      _guestRelease = _flushThenDrop();
    }
    return _guestRelease ?? Future<void>.value();
  }

  /// Stops serving the cached controller at once, lets its queued writes
  /// and document transactions finish (they need a live controller), then
  /// disposes it.
  Future<void> _flushThenDrop() async {
    final loading = _loading;
    final controller = _current;
    _generation++;
    _pending = null;
    _loading = null;
    _current = null;
    _key = null;
    final live = controller ?? (loading == null ? null : await loading);
    if (live == null) return;
    try {
      await live.flush();
    } finally {
      live.dispose();
    }
  }

  /// Stops serving learning controllers and flushes the cached one before
  /// learning files are replaced underneath it.
  Future<void> suspendLearning() async {
    _suspended = true;
    if (_key == GuestProfile.profileKey) {
      await releaseGuest();
      return;
    }
    await _flushThenDrop();
  }

  /// Serves controllers again; mounted screens reload from disk.
  void resumeLearning() {
    _suspended = false;
    _dropCurrent();
    _reloads.value++;
  }

  void _onIdentity(Identity? identity) {
    final next =
        identity?.publicKey ?? (_guestActive ? GuestProfile.profileKey : null);
    if (next != _key) {
      if (_key == GuestProfile.profileKey) {
        unawaited(releaseGuest().catchError((Object _) {}));
      } else {
        _dropCurrent();
      }
    }
    if (identity != null) _replacing = false;
  }

  void _dropCurrent() {
    _generation++;
    _current?.dispose();
    _current = null;
    _pending = null;
    _loading = null;
    _key = null;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final identity = _identity;
    if (identity is PersistentIdentityService) {
      identity.unregisterDataStore(this);
    }
    // Cancel is synchronous for delivery; its future is the root-zone
    // `_nullFuture`, which never resumes under FakeAsync, so do not await it
    // or the controller below would never be disposed in widget tests.
    unawaited(_sub?.cancel());
    _guestMode?.removeListener(_onGuestMode);
    _dropCurrent();
  }

  @override
  Future<void> flush() async {
    final loading = _loading;
    final controller = _current;
    if (controller != null) {
      await controller.flush();
    } else if (loading != null) {
      await (await loading).flush();
    }
  }

  @override
  Future<void> prepareForReplacement() async {
    final loading = _loading;
    final controller = _current;
    // Invalidate synchronously, before awaiting writes. Old screens must
    // stop issuing mutations while the backend is replacing their files.
    _replacing = true;
    _dropCurrent();
    // Disposal stops new mutations at once; writes and document
    // transactions submitted before it still complete, and flush waits.
    if (controller != null) {
      await controller.flush();
    } else if (loading != null) {
      final late = await loading;
      late.dispose();
      await late.flush();
    }
  }
}

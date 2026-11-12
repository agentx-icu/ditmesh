import 'dart:async';
import 'dart:convert';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter/widgets.dart';

import '../i18n/key_value_store.dart';
import 'location_source.dart';
import 'nearby_service.dart';

enum LocationIssue {
  disabled,
  permissionDenied,
  serviceDisabled,
  unavailable,
  saveFailed,
}

/// Device-local, identity-scoped consent and foreground-only location work.
/// Coordinates, discovery keys and visibility never enter portable backups.
class NearbyController extends ChangeNotifier
    with WidgetsBindingObserver
    implements IdentityDataStore {
  NearbyController({
    required IdentityService identity,
    required ChatService chat,
    required KeyValueStore store,
    this.location = const GeolocatorLocationSource(),
    NearbyTransport? Function()? transport,
  }) : _identity = identity,
       _chat = chat,
       _store = store,
       _transport =
           transport ??
           (() => chat is NearbyTransportProvider
               ? (chat as NearbyTransportProvider).nearbyTransport
               : null) {
    _foreground = !{
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.detached,
    }.contains(WidgetsBinding.instance.lifecycleState);
    _loadIdentity();
    _identitySub = identity.identityChanges.listen((_) => _loadIdentity());
    _sessionSub = chat.sessionChanges.listen((_) => _syncTransport());
    _requestsSub = chat.friendRequestChanges.listen(_matchReplies);
    if (identity is PersistentIdentityService) identity.registerDataStore(this);
    WidgetsBinding.instance.addObserver(this);
  }

  final IdentityService _identity;
  final ChatService _chat;
  final KeyValueStore _store;
  final LocationSource location;
  final NearbyTransport? Function() _transport;
  StreamSubscription<Identity?>? _identitySub;
  StreamSubscription<bool>? _sessionSub;
  StreamSubscription<List<FriendRequest>>? _requestsSub;
  final Map<String, PendingIntent> _replies = {};
  PendingIntent? replyFor(String publicKey) => _replies[publicKey];
  String? _key;
  bool _disposed = false;
  bool _foreground = true;
  bool _replacing = false;
  int _generation = 0;
  int _consentEpoch = 0;
  final Set<String> _removals = {};
  bool get hasIdentity => _key != null;
  int _pages = 0;
  Timer? _idle;
  NearbyTransport? _wire;
  NearbyService? _nearby;
  NearbyService? get nearby => _nearby;
  bool _locationEnabled = false;
  bool get locationEnabled => _locationEnabled;
  bool _nearbyVisible = false;
  bool get nearbyVisible => _nearbyVisible;
  bool _busy = false;
  bool get busy => _busy;
  bool _locating = false;
  bool get locating => _locating;
  bool get available => _chat.hasSession && _transport() != null;
  LocationFix? _fix;
  LocationFix? get fix => _fix;
  LocationIssue? _issue;
  LocationIssue? get issue => _issue;
  Future<void> _pending = Future<void>.value();
  Future<LocationFix?>? _fixFuture;
  Future<LocationPermissionState>? _permissionFuture;

  bool get _allowed => !_disposed && !_replacing && _foreground && _key != null;
  bool get _canDiscover =>
      _allowed &&
      locationEnabled &&
      nearbyVisible &&
      !_busy &&
      (_pages > 0 || _idle != null);
  String _storageKey(String key) => 'location.device.$key';
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _loadIdentity() {
    if (_disposed) return;
    final key = _identity.current?.publicKey.toUpperCase();
    if (key == _key && !_replacing) return;
    final previous = _key;
    _consentEpoch++;
    _generation++;
    _fix = null;
    _fixFuture = null;
    _locating = false;
    _retire();
    _key = key;
    _replacing = false;
    _locationEnabled = false;
    _nearbyVisible = false;
    _issue = null;
    if (key == null && previous != null) {
      _removals.add(_storageKey(previous));
      unawaited(
        flush().catchError((Object error) {
          _issue = LocationIssue.saveFailed;
          _notify();
        }),
      );
    }
    if (key != null && !_removals.contains(_storageKey(key))) {
      try {
        final raw = _store.getString(_storageKey(key));
        final values = raw == null ? null : jsonDecode(raw);
        if (values is Map) {
          _locationEnabled = values['enabled'] == true;
          _nearbyVisible = _locationEnabled && values['visible'] == true;
        }
      } on FormatException {
        /* Optional consent starts off if malformed. */
      }
    }
    _syncTransport();
    _notify();
  }

  void _retire() {
    _idle?.cancel();
    _idle = null;
    final old = _nearby;
    _nearby = null;
    _wire = null;
    _replies.clear();
    if (old != null) {
      old.removeListener(_notify);
      old.stop().ignore();
      old.dispose();
    }
  }

  void _syncTransport() {
    if (_disposed) return;
    final wire = _chat.hasSession && !_replacing ? _transport() : null;
    if (identical(wire, _wire)) return;
    _generation++;
    _fixFuture = null;
    _locating = false;
    _retire();
    _wire = wire;
    if (wire != null && _key != null) {
      final key = _key;
      _nearby = NearbyService(
        transport: wire,
        location: location,
        selfAddress: () async => _identity.current?.toxId ?? '',
        displayName: () => _identity.current?.displayName ?? '',
        canRun: () async =>
            _canDiscover && _key == key && identical(_wire, wire),
      )..addListener(_notify);
      if (_pages > 0) startIfEnabled().ignore();
    }
    _notify();
  }

  void _matchReplies(List<FriendRequest> requests) {
    if (_disposed) return;
    _replies.removeWhere((key, _) => !requests.any((r) => r.publicKey == key));
    for (final request in requests) {
      if (_replies.containsKey(request.publicKey)) continue;
      final intent = _nearby?.matchFriendApplication(request.message);
      if (intent != null) _replies[request.publicKey] = intent;
    }
    _notify();
  }

  /// A switch change is committed to disk before it becomes visible.
  Future<bool> _change(Future<bool> Function() action) {
    final key = _key;
    final epoch = _consentEpoch;
    final operation = _pending.then((_) async {
      if (!_allowed || key != _key || epoch != _consentEpoch) return false;
      _busy = true;
      _issue = null;
      _notify();
      try {
        await _drainRemovals();
        if (!_allowed || key != _key || epoch != _consentEpoch) return false;
        return await action();
      } on Object {
        if (!_disposed) _issue = LocationIssue.saveFailed;
        return false;
      } finally {
        _busy = false;
        _notify();
      }
    });
    _pending = operation.then((_) {});
    return operation;
  }

  Future<LocationPermissionState> _permission() => _permissionFuture ??=
      location.requestPermission().whenComplete(() => _permissionFuture = null);

  void _permissionIssue(LocationPermissionState state) {
    _issue = switch (state) {
      LocationPermissionState.granted => null,
      LocationPermissionState.serviceDisabled => LocationIssue.serviceDisabled,
      LocationPermissionState.denied ||
      LocationPermissionState.deniedForever => LocationIssue.permissionDenied,
      LocationPermissionState.unavailable => LocationIssue.unavailable,
    };
  }

  Future<bool> setLocationEnabled(bool value) => _change(() async {
    final key = _key!;
    final epoch = _consentEpoch;
    if (value) {
      final state = await _permission();
      if (!_allowed || key != _key || epoch != _consentEpoch) return false;
      _permissionIssue(state);
      if (state != LocationPermissionState.granted) return false;
    } else {
      _generation++;
      _fix = null;
      _fixFuture = null;
      _locating = false;
      await _nearby?.stop();
    }
    await _store.setString(
      _storageKey(key),
      jsonEncode({'enabled': value, 'visible': value && _nearbyVisible}),
    );
    if (_disposed || _replacing || key != _key || epoch != _consentEpoch) {
      return false;
    }
    _locationEnabled = value;
    if (!value) _nearbyVisible = false;
    return true;
  });

  Future<bool> setNearbyVisible(bool value, {bool consent = false}) async {
    final changed = await _change(() async {
      if (value && (!locationEnabled || !consent)) return false;
      final key = _key!;
      final epoch = _consentEpoch;
      if (!value) await _nearby?.stop();
      await _store.setString(
        _storageKey(key),
        jsonEncode({'enabled': _locationEnabled, 'visible': value}),
      );
      if (_disposed || _replacing || key != _key || epoch != _consentEpoch) {
        return false;
      }
      _nearbyVisible = value;
      return true;
    });
    if (changed && value) await startIfEnabled();
    return changed;
  }

  Future<LocationFix?> locate() {
    if (!_allowed || !locationEnabled) {
      _issue = LocationIssue.disabled;
      _notify();
      return Future.value();
    }
    return _fixFuture ??= _locate();
  }

  Future<LocationFix?> _locate() async {
    final generation = _generation;
    bool current() => _allowed && locationEnabled && generation == _generation;
    _locating = true;
    _issue = null;
    _notify();
    try {
      final state = await _permission();
      if (!current()) return null;
      _permissionIssue(state);
      if (state != LocationPermissionState.granted) {
        _fix = null;
        await _nearby?.stop();
        return null;
      }
      final fix = await location.currentFix();
      if (!current()) return null;
      if (fix == null ||
          !fix.isValid ||
          DateTime.now().difference(fix.at) > const Duration(minutes: 3)) {
        _issue = LocationIssue.unavailable;
        return null;
      }
      _fix = fix;
      return fix;
    } on Object {
      if (current()) _issue = LocationIssue.unavailable;
      return null;
    } finally {
      if (generation == _generation) {
        _locating = false;
        _fixFuture = null;
        _notify();
      }
    }
  }

  void pageOpened() {
    _pages++;
    _idle?.cancel();
    _idle = null;
    startIfEnabled().ignore();
  }

  void pageClosed() {
    if (_pages > 0) _pages--;
    if (_disposed || _pages > 0 || !(_nearby?.running ?? false)) return;
    _idle?.cancel();
    _idle = Timer(const Duration(minutes: 5), () {
      _idle = null;
      _nearby?.stop().ignore();
    });
  }

  Future<bool> startIfEnabled() async {
    _syncTransport();
    final nearby = _nearby;
    if (!_canDiscover || nearby == null) return false;
    await nearby.start();
    return nearby.running;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      if (_pages > 0) startIfEnabled().ignore();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _foreground = false;
      _generation++;
      _fix = null;
      _fixFuture = null;
      _locating = false;
      _nearby?.stop().ignore();
      _notify();
    }
  }

  Future<void> _drainRemovals() async {
    for (final key in _removals.toList()) {
      await _store.remove(key);
      _removals.remove(key);
    }
  }

  @override
  Future<void> flush() {
    final operation = _pending.then((_) => _drainRemovals());
    _pending = operation.then<void>((_) {}, onError: (Object error) {});
    return operation;
  }

  @override
  Future<void> prepareForReplacement() async {
    _replacing = true;
    _consentEpoch++;
    _generation++;
    _fix = null;
    _locationEnabled = false;
    _nearbyVisible = false;
    if (_key case final key?) _removals.add(_storageKey(key));
    _retire();
    await flush();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _consentEpoch++;
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    final identity = _identity;
    if (identity is PersistentIdentityService) {
      identity.unregisterDataStore(this);
    }
    _identitySub?.cancel().ignore();
    _sessionSub?.cancel().ignore();
    _requestsSub?.cancel().ignore();
    _retire();
    super.dispose();
  }
}

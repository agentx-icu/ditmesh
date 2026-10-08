import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../lifecycle/lifecycle_hint.dart';

/// What the diagnostics page can say about the selected peer. Local
/// connectivity and peer availability are separate facts: while we are not
/// online, a friend's last known state is stale and reads as [unknown].
enum PeerAvailability { online, offline, unknown, notApplicable }

/// Why [ConnectionDiagnosticsSnapshot.statusSince] is the time it is.
enum StatusSinceKind {
  /// First observation after the identity opened (or the app started).
  firstObserved,

  /// An observed change to this state.
  changed,

  /// The app came back from a background period long enough for the OS to
  /// suspend it: observation restarted here, nothing is claimed in between.
  resumed,
}

/// The reconnect action's progress. Completion does not mean online.
enum ReconnectState { idle, running, failed }

/// One read-only view of the connection, scoped to one identity (F09).
/// Unsupported observations are null / [PeerAvailability.unknown]: nothing
/// here infers NAT, firewall, delivery or read receipts from "offline".
@immutable
final class ConnectionDiagnosticsSnapshot {
  const ConnectionDiagnosticsSnapshot({
    required this.identityKey,
    required this.observedAt,
    required this.status,
    required this.statusSince,
    required this.statusSinceKind,
    required this.lastOnlineAt,
    required this.peer,
    required this.pending,
    required this.reconnect,
    this.errorCode,
  });

  /// Public key of the identity these observations belong to; null when no
  /// identity is open.
  final String? identityKey;
  final DateTime observedAt;
  final ConnectionStatus status;
  final DateTime? statusSince;
  final StatusSinceKind statusSinceKind;

  /// When a local connection was last observed (the moment it ended); null
  /// when none was observed yet. Not a delivery time.
  final DateTime? lastOnlineAt;
  final PeerAvailability peer;

  /// Durable outbox of the identity (or the selected conversation); null
  /// when the transport cannot report it right now.
  final PendingOutboxSummary? pending;
  final ReconnectState reconnect;

  /// [ChatException.code] of the last failed reconnect, `unknown` for any
  /// other error; null unless [reconnect] is [ReconnectState.failed].
  final String? errorCode;
}

/// Observes connection state per identity for the diagnostics page.
///
/// Read-only except for [reconnect], which is coalesced: taps while one is
/// running join it. A finished reconnect only means `connect()` returned;
/// the status keeps following [IdentityService.connectionChanges]. Replacing
/// the identity drops every observation, and a reconnect started for the
/// old identity cannot report into the new one.
class ConnectionDiagnostics extends ChangeNotifier {
  ConnectionDiagnostics({
    required IdentityService identity,
    required ChatService chat,
    Stream<LifecycleHint>? lifecycleHints,
    Future<Object?> Function()? reconnect,
    DateTime Function()? now,
  }) : _identity = identity,
       _chat = chat,
       _hints = lifecycleHints,
       _reconnectCall = reconnect,
       _now = now ?? DateTime.now;

  final IdentityService _identity;
  final ChatService _chat;
  final Stream<LifecycleHint>? _hints;
  final Future<Object?> Function()? _reconnectCall;
  final DateTime Function() _now;

  final List<StreamSubscription<Object?>> _subs = [];
  bool _started = false;
  bool _disposed = false;

  String? _key;
  ConnectionStatus _status = ConnectionStatus.offline;
  DateTime? _statusSince;
  StatusSinceKind _sinceKind = StatusSinceKind.firstObserved;
  DateTime? _lastOnlineAt;
  DateTime? _backgroundAt;
  bool _suspended = false;
  ReconnectState _reconnect = ReconnectState.idle;
  String? _errorCode;
  Future<void>? _inFlight;

  /// Bumped on every identity change; a reconnect remembers the one it began
  /// under and drops its result when they differ.
  int _generation = 0;

  ReconnectState get reconnectState => _reconnect;

  /// Seeds from the current state and follows changes. Idempotent.
  void start() {
    if (_started || _disposed) return;
    _started = true;
    _resetFor(_identity.current?.publicKey);
    _subs
      ..add(_identity.identityChanges.listen(_onIdentity))
      ..add(_identity.connectionChanges.listen(_onStatus))
      ..add(_chat.friendChanges.listen((_) => _notify()))
      ..add(_chat.sessionChanges.listen((_) => _notify()))
      // Status changes of our own rows move the outbox count.
      ..add(_chat.messageEvents.listen((_) => _notify()));
    final hints = _hints;
    if (hints != null) _subs.add(hints.listen(_onHint));
  }

  void _resetFor(String? key) {
    _generation++;
    _key = key;
    _status = _identity.connectionStatus;
    _statusSince = key == null ? null : _now();
    _sinceKind = StatusSinceKind.firstObserved;
    _lastOnlineAt = null;
    _backgroundAt = null;
    _suspended = false;
    _reconnect = ReconnectState.idle;
    _errorCode = null;
    _inFlight = null;
  }

  void _onIdentity(Identity? identity) {
    final key = identity?.publicKey;
    if (key == _key) return;
    _resetFor(key);
    _notify();
  }

  void _onStatus(ConnectionStatus status) {
    // A status that arrives before the identity event of a replacement must
    // not be filed under the previous identity.
    final key = _identity.current?.publicKey;
    if (key != _key) _resetFor(key);
    _apply(status, _now());
    _notify();
  }

  void _apply(ConnectionStatus status, DateTime at) {
    if (status == _status) return;
    if (_status == ConnectionStatus.online) {
      // After a suspension a queued "connection lost" may be delivered on
      // thaw, before the foreground hint: we can only vouch for the moment
      // the app left the foreground (or, failing that, when the connection
      // was last seen to begin), never for the time we woke up.
      _lastOnlineAt = _suspended ? (_backgroundAt ?? _statusSince ?? at) : at;
    }
    _status = status;
    _statusSince = at;
    _sinceKind = StatusSinceKind.changed;
  }

  void _onHint(LifecycleHint hint) {
    switch (hint) {
      case LifecycleHint.background:
        _backgroundAt = _now();
      case LifecycleHint.mayBeDisconnected:
        _suspended = true;
      case LifecycleHint.foreground:
        if (_suspended) _resumeObservation();
        _suspended = false;
        _backgroundAt = null;
      case LifecycleHint.reconnectRequested:
      case LifecycleHint.reconnectFailed:
        break;
    }
  }

  /// After a suspension nothing was observed: the last online moment we can
  /// vouch for is when the app left the foreground, and the current state is
  /// re-read rather than assumed to have held all along.
  void _resumeObservation() {
    final at = _now();
    if (_status == ConnectionStatus.online) {
      _lastOnlineAt = _backgroundAt ?? _lastOnlineAt;
    }
    _status = _identity.connectionStatus;
    if (_key != null) {
      _statusSince = at;
      _sinceKind = StatusSinceKind.resumed;
    }
    _notify();
  }

  /// The current view, for [conversationId] when given (peer state and that
  /// conversation's queue) or for the whole identity.
  ConnectionDiagnosticsSnapshot snapshot({String? conversationId}) {
    final PendingOutboxSummary? pending = switch (_chat) {
      final OutboxInspector inspector when _key != null =>
        inspector.pendingOutbox(conversationId: conversationId),
      _ => null,
    };
    return ConnectionDiagnosticsSnapshot(
      identityKey: _key,
      observedAt: _now(),
      status: _status,
      statusSince: _statusSince,
      statusSinceKind: _sinceKind,
      lastOnlineAt: _lastOnlineAt,
      peer: _peerOf(conversationId),
      pending: pending,
      reconnect: _reconnect,
      errorCode: _reconnect == ReconnectState.failed ? _errorCode : null,
    );
  }

  PeerAvailability _peerOf(String? conversationId) {
    if (conversationId == null) return PeerAvailability.notApplicable;
    if (conversationId == _chat.selfConversationId) {
      return PeerAvailability.notApplicable;
    }
    if (_key == null || !conversationId.startsWith('c2c_')) {
      return PeerAvailability.unknown;
    }
    // Friend presence is only observed while we are online ourselves.
    if (_status != ConnectionStatus.online || !_chat.hasSession) {
      return PeerAvailability.unknown;
    }
    final peer = conversationId.substring(4).toUpperCase();
    final friend = _chat.friends
        .where((f) => f.publicKey.toUpperCase() == peer)
        .firstOrNull;
    if (friend == null) return PeerAvailability.unknown;
    return friend.online ? PeerAvailability.online : PeerAvailability.offline;
  }

  /// Asks the identity coordinator to (re)connect. Repeated calls while one
  /// is running return the same future. Never throws; a failure is kept as
  /// [ReconnectState.failed] with a code, and queued data is untouched.
  Future<void> reconnect() {
    final running = _inFlight;
    if (running != null) return running;
    if (_disposed || _key == null) return Future<void>.value();
    final generation = _generation;
    _reconnect = ReconnectState.running;
    _errorCode = null;
    _notify();
    final future = _run(generation);
    _inFlight = future;
    return future;
  }

  Future<void> _run(int generation) async {
    Object? error;
    try {
      final call = _reconnectCall;
      if (call != null) {
        error = await call();
      } else {
        await _identity.connect();
      }
    } on Object catch (e) {
      error = e;
    }
    if (_disposed || generation != _generation) return;
    _inFlight = null;
    if (error == null) {
      _reconnect = ReconnectState.idle;
    } else {
      _reconnect = ReconnectState.failed;
      _errorCode = error is ChatException ? error.code : 'unknown';
    }
    // The call may have returned without a status event: re-read it.
    _apply(_identity.connectionStatus, _now());
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final sub in _subs) {
      sub.cancel().ignore();
    }
    _subs.clear();
    super.dispose();
  }
}

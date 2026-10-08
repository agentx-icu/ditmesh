import 'dart:async';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

/// Minimal [IdentityService] for lifecycle / banner tests: counts
/// `connect()` calls and lets the test drive [connectionStatus] directly.
/// Everything else is unreachable and falls through to [noSuchMethod].
final class StubIdentityService implements IdentityService {
  StubIdentityService({Identity? identity, this.connectError})
    : _current = identity ?? Identity(toxId: 'F' * 76, displayName: 'Me');

  Identity? _current;
  int connectCalls = 0;

  /// When set, `connect()` throws it.
  Object? connectError;

  ConnectionStatus _status = ConnectionStatus.offline;
  final StreamController<ConnectionStatus> _statuses =
      StreamController<ConnectionStatus>.broadcast();

  void setStatus(ConnectionStatus status) {
    _status = status;
    _statuses.add(status);
  }

  final StreamController<Identity?> _identities =
      StreamController<Identity?>.broadcast();

  /// Simulates "no identity loaded yet".
  void clearIdentity() => _current = null;

  /// Replaces the identity without an identity event (as when a status
  /// event is delivered first).
  void setIdentityQuietly(Identity? identity) => _current = identity;

  /// Replaces the identity and announces it (null: deleted).
  void setIdentity(Identity? identity) {
    _current = identity;
    _identities.add(identity);
  }

  Future<void> dispose() async {
    await _statuses.close();
    await _identities.close();
  }

  @override
  Identity? get current => _current;

  @override
  Stream<Identity?> get identityChanges => _identities.stream;

  @override
  ConnectionStatus get connectionStatus => _status;

  @override
  Stream<ConnectionStatus> get connectionChanges => _statuses.stream;

  @override
  Future<void> connect() async {
    connectCalls++;
    final Object? error = connectError;
    if (error != null) throw error;
  }

  @override
  Future<void> disconnect() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

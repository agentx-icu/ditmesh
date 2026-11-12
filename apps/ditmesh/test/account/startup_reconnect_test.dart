import 'dart:async';

import 'package:ditmesh/startup/startup_controller.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ditmesh_chat_api/testing.dart';
import 'package:flutter_test/flutter_test.dart';

/// A running native engine can remain offline while connect() is a no-op.
class _Identity implements IdentityService {
  @override
  Identity? current = Identity(toxId: 'F' * 76, displayName: 'Me');
  final _changes = StreamController<Identity?>.broadcast();
  int connectCalls = 0;
  int disconnectCalls = 0;
  Object? connectError;
  Completer<void>? connectGate;

  @override
  Stream<Identity?> get identityChanges => _changes.stream;
  @override
  Stream<ConnectionStatus> get connectionChanges => const Stream.empty();
  @override
  ConnectionStatus get connectionStatus => ConnectionStatus.offline;
  @override
  Future<IdentityState> inspect() async =>
      current == null ? IdentityState.none : IdentityState.ready;
  @override
  Future<Identity> open() async => current!;
  @override
  Future<void> connect() {
    connectCalls++;
    final error = connectError;
    if (error != null) throw error;
    return connectGate?.future ?? Future<void>.value();
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
  }

  void replace(Identity? value) {
    current = value;
    _changes.add(value);
  }

  Future<void> dispose() => _changes.close();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not stubbed');
}

class _Network extends FakeNetworkBootstrapService {
  int calls = 0;
  final disconnectedOnly = <bool>[];
  final guards = <bool Function()?>[];
  Object? error;
  Completer<void>? gate;

  @override
  Future<void> rebootstrap({
    bool onlyIfDisconnected = false,
    bool Function()? isCurrent,
  }) {
    calls++;
    disconnectedOnly.add(onlyIfDisconnected);
    guards.add(isCurrent);
    final failure = error;
    if (failure != null) throw failure;
    return gate?.future ?? Future<void>.value();
  }
}

void main() {
  late _Identity identity;
  late _Network network;
  late StartupController controller;
  late bool disposed;

  setUp(() {
    identity = _Identity();
    network = _Network();
    controller = StartupController(identity, networkBootstrap: network);
    disposed = false;
  });
  tearDown(() async {
    if (!disposed) controller.dispose();
    await identity.dispose();
    await network.dispose();
  });

  Future<void> start() async {
    await controller.ensureStarted();
    await Future<void>.delayed(Duration.zero);
  }

  test(
    'offline running session actually reapplies bootstrap on retry',
    () async {
      await start();
      expect(identity.connectCalls, 1);
      expect(network.calls, 0, reason: 'initial connect already bootstraps');
      await controller.reconnect();
      expect(identity.connectCalls, 2);
      expect(network.calls, 1);
      expect(network.disconnectedOnly, [true]);
      expect(network.guards.single!(), isTrue);
      expect(identity.disconnectCalls, 0);
      expect(controller.phase, StartupPhase.ready);
      expect(controller.connectionError, isNull);
    },
  );

  test('without an identity reconnect does nothing', () async {
    identity.current = null;
    await start();
    await controller.reconnect();
    expect(identity.connectCalls, 0);
    expect(network.calls, 0);
  });

  test('disposed controller cannot start another connection', () async {
    await start();
    controller.dispose();
    disposed = true;
    await controller.reconnect();
    expect(identity.connectCalls, 1);
    expect(network.calls, 0);
  });

  test('repeated reconnects share the in-flight recovery operation', () async {
    await start();
    network.gate = Completer<void>();
    final first = controller.reconnect();
    final second = controller.reconnect();
    expect(identical(first, second), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(identity.connectCalls, 2);
    expect(network.calls, 1);
    network.gate!.complete();
    await Future.wait([first, second]);
  });

  test(
    'bootstrap failure is visible and a successful retry clears it',
    () async {
      await start();
      final failure = StateError('bootstrap failed');
      network.error = failure;
      await controller.reconnect();
      expect(controller.connectionError, same(failure));
      network.error = null;
      await controller.reconnect();
      expect(controller.connectionError, isNull);
      expect(network.calls, 2);
    },
  );

  test(
    'failed initial connect can be retried without a latched operation',
    () async {
      final failure = StateError('start failed');
      identity.connectError = failure;
      await start();
      expect(controller.connectionError, same(failure));
      identity.connectError = null;
      await controller.reconnect();
      expect(controller.connectionError, isNull);
      expect(identity.connectCalls, 2);
      expect(network.calls, 1);
    },
  );

  test(
    'reconnect during initial start schedules one trailing bootstrap',
    () async {
      identity.connectGate = Completer<void>();
      await start();
      final first = controller.reconnect();
      final second = controller.reconnect();
      expect(identical(first, second), isTrue);
      expect(identity.connectCalls, 1);
      expect(network.calls, 0);
      identity.connectGate!.complete();
      await Future.wait([first, second]);
      expect(identity.connectCalls, 1);
      expect(network.calls, 1);
    },
  );

  test('dispose during connect prevents a later bootstrap', () async {
    await start();
    identity.connectGate = Completer<void>();
    final recovery = controller.reconnect();
    controller.dispose();
    disposed = true;
    identity.connectGate!.complete();
    await recovery;
    expect(network.calls, 0);
  });

  test(
    'replacement invalidates an in-flight recovery and its errors',
    () async {
      await start();
      network.gate = Completer<void>();
      final recovery = controller.reconnect();
      await Future<void>.delayed(Duration.zero);
      final guard = network.guards.single!;
      identity.replace(Identity(toxId: 'A' * 76, displayName: 'New identity'));
      expect(guard(), isFalse);
      network.gate!.completeError(StateError('old identity failure'));
      await recovery;
      expect(controller.connectionError, isNull);
      network.gate = null;
      await controller.reconnect();
      expect(network.calls, 2);
      expect(network.guards.last!(), isTrue);
    },
  );
}

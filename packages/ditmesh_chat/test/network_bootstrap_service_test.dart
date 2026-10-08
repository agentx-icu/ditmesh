import 'dart:async';

import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/bootstrap/bootstrap_runtime.dart';
import 'package:ditmesh_chat/src/bootstrap/network_bootstrap_service.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter_test/flutter_test.dart';

const _key = '7E5668E0EE09E19F320AD47902419331FFEE147BB3606769CFBE921A2A2FD34C';
const _node = BootstrapNode(
  host: '192.0.2.1',
  port: 33445,
  publicKey: _key,
  udpOnline: true,
);
const _lan = BootstrapNode(host: '192.168.1.5', port: 45500, publicKey: _key);

class _Runtime implements BootstrapRuntime {
  final applied = <BootstrapNode>[];
  BootstrapProbeVerdict verdict = BootstrapProbeVerdict.reachable;
  bool accepts = true;
  Future<bool> Function(BootstrapNode)? applyOverride;
  bool stops = true;
  bool live = true;
  bool online = false;
  Completer<BootstrapNode?>? startGate;
  int stopped = 0;
  int disposed = 0;
  @override
  bool get supportsLan => true;
  @override
  bool get hasSession => live;
  @override
  bool get isConnected => online;
  @override
  Future<bool> apply(BootstrapNode node, {bool Function()? isCurrent}) async {
    applied.add(node);
    return applyOverride == null ? accepts : await applyOverride!(node);
  }

  @override
  Future<BootstrapProbeVerdict> probe(BootstrapNode node) async => verdict;
  @override
  Future<BootstrapNode?> startLan(int port) async =>
      startGate == null ? _lan : await startGate!.future;
  @override
  Future<bool> stopLan() async {
    stopped++;
    return stops;
  }

  @override
  Future<void> dispose() async {
    disposed++;
    final gate = startGate;
    if (gate != null && !gate.isCompleted) gate.complete(null);
  }
}

class _BlockedStore extends MemoryKeyValueStore {
  String? blockKey;
  final entered = Completer<void>();
  final release = Completer<void>();
  Future<void> _block(String key) async {
    if (key != blockKey) return;
    blockKey = null;
    entered.complete();
    await release.future;
  }

  @override
  Future<void> setString(String key, String value) async {
    await _block(key);
    await super.setString(key, value);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await _block(key);
    await super.setBool(key, value);
  }
}

class _FailingStore extends MemoryKeyValueStore {
  String? failKey;
  @override
  Future<void> setString(String key, String value) async {
    if (key == failKey) {
      failKey = null;
      throw StateError('injected disk failure');
    }
    await super.setString(key, value);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    if (key == failKey) {
      failKey = null;
      throw StateError('injected disk failure');
    }
    await super.setBool(key, value);
  }
}

void main() {
  late _Runtime runtime;
  late MemoryKeyValueStore store;
  late Tim2ToxNetworkBootstrapService service;
  setUp(() async {
    runtime = _Runtime();
    store = MemoryKeyValueStore();
    service = Tim2ToxNetworkBootstrapService(
      store: store,
      runtime: runtime,
      fetchNodes: () async =>
          const BootstrapCatalogue(nodes: [_node], fromFallback: false),
    );
    await service.initialize();
  });
  tearDown(() => service.dispose());

  test('manual mode applies only chosen node and does not fetch', () async {
    await service.setMode(BootstrapMode.manual);
    await service.selectNode(_node);
    runtime.applied.clear();
    await service.rebootstrap();
    expect(runtime.applied, [_node]);
  });

  test('manual promotion requires a probe of the exact descriptor', () async {
    await service.setMode(BootstrapMode.manual);
    await expectLater(
      service.selectNode(_node, requireProbe: true),
      throwsA(isA<ChatException>()),
    );
    expect(await service.probe(_node), BootstrapProbeVerdict.reachable);
    await service.selectNode(_node, requireProbe: true);
    expect(service.configuration.current, _node);
    await expectLater(
      service.selectNode(
        const BootstrapNode(host: '192.0.2.2', port: 33445, publicKey: _key),
        requireProbe: true,
      ),
      throwsA(isA<ChatException>()),
    );
  });

  test(
    'local UDP limitation stays neutral and permits manual choice',
    () async {
      runtime.verdict = BootstrapProbeVerdict.udpUnavailable;
      expect(await service.probe(_node), BootstrapProbeVerdict.udpUnavailable);
      await service.selectNode(_node, requireProbe: true);
      expect(service.configuration.current, _node);
    },
  );

  test('native application failure preserves prior node', () async {
    await service.selectNode(_node);
    runtime.accepts = false;
    await expectLater(service.selectNode(_lan), throwsA(isA<ChatException>()));
    expect(service.configuration.current, _node);
  });

  test('LAN stop restores previous node and clears snapshot', () async {
    await service.selectNode(_node);
    await service.setMode(BootstrapMode.lan);
    await service.startLan(45500);
    expect(service.configuration.lanNode, _lan);
    expect(service.configuration.current, _lan);
    await service.stopLan();
    expect(service.configuration.current, _node);
    expect(service.configuration.lanNode, isNull);
    expect(store.getString('pre_lan_bootstrap_host'), isNull);
  });

  test(
    'failed restore keeps host alive and recovery snapshot for retry',
    () async {
      await service.selectNode(_node);
      await service.setMode(BootstrapMode.lan);
      await service.startLan(45500);
      runtime.accepts = false;
      await expectLater(service.stopLan(), throwsA(isA<ChatException>()));
      expect(service.configuration.lanNode, _lan);
      expect(store.getString('pre_lan_bootstrap_host'), _node.host);
      runtime.accepts = true;
    },
  );

  test(
    'pre-identity selection and LAN hosting do not need a chat session',
    () async {
      runtime.live = false;
      await service.selectNode(_node);
      await service.setMode(BootstrapMode.lan);
      await service.startLan(45500);
      expect(service.configuration.lanNode, _lan);
      await service.stopLan();
      expect(service.configuration.current, _node);
      expect(runtime.applied, isEmpty);
    },
  );

  for (final failure in [
    'current_bootstrap_host',
    'lan_bootstrap_service_running',
  ]) {
    test(
      'LAN persistence failure re-applies prior live node: $failure',
      () async {
        await service.dispose();
        final failingStore = _FailingStore();
        service = Tim2ToxNetworkBootstrapService(
          store: failingStore,
          runtime: runtime,
        );
        await service.initialize();
        await service.selectNode(_node);
        await service.setMode(BootstrapMode.lan);
        runtime.applied.clear();
        failingStore.failKey = failure;
        await expectLater(service.startLan(45500), throwsStateError);
        expect(runtime.applied, [_lan, _node]);
        expect(service.configuration.current, _node);
        expect(service.configuration.lanNode, isNull);
      },
    );
  }
  for (final throws in [false, true]) {
    test(
      'failed live LAN rollback retains recovery journal: throws=$throws',
      () async {
        await service.dispose();
        final failing = _FailingStore();
        service = Tim2ToxNetworkBootstrapService(
          store: failing,
          runtime: runtime,
        );
        await service.initialize();
        await service.selectNode(_node);
        await service.setMode(BootstrapMode.lan);
        failing.failKey = 'lan_bootstrap_service_running';
        runtime.applyOverride = (node) async {
          if (node == _node) {
            if (throws) throw StateError('temporary DNS failure');
            return false;
          }
          return true;
        };
        await expectLater(service.startLan(45500), throwsStateError);
        expect(failing.getString('pre_lan_bootstrap_host'), _node.host);
        expect(failing.getBool('lan_bootstrap_transition_pending'), isTrue);
        expect(service.configuration.current, _node);
        runtime.applyOverride = null;
        await service.stopLan();
        expect(failing.getString('pre_lan_bootstrap_host'), isNull);
        expect(failing.getBool('lan_bootstrap_transition_pending'), isNull);
      },
    );
  }

  test('selection persistence failure re-applies previous live node', () async {
    await service.dispose();
    final failingStore = _FailingStore();
    service = Tim2ToxNetworkBootstrapService(
      store: failingStore,
      runtime: runtime,
    );
    await service.initialize();
    await service.selectNode(_node);
    runtime.applied.clear();
    failingStore.failKey = 'current_bootstrap_host';
    await expectLater(service.selectNode(_lan), throwsStateError);
    expect(runtime.applied, [_lan, _node]);
    expect(service.configuration.current, _node);
  });
  test(
    'dispose cancels blocked native startup before awaiting operation queue',
    () async {
      await service.setMode(BootstrapMode.lan);
      runtime.startGate = Completer<BootstrapNode?>();
      final start = service.startLan(45500);
      final failure = expectLater(start, throwsA(isA<ChatException>()));
      await Future<void>.delayed(Duration.zero);
      await service.dispose().timeout(const Duration(milliseconds: 200));
      await failure;
      expect(service.configuration.lanNode, isNull);
    },
  );

  for (final write in [
    'current_bootstrap_host',
    'lan_bootstrap_service_running',
  ]) {
    test(
      'dispose during LAN metadata write cannot publish a stopped host: $write',
      () async {
        await service.dispose();
        final blocked = _BlockedStore();
        service = Tim2ToxNetworkBootstrapService(
          store: blocked,
          runtime: runtime,
        );
        await service.initialize();
        await service.selectNode(_node);
        await service.setMode(BootstrapMode.lan);
        blocked.blockKey = write;
        final failure = expectLater(
          service.startLan(45500),
          throwsA(isA<ChatException>()),
        );
        await blocked.entered.future;
        final disposedBefore = runtime.disposed;
        final disposal = service.dispose();
        await Future<void>.delayed(Duration.zero);
        expect(runtime.disposed, disposedBefore + 1);
        blocked.release.complete();
        await failure;
        await disposal;
        expect(service.configuration.lanNode, isNull);
        expect(service.configuration.current, _node);
        expect(blocked.getBool('lan_bootstrap_service_running'), isFalse);
        expect(blocked.getString('pre_lan_bootstrap_host'), isNull);
      },
    );
  }

  test(
    'dispose during native LAN application prevents metadata commit',
    () async {
      await service.selectNode(_node);
      await service.setMode(BootstrapMode.lan);
      final entered = Completer<void>();
      final release = Completer<bool>();
      runtime.applyOverride = (node) async {
        if (node == _lan) {
          entered.complete();
          return release.future;
        }
        return true;
      };
      final failure = expectLater(
        service.startLan(45500),
        throwsA(isA<ChatException>()),
      );
      await entered.future;
      final disposal = service.dispose();
      await Future<void>.delayed(Duration.zero);
      release.complete(true);
      await failure;
      await disposal;
      expect(service.configuration.lanNode, isNull);
      expect(service.configuration.current, _node);
      expect(store.getBool('lan_bootstrap_service_running'), isFalse);
    },
  );

  test(
    'automatic refresh cannot apply after switching to manual mode',
    () async {
      final gate = Completer<BootstrapCatalogue>();
      await service.dispose();
      service = Tim2ToxNetworkBootstrapService(
        store: store,
        runtime: runtime,
        fetchNodes: () => gate.future,
      );
      await service.initialize();
      final refresh = service.rebootstrap();
      await Future<void>.delayed(Duration.zero);
      await service.setMode(BootstrapMode.manual);
      runtime.applied.clear();
      gate.complete(
        const BootstrapCatalogue(nodes: [_node], fromFallback: false),
      );
      await refresh;
      expect(runtime.applied, isEmpty);
    },
  );
}

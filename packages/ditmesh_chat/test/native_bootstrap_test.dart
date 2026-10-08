@Tags(['needs-native'])
library;

import 'dart:async';
import 'dart:io';

import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/bootstrap/lan_bootstrap_host.dart';
import 'package:ditmesh_chat/src/bootstrap/node_probe.dart';
import 'package:ditmesh_chat/src/bootstrap/native_instance_scope.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ffi/ffi.dart' as alloc;
import 'package:flutter_test/flutter_test.dart';
import 'package:tim2tox_dart/ffi/tim2tox_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final override = Platform.environment['TIM2TOX_FFI_LIB'];
  NativeLibrarySetup.ensure(libraryPathOverride: override);
  final loadable = NativeLibrarySetup.isNativeLibraryLoadable;
  late Directory root;
  late LanBootstrapHost host;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('ditmesh_lan_native_');
    host = LanBootstrapHost(
      profileDirectory: '${root.path}/host',
      localAddress: () async => '127.0.0.1',
    );
  });
  tearDown(() async {
    if (loadable) await host.stop();
    await root.delete(recursive: true);
  });

  test(
    'real LAN node binds requested range and start/stop preserve default instance',
    () async {
      final ffi = Tim2ToxFfi.open();
      final before = ffi.getCurrentInstanceId();
      final node = await host.start(45500);
      expect(node, isNotNull);
      expect(node!.port, inInclusiveRange(45500, 45600));
      expect(node.publicKey, matches(RegExp(r'^[0-9A-F]{64}$')));
      expect(ffi.isInstanceInitialized(host.handle!), 1);
      expect(ffi.isInstanceEventLoopRunning(host.handle!), 1);
      expect(ffi.getCurrentInstanceId(), before);
      expect(await host.start(45500), node);
      final handle = host.handle!;
      expect(await host.stop(), isTrue);
      expect(ffi.isInstanceInitialized(handle), 0);
      expect(ffi.getCurrentInstanceId(), before);
      expect(host.node, isNull);
    },
    skip: !loadable,
  );

  test('LAN lifecycle preserves a separate current peer instance', () async {
    final ffi = Tim2ToxFfi.open();
    final previous = ffi.getCurrentInstanceId();
    final path = '${root.path}/peer'.toNativeUtf8();
    final peer = ffi.createTestInstanceExNative(path, 0, 1);
    alloc.malloc.free(path);
    expect(peer, isNot(0));
    try {
      expect(ffi.setCurrentInstance(peer), 1);
      expect(await host.start(45510), isNotNull);
      expect(ffi.getCurrentInstanceId(), peer);
      expect(await host.stop(), isTrue);
      expect(ffi.getCurrentInstanceId(), peer);
      expect(ffi.isInstanceInitialized(peer), 1);
    } finally {
      ffi.setCurrentInstance(previous);
      ffi.destroyTestInstance(peer);
    }
  }, skip: !loadable);

  test(
    'concurrent start shares one handle and cancellation releases late startup',
    () async {
      final gate = Completer<String?>();
      final delayed = LanBootstrapHost(
        profileDirectory: '${root.path}/delayed',
        localAddress: () => gate.future,
      );
      final first = delayed.start(45520);
      final second = delayed.start(45520);
      await delayed.stop();
      gate.complete('127.0.0.1');
      expect(await first, isNull);
      expect(await second, isNull);
      expect(delayed.handle, isNull);
    },
    skip: !loadable,
  );

  test(
    'real LAN host brings two isolated clients online without public bootstrap',
    () async {
      final ffi = Tim2ToxFfi.open();
      final previous = ffi.getCurrentInstanceId();
      final handles = <int>[];
      final probe = NativeNodeProbe(profileRoot: '${root.path}/live-probes');
      try {
        final node = (await host.start(45560))!;
        for (final name in ['first-client', 'second-client']) {
          final path = '${root.path}/$name'.toNativeUtf8();
          try {
            handles.add(ffi.createTestInstanceExNative(path, 0, 1));
          } finally {
            alloc.malloc.free(path);
            ffi.setCurrentInstance(previous);
          }
        }
        expect(handles, everyElement(isNot(0)));
        final deadline = DateTime.now().add(const Duration(seconds: 15));
        while (DateTime.now().isBefore(deadline)) {
          for (final handle in handles) {
            final address = node.host.toNativeUtf8();
            final key = node.publicKey.toNativeUtf8();
            try {
              expect(ffi.addBootstrapNode(handle, address, node.port, key), 1);
            } finally {
              alloc.malloc.free(address);
              alloc.malloc.free(key);
            }
          }
          if (handles.every(
            (handle) =>
                NativeInstanceScope.run(
                  ffi,
                  handle,
                  ffi.getSelfConnectionStatus,
                ) >
                0,
          )) {
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        // toxcore uses dht_non_lan_connected for its UDP self-status flag:
        // a localhost-only DHT can report1 even though this host has no TCP relay.
        // The fresh DHT probe below independently proves a real UDP response.
        expect(
          handles.map(
            (handle) => NativeInstanceScope.run(
              ffi,
              handle,
              ffi.getSelfConnectionStatus,
            ),
          ),
          everyElement(greaterThan(0)),
          reason: 'Online using only the local DHT host',
        );
        ffi.setCurrentInstance(handles.first);
        expect(await probe.probe(node), BootstrapProbeVerdict.reachable);
        expect(ffi.getCurrentInstanceId(), handles.first);
        expect(
          NativeInstanceScope.run(
            ffi,
            handles.first,
            ffi.getSelfConnectionStatus,
          ),
          greaterThan(0),
        );
        expect(
          NativeInstanceScope.run(
            ffi,
            handles.last,
            ffi.getSelfConnectionStatus,
          ),
          greaterThan(0),
        );
      } finally {
        await probe.dispose();
        ffi.setCurrentInstance(previous);
        for (final handle in handles) {
          if (handle != 0) NativeInstanceScope.destroy(ffi, handle);
        }
      }
    },
    skip: !loadable,
    timeout: const Timeout(Duration(seconds: 35)),
  );

  test(
    'dispose interrupts an active isolated probe without its ten-second timeout',
    () async {
      final probe = NativeNodeProbe(profileRoot: '${root.path}/cancel-probes');
      final pending = probe.probe(
        const BootstrapNode(
          host: '192.0.2.1',
          port: 33445,
          publicKey:
              '7E5668E0EE09E19F320AD47902419331FFEE147BB3606769CFBE921A2A2FD34C',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final timer = Stopwatch()..start();
      await probe.dispose();
      expect(timer.elapsed, lessThan(const Duration(seconds: 2)));
      expect(await pending, BootstrapProbeVerdict.unavailable);
    },
    skip: !loadable,
    timeout: const Timeout(Duration(seconds: 15)),
  );

  test(
    'isolated DHT probe distinguishes a real local node from wrong key',
    () async {
      final peer = LanBootstrapHost(
        profileDirectory: '${root.path}/neighbour',
        localAddress: () async => '127.0.0.1',
      );
      final probe = NativeNodeProbe(profileRoot: '${root.path}/probes');
      final ffi = Tim2ToxFfi.open();
      final previous = ffi.getCurrentInstanceId();
      try {
        final a = (await host.start(45530))!;
        final b = (await peer.start(45640))!;
        void prime(int handle, BootstrapNode node) {
          final address = node.host.toNativeUtf8();
          final key = node.publicKey.toNativeUtf8();
          try {
            expect(ffi.addBootstrapNode(handle, address, node.port, key), 1);
          } finally {
            alloc.malloc.free(address);
            alloc.malloc.free(key);
          }
        }

        prime(host.handle!, b);
        prime(peer.handle!, a);
        await Future<void>.delayed(const Duration(seconds: 3));
        expect(await probe.probe(a), BootstrapProbeVerdict.reachable);
        expect(
          await probe.probe(
            BootstrapNode(
              host: a.host,
              port: a.port,
              publicKey:
                  '7E5668E0EE09E19F320AD47902419331FFEE147BB3606769CFBE921A2A2FD34C',
            ),
            timeout: const Duration(seconds: 2),
          ),
          BootstrapProbeVerdict.unreachable,
        );
        expect(ffi.getCurrentInstanceId(), previous);
        expect(ffi.isInstanceInitialized(host.handle!), 1);
      } finally {
        await probe.dispose();
        await peer.stop();
      }
    },
    skip: !loadable,
    timeout: const Timeout(Duration(seconds: 35)),
  );
}

@Tags(['needs-native'])
library;

import 'dart:async';
import 'dart:io';
import 'dart:ffi' as dartffi;
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/adapters/bootstrap_adapter.dart';
import 'package:ditmesh_chat/src/adapters/prefs_adapter.dart';
import 'package:ditmesh_chat/src/bootstrap/lan_bootstrap_host.dart';
import 'package:ditmesh_chat/src/bootstrap/native_instance_scope.dart';
import 'package:ditmesh_chat/src/bootstrap/probe_session.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ffi/ffi.dart' as alloc;
import 'package:flutter_test/flutter_test.dart';
import 'package:tim2tox_dart/ffi/tim2tox_ffi.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  NativeLibrarySetup.ensure(
    libraryPathOverride: Platform.environment['TIM2TOX_FFI_LIB'],
  );
  final loadable = NativeLibrarySetup.isNativeLibraryLoadable;
  test(
    'a connected probe emits no broadcast conn events and never flips the live service',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'ditmesh_probe_isolation_',
      );
      final ffi = Tim2ToxFfi.open();
      final previous = ffi.getCurrentInstanceId();
      final path = '${root.path}/live'.toNativeUtf8();
      final handle = ffi.createTestInstanceExNative(path, 0, 1);
      alloc.malloc.free(path);
      expect(handle, isNot(0));
      ffi.setCurrentInstance(handle);
      final store = MemoryKeyValueStore();
      await store.setString('bootstrap_node_mode', 'manual');
      final live = FfiChatService(
        historyDirectory: '${root.path}/history',
        queueFilePath: '${root.path}/queue.json',
        fileRecvPath: '${root.path}/files',
        avatarsPath: '${root.path}/avatars',
        preferencesService: Tim2ToxPreferencesAdapter(
          store,
          accountPrefix: 'live',
        ),
        bootstrapService: Tim2ToxBootstrapAdapter(store),
      );
      final host = LanBootstrapHost(
        profileDirectory: '${root.path}/host',
        localAddress: () async => '127.0.0.1',
      );
      final neighbour = LanBootstrapHost(
        profileDirectory: '${root.path}/neighbour',
        localAddress: () async => '127.0.0.1',
      );
      NativeProbeSession? probe;
      StreamSubscription<bool>? sub;
      final changes = <bool>[];
      void bootstrap(int instance, BootstrapNode node) {
        final address = node.host.toNativeUtf8();
        final key = node.publicKey.toNativeUtf8();
        try {
          expect(ffi.addBootstrapNode(instance, address, node.port, key), 1);
        } finally {
          alloc.malloc.free(address);
          alloc.malloc.free(key);
        }
      }

      List<String> drainBroadcast() {
        final buffer = alloc.malloc.allocate<dartffi.Int8>(4096);
        final rows = <String>[];
        try {
          for (
            var n = ffi.pollText(0, buffer, 4096);
            n > 0;
            n = ffi.pollText(0, buffer, 4096)
          ) {
            rows.add(buffer.cast<alloc.Utf8>().toDartString(length: n));
          }
        } finally {
          alloc.malloc.free(buffer);
        }
        return rows;
      }

      Future<void> connectProbe(
        NativeProbeSession session,
        BootstrapNode node,
      ) async {
        final deadline = DateTime.now().add(const Duration(seconds: 15));
        while (NativeInstanceScope.run(
                  ffi,
                  session.handle,
                  ffi.getSelfConnectionStatus,
                ) ==
                0 &&
            DateTime.now().isBefore(deadline)) {
          bootstrap(session.handle, node);
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        expect(
          NativeInstanceScope.run(
            ffi,
            session.handle,
            ffi.getSelfConnectionStatus,
          ),
          greaterThan(0),
        );
      }

      try {
        await live.init(profileDirectory: '${root.path}/live');
        final a = (await host.start(45700))!;
        final b = (await neighbour.start(45810))!;
        bootstrap(host.handle!, b);
        bootstrap(neighbour.handle!, a);
        drainBroadcast();
        expect(ffi.getSelfConnectionStatus(), 0);
        probe = await NativeProbeSession.start('${root.path}/probes');
        await connectProbe(probe, a);
        expect(
          drainBroadcast().where((row) => row.startsWith('conn:')),
          isEmpty,
          reason:
              'Auxiliary probes must have no SDK/global connection listener',
        );
        await probe.dispose();
        probe = null;
        sub = live.connectionStatusStream.listen(changes.add);
        await live.startPolling();
        probe = await NativeProbeSession.start('${root.path}/probes');
        await connectProbe(probe, a);
        await Future<void>.delayed(const Duration(seconds: 1));
        expect(
          ffi.getSelfConnectionStatus(),
          0,
          reason: 'The live peer did not bootstrap',
        );
        expect(live.isConnected, isFalse);
        expect(changes.where((value) => value), isEmpty);
        expect(ffi.getCurrentInstanceId(), handle);
      } finally {
        await sub?.cancel();
        await probe?.dispose();
        await host.stop();
        await neighbour.stop();
        await live.dispose();
        ffi.setCurrentInstance(previous);
        NativeInstanceScope.destroy(ffi, handle);
        await root.delete(recursive: true);
      }
    },
    skip: !loadable,
    timeout: const Timeout(Duration(seconds: 45)),
  );
}

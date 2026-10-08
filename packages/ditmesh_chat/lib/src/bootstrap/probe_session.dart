import 'dart:async';
import 'dart:io';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ffi/ffi.dart' as alloc;
import 'package:tim2tox_dart/ffi/tim2tox_ffi.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

import '../util/posix_permissions.dart';
import 'host_resolver.dart';
import 'native_instance_scope.dart';

class NativeProbeSession {
  NativeProbeSession._(
    this.library,
    this.handle,
    this.directory,
    this.service,
    this.udpPort,
  );
  final Tim2ToxFfi library;
  final int handle;
  final Directory directory;
  final FfiChatService service;
  final int udpPort;
  int sendCount = 0;
  final _cancelled = Completer<void>();
  Timer? _retry;
  Timer? _deadline;
  void cancel() {
    _retry?.cancel();
    _deadline?.cancel();
    if (!_cancelled.isCompleted) _cancelled.complete();
  }

  final Set<DhtSendNodesRequestError> sendErrors = {};

  static Future<NativeProbeSession> start(String root) async {
    await PosixPermissions.createPrivateDirectory(root);
    final dir = await Directory(root).createTemp('probe-');
    final library = Tim2ToxFfi.open();
    final path = dir.path.toNativeUtf8();
    final previous = library.getCurrentInstanceId();
    int handle = 0;
    try {
      try {
        // DitMesh's reviewed native overlay reserves -1 on the headless creator
        // for private probes: discovery disabled, default UDP range, no SDK
        // or process-wide chat listeners. C/Dart use signed int/Int32 here.
        handle = library.createBootstrapInstanceNative(path, -1);
      } finally {
        alloc.malloc.free(path);
        library.setCurrentInstance(previous);
      }
      if (handle == 0) throw StateError('Could not create isolated probe');
      return NativeProbeSession._(
        library,
        handle,
        dir,
        FfiChatService(
          historyDirectory: dir.path,
          queueFilePath: '${dir.path}/queue.json',
          fileRecvPath: '${dir.path}/files',
          avatarsPath: '${dir.path}/avatars',
        ),
        library.getUdpPort(handle),
      );
    } on Object {
      if (handle != 0) NativeInstanceScope.destroy(library, handle);
      await dir.delete(recursive: true);
      rethrow;
    }
  }

  Future<bool> awaitResponse(BootstrapNode node, Duration timeout) async {
    final finished = Completer<bool>();
    _deadline = Timer(timeout, () {
      if (!finished.isCompleted) finished.complete(false);
    });
    unawaited(
      _cancelled.future.then((_) {
        if (!finished.isCompleted) finished.complete(false);
      }),
    );
    // One deadline covers DNS, alternate addresses and the DHT exchange.
    final addresses = await Future.any<List<String>>([
      Future.wait(
        node.hosts.map(
          (host) => BootstrapHostResolver(timeout: timeout).addresses(host),
        ),
      ).then((values) => values.expand((value) => value).toSet().toList()),
      finished.future.then((_) => <String>[]),
    ]);
    if (finished.isCompleted) return finished.future;
    if (addresses.isEmpty) {
      sendErrors.add(DhtSendNodesRequestError.badIp);
      _deadline?.cancel();
      return false;
    }
    NativeInstanceScope.run(
      library,
      handle,
      () => service.setDhtNodesResponseCallback((_, _, _) {
        if (!finished.isCompleted) finished.complete(true);
      }),
    );
    void send() {
      if (_cancelled.isCompleted || finished.isCompleted) return;
      for (final address in addresses) {
        try {
          final error = NativeInstanceScope.run(
            library,
            handle,
            () => service.dhtSendNodesRequestChecked(
              node.publicKey,
              address,
              node.port,
              node.publicKey,
            ),
          );
          if (error == null) {
            sendCount++;
          } else {
            sendErrors.add(error);
          }
        } on Object {
          sendErrors.add(DhtSendNodesRequestError.notReady);
        }
      }
    }

    try {
      send();
      _retry = Timer.periodic(const Duration(seconds: 1), (_) => send());
      return await finished.future;
    } finally {
      _retry?.cancel();
      _deadline?.cancel();
    }
  }

  Future<void> dispose() async {
    cancel();
    try {
      NativeInstanceScope.run(
        library,
        handle,
        service.clearDhtNodesResponseCallback,
      );
    } finally {
      NativeInstanceScope.destroy(library, handle);
      if (await directory.exists()) await directory.delete(recursive: true);
    }
  }
}

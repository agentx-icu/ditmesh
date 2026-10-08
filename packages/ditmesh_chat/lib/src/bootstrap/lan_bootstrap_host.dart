import 'dart:async';
import 'dart:ffi' as ffi;

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:ffi/ffi.dart' as alloc;
import 'package:tim2tox_dart/ffi/tim2tox_ffi.dart';

import '../logging/chat_logger.dart';
import '../util/posix_permissions.dart';
import 'lan_addresses.dart';
import 'native_instance_scope.dart';

/// In-process, headless UDP/DHT host; no SDK listeners or TCP relay server.
class LanBootstrapHost {
  LanBootstrapHost({
    required this.profileDirectory,
    Future<String?> Function()? localAddress,
    this.startupTimeout = const Duration(seconds: 30),
    ChatLogger logger = const SilentChatLogger(),
  }) : _localAddress = localAddress ?? LanAddresses.getLocalIPAddress,
       _logger = logger;
  final String profileDirectory;
  final Future<String?> Function() _localAddress;
  final Duration startupTimeout;
  final ChatLogger _logger;
  Tim2ToxFfi? _library;
  int? _handle;
  BootstrapNode? _node;
  int _generation = 0;
  Completer<BootstrapNode?>? _pending;
  int? get handle => _handle;
  BootstrapNode? get node => _node;

  Future<BootstrapNode?> start(int port) {
    if (port < 1 || port > 65535) return Future.value(null);
    if (_node != null) return Future.value(_node);
    if (_pending != null) return _pending!.future;
    final pending = Completer<BootstrapNode?>();
    _pending = pending;
    final generation = ++_generation;
    unawaited(
      _runStart(port, generation).then((node) {
        if (!pending.isCompleted) pending.complete(node);
        if (identical(_pending, pending)) _pending = null;
      }),
    );
    return pending.future;
  }

  Future<BootstrapNode?> _runStart(int port, int generation) async {
    try {
      final ip = await _localAddress().timeout(startupTimeout);
      if (ip == null || generation != _generation) return null;
      await PosixPermissions.createPrivateDirectory(profileDirectory);
      if (generation != _generation) return null;
      final library = _library = Tim2ToxFfi.open();
      final path = profileDirectory.toNativeUtf8();
      final previous = library.getCurrentInstanceId();
      final int nativeHandle;
      try {
        nativeHandle = library.createBootstrapInstanceNative(path, port);
      } finally {
        alloc.malloc.free(path);
        library.setCurrentInstance(previous);
      }
      if (nativeHandle == 0) return null;
      _handle = nativeHandle;
      if (library.isInstanceInitialized(nativeHandle) != 1) {
        throw StateError('LAN node did not initialize');
      }
      final actualPort = library.getUdpPort(nativeHandle);
      final buffer = alloc.malloc.allocate<ffi.Int8>(65);
      final String key;
      try {
        final length = library.getDhtIdForInstanceNative(
          nativeHandle,
          buffer,
          65,
        );
        if (length != 64) throw StateError('LAN DHT key is unavailable');
        key = buffer.cast<alloc.Utf8>().toDartString(length: length);
      } finally {
        alloc.malloc.free(buffer);
      }
      final node = BootstrapNode(host: ip, port: actualPort, publicKey: key);
      if (!node.isValid) throw StateError('LAN node info is unavailable');
      _node = node;
      _logger.info('[Bootstrap] LAN node started at ${node.endpoint}');
      return node;
    } on Object catch (error, stack) {
      _logger.error('[Bootstrap] LAN startup failed', error, stack);
      if (generation == _generation) await stop();
      return null;
    }
  }

  Future<bool> stop() async {
    _generation++;
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(null);
    final owned = _handle;
    if (owned != null) {
      try {
        if (!NativeInstanceScope.destroy(_library!, owned)) return false;
      } on Object catch (error, stack) {
        _logger.error('[Bootstrap] LAN teardown failed', error, stack);
        return false;
      }
    }
    _handle = null;
    _node = null;
    return true;
  }
}

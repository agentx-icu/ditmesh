import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// A process owns the app's whole support directory before opening any store.
///
/// The lock file is deliberately never removed: unlinking it could let another
/// process lock a different inode. A crash releases the OS lock and socket.
/// Only the current owner writes activation metadata, under the process lock.
final class DesktopInstance {
  DesktopInstance._(this._lock, this._server, this._token) {
    _server.listen(_receiveActivation);
  }

  final RandomAccessFile _lock;
  final ServerSocket _server;
  final String _token;
  Future<void> Function()? _onActivate;
  bool _activationPending = false;
  bool _closed = false;

  /// Installs the window callback after shell startup, preserving early taps.
  set onActivate(Future<void> Function()? callback) {
    _onActivate = callback;
    if (_activationPending && callback != null) {
      _activationPending = false;
      unawaited(_activate());
    }
  }

  /// Returns null for a secondary process, after requesting owner activation.
  /// An unexpected filesystem/socket failure throws; callers must fail closed.
  static Future<DesktopInstance?> acquire(Directory root) async {
    await root.create(recursive: true);
    final lock = await File(
      '${root.path}/.desktop.lock',
    ).open(mode: FileMode.append);
    final endpoint = File('${root.path}/.desktop-activation.json');
    try {
      await lock.lock(FileLock.exclusive);
    } on FileSystemException {
      await lock.close();
      await _notifyOwner(endpoint);
      return null;
    }
    ServerSocket? server;
    try {
      server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final random = Random.secure();
      final token = List.generate(
        32,
        (_) => random.nextInt(256),
      ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
      await endpoint.writeAsString(
        jsonEncode({'port': server.port, 'token': token}),
        flush: true,
      );
      return DesktopInstance._(lock, server, token);
    } on Object {
      await server?.close();
      await lock.close();
      rethrow;
    }
  }

  static Future<void> _notifyOwner(File endpoint) async {
    // A second launch may arrive between the owner's lock and socket setup.
    for (var attempt = 0; attempt < 20; attempt++) {
      Socket? socket;
      try {
        final data = jsonDecode(await endpoint.readAsString());
        if (data is! Map<String, dynamic> ||
            data['port'] is! int ||
            data['token'] is! String) {
          throw const FormatException('Invalid activation endpoint');
        }
        socket = await Socket.connect(
          InternetAddress.loopbackIPv4,
          data['port'] as int,
          timeout: const Duration(milliseconds: 200),
        );
        socket.writeln(data['token']);
        await socket.flush();
        final response = await socket
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .first
            .timeout(const Duration(seconds: 2));
        if (response == 'ok') return;
      } on Object {
        // A stale endpoint is expected during owner replacement after a crash.
      } finally {
        socket?.destroy();
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _receiveActivation(Socket socket) async {
    try {
      final bytes = <int>[];
      await for (final chunk in socket.timeout(const Duration(seconds: 2))) {
        bytes.addAll(chunk);
        if (bytes.length > 128) return;
        if (!bytes.contains(10)) continue;
        if (utf8.decode(bytes).trim() != _token) return;
        if (_onActivate == null) {
          _activationPending = true;
        } else {
          await _activate();
        }
        socket.writeln('ok');
        await socket.flush();
        return;
      }
    } on Object {
      // Activation is optional; a local client must never take the owner down.
    } finally {
      socket.destroy();
    }
  }

  Future<void> _activate() async {
    try {
      await _onActivate?.call();
    } on Object {
      // Keep ownership if a window backend temporarily refuses activation.
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _server.close();
    await _lock.close();
  }
}

import 'dart:async';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

import 'probe_session.dart';

/// A candidate's DHT response, not tox_bootstrap's argument-acceptance boolean.
/// Each query owns a fresh instance with LAN discovery disabled and no saved nodes.
class NativeNodeProbe {
  NativeNodeProbe({required this.profileRoot});
  final String profileRoot;
  // Serialize across service instances because native callback routing is global.
  static Future<void> _queue = Future<void>.value();
  bool _disposed = false;
  NativeProbeSession? _active;
  Future<BootstrapProbeVerdict> probe(
    BootstrapNode node, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    if (!node.isValid) return Future.value(BootstrapProbeVerdict.invalid);
    final completed = Completer<BootstrapProbeVerdict>();
    _queue = _queue.then((_) async {
      if (_disposed) {
        completed.complete(BootstrapProbeVerdict.unavailable);
        return;
      }
      NativeProbeSession? session;
      try {
        session = await NativeProbeSession.start(profileRoot);
        _active = session;
        if (_disposed) {
          completed.complete(BootstrapProbeVerdict.unavailable);
          return;
        }
        if (session.udpPort == 0) {
          completed.complete(BootstrapProbeVerdict.udpUnavailable);
          return;
        }
        final answered = await session.awaitResponse(node, timeout);
        completed.complete(
          _disposed
              ? BootstrapProbeVerdict.unavailable
              : verdictFor(
                  answered: answered,
                  sendCount: session.sendCount,
                  sendErrors: session.sendErrors,
                ),
        );
      } on Object {
        completed.complete(BootstrapProbeVerdict.unavailable);
      } finally {
        _active = null;
        // Cleanup failure must not poison the process-wide serialization queue.
        try {
          await session?.dispose();
        } on Object {
          /* Already retired. */
        }
      }
    });
    return completed.future;
  }

  static BootstrapProbeVerdict verdictFor({
    required bool answered,
    required int sendCount,
    required Set<DhtSendNodesRequestError> sendErrors,
  }) {
    if (answered) return BootstrapProbeVerdict.reachable;
    if (sendCount > 0) return BootstrapProbeVerdict.unreachable;
    final descriptorOnly =
        sendErrors.isNotEmpty &&
        sendErrors.every((error) => error.isDescriptorProblem);
    return descriptorOnly
        ? BootstrapProbeVerdict.unreachable
        : BootstrapProbeVerdict.udpUnavailable;
  }

  Future<void> dispose() async {
    _disposed = true;
    _active?.cancel();
    await _queue;
  }
}

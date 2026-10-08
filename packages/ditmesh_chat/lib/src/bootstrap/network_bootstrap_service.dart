import 'dart:async';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../adapters/key_value_store.dart';
import '../logging/chat_logger.dart';
import 'bootstrap_runtime.dart';
import 'bootstrap_settings.dart';
import 'node_catalogue.dart';

/// Node policy independent of UI and native handles. The runtime owns sockets.
class Tim2ToxNetworkBootstrapService implements NetworkBootstrapService {
  Tim2ToxNetworkBootstrapService({
    required KeyValueStore store,
    required BootstrapRuntime runtime,
    Future<BootstrapCatalogue> Function()? fetchNodes,
    ChatLogger logger = const SilentChatLogger(),
  }) : _settings = BootstrapSettings(store),
       _runtime = runtime,
       _fetch = fetchNodes ?? NodeCatalogue().fetch,
       _logger = logger;

  final BootstrapSettings _settings;
  final BootstrapRuntime _runtime;
  final Future<BootstrapCatalogue> Function() _fetch;
  final ChatLogger _logger;
  final _changes = StreamController<BootstrapConfiguration>.broadcast(
    sync: true,
  );
  final Map<String, BootstrapProbeVerdict> _probes = {};
  BootstrapNode? _lanNode;
  bool _disposed = false;
  int _generation = 0;
  Future<void> _operations = Future<void>.value();

  Future<void> initialize() async {
    // Pure prefs recovery before any native chat init reads the saved node.
    await _settings.recoverLan();
    if (!_runtime.supportsLan && _settings.mode == BootstrapMode.lan) {
      await _settings.setMode(BootstrapMode.auto);
    }
    if (_settings.mode == BootstrapMode.auto && _settings.current == null) {
      await _settings.setCurrent(NodeCatalogue.fallback.first);
    }
  }

  @override
  BootstrapConfiguration get configuration => BootstrapConfiguration(
    mode: _settings.mode,
    current: _settings.current,
    lanNode: _lanNode,
    lanPort: _settings.lanPort,
    supportsLan: _runtime.supportsLan,
  );
  @override
  Stream<BootstrapConfiguration> get changes => _changes.stream;
  void _publish() {
    if (!_changes.isClosed) _changes.add(configuration);
  }

  void sessionStopped() {
    _generation++;
  }

  bool _live(int generation, bool Function()? isCurrent) =>
      !_disposed && generation == _generation && (isCurrent?.call() ?? true);

  Future<void> sessionStarted() async {
    final generation = ++_generation;
    if (_settings.mode == BootstrapMode.auto) {
      await _apply(NodeCatalogue.fallback, generation);
      unawaited(_refreshAuto(generation));
    }
  }

  @override
  Future<BootstrapCatalogue> loadNodes() => _fetch();

  @override
  Future<BootstrapProbeVerdict> probe(BootstrapNode node) async {
    if (!node.isValid) return BootstrapProbeVerdict.invalid;
    if (_disposed) return BootstrapProbeVerdict.unavailable;
    BootstrapProbeVerdict verdict;
    try {
      verdict = await _runtime.probe(node);
    } on Object catch (error, stack) {
      _logger.error('[Bootstrap] probe unavailable', error, stack);
      verdict = BootstrapProbeVerdict.unavailable;
    }
    if (!_disposed) _probes[node.id] = verdict;
    return verdict;
  }

  Future<void> _serial(Future<void> Function() action) {
    final next = _operations.then((_) async {
      if (_disposed) {
        throw const ChatException(
          'bootstrap_unavailable',
          'Network settings are closed',
        );
      }
      await action();
    });
    _operations = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  @override
  Future<void> selectNode(
    BootstrapNode node, {
    bool requireProbe = false,
  }) => _serial(() async {
    if (!node.isValid) {
      throw const ChatException('bootstrap_invalid', 'Invalid node descriptor');
    }
    if (requireProbe && !(_probes[node.id]?.permitsSelection ?? false)) {
      throw const ChatException(
        'bootstrap_not_tested',
        'Probe this exact node before selecting',
      );
    }
    final generation = ++_generation;
    final prior = _settings.current;
    if (_runtime.hasSession &&
        !await _runtime.apply(node, isCurrent: () => _live(generation, null))) {
      throw const ChatException(
        'bootstrap_apply_failed',
        'Could not apply node',
      );
    }
    if (!_live(generation, null)) return;
    try {
      await _settings.setCurrent(node);
    } on Object {
      if (!await _rollback(prior, generation)) {
        throw const ChatException(
          'bootstrap_restore_failed',
          'Could not restore previous live node',
        );
      }
      rethrow;
    }
    _publish();
  });

  @override
  Future<void> setMode(BootstrapMode mode) => _serial(() async {
    if (mode == BootstrapMode.lan && !_runtime.supportsLan) {
      throw const ChatException(
        'bootstrap_lan_unsupported',
        'LAN hosting requires desktop',
      );
    }
    if (_settings.mode == BootstrapMode.lan && mode != BootstrapMode.lan) {
      await _stopLan();
    }
    _generation++;
    await _settings.setMode(mode);
    if (mode == BootstrapMode.auto && _settings.current == null) {
      await _settings.setCurrent(NodeCatalogue.fallback.first);
    }
    _publish();
    if (mode == BootstrapMode.auto) unawaited(_refreshAuto(_generation));
  });

  @override
  Future<void> startLan(int port) => _serial(() async {
    if (!_runtime.supportsLan || _settings.mode != BootstrapMode.lan) {
      throw const ChatException(
        'bootstrap_lan_unsupported',
        'Select desktop LAN mode first',
      );
    }
    if (port < 1 || port > 65535) {
      throw const ChatException('bootstrap_invalid', 'Invalid UDP port');
    }
    if (_lanNode != null) return;
    final generation = ++_generation;
    await _settings.setPort(port);
    await _settings.stageLan();
    void requireCurrent() {
      if (!_live(generation, null)) {
        throw const ChatException(
          'bootstrap_lan_cancelled',
          'LAN startup was cancelled',
        );
      }
    }

    try {
      final node = await _runtime.startLan(port);
      if (node == null || !_live(generation, null)) {
        throw const ChatException(
          'bootstrap_lan_failed',
          'Could not start LAN node',
        );
      }
      if (_runtime.hasSession &&
          !await _runtime.apply(
            node,
            isCurrent: () => _live(generation, null),
          )) {
        throw const ChatException(
          'bootstrap_apply_failed',
          'Could not apply LAN node',
        );
      }
      requireCurrent();
      await _settings.setCurrent(node);
      requireCurrent();
      await _settings.setLanRunning(true);
      requireCurrent();
      _lanNode = node;
      _publish();
    } on Object {
      if (await _runtime.stopLan()) {
        if (await _rollback(_settings.preLan, generation)) {
          await _settings.clearLanJournal();
        }
      }
      rethrow;
    }
  });

  Future<bool> _rollback(BootstrapNode? prior, int generation) async {
    var restored = true;
    if (prior != null && _runtime.hasSession && _live(generation, null)) {
      try {
        restored = await _runtime.apply(
          prior,
          isCurrent: () => _live(generation, null),
        );
      } on Object catch (error, stack) {
        restored = false;
        _logger.error('[Bootstrap] live rollback failed', error, stack);
      }
    }
    await _settings.setCurrent(prior);
    if (!restored) {
      _logger.warn(
        '[Bootstrap] live rollback deferred; recovery state retained',
      );
    }
    return restored;
  }

  @override
  Future<void> stopLan() => _serial(_stopLan);
  Future<void> _stopLan() async {
    if (_lanNode == null && !_settings.lanPending && !_settings.lanRunning) {
      return;
    }
    final prior = _settings.preLan;
    final generation = ++_generation;
    if (prior != null &&
        _runtime.hasSession &&
        !await _runtime.apply(
          prior,
          isCurrent: () => _live(generation, null),
        )) {
      throw const ChatException(
        'bootstrap_restore_failed',
        'Could not restore previous node',
      );
    }
    // Restore before destroying the service. A failure retains the journal.
    await _settings.setCurrent(prior);
    if (!await _runtime.stopLan()) {
      throw const ChatException(
        'bootstrap_lan_failed',
        'Could not stop LAN node',
      );
    }
    _lanNode = null;
    await _settings.clearLanJournal();
    _publish();
  }

  Future<void> _apply(
    Iterable<BootstrapNode> nodes,
    int generation, {
    bool Function()? isCurrent,
  }) async {
    for (final node in nodes.take(4)) {
      if (!_live(generation, isCurrent) || !_runtime.hasSession) return;
      try {
        await _runtime.apply(
          node,
          isCurrent: () => _live(generation, isCurrent),
        );
      } on Object catch (error, stack) {
        _logger.error('[Bootstrap] node application failed', error, stack);
      }
    }
  }

  Future<void> _refreshAuto(
    int generation, {
    bool Function()? isCurrent,
  }) async {
    try {
      final catalogue = await _fetch();
      if (!_live(generation, isCurrent) ||
          _settings.mode != BootstrapMode.auto) {
        return;
      }
      final online = catalogue.nodes
          .where((node) => node.online && node.isValid)
          .toList();
      await _apply(
        online.isEmpty ? catalogue.nodes.where((node) => node.isValid) : online,
        generation,
        isCurrent: isCurrent,
      );
    } on Object catch (error, stack) {
      _logger.error('[Bootstrap] catalogue refresh failed', error, stack);
    }
  }

  @override
  Future<void> rebootstrap({
    bool onlyIfDisconnected = false,
    bool Function()? isCurrent,
  }) async {
    if (_disposed ||
        !_runtime.hasSession ||
        (onlyIfDisconnected && _runtime.isConnected)) {
      return;
    }
    final generation = _generation;
    final saved = _settings.current;
    if (saved != null) await _apply([saved], generation, isCurrent: isCurrent);
    if (!_live(generation, isCurrent) || _settings.mode != BootstrapMode.auto) {
      return;
    }
    await _apply(NodeCatalogue.fallback, generation, isCurrent: isCurrent);
    await _refreshAuto(generation, isCurrent: isCurrent);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    await _runtime.dispose();
    await _operations;
    await _changes.close();
  }
}

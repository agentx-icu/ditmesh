import 'dart:async';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:tim2tox_dart/service/ffi_chat_service.dart';

import '../adapters/bootstrap_adapter.dart';
import '../adapters/bootstrap_nodes.dart';
import '../adapters/key_value_store.dart';
import '../adapters/prefs_adapter.dart';
import '../adapters/scratch_file_adapter.dart';
import '../bootstrap/host_resolver.dart';
import '../identity/identity_paths.dart';
import '../logging/chat_logger.dart';
import '../native/native_library.dart';
import '../util/value_stream.dart';
import 'ditmesh_ffi_chat_service.dart';
import 'native_callbacks.dart';

/// Everything a Tim2Tox session needs to know about the identity it serves.
class EngineSessionConfig {
  const EngineSessionConfig({
    required this.paths,
    required this.toxId,
    required this.displayName,
    required this.statusMessage,
    this.profilePassphrase,
  });

  final IdentityPaths paths;
  final String toxId;
  final String displayName;
  final String statusMessage;

  /// The identity's password, or null for an unprotected one. Native
  /// Tim2Tox opens the encrypted profile with it and encrypts every save, so
  /// `tox_profile.tox` is never plaintext on disk — not while running, not
  /// while backgrounded, not after a crash.
  final String? profilePassphrase;

  /// First 16 hex chars of the Tox ID: the preferences scope (toxee's
  /// convention).
  String get accountPrefix =>
      toxId.length >= 16 ? toxId.substring(0, 16).toUpperCase() : toxId;
}

/// The running Tim2Tox node, or the absence of one.
///
/// `IdentityService.connect()` starts it, `disconnect()` stops it, and the
/// chat service follows [sessionChanges] to bind to whichever
/// `FfiChatService` is live. The interface exists so the identity state
/// machine can be tested with a fake that never touches the native library.
abstract class ChatEngine {
  /// The live service, or null while stopped.
  FfiChatService? get service;

  /// Emits the new service on start and null on stop; replays the current one.
  Stream<FfiChatService?> get sessionChanges;

  /// Tox DHT connectivity of the live service (false while stopped).
  bool get isConnected;
  Stream<bool> get connectionChanges;

  /// Generates a fresh Tox profile in `paths.profileDirectory`, applies the
  /// name/status, saves it, and returns the 76-hex Tox ID. Leaves no running
  /// instance behind (the same "bootstrap instance" trick toxee's
  /// `registerNewAccount` uses). With a [passphrase] the profile is written
  /// encrypted from its very first save.
  Future<String> createProfile({
    required IdentityPaths paths,
    required String displayName,
    required String statusMessage,
    String? passphrase,
  });

  /// Re-keys the running profile to [passphrase] (null: plaintext) and
  /// writes it. False when nothing runs or the write failed; the profile on
  /// disk then still carries the previous passphrase.
  bool rekeyProfilePassphrase(String? passphrase);

  /// init → login → self profile → startPolling → group identity sync.
  Future<void> start(EngineSessionConfig config);

  /// Flush + uninit. Safe when already stopped. Completes with
  /// `ChatException('teardown_unconfirmed')` when the native teardown did not
  /// confirm (see [nativeTeardownConfirmed]); every teardown step still runs.
  Future<void> stop();

  /// False after a teardown ([stop], a failed [start], [createProfile]) whose
  /// native instance could not be confirmed stopped: the dispose threw, or
  /// Tim2Tox quarantined the instance because a background task outlived
  /// the drain window. Such a task — the profile-save path included — can
  /// still write into the profile directory, so nothing may snapshot,
  /// replace, re-encrypt or delete that directory until a later teardown
  /// confirms (or the process restarts). True initially.
  bool get nativeTeardownConfirmed => true;

  /// Re-applies the name/status to the running instance, if any.
  Future<void> updateSelfProfile(String displayName, String statusMessage);

  /// Forces Tox savedata to disk now (before an export, before backgrounding).
  void saveProfileNow();

  /// Await the host's suspension barrier, including debounced history/queue.
  Future<void> persist() async {
    saveProfileNow();
    final current = service;
    if (current == null) return;
    await current.messageHistoryPersistence.flushPendingSaves();
    await current.offlineMessageQueuePersistence.flushPendingMutations();
  }

  Future<void> dispose();
}

/// The real thing: one `FfiChatService` per started session.
///
/// A fresh service object per session (rather than re-initialising one
/// object) keeps every stream controller fresh: `FfiChatService.dispose`
/// closes its object-lifetime controllers and does not recreate them.
class Tim2ToxEngine extends ChatEngine {
  Tim2ToxEngine({
    required KeyValueStore store,
    required ChatLogger logger,
    String? libraryPathOverride,
    this.onBootstrapStart,
    this.onBootstrapStop,
  }) : _store = store,
       _logger = logger,
       _libraryPathOverride = libraryPathOverride;

  /// V2TIM login alias Tim2Tox stamps on our own rows (`fromUserId`,
  /// `isSelf`). Never leaves the device; the wire identity is the Tox key.
  static const String loginAlias = 'ditmesh';

  final KeyValueStore _store;
  final ChatLogger _logger;
  final String? _libraryPathOverride;
  final Future<void> Function()? onBootstrapStart;
  final void Function()? onBootstrapStop;

  /// ditmesh's owner of the SDK's process-global custom-callback hook.
  late final NativeCustomCallbacks _callbacks = NativeCustomCallbacks(_logger);

  FfiChatService? _service;
  StreamSubscription<bool>? _connSub;
  IdentityScratchFileService? _scratch;
  final ValueStream<FfiChatService?> _sessions = ValueStream(null);
  final ValueStream<bool> _connected = ValueStream(false);
  // Completion of the last stop(); never fails (start() waits on it).
  Future<void>? _stopping;
  bool _teardownConfirmed = true;

  @override
  FfiChatService? get service => _service;

  @override
  bool get nativeTeardownConfirmed => _teardownConfirmed;

  /// Disposes [svc] and records whether native ownership provably ended.
  /// Returns the failure to report (null when confirmed); never throws.
  Future<ChatException?> _teardown(FfiChatService svc, String what) async {
    Object? error;
    try {
      await svc.dispose();
    } catch (e, st) {
      error = e;
      _logger.error('[Tim2ToxEngine] $what: dispose failed', e, st);
    }
    // Tim2Tox publishes this before deciding between uninit and quarantine;
    // "dispose did not throw" alone does not rule out a live instance.
    final confirmed = error == null && svc.nativeInstanceStopped == true;
    _teardownConfirmed = confirmed;
    if (confirmed) return null;
    _logger.error(
      '[Tim2ToxEngine] $what: native teardown unconfirmed '
      '(stopped=${svc.nativeInstanceStopped}); the profile directory stays '
      'locked until a later teardown confirms',
    );
    return ChatException(
      'teardown_unconfirmed',
      error == null
          ? 'The Tox session did not stop in time'
          : 'The Tox session failed to stop: $error',
    );
  }

  @override
  Stream<FfiChatService?> get sessionChanges => _sessions.stream;

  @override
  bool get isConnected => _connected.value;

  @override
  Stream<bool> get connectionChanges => _connected.stream;

  FfiChatService _build(IdentityPaths paths, String accountPrefix) {
    NativeLibrarySetup.ensure(libraryPathOverride: _libraryPathOverride);
    final scratch = IdentityScratchFileService(paths.scratchDirectory);
    _scratch = scratch;
    final resolver = BootstrapHostResolver();
    final resolved = <String, Future<String?>>{};
    Future<String?> numericHost(String host) =>
        resolved.putIfAbsent(host, () async {
          final addresses = await resolver.addresses(host);
          return addresses.isEmpty ? null : addresses.first;
        });
    return DitmeshFfiChatService(
      preferencesService: Tim2ToxPreferencesAdapter(
        _store,
        accountPrefix: accountPrefix,
        resolveBootstrapHost: numericHost,
        persistBootstrapSelection: false,
      ),
      loggerService: Tim2ToxLoggerAdapter(_logger),
      bootstrapService: Tim2ToxBootstrapAdapter(
        _store,
        resolveHost: numericHost,
      ),
      historyDirectory: paths.historyDirectory,
      queueFilePath: paths.offlineQueueFile,
      fileRecvPath: paths.fileRecvDirectory,
      avatarsPath: paths.avatarsDirectory,
      scratchFileService: scratch,
    );
  }

  /// Stages [passphrase] for the next native init (single use; null clears
  /// whatever an abandoned start may have staged).
  void _stagePassphrase(FfiChatService svc, String? passphrase) {
    final staged = svc.setProfilePassphrase(passphrase);
    if (!staged && passphrase != null && passphrase.isNotEmpty) {
      throw const ChatException(
        'encryption_unavailable',
        'The native library cannot encrypt the profile',
      );
    }
  }

  @override
  Future<String> createProfile({
    required IdentityPaths paths,
    required String displayName,
    required String statusMessage,
    String? passphrase,
  }) async {
    await paths.ensureDirectories();
    // No Tox ID yet, so no scope: this instance persists nothing but the
    // savedata and is torn down before the real session opens.
    final svc = _build(paths, '');
    final String toxId;
    try {
      _stagePassphrase(svc, passphrase);
      await svc.init(profileDirectory: paths.profileDirectory);
      await svc.login(userId: loginAlias, userSig: 'dummy_sig');
      final reported = svc.getSelfToxId();
      if (reported == null || reported.isEmpty) {
        throw StateError('Tox did not report an address for the new profile');
      }
      await svc.updateSelfProfile(
        nickname: displayName,
        statusMessage: statusMessage,
      );
      svc.saveToxProfileNow();
      toxId = reported.toUpperCase();
    } catch (_) {
      // The original failure is the one to report; the latch still records
      // an unconfirmed teardown for the caller's cleanup to respect.
      await _teardown(svc, 'createProfile');
      rethrow;
    }
    // The bootstrap instance wrote into paths.profileDirectory; a zombie
    // save after an unconfirmed teardown would too, so the caller must not
    // treat the directory as its own yet.
    final failure = await _teardown(svc, 'createProfile');
    if (failure != null) throw failure;
    return toxId;
  }

  @override
  Future<void> start(EngineSessionConfig config) async {
    if (_service != null) return;
    await _stopping;
    await config.paths.ensureDirectories();
    final bootstrap = BootstrapNodes(_store, logger: _logger);
    await bootstrap.ensureConfigured();
    final svc = _build(config.paths, config.accountPrefix);
    // Before init: the native session posts friendAddResult and the group
    // notifications through the SDK port from its first tick on.
    _callbacks
      ..install()
      ..target = svc;
    try {
      _stagePassphrase(svc, config.profilePassphrase);
      await svc.init(profileDirectory: config.paths.profileDirectory);
      // Tim2Tox may fall back onto a native instance it could not detach;
      // never publish (or rename) a session that is not this identity's.
      final loaded = svc.getSelfToxId()?.toUpperCase() ?? '';
      final expected = config.toxId.toUpperCase();
      if (loaded.length < 64 ||
          expected.length < 64 ||
          loaded.substring(0, 64) != expected.substring(0, 64)) {
        throw const ChatException(
          'identity_mismatch',
          'The native session is not this identity',
        );
      }
      await svc.login(userId: loginAlias, userSig: 'dummy_sig');
      await svc.updateSelfProfile(
        nickname: config.displayName,
        statusMessage: config.statusMessage,
      );
    } catch (e, st) {
      _logger.error('[Tim2ToxEngine] start failed', e, st);
      try {
        // Accounted like stop(): an unconfirmed teardown here latches too.
        await _teardown(svc, 'start');
      } finally {
        _callbacks.target = null;
      }
      rethrow;
    }
    _service = svc;
    _connected.add(svc.isConnected);
    _connSub = svc.connectionStatusStream.listen(_connected.add);
    // Polling is what pumps friend presence, inbound messages, file requests
    // and the offline-queue drains; nothing moves before this call.
    await svc.startPolling();
    if (onBootstrapStart != null) {
      await onBootstrapStart!();
    } else {
      await bootstrap.applyAutoNodes(
        svc.tryBootstrapNode,
        isCurrent: () => identical(_service, svc),
      );
    }
    // startPolling schedules this un-awaited; do it once more explicitly so
    // callers can rely on persisted group identities right after connect().
    // It is also the pull-side fallback for the group callbacks that are
    // dropped when Tim2ToxSdkPlatform is not installed (toxee
    // HYBRID_ARCHITECTURE.md §4.3).
    await svc.syncGroupIdentitiesFromNative();
    _sessions.force(svc);
  }

  @override
  Future<void> stop() {
    final svc = _service;
    if (svc == null) {
      // Already stopped (or stopping): the caller still gets the truth about
      // ownership, not the success of a teardown someone else was told failed.
      return (_stopping ?? Future<void>.value()).then((_) {
        if (!_teardownConfirmed) {
          throw const ChatException(
            'teardown_unconfirmed',
            'The Tox session did not stop in time',
          );
        }
      });
    }
    onBootstrapStop?.call();
    _service = null;
    // Synchronous part first so consumers see the detach at once; the
    // cancel future is the root-zone one (never resumes under FakeAsync)
    // and is awaited last.
    final cancelled = _connSub?.cancel();
    _connSub = null;
    _connected.add(false);
    _sessions.force(null);
    final done = () async {
      // Native teardown first; the callback target stays on this session
      // until it is gone so a friendAddResult that lands during teardown
      // still resolves its completer instead of waiting out the 30 s
      // timeout (start() awaits _stopping before binding a new target).
      // Every step runs even if an earlier one fails: the session must be
      // disposed and the target released no matter what. The outcome is
      // reported at the end, not swallowed.
      try {
        svc.saveToxProfileNow();
        await svc.flushPendingHistory();
      } catch (e, st) {
        _logger.error('[Tim2ToxEngine] stop: save/flush failed', e, st);
      }
      final ChatException? failure;
      try {
        failure = await _teardown(svc, 'stop');
      } finally {
        _callbacks.target = null;
      }
      try {
        await _scratch?.clear();
      } catch (e, st) {
        _logger.error('[Tim2ToxEngine] stop: scratch clear failed', e, st);
      }
      _scratch = null;
      await cancelled;
      return failure;
    }();
    // start() only needs to know the teardown is over; the failure goes to
    // this caller alone, or a stale error would surface on every later
    // start() through the retained future.
    _stopping = done.then((_) {});
    return done.then((failure) {
      if (failure != null) throw failure;
    });
  }

  @override
  Future<void> updateSelfProfile(String displayName, String statusMessage) {
    final svc = _service;
    if (svc == null) return Future<void>.value();
    return svc.updateSelfProfile(
      nickname: displayName,
      statusMessage: statusMessage,
    );
  }

  @override
  void saveProfileNow() => _service?.saveToxProfileNow();

  @override
  bool rekeyProfilePassphrase(String? passphrase) =>
      _service?.rekeyLiveProfilePassphrase(passphrase) ?? false;

  @override
  Future<void> dispose() async {
    // End of life: an unconfirmed teardown is logged by stop() and nothing
    // destructive follows, so it does not fail the dispose.
    final stopped = stop().catchError((Object _) {});
    // stop() published its last events synchronously; the streams can close
    // now. The hook stays installed until the native teardown is over so a
    // result that lands meanwhile still reaches its completer.
    try {
      await Future.wait([stopped, _sessions.close(), _connected.close()]);
    } finally {
      _callbacks.uninstall();
    }
  }
}

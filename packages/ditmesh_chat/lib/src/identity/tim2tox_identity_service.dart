import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;

import '../adapters/key_value_store.dart';
import '../adapters/kv_snapshot.dart';
import '../adapters/prefs_adapter.dart';
import '../chat/conversation_meta_store.dart';
import '../engine/chat_engine.dart';
import '../logging/chat_logger.dart';
import '../util/atomic_file.dart';
import '../util/posix_permissions.dart';
import '../util/value_stream.dart';
import 'backup_archive.dart';
import 'backup_container.dart';
import 'backup_envelope.dart';
import 'backup_snapshot.dart';
import 'group_descriptors.dart';
import 'identity_paths.dart';
import 'identity_record.dart';
import 'password_verifier.dart';
import 'profile_crypto.dart';

part 'identity_backup.dart';
part 'identity_backup_v2.dart';
part 'identity_profile.dart';
part 'identity_backup_inventory.dart';
part 'identity_recovery.dart';

/// [IdentityService] over Tim2Tox. States: `none` (no `tox_profile.tox`),
/// `locked` (the verifier holds a password or the file is encrypted, and this
/// process has not unlocked it), `ready` (plain, or unlocked this run).
///
/// Encryption at rest: with a password set, `tox_profile.tox` is encrypted
/// on disk at all times. [connect] hands the session password to native
/// Tim2Tox, which opens the encrypted profile and encrypts every save, so a
/// running, backgrounded or killed app never leaves a plaintext profile
/// behind (an older build's plaintext file is migrated by the first save).
/// [disconnect] still encrypts a plaintext file it finds, as a safety net,
/// and keeps retrying on later disconnects until that succeeds. The session
/// password lives in memory only. An encrypted profile proves its own
/// password and repairs a verifier interrupted during a password change or
/// restore.
class Tim2ToxIdentityService
    implements PersistentIdentityService, EncryptedBackupService {
  Tim2ToxIdentityService({
    required IdentityPaths paths,
    required ChatEngine engine,
    required ProfileCrypto crypto,
    required PasswordVerifier verifier,
    KeyValueStore? store,
    ChatLogger logger = const SilentChatLogger(),
  }) : _paths = paths,
       _engine = engine,
       _crypto = crypto,
       _verifier = verifier,
       _store = store,
       _logger = logger {
    _connSub = _engine.connectionChanges.listen(_onEngineConnection);
  }

  final IdentityPaths _paths;
  final ChatEngine _engine;
  final ProfileCrypto _crypto;
  final PasswordVerifier _verifier;
  final KeyValueStore? _store;
  final Set<IdentityDataStore> _dataStores = {};
  Future<void> _mutationTail = Future<void>.value();
  final ChatLogger _logger;

  final ValueStream<Identity?> _identity = ValueStream(null);
  final ValueStream<ConnectionStatus> _status = ValueStream(
    ConnectionStatus.offline,
  );
  StreamSubscription<bool>? _connSub;

  IdentityRecord? _record;
  String? _sessionPassword;
  bool _connecting = false;
  // Started by [connect], not yet stopped. Tracked here, not inferred from
  // `engine.service`, so encrypt-at-rest never depends on the engine's shape.
  bool _started = false;
  // Set once [inspect] has excluded the existing identity container.
  bool _backupExclusionChecked = false;

  /// Exposed for the backend / diagnostics.
  IdentityPaths get paths => _paths;

  @override
  Identity? get current => _identity.value;

  @override
  Stream<Identity?> get identityChanges => _identity.stream;

  @override
  ConnectionStatus get connectionStatus => _status.value;

  @override
  Stream<ConnectionStatus> get connectionChanges => _status.stream;

  void _onEngineConnection(bool online) {
    if (online) {
      _status.add(ConnectionStatus.online);
    } else if (_started || _connecting) {
      _status.add(ConnectionStatus.connecting);
    } else {
      _status.add(ConnectionStatus.offline);
    }
  }

  void _publish(IdentityRecord record) {
    _record = record;
    _identity.force(record.toIdentity());
  }

  // ---- inspect / open / unlock / create ------------------------------------

  @override
  Future<IdentityState> inspect() async {
    // Startup runs inspect for every state (none / locked / ready), so this
    // is where an existing install gets its backup exclusion even if it is
    // never unlocked. Once per service; no directory is created for it.
    if (!_backupExclusionChecked) {
      _backupExclusionChecked = await _paths.excludeExistingFromBackup();
    }
    // A restore killed between its two renames left the previous identity
    // in staging and no root. Serialised with the mutations: a restore in
    // progress has the same shape for a moment and must not be mistaken.
    if (!_paths.profileExists) await _runMutation(_recoverInterruptedImport);
    return _inspect();
  }

  Future<IdentityState> _inspect() async {
    if (!_paths.profileExists) return IdentityState.none;
    if (_record != null) return IdentityState.ready;
    final record = await IdentityRecord.read(_paths.identityFile);
    final encrypted = await _profileIsEncrypted();
    if (record == null) {
      // Profile without identity.json (foreign / half-imported file).
      return encrypted ? IdentityState.locked : IdentityState.ready;
    }
    final hasPassword =
        record.hasPassword || await _verifier.hasPassword(record.toxId);
    return hasPassword || encrypted
        ? IdentityState.locked
        : IdentityState.ready;
  }

  @override
  Future<Identity> open() => _runMutation(_open);

  Future<Identity> _open() async {
    if (_record != null) return _record!.toIdentity();
    await _recoverInterruptedImport();
    if (!_paths.profileExists) {
      throw const ChatException('no_identity', 'No identity on disk');
    }
    if (await _inspect() == IdentityState.locked) {
      throw const ChatException('locked', 'Identity requires a password');
    }
    final record = await _loadOrRecoverRecord(password: null);
    _publish(record);
    return record.toIdentity();
  }

  @override
  Future<Identity> unlock(String password) =>
      _runMutation(() => _unlock(password));

  Future<Identity> _unlock(String password) async {
    if (_record != null) return _record!.toIdentity();
    await _recoverInterruptedImport();
    if (!_paths.profileExists) {
      throw const ChatException('no_identity', 'No identity on disk');
    }
    if (password.isEmpty) {
      throw const ChatException('wrong_password', 'Password required');
    }
    final stored = await IdentityRecord.read(_paths.identityFile);
    final bytes = await File(_paths.profileFile).readAsBytes();
    final encrypted = _crypto.isEncrypted(bytes);
    if (encrypted) {
      // Ciphertext proves the password even if a process exited between a
      // verifier replacement and the profile rename during password change.
      _crypto.decrypt(bytes, password);
    } else if (stored != null && await _verifier.hasPassword(stored.toxId)) {
      if (!await _verifier.verify(stored.toxId, password)) {
        throw const ChatException('wrong_password', 'Incorrect password');
      }
    } else {
      throw const ChatException('not_locked', 'Identity has no password');
    }
    var record = stored ?? await _loadOrRecoverRecord(password: password);
    if (!await _verifier.verify(record.toxId, password)) {
      await _verifier.setPassword(record.toxId, password);
    }
    if (!record.hasPassword) {
      record = record.copyWith(hasPassword: true);
      await record.write(_paths.identityFile);
    }
    _sessionPassword = password;
    _publish(record);
    return record.toIdentity();
  }

  @override
  Future<Identity> create({required String displayName, String? password}) =>
      _runMutation(() => _create(displayName, password));

  /// identity.json, or one rebuilt from the profile's public key when the
  /// JSON is missing (an import that copied only the `.tox`).
  Future<IdentityRecord> _loadOrRecoverRecord({String? password}) async {
    final stored = await IdentityRecord.read(_paths.identityFile);
    if (stored != null) return stored;
    var bytes = await File(_paths.profileFile).readAsBytes();
    if (_crypto.isEncrypted(bytes)) {
      if (password == null) {
        throw const ChatException('locked', 'Identity requires a password');
      }
      bytes = _crypto.decrypt(bytes, password);
    }
    final record = IdentityRecord(
      toxId: _crypto.extractPublicKey(bytes),
      displayName: 'ditmesh',
      hasPassword: password != null,
    );
    await record.write(_paths.identityFile);
    return record;
  }

  @override
  Future<void> changePassword({String? oldPassword, String? newPassword}) =>
      _runMutation(() => _changePassword(oldPassword, newPassword));

  @override
  Future<Identity> updateProfile({
    String? displayName,
    String? statusMessage,
  }) => _runMutation(() => _updateProfile(displayName, statusMessage));

  @override
  Future<Uint8List> exportBackup({bool includeMedia = false}) =>
      _runMutation(() => _exportBackup(includeMedia: includeMedia));

  @override
  Future<Identity> importBackup(Uint8List bytes, {String? password}) =>
      _runMutation(() => _importBackup(bytes, password));

  @override
  Future<BackupInventory> backupInventory() =>
      _runMutation(_backupInventory);

  @override
  Future<Uint8List> exportEncryptedBackup(EncryptedBackupRequest request) =>
      _runMutation(() => _exportEncrypted(request));

  @override
  Future<BackupPreview> previewEncryptedBackup(
    Uint8List bytes,
    String passphrase,
  ) async => _openCached(bytes, passphrase).$1;

  /// The archive the last preview opened: restoring the same bytes with the
  /// same passphrase does not decrypt the whole file a second time.
  (Uint8List, String, (BackupPreview, BackupContainer))? _opened;

  @override
  void forgetPreview() => _opened = null;

  (BackupPreview, BackupContainer) _openCached(
    Uint8List bytes,
    String passphrase,
  ) {
    final cached = _opened;
    if (cached != null &&
        identical(cached.$1, bytes) &&
        cached.$2 == passphrase) {
      return cached.$3;
    }
    _opened = null;
    final opened = BackupArchive.open(bytes, passphrase, _crypto);
    _opened = (bytes, passphrase, opened);
    return opened;
  }

  @override
  Future<RestoreReport> restoreEncryptedBackup(
    Uint8List bytes,
    String passphrase, {
    String? identityPassword,
  }) => _runMutation(
    () => _restoreEncrypted(bytes, passphrase, identityPassword),
  ).whenComplete(() => _opened = null);

  // ---- connect / disconnect / delete ----------------------------------------

  @override
  Future<void> connect() => _runMutation(_connectImpl);

  Future<void> _connectImpl() async {
    if (_started) return;
    final record = _requireRecord();
    _connecting = true;
    _status.add(ConnectionStatus.connecting);
    try {
      final password = _sessionPassword;
      if (password == null && await _profileIsEncrypted()) {
        throw const ChatException(
          'wrong_password',
          'Profile is encrypted and no password is available',
        );
      }
      await _engine.start(
        EngineSessionConfig(
          paths: _paths,
          toxId: record.toxId,
          displayName: record.displayName,
          statusMessage: record.statusMessage,
          profilePassphrase: password,
        ),
      );
    } catch (e) {
      _connecting = false;
      _status.add(ConnectionStatus.offline);
      try {
        await _engine.stop();
      } on Object catch (stopError, st) {
        // The start failure is the one to report; the engine's latch keeps
        // the profile directory locked (see _encryptProfileAtRest).
        _logger.error('[Identity] stop after failed start', stopError, st);
      }
      // Never leave a plaintext profile behind after a failed start.
      await _encryptProfileAtRest();
      if (e is ChatException) rethrow;
      throw ChatException('connect_failed', 'Could not start Tox: $e');
    }
    _connecting = false;
    _started = true;
    _onEngineConnection(_engine.isConnected);
  }

  @override
  Future<void> disconnect() => _runMutation(_disconnectImpl);

  Future<void> _disconnectImpl() async {
    if (_started) {
      _started = false;
      // An unconfirmed native teardown fails the disconnect out loud; the
      // engine already published the detach, so the status is offline.
      await _engine.stop();
      _status.add(ConnectionStatus.offline);
    }
    // Also when already stopped: an encryption that failed on an earlier
    // disconnect is retried (a no-op once the file is encrypted).
    await _encryptProfileAtRest();
  }

  @override
  Future<void> deleteIdentity() => _runMutation(() async {
    final record = _record ?? await IdentityRecord.read(_paths.identityFile);
    final password = _sessionPassword;
    try {
      await _prepareForReplacement();
      await _disconnectImpl();
      _requireTeardownConfirmed();
      Future<void> removeFiles() async {
        if (record != null) await _clearPreferences(record.toxId);
        await _paths.deleteAll();
        _forgetIdentity();
      }

      if (record == null) {
        await removeFiles();
      } else {
        await _verifier.replacePassword(record.toxId, null, removeFiles);
      }
    } catch (_) {
      if (_paths.profileExists && record != null) {
        _sessionPassword = password;
        _publish(record);
      }
      rethrow;
    }
  });

  @override
  void registerDataStore(IdentityDataStore store) => _dataStores.add(store);

  @override
  void unregisterDataStore(IdentityDataStore store) =>
      _dataStores.remove(store);

  @override
  Future<void> persist() => _runMutation(_persist);

  Future<void> _persist() => Future.wait([
    Future<void>.sync(_engine.persist),
    for (final store in _dataStores.toList()) Future<void>.sync(store.flush),
  ]);

  Future<void> _prepareForReplacement() async {
    for (final store in _dataStores.toList()) {
      await store.prepareForReplacement();
    }
  }

  void _forgetIdentity() {
    _record = null;
    _sessionPassword = null;
    _identity.force(null);
    _status.add(ConnectionStatus.offline);
  }

  Future<void> _clearPreferences(String toxId) async {
    final store = _store;
    if (store == null || toxId.length < 16) return;
    await Tim2ToxPreferencesAdapter(
      store,
      accountPrefix: toxId.substring(0, 16).toUpperCase(),
    ).clear();
  }

  Future<T> _runMutation<T>(Future<T> Function() action) {
    final run = _mutationTail.then((_) => action());
    _mutationTail = run.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return run;
  }

  @override
  Future<String> dataDirectory() async {
    _requireRecord();
    await Directory(_paths.trainingDirectory).create(recursive: true);
    return _paths.trainingDirectory;
  }

  Future<void> dispose() async {
    await _mutationTail;
    final cancelled = _connSub?.cancel();
    _connSub = null;
    await Future.wait([?cancelled, _identity.close(), _status.close()]);
  }

  // ---- helpers ----------------------------------------------------------------

  IdentityRecord _requireRecord() {
    final r = _record;
    if (r == null) {
      throw const ChatException(
        'no_identity',
        'No identity is open (create, open or unlock first)',
      );
    }
    return r;
  }

  Future<bool> _profileIsEncrypted() async {
    final file = File(_paths.profileFile);
    if (!await file.exists()) return false;
    try {
      return _crypto.isEncrypted(await file.readAsBytes());
    } catch (e, st) {
      _logger.error('[Identity] could not probe profile encryption', e, st);
      return false;
    }
  }

}

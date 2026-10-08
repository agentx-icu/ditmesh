import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../encrypted_backup.dart';
import '../identity_service.dart';
import '../models.dart';
import '../tox_address.dart';

part 'fake_identity_backup.dart';

/// In-memory [IdentityService] for widget tests and UI development.
///
/// Models the on-disk profile as [_StoredProfile]; [inspect] reads it exactly
/// the way the real backend would look at a `.tox` file:
///
/// * nothing stored → [IdentityState.none]
/// * stored with a password and not yet unlocked → [IdentityState.locked]
/// * otherwise → [IdentityState.ready]
///
/// Everything is deterministic: Tox IDs derive from a counter (see
/// [toxIdForSeed]) and [connect] flips `connecting → online` after
/// [connectDelay], which tests set to [Duration.zero].
final class FakeIdentityService
    implements IdentityService, EncryptedBackupService {
  /// Starts with no profile on disk (first run).
  FakeIdentityService({
    this.connectDelay = const Duration(milliseconds: 400),
    String? dataDirectoryPath,
    int seed = 1,
  }) : _dataDirectoryPath = dataDirectoryPath,
       _nextSeed = seed;

  /// Starts with [identity] already on disk, encrypted when [password] is set.
  /// Use this to drive the `locked` / `ready` startup paths.
  FakeIdentityService.withProfile({
    required Identity identity,
    String? password,
    this.connectDelay = const Duration(milliseconds: 400),
    String? dataDirectoryPath,
    int seed = 1,
  }) : _dataDirectoryPath = dataDirectoryPath,
       _nextSeed = seed,
       _disk = _StoredProfile(
         identity.copyWith(hasPassword: password != null),
         password,
       );

  /// Where [dataDirectory] puts per-identity folders when no
  /// `dataDirectoryPath` is given. Tests that boot the app with the default
  /// fake (e.g. the launch integration test) clear it to start clean.
  static String get defaultDataRoot =>
      '${Directory.systemTemp.path}${Platform.pathSeparator}ditmesh_fake';

  /// Magic prefix of the backup container produced by [exportBackup].
  static const String backupMagic = 'MCQ-FAKE-BACKUP-1';

  /// How long [connect] stays `connecting` before reporting `online`.
  final Duration connectDelay;

  /// When set, [inspect] throws it once (then clears it). Lets tests drive
  /// the startup gate's error/retry path.
  Object? inspectError;

  final String? _dataDirectoryPath;
  int _nextSeed;
  _StoredProfile? _disk;
  Identity? _current;
  ConnectionStatus _connection = ConnectionStatus.offline;
  Timer? _connectTimer;
  bool _disposed = false;

  final _identityController = StreamController<Identity?>.broadcast();
  final _connectionController = StreamController<ConnectionStatus>.broadcast();

  // ---- Introspection for tests ---------------------------------------------

  /// The password currently protecting the stored profile, if any.
  String? get storedPassword => _disk?.password;

  /// Whether a profile exists on the simulated disk.
  bool get hasStoredProfile => _disk != null;

  /// Deterministic 76-hex Tox ID for [seed]: 64 hex public key and 8 hex
  /// nospam from a small LCG (IDs differ per seed but never depend on
  /// wall-clock time), then the real 4 hex checksum, so the ID passes the
  /// same validation a real Tox address does.
  static String toxIdForSeed(int seed) {
    var state = 0x9E3779B9 ^ (seed * 0x85EBCA6B);
    final buffer = StringBuffer();
    while (buffer.length < 72) {
      state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
      buffer.write(((state >> 16) & 0xF).toRadixString(16).toUpperCase());
    }
    return ToxAddress.withChecksum(buffer.toString());
  }

  // ---- IdentityService -----------------------------------------------------

  @override
  Identity? get current => _current;

  @override
  Stream<Identity?> get identityChanges => _identityController.stream;

  @override
  Stream<ConnectionStatus> get connectionChanges =>
      _connectionController.stream;

  @override
  ConnectionStatus get connectionStatus => _connection;

  @override
  Future<IdentityState> inspect() async {
    final error = inspectError;
    if (error != null) {
      inspectError = null;
      throw error;
    }
    final disk = _disk;
    if (disk == null) return IdentityState.none;
    if (disk.password != null && _current == null) return IdentityState.locked;
    return IdentityState.ready;
  }

  @override
  Future<Identity> create({
    required String displayName,
    String? password,
  }) async {
    if (_disk != null) {
      // Like the backend: delete (or import over) the existing one first.
      throw const ChatException('identity_exists', 'An identity already exists');
    }
    final name = displayName.trim();
    if (name.isEmpty) {
      throw const ChatException('invalid_name', 'Display name is required.');
    }
    final identity = Identity(
      toxId: toxIdForSeed(_nextSeed++),
      displayName: name,
      hasPassword: password != null && password.isNotEmpty,
    );
    _disk = _StoredProfile(
      identity,
      password == null || password.isEmpty ? null : password,
    );
    _setCurrent(identity);
    return identity;
  }

  @override
  Future<Identity> unlock(String password) async {
    final disk = _requireDisk();
    if (disk.password == null) {
      throw const ChatException('not_locked', 'Identity has no password');
    }
    if (password != disk.password) {
      throw const ChatException('wrong_password', 'Wrong password.');
    }
    _setCurrent(disk.identity);
    return disk.identity;
  }

  @override
  Future<Identity> open() async {
    final disk = _requireDisk();
    if (disk.password != null && _current == null) {
      throw const ChatException(
        'locked',
        'Profile is encrypted; unlock it with the password.',
      );
    }
    _setCurrent(disk.identity);
    return disk.identity;
  }

  @override
  Future<void> changePassword({
    String? oldPassword,
    String? newPassword,
  }) async {
    final disk = _requireDisk();
    _requireCurrent();
    if (disk.password != null && oldPassword != disk.password) {
      throw const ChatException('wrong_password', 'Wrong password.');
    }
    final next = newPassword == null || newPassword.isEmpty
        ? null
        : newPassword;
    final identity = disk.identity.copyWith(hasPassword: next != null);
    _disk = _StoredProfile(identity, next);
    _setCurrent(identity);
  }

  @override
  Future<Identity> updateProfile({
    String? displayName,
    String? statusMessage,
  }) async {
    final disk = _requireDisk();
    _requireCurrent();
    final trimmed = displayName?.trim();
    if (trimmed != null && trimmed.isEmpty) {
      throw const ChatException('invalid_name', 'Display name is required.');
    }
    final identity = disk.identity.copyWith(
      displayName: trimmed,
      statusMessage: statusMessage,
    );
    _disk = _StoredProfile(identity, disk.password);
    _setCurrent(identity);
    return identity;
  }

  @override
  Future<Uint8List> exportBackup({bool includeMedia = false}) async {
    final disk = _requireDisk();
    _requireCurrent();
    final payload = jsonEncode({
      'magic': backupMagic,
      'toxId': disk.identity.toxId,
      'displayName': disk.identity.displayName,
      'statusMessage': disk.identity.statusMessage,
      'password': disk.password,
    });
    return Uint8List.fromList(utf8.encode(payload));
  }

  /// Extra category sizes [backupInventory] reports (tests set them).
  Map<BackupCategory, BackupCategorySize> fakeBackupSizes = {};

  /// Outbox size [backupInventory] reports and exports carry.
  int fakePendingMessages = 0;

  @override
  Future<BackupInventory> backupInventory() async => _inventory();

  @override
  Future<Uint8List> exportEncryptedBackup(
    EncryptedBackupRequest request,
  ) async => _export(request);

  @override
  Future<BackupPreview> previewEncryptedBackup(
    Uint8List bytes,
    String passphrase,
  ) async => _preview(_open(bytes, passphrase));

  @override
  void forgetPreview() {}

  @override
  Future<RestoreReport> restoreEncryptedBackup(
    Uint8List bytes,
    String passphrase, {
    String? identityPassword,
  }) => _restore(bytes, passphrase, identityPassword);

  @override
  Future<Identity> importBackup(Uint8List bytes, {String? password}) async {
    final Map<String, Object?> map;
    try {
      map = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    } on Object {
      throw const ChatException(
        'invalid_backup',
        'This file is not a ditmesh backup.',
      );
    }
    if (map['magic'] != backupMagic || map['toxId'] is! String) {
      throw const ChatException(
        'invalid_backup',
        'This file is not a ditmesh backup.',
      );
    }
    final storedPassword = map['password'] as String?;
    if (storedPassword != null && storedPassword != password) {
      throw const ChatException('wrong_password', 'Wrong password.');
    }
    await disconnect();
    // The replacement boundary the backend has too: observers see the old
    // identity end before the restored one (even with the same key) begins.
    _setCurrent(null);
    final identity = Identity(
      toxId: map['toxId']! as String,
      displayName: (map['displayName'] as String?) ?? 'Restored',
      statusMessage: (map['statusMessage'] as String?) ?? '',
      hasPassword: storedPassword != null,
    );
    _disk = _StoredProfile(identity, storedPassword);
    _setCurrent(identity);
    return identity;
  }

  @override
  Future<void> connect() async {
    _requireCurrent();
    if (_connection != ConnectionStatus.offline) return;
    _setConnection(ConnectionStatus.connecting);
    if (connectDelay == Duration.zero) {
      _setConnection(ConnectionStatus.online);
      return;
    }
    _connectTimer?.cancel();
    _connectTimer = Timer(connectDelay, () {
      _connectTimer = null;
      if (_disposed || _connection != ConnectionStatus.connecting) return;
      _setConnection(ConnectionStatus.online);
    });
  }

  @override
  Future<void> disconnect() async {
    _connectTimer?.cancel();
    _connectTimer = null;
    if (_connection == ConnectionStatus.offline) return;
    _setConnection(ConnectionStatus.offline);
  }

  @override
  Future<void> deleteIdentity() async {
    await disconnect();
    _disk = null;
    _setCurrent(null);
  }

  @override
  Future<String> dataDirectory() async {
    final identity = _requireCurrent();
    final base = _dataDirectoryPath ?? defaultDataRoot;
    final dir = Directory(
      '$base${Platform.pathSeparator}${identity.publicKey.substring(0, 16)}',
    );
    // Synchronous on purpose: widget tests run in a FakeAsync zone where real
    // asynchronous I/O never completes unless wrapped in `runAsync`.
    dir.createSync(recursive: true);
    return dir.path;
  }

  /// Close the streams. Not part of [IdentityService]; call from tests or the
  /// DI scope that owns this instance.
  Future<void> dispose() async {
    _disposed = true;
    _connectTimer?.cancel();
    await Future.wait([
      _identityController.close(),
      _connectionController.close(),
    ]);
  }

  // ---- Internals -----------------------------------------------------------

  _StoredProfile _requireDisk() {
    final disk = _disk;
    if (disk == null) {
      throw const ChatException('no_identity', 'No identity exists yet.');
    }
    return disk;
  }

  Identity _requireCurrent() {
    final identity = _current;
    if (identity == null) {
      throw const ChatException('no_identity', 'Identity is not loaded.');
    }
    return identity;
  }

  void _setCurrent(Identity? identity) {
    _current = identity;
    if (!_identityController.isClosed) _identityController.add(identity);
  }

  void _setConnection(ConnectionStatus status) {
    _connection = status;
    if (!_connectionController.isClosed) _connectionController.add(status);
  }
}

final class _StoredProfile {
  const _StoredProfile(this.identity, this.password);

  final Identity identity;
  final String? password;
}

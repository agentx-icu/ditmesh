part of 'fake_identity_service.dart';

/// [EncryptedBackupService] for the fake: the same flow and error codes as
/// the backend (`MCQE` magic, passphrase check, preview without changes,
/// replacement boundary), but the payload is plain JSON — this is a test
/// double, not encryption.
extension _FakeEncryptedBackup on FakeIdentityService {
  static int _digest(String s) {
    var hash = 0xcbf29ce484222325;
    for (final b in utf8.encode(s)) {
      hash = (hash ^ b) * 0x100000001b3;
    }
    return hash;
  }

  BackupInventory _inventory() {
    final disk = _requireDisk();
    _requireCurrent();
    return BackupInventory(
      sizes: {
        BackupCategory.identity: const BackupCategorySize(items: 2, bytes: 512),
        BackupCategory.training: const BackupCategorySize(items: 1, bytes: 256),
        if (fakePendingMessages > 0)
          BackupCategory.pendingMessages: BackupCategorySize(
            items: fakePendingMessages,
            bytes: 0,
          ),
        ...fakeBackupSizes,
      },
      pendingMessages: fakePendingMessages,
      queuedInvites: 0,
      profileHasPassword: disk.password != null,
    );
  }

  Uint8List _export(EncryptedBackupRequest request) {
    final disk = _requireDisk();
    _requireCurrent();
    if (request.passphrase.isEmpty) {
      throw const ChatException('wrong_passphrase', 'Passphrase required');
    }
    final cats = {...request.categories, BackupCategory.identity};
    final sizes = _inventory().sizes;
    final payload = jsonEncode({
      'key': _digest(request.passphrase),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'toxId': disk.identity.toxId,
      'displayName': disk.identity.displayName,
      'statusMessage': disk.identity.statusMessage,
      'password': disk.password,
      'categories': [
        for (final c in cats)
          if (sizes.containsKey(c)) c.name,
      ],
      'pending': fakePendingMessages,
      if (request.preferences != null && cats.contains(BackupCategory.preferences))
        'preferences': base64.encode(request.preferences!),
    });
    return Uint8List.fromList([
      ...encryptedBackupMagic,
      1,
      1,
      0,
      0,
      ...utf8.encode(payload),
    ]);
  }

  Map<String, Object?> _open(Uint8List bytes, String passphrase) {
    if (!isEncryptedBackup(bytes) || bytes.length < 8) {
      throw const ChatException('invalid_backup', 'Not an encrypted backup');
    }
    if (bytes[4] != 1 || bytes[5] != 1) {
      throw const ChatException('unsupported_backup_version', 'Newer backup');
    }
    final Map<String, Object?> map;
    try {
      map = jsonDecode(utf8.decode(bytes.sublist(8))) as Map<String, Object?>;
    } on Object {
      throw const ChatException('wrong_passphrase', 'Altered backup');
    }
    if (map['key'] != _digest(passphrase)) {
      throw const ChatException('wrong_passphrase', 'Wrong passphrase');
    }
    return map;
  }

  BackupPreview _preview(Map<String, Object?> map) {
    final cats = (map['categories']! as List).cast<String>();
    final pending = map['pending']! as int;
    return BackupPreview(
      toxId: map['toxId']! as String,
      displayName: map['displayName']! as String,
      createdAt: DateTime.parse(map['createdAt']! as String),
      sizes: {
        for (final name in cats)
          BackupCategory.values.byName(name): const BackupCategorySize(
            items: 1,
            bytes: 256,
          ),
      },
      pendingMessages: pending,
      pendingIncluded: cats.contains(BackupCategory.pendingMessages.name),
      queuedInvites: 0,
      profileNeedsPassword: map['password'] != null,
    );
  }

  Future<RestoreReport> _restore(
    Uint8List bytes,
    String passphrase,
    String? identityPassword,
  ) async {
    final map = _open(bytes, passphrase);
    final preview = _preview(map);
    final stored = map['password'] as String?;
    if (stored != null && stored != identityPassword) {
      throw const ChatException('wrong_password', 'Wrong password.');
    }
    await disconnect();
    _setCurrent(null);
    final identity = Identity(
      toxId: preview.toxId,
      displayName: preview.displayName,
      statusMessage: (map['statusMessage'] as String?) ?? '',
      hasPassword: stored != null,
    );
    _disk = _StoredProfile(identity, stored);
    _setCurrent(identity);
    final restored = preview.sizes.keys.toSet();
    final prefs = map['preferences'];
    return RestoreReport(
      restored: restored,
      notIncluded: BackupCategory.values.toSet().difference(restored),
      pendingForReview: preview.pendingIncluded ? preview.pendingMessages : 0,
      pendingNotResumed: preview.pendingIncluded ? 0 : preview.pendingMessages,
      queuedInvitesNotResumed: 0,
      preferences: prefs is String ? base64.decode(prefs) : null,
    );
  }
}

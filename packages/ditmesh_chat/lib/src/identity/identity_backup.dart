part of 'tim2tox_identity_service.dart';

extension _IdentityBackup on Tim2ToxIdentityService {
  Future<Uint8List> _exportBackup({bool includeMedia = false}) async {
    final record = _requireRecord();
    await _persist();
    // A quarantined instance from an earlier stop could still be changing
    // the tree this reads.
    _requireTeardownConfirmed();
    var profile = await File(_paths.profileFile).readAsBytes();
    final password = _sessionPassword;
    _requireBytesOwned(record.toxId, profile, password);
    var encrypted = _crypto.isEncrypted(profile);
    if (!encrypted && password != null && password.isNotEmpty) {
      profile = _crypto.encrypt(profile, password);
      encrypted = true;
    }
    final entries = <String, Uint8List>{
      BackupContainer.identityEntry: record.encode(),
      BackupContainer.profileEntry: profile,
    };
    final training = Directory(_paths.trainingDirectory);
    if (await training.exists()) {
      final files =
          training
              .listSync(recursive: true, followLinks: false)
              .whereType<File>()
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));
      for (final file in files) {
        final rel = p.url.joinAll(
          p.split(p.relative(file.path, from: training.path)),
        );
        entries['${BackupContainer.trainingPrefix}$rel'] = await file
            .readAsBytes();
      }
    }
    if (includeMedia) {
      // Opt-in only: exactly the saved recordings the app counted before
      // asking (BackupMedia.referenced) — never the working recording or
      // staging/temporary files — and never more than BackupMedia.maxBytes.
      final doc = File(p.join(training.path, BackupMedia.materialsDoc));
      final names = BackupMedia.referenced(
        await doc.exists() ? await doc.readAsString() : null,
      ).toList()..sort();
      var total = 0;
      for (final name in names) {
        final file = File(p.join(_paths.root, 'media', 'recordings', name));
        if (!await file.exists()) continue;
        total += await file.length();
        if (total > BackupMedia.maxBytes) {
          throw const ChatException(
            'backup_media_too_large',
            'Recordings exceed the backup size limit',
          );
        }
        entries['${BackupContainer.mediaPrefix}$name'] = await file
            .readAsBytes();
      }
    }
    return BackupContainer(
      entries: entries,
      profileEncrypted: encrypted,
    ).encode();
  }

  Future<Identity> _importBackup(Uint8List bytes, String? password) async {
    if (bytes.length > BackupContainer.maxBytes) {
      throw const ChatException('invalid_backup', 'Backup file is too large');
    }
    final backup = BackupContainer.hasMagic(bytes)
        ? BackupContainer.decode(bytes)
        : null;
    final profile = backup == null ? bytes : backup.profile;
    if (profile == null || profile.isEmpty) {
      throw const ChatException('invalid_backup', 'Backup has no Tox profile');
    }
    final encrypted = _crypto.isEncrypted(profile);
    if (encrypted && (password == null || password.isEmpty)) {
      throw const ChatException(
        'wrong_password',
        'This backup is password protected',
      );
    }
    final plain = encrypted ? _crypto.decrypt(profile, password!) : profile;
    final metadata = backup?.identity;
    final stored = metadata == null ? null : IdentityRecord.decode(metadata);
    final key = _backupProfileIdentifier(plain, fullAddress: stored == null);
    if (stored != null && !stored.toxId.toUpperCase().startsWith(key)) {
      throw const ChatException(
        'invalid_backup',
        'Identity does not match the Tox profile',
      );
    }
    final record =
        (stored ?? IdentityRecord(toxId: key, displayName: 'ditmesh')).copyWith(
          hasPassword: encrypted,
        );
    await _replaceIdentityFromBackup(record, encrypted ? password : null, (
      staged,
    ) async {
      await writeBytesAtomic(File(staged.profileFile), profile);
      await record.write(staged.identityFile);
      for (final entry
          in backup?.trainingFiles ?? const <MapEntry<String, Uint8List>>[]) {
        final rel = entry.key.substring(BackupContainer.trainingPrefix.length);
        final target = File(
          p.join(staged.trainingDirectory, p.joinAll(rel.split('/'))),
        );
        await target.parent.create(recursive: true);
        await target.writeAsBytes(entry.value, flush: true);
      }
      for (final entry
          in backup?.mediaFiles ?? const <MapEntry<String, Uint8List>>[]) {
        final name = entry.key.substring(BackupContainer.mediaPrefix.length);
        final target = File(p.join(staged.root, 'media', 'recordings', name));
        await target.parent.create(recursive: true);
        await target.writeAsBytes(entry.value, flush: true);
      }
    });
    return record.toIdentity();
  }

  String _backupProfileIdentifier(
    Uint8List plain, {
    required bool fullAddress,
  }) {
    try {
      return fullAddress
          ? _crypto.extractAddress(plain)
          : _crypto.extractPublicKey(plain);
    } on ChatException catch (error) {
      if (error.code != 'invalid_profile') rethrow;
      throw const ChatException('invalid_backup', 'File is not a Tox profile');
    }
  }
}

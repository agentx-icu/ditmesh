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
    final backup = BackupContainer.decode(bytes);
    final profile = backup.profile;
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
    final key = _crypto.extractPublicKey(plain);
    final stored = backup.identity == null
        ? null
        : IdentityRecord.decode(backup.identity!);
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
    final root = Directory(_paths.root);
    await PosixPermissions.createPrivateDirectory(root.parent.path);
    // The staged tree below must not land in a directory iOS would back up.
    await _paths.excludeFromBackup();
    final stage = await root.parent.createTemp(IdentityPaths.importStagePrefix);
    final previous = Directory(p.join(stage.path, 'previous'));
    final staged = IdentityPaths(p.join(stage.path, 'identity'));
    var replaced = false;
    final old = _record ?? await IdentityRecord.read(_paths.identityFile);
    final oldPassword = _sessionPassword;
    try {
      // Finish every archive write before touching the existing account.
      await staged.ensureDirectories();
      // Owner-only from the first byte (writeBytesAtomic stages at 0600).
      await writeBytesAtomic(File(staged.profileFile), profile);
      await record.write(staged.identityFile);
      for (final entry in backup.trainingFiles) {
        final rel = entry.key.substring(BackupContainer.trainingPrefix.length);
        final target = File(
          p.join(staged.trainingDirectory, p.joinAll(rel.split('/'))),
        );
        await target.parent.create(recursive: true);
        await target.writeAsBytes(entry.value, flush: true);
      }
      for (final entry in backup.mediaFiles) {
        final name = entry.key.substring(BackupContainer.mediaPrefix.length);
        final target = File(p.join(staged.root, 'media', 'recordings', name));
        await target.parent.create(recursive: true);
        await target.writeAsBytes(entry.value, flush: true);
      }
      await _prepareForReplacement();
      await _disconnectImpl();
      _requireTeardownConfirmed();
      final store = _store;
      final before = store == null ? null : KvSnapshot.capture(store);
      await _verifier.replacePassword(
        record.toxId,
        encrypted ? password : null,
        () async {
          if (await root.exists()) await root.rename(previous.path);
          var movedIn = false;
          try {
            await Directory(staged.root).rename(root.path);
            movedIn = true;
            // Part of the commit: stale bindings or queued invites of the
            // restored identity must not survive into its next session.
            if (old != null) await _clearPreferences(old.toxId);
            await _clearPreferences(record.toxId);
            replaced = true;
          } catch (_) {
            if (store != null && before != null) {
              try {
                await before.restore(store);
              } on Object catch (e, st) {
                _logger.error('[Backup] preference rollback failed', e, st);
              }
            }
            if (movedIn) await root.rename(staged.root);
            if (await previous.exists()) await previous.rename(root.path);
            rethrow;
          }
        },
      );
      _forgetIdentity();
      _sessionPassword = encrypted ? password : null;
      _publish(record);
      if (old != null && old.toxId != record.toxId) {
        // Cleanup after the commit: a failure must not report the committed
        // import as failed.
        try {
          await _verifier.removePassword(old.toxId);
        } on Object catch (e, st) {
          _logger.error('[Backup] could not remove the old verifier', e, st);
        }
      }
    } catch (_) {
      if (!replaced && old != null) {
        _sessionPassword = oldPassword;
        _publish(old);
      }
      rethrow;
    } finally {
      await _discardStage(stage, previous, committed: replaced);
    }
    return record.toIdentity();
  }

  /// Removes an import's staging directory. If both the replacement rename
  /// and its rollback failed, the old tree in [previous] is the only copy
  /// and is kept for recovery. After a commit a failed deletion must not
  /// report the import as failed: it is logged, and at least the previous
  /// profile is removed so the leftover can never be mistaken for an
  /// interrupted import (`interruptedImports`) and "recovered" later.
  Future<void> _discardStage(
    Directory stage,
    Directory previous, {
    required bool committed,
  }) async {
    if (!committed && await previous.exists()) return;
    try {
      await stage.delete(recursive: true);
    } on Object catch (e, st) {
      if (!committed) rethrow;
      _logger.error('[Backup] could not remove the import staging', e, st);
      try {
        final old = File(IdentityPaths(previous.path).profileFile);
        if (await old.exists()) await old.delete();
      } on Object catch (e, st) {
        _logger.error('[Backup] stale previous profile left in staging', e, st);
      }
    }
  }
}

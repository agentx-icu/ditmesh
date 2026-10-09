part of 'tim2tox_identity_service.dart';

/// Complete encrypted backups (F10): inventory, consistent export, preview
/// and transactional restore. Layout: `backup_snapshot.dart`; envelope:
/// `backup_envelope.dart`.
extension _EncryptedBackup on Tim2ToxIdentityService {
  static const int _snapshotAttempts = 3;

  static String _accountPrefix(String toxId) =>
      toxId.length < 16 ? '' : toxId.substring(0, 16).toUpperCase();

  ConversationMetaStore? _metaFor(String toxId) {
    final store = _store;
    if (store == null || toxId.length < 16) return null;
    return ConversationMetaStore(store, accountPrefix: _accountPrefix(toxId));
  }

  String get _mediaDirectory => p.join(_paths.root, 'media', 'recordings');

  Future<Uint8List> _exportEncrypted(EncryptedBackupRequest request) async {
    final record = _requireRecord();
    if (request.passphrase.isEmpty) {
      throw const ChatException('wrong_passphrase', 'Passphrase required');
    }
    await _persist();
    // Native history and the outbox are written by the running node; stop it
    // so both are read at one moment (a message cannot land in history while
    // the queue is being copied). Sends fail `not_connected` meanwhile.
    final wasStarted = _started;
    if (wasStarted) await _disconnectImpl();
    try {
      // A zombie native save would land in the snapshot or right after it.
      _requireTeardownConfirmed();
      for (var attempt = 1; ; attempt++) {
        try {
          final inner = await _snapshot(record, request);
          return BackupEnvelope.seal(inner, request.passphrase, _crypto);
        } on SnapshotUnstable catch (e) {
          _logger.info('[Backup] ${e.path} changed during export, retrying');
          if (attempt >= _snapshotAttempts) {
            throw const ChatException(
              'backup_busy',
              'Data kept changing while the backup was taken',
            );
          }
        }
      }
    } finally {
      if (wasStarted) {
        try {
          await _connectImpl();
        } catch (e, st) {
          // The export itself succeeded; the user can reconnect.
          _logger.error('[Backup] could not reconnect after export', e, st);
        }
      }
    }
  }

  Future<Uint8List> _snapshot(
    IdentityRecord record,
    EncryptedBackupRequest request,
  ) async {
    final cats = {...request.categories, BackupCategory.identity};
    final entries = <String, Uint8List>{};
    final sizes = <BackupCategory, BackupCategorySize>{};
    final stamps = <String, (int, DateTime)>{};
    void add(BackupCategory c, String path, Uint8List bytes) {
      entries[path] = bytes;
      final was = sizes[c] ?? BackupCategorySize.zero;
      sizes[c] = BackupCategorySize(
        items: was.items + 1,
        bytes: was.bytes + bytes.length,
      );
    }

    // Stamped before and after each read: a write that lands while the
    // bytes are read is caught here, one that lands later by verifyStable.
    Future<Uint8List> readFile(File f) async {
      final before = (await f.length(), await f.lastModified());
      final bytes = await f.readAsBytes();
      if ((await f.length(), await f.lastModified()) != before ||
          bytes.length != before.$1) {
        throw SnapshotUnstable(f.path);
      }
      stamps[f.path] = before;
      return bytes;
    }

    final profileFile = File(_paths.profileFile);
    var profile = await readFile(profileFile);
    var profileEncrypted = _crypto.isEncrypted(profile);
    final password = _sessionPassword;
    if (!profileEncrypted && password != null && password.isNotEmpty) {
      profile = _crypto.encrypt(profile, password);
      profileEncrypted = true;
    }
    add(BackupCategory.identity, 'identity.json', record.encode());
    add(BackupCategory.identity, 'tox_profile.tox', profile);
    // Group membership lives in preferences, not in the Tox savedata: the
    // ids, chat ids and kinds Tim2Tox rebinds and rejoins from on start.
    // Part of the identity (always included), like the friend list is.
    final store = _store;
    final groups = store == null
        ? null
        : await GroupDescriptors.export(store, _accountPrefix(record.toxId));
    if (groups != null) {
      add(
        BackupCategory.identity,
        BackupSnapshot.groupsEntry,
        BackupSnapshot.encodeJson(groups),
      );
    }

    // Stamped before the queue is copied and parsed, like every other file.
    for (final f in [
      File(_paths.offlineQueueFile),
      File('${_paths.offlineQueueFile}.bak'),
    ]) {
      if (await f.exists()) {
        stamps[f.path] = (await f.length(), await f.lastModified());
      }
    }
    final queue = await BackupSnapshot.readQueue(_paths);
    // Withdrawn rows stay withheld from history (the full queue filters it
    // below) but are not offered for review; the withdrawal records
    // themselves are not exported: a restore never rebuilds the outbox, so
    // there is nothing for them to withdraw there.
    final reviewable = BackupSnapshot.withoutWithdrawn(
      queue,
      _metaFor(record.toxId)?.withdrawals ?? const {},
    );
    var pendingItems = [for (final (i, q) in reviewable.indexed) q.toItem(i)];

    for (final (rel, file) in await BackupSnapshot.files(
      _paths.trainingDirectory,
    )) {
      if (rel == BackupSnapshot.bookmarksFile) {
        if (cats.contains(BackupCategory.conversationMeta)) {
          add(
            BackupCategory.conversationMeta,
            BackupSnapshot.bookmarksEntry,
            await readFile(file),
          );
        }
      } else if (rel == BackupSnapshot.restoredPendingFile) {
        // Review items an earlier restore brought over stay reviewable.
        pendingItems = [
          ...pendingItems,
          ...BackupSnapshot.pendingItems(await readFile(file)),
        ];
      } else if (cats.contains(BackupCategory.training)) {
        add(
          BackupCategory.training,
          '${BackupSnapshot.trainingPrefix}$rel',
          await readFile(file),
        );
      }
    }
    var withheld = 0;
    if (cats.contains(BackupCategory.chatHistory)) {
      for (final (rel, file) in await BackupSnapshot.files(
        _paths.historyDirectory,
      )) {
        final (bytes, removed) = BackupSnapshot.withoutQueued(
          rel,
          await readFile(file),
          queue,
        );
        withheld += removed;
        add(
          BackupCategory.chatHistory,
          '${BackupSnapshot.historyPrefix}$rel',
          bytes,
        );
      }
    }
    final meta = _metaFor(record.toxId);
    if (cats.contains(BackupCategory.conversationMeta) && meta != null) {
      add(
        BackupCategory.conversationMeta,
        BackupSnapshot.conversationsEntry,
        BackupSnapshot.encodeJson(meta.exportPortable()),
      );
    }
    final prefs = request.preferences;
    if (cats.contains(BackupCategory.preferences) && prefs != null) {
      add(BackupCategory.preferences, BackupSnapshot.preferencesEntry, prefs);
    }
    if (cats.contains(BackupCategory.media)) {
      var total = 0;
      for (final name in await _referencedMedia()) {
        final file = File(p.join(_mediaDirectory, name));
        if (!await file.exists()) continue;
        final bytes = await readFile(file);
        total += bytes.length;
        if (total > BackupMedia.maxBytes) {
          throw const ChatException(
            'backup_media_too_large',
            'Recordings exceed the backup size limit',
          );
        }
        add(
          BackupCategory.media,
          '${BackupSnapshot.mediaPrefix}$name',
          bytes,
        );
      }
    }
    final pendingIncluded =
        cats.contains(BackupCategory.pendingMessages) &&
        pendingItems.isNotEmpty;
    if (pendingIncluded) {
      entries[BackupSnapshot.pendingEntry] = BackupSnapshot.encodePending(
        pendingItems,
      );
      sizes[BackupCategory.pendingMessages] = BackupCategorySize(
        items: pendingItems.length,
        bytes: entries[BackupSnapshot.pendingEntry]!.length,
      );
    }

    await BackupSnapshot.verifyStable(stamps, await _selection(cats));

    final manifest = <String, Object?>{
      'format': BackupSnapshot.manifestFormat,
      'version': BackupContainer.innerVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'platform': Platform.operatingSystem,
      'identity': {'toxId': record.toxId, 'displayName': record.displayName},
      'profileEncrypted': profileEncrypted,
      'categories': {
        for (final MapEntry(:key, :value) in sizes.entries)
          key.name: {'items': value.items, 'bytes': value.bytes},
      },
      'pending': {
        'count': pendingItems.length,
        'included': pendingIncluded,
        'withheldFromHistory': withheld,
      },
      'queuedInvites': meta?.queuedInvites.length ?? 0,
    };
    return BackupContainer(
      entries: {
        BackupSnapshot.manifestEntry: BackupSnapshot.encodeJson(manifest),
        ...entries,
      },
      profileEncrypted: profileEncrypted,
      formatVersion: BackupContainer.innerVersion,
    ).encode();
  }

  /// The files [_snapshot] reads for [cats], listed afresh: a file that
  /// appears here but was not read means data arrived mid-snapshot.
  Future<List<File>> _selection(Set<BackupCategory> cats) async => [
    File(_paths.profileFile),
    for (final f in [
      File(_paths.offlineQueueFile),
      File('${_paths.offlineQueueFile}.bak'),
    ])
      if (await f.exists()) f,
    for (final (rel, f) in await BackupSnapshot.files(
      _paths.trainingDirectory,
    ))
      if (rel == BackupSnapshot.restoredPendingFile ||
          (rel == BackupSnapshot.bookmarksFile
              ? cats.contains(BackupCategory.conversationMeta)
              : cats.contains(BackupCategory.training)))
        f,
    if (cats.contains(BackupCategory.chatHistory))
      for (final (_, f) in await BackupSnapshot.files(_paths.historyDirectory))
        f,
    if (cats.contains(BackupCategory.media))
      for (final name in await _referencedMedia())
        if (await File(p.join(_mediaDirectory, name)).exists())
          File(p.join(_mediaDirectory, name)),
  ];

  Future<RestoreReport> _restoreEncrypted(
    Uint8List bytes,
    String passphrase,
    String? identityPassword,
  ) async {
    final (preview, backup) = _openCached(bytes, passphrase);
    final profile = backup.profile!;
    final encrypted = preview.profileNeedsPassword;
    if (encrypted) {
      if (identityPassword == null || identityPassword.isEmpty) {
        throw const ChatException(
          'wrong_password',
          'The identity in this backup has its own password',
        );
      }
      final plain = _crypto.decrypt(profile, identityPassword);
      if (!preview.toxId.toUpperCase().startsWith(
        _crypto.extractPublicKey(plain),
      )) {
        throw const ChatException('invalid_backup', 'Identity mismatch');
      }
    }
    final record = IdentityRecord.decode(backup.identity!)!.copyWith(
      hasPassword: encrypted,
    );
    final pendingItems = BackupSnapshot.pendingItems(
      backup.entries[BackupSnapshot.pendingEntry],
    );
    final metaDoc = backup.entries[BackupSnapshot.conversationsEntry];
    final groupsDoc = backup.entries[BackupSnapshot.groupsEntry];

    final root = Directory(_paths.root);
    await PosixPermissions.createPrivateDirectory(root.parent.path);
    await _paths.excludeFromBackup();
    final stage = await root.parent.createTemp(IdentityPaths.importStagePrefix);
    final previous = Directory(p.join(stage.path, 'previous'));
    final staged = IdentityPaths(p.join(stage.path, 'identity'));
    var replaced = false;
    final old = _record ?? await IdentityRecord.read(_paths.identityFile);
    final oldPassword = _sessionPassword;
    try {
      await staged.ensureDirectories();
      await writeBytesAtomic(File(staged.profileFile), profile);
      await record.write(staged.identityFile);
      Future<void> put(String dir, String rel, Uint8List data) async {
        final target = File(p.join(dir, p.joinAll(rel.split('/'))));
        await target.parent.create(recursive: true);
        await target.writeAsBytes(data, flush: true);
      }

      for (final MapEntry(:key, :value) in backup.entries.entries) {
        if (key.startsWith(BackupSnapshot.trainingPrefix)) {
          await put(
            staged.trainingDirectory,
            key.substring(BackupSnapshot.trainingPrefix.length),
            value,
          );
        } else if (key.startsWith(BackupSnapshot.historyPrefix)) {
          await put(
            staged.historyDirectory,
            key.substring(BackupSnapshot.historyPrefix.length),
            value,
          );
        } else if (key.startsWith(BackupSnapshot.mediaPrefix)) {
          await put(
            p.join(staged.root, 'media', 'recordings'),
            key.substring(BackupSnapshot.mediaPrefix.length),
            value,
          );
        } else if (key == BackupSnapshot.bookmarksEntry) {
          await put(staged.trainingDirectory, BackupSnapshot.bookmarksFile, value);
        }
      }
      // Unsent messages become inert review items: no queue file is ever
      // written, so nothing can drain them, now or after a restart.
      if (pendingItems.isNotEmpty) {
        await put(
          staged.trainingDirectory,
          BackupSnapshot.restoredPendingFile,
          BackupSnapshot.encodePending(pendingItems),
        );
      }
      await _prepareForReplacement();
      await _disconnectImpl();
      _requireTeardownConfirmed();
      final store = _store;
      final before = store == null ? null : KvSnapshot.capture(store);
      await _verifier.replacePassword(
        record.toxId,
        encrypted ? identityPassword : null,
        () async {
          if (await root.exists()) await root.rename(previous.path);
          var movedIn = false;
          try {
            await Directory(staged.root).rename(root.path);
            movedIn = true;
            if (old != null) await _clearPreferences(old.toxId);
            await _clearPreferences(record.toxId);
            // Before the next connect() reads them (restore runs stopped).
            if (groupsDoc != null && store != null) {
              await GroupDescriptors.restore(
                store,
                _accountPrefix(record.toxId),
                BackupSnapshot.decodeJson(groupsDoc),
              );
            }
            if (metaDoc != null) {
              await _metaFor(record.toxId)?.importPortable(
                BackupSnapshot.decodeJson(metaDoc),
              );
            }
            replaced = true;
          } catch (_) {
            // Put the previous installation back: preferences first, then
            // the tree (the restored one returns to staging).
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
      _sessionPassword = encrypted ? identityPassword : null;
      _publish(record);
      if (old != null && old.toxId != record.toxId) {
        // Cleanup after the commit: a failure here must not report the
        // committed restore as failed.
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
    final restored = preview.sizes.keys.toSet()..add(BackupCategory.identity);
    return RestoreReport(
      restored: restored,
      notIncluded: BackupCategory.values.toSet().difference(restored),
      pendingForReview: pendingItems.length,
      pendingNotResumed: preview.pendingIncluded ? 0 : preview.pendingMessages,
      queuedInvitesNotResumed: preview.queuedInvites,
      preferences: backup.entries[BackupSnapshot.preferencesEntry],
    );
  }
}

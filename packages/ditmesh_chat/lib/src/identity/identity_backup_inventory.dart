part of 'tim2tox_identity_service.dart';

/// The export preview of a complete encrypted backup (F10): what the open
/// identity holds per category. Snapshot and restore: `identity_backup_v2.dart`.
extension _BackupInventory on Tim2ToxIdentityService {
  Future<BackupInventory> _backupInventory() async {
    final record = _requireRecord();
    await _persist();
    final sizes = <BackupCategory, BackupCategorySize>{};
    void add(BackupCategory c, int bytes) {
      final was = sizes[c] ?? BackupCategorySize.zero;
      sizes[c] = BackupCategorySize(
        items: was.items + 1,
        bytes: was.bytes + bytes,
      );
    }

    add(BackupCategory.identity, await File(_paths.profileFile).length());
    final queue = await BackupSnapshot.readQueue(_paths);
    var restoredPending = 0;
    for (final (rel, file) in await BackupSnapshot.files(
      _paths.trainingDirectory,
    )) {
      if (rel == BackupSnapshot.bookmarksFile) {
        add(BackupCategory.conversationMeta, await file.length());
      } else if (rel == BackupSnapshot.restoredPendingFile) {
        restoredPending = BackupSnapshot.pendingItems(
          await file.readAsBytes(),
        ).length;
      } else {
        add(BackupCategory.training, await file.length());
      }
    }
    for (final (_, file) in await BackupSnapshot.files(
      _paths.historyDirectory,
    )) {
      add(BackupCategory.chatHistory, await file.length());
    }
    final meta = _metaFor(record.toxId);
    if (meta != null) {
      final doc = meta.exportPortable();
      final count =
          (doc['pinned']! as List).length +
          (doc['hidden']! as List).length +
          (doc['drafts']! as Map).length;
      if (count > 0) {
        final was = sizes[BackupCategory.conversationMeta];
        sizes[BackupCategory.conversationMeta] = BackupCategorySize(
          items: (was?.items ?? 0) + count,
          bytes: (was?.bytes ?? 0) + BackupSnapshot.encodeJson(doc).length,
        );
      }
    }
    for (final name in await _referencedMedia()) {
      final file = File(p.join(_mediaDirectory, name));
      if (await file.exists()) add(BackupCategory.media, await file.length());
    }
    final pending = queue.length + restoredPending;
    if (pending > 0) {
      sizes[BackupCategory.pendingMessages] = BackupCategorySize(
        items: pending,
        bytes: 0,
      );
    }
    return BackupInventory(
      sizes: sizes,
      pendingMessages: pending,
      queuedInvites: meta?.queuedInvites.length ?? 0,
      profileHasPassword: _crypto.isEncrypted(
        await File(_paths.profileFile).readAsBytes(),
      ),
    );
  }

  Future<List<String>> _referencedMedia() async {
    // Relative to dataDirectory() (the training directory), like the
    // legacy exporter and the app's own count.
    final doc = File(p.join(_paths.trainingDirectory, BackupMedia.materialsDoc));
    return BackupMedia.referenced(
      await doc.exists() ? await doc.readAsString() : null,
    ).toList()..sort();
  }
}

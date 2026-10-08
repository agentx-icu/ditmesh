import 'dart:typed_data';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'backup_container.dart';
import 'backup_envelope.dart';
import 'backup_snapshot.dart';
import 'identity_record.dart';
import 'profile_crypto.dart';

/// Reading side of a complete encrypted backup (F10): opens the envelope
/// and checks the inner archive against its private manifest before any
/// restore step may touch the disk.
abstract final class BackupArchive {
  /// Opens and fully validates an encrypted backup; nothing is written.
  static (BackupPreview, BackupContainer) open(
    Uint8List bytes,
    String passphrase,
    ProfileCrypto crypto,
  ) {
    const invalid = ChatException('invalid_backup', 'Backup is malformed');
    final inner = BackupEnvelope.open(bytes, passphrase, crypto);
    final container = BackupContainer.decode(inner, inner: true);
    final rawManifest = container.entries[BackupSnapshot.manifestEntry];
    if (rawManifest == null) throw invalid;
    final manifest = BackupSnapshot.decodeJson(rawManifest);
    if (manifest is! Map ||
        manifest['format'] != BackupSnapshot.manifestFormat) {
      throw invalid;
    }
    if (manifest['version'] != BackupContainer.innerVersion) {
      throw const ChatException(
        'unsupported_backup_version',
        'This backup was written by a newer DitMesh',
      );
    }
    final profile = container.profile;
    final rawRecord = container.identity;
    if (profile == null || profile.isEmpty || rawRecord == null) throw invalid;
    final record = IdentityRecord.decode(rawRecord);
    final declared = manifest['identity'];
    if (record == null ||
        declared is! Map ||
        declared['toxId'] != record.toxId) {
      throw invalid;
    }
    final encrypted = crypto.isEncrypted(profile);
    if (!encrypted &&
        !record.toxId.toUpperCase().startsWith(
          crypto.extractPublicKey(profile),
        )) {
      throw invalid;
    }

    // Every entry must belong to a category the manifest declares, with
    // exactly the declared counts and sizes.
    final actual = <BackupCategory, (int, int)>{};
    for (final MapEntry(:key, :value) in container.entries.entries) {
      if (key == BackupSnapshot.manifestEntry) continue;
      final c = BackupSnapshot.categoryOf(key);
      if (c == null) throw invalid;
      final (n, b) = actual[c] ?? (0, 0);
      actual[c] = (n + 1, b + value.length);
    }
    final declaredCats = manifest['categories'];
    if (declaredCats is! Map) throw invalid;
    final sizes = <BackupCategory, BackupCategorySize>{};
    for (final c in BackupCategory.values) {
      final d = declaredCats[c.name];
      final a = actual[c];
      if (d == null && a == null) continue;
      if (d is! Map || a == null) throw invalid;
      final items = d['items'];
      final size = d['bytes'];
      if (items is! int || size is! int) throw invalid;
      if (c == BackupCategory.pendingMessages) {
        final list = BackupSnapshot.pendingItems(
          container.entries[BackupSnapshot.pendingEntry],
        );
        if (list.length != items || a.$2 != size) throw invalid;
      } else if (a.$1 != items || a.$2 != size) {
        throw invalid;
      }
      sizes[c] = BackupCategorySize(items: items, bytes: size);
    }
    final pending = manifest['pending'];
    final createdAt = DateTime.tryParse('${manifest['createdAt']}');
    if (pending is! Map || createdAt == null) throw invalid;
    final pendingCount = pending['count'];
    final pendingIncluded = pending['included'];
    final invites = manifest['queuedInvites'];
    if (pendingCount is! int || pendingIncluded is! bool || invites is! int) {
      throw invalid;
    }
    if (pendingIncluded != sizes.containsKey(BackupCategory.pendingMessages)) {
      throw invalid;
    }
    return (
      BackupPreview(
        toxId: record.toxId,
        displayName: record.displayName,
        createdAt: createdAt,
        sourcePlatform: '${manifest['platform'] ?? ''}',
        sizes: sizes,
        pendingMessages: pendingCount,
        pendingIncluded: pendingIncluded,
        queuedInvites: invites,
        profileNeedsPassword: encrypted,
      ),
      container,
    );
  }
}

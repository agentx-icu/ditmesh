import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'backup_media.dart';

/// What a complete backup can carry (F10). [identity] is always included;
/// everything else is chosen on export.
enum BackupCategory {
  /// identity.json and the Tox profile. Required.
  identity,

  /// Training progress, settings and saved learning materials.
  training,

  /// Native chat history, including note-to-self.
  chatHistory,

  /// Drafts, pins, hidden conversations and message bookmarks.
  conversationMeta,

  /// Explicitly portable app preferences (playback, notifications,
  /// appearance, language). Never window bounds or hardware bindings.
  preferences,

  /// Saved workbench recordings (opt-in; large).
  media,

  /// Unsent messages, restored only as inert review items: never put back
  /// into the live send queue.
  pendingMessages,
}

/// Item count and byte size of one category.
@immutable
final class BackupCategorySize {
  const BackupCategorySize({required this.items, required this.bytes});

  static const BackupCategorySize zero = BackupCategorySize(items: 0, bytes: 0);

  final int items;
  final int bytes;
}

/// What the open identity holds, for the export preview.
@immutable
final class BackupInventory {
  const BackupInventory({
    required this.sizes,
    required this.pendingMessages,
    required this.queuedInvites,
    required this.profileHasPassword,
  });

  /// Size per category present on this device (absent: nothing to back up).
  final Map<BackupCategory, BackupCategorySize> sizes;

  /// Messages in the durable outbox right now.
  final int pendingMessages;

  /// Group invitations queued for offline friends; never carried over.
  final int queuedInvites;

  /// Whether the Tox profile inside stays encrypted with the identity
  /// password (the destination then needs that password too).
  final bool profileHasPassword;

  BackupCategorySize sizeOf(BackupCategory c) =>
      sizes[c] ?? BackupCategorySize.zero;
}

/// Export parameters.
@immutable
final class EncryptedBackupRequest {
  const EncryptedBackupRequest({
    required this.passphrase,
    required this.categories,
    this.preferences,
  });

  /// Encrypts the whole archive. Separate from the identity password and
  /// never stored.
  final String passphrase;

  /// Categories to include; [BackupCategory.identity] is implied.
  final Set<BackupCategory> categories;

  /// The app's portable preferences document (UTF-8 JSON), carried when
  /// [BackupCategory.preferences] is selected. The backend does not read it.
  final Uint8List? preferences;
}

/// What an encrypted backup holds, read after the passphrase opened it and
/// every entry validated. Nothing on disk has changed yet.
@immutable
final class BackupPreview {
  const BackupPreview({
    required this.toxId,
    required this.displayName,
    required this.createdAt,
    required this.sizes,
    required this.pendingMessages,
    required this.pendingIncluded,
    required this.queuedInvites,
    required this.profileNeedsPassword,
    this.sourcePlatform = '',
  });

  final String toxId;
  final String displayName;
  final DateTime createdAt;
  final String sourcePlatform;

  /// Included categories and their sizes; a category missing here was left
  /// out on export (or did not exist on the source).
  final Map<BackupCategory, BackupCategorySize> sizes;

  /// Unsent messages on the source when it was exported.
  final int pendingMessages;

  /// Whether their texts are in the archive (as review items).
  final bool pendingIncluded;
  final int queuedInvites;

  /// The Tox profile is still encrypted with the identity password: restore
  /// asks for it as well.
  final bool profileNeedsPassword;

  String get publicKey => toxId.length >= 64 ? toxId.substring(0, 64) : toxId;

  bool includes(BackupCategory c) => sizes.containsKey(c);
}

/// Outcome of a restore, for the report screen.
@immutable
final class RestoreReport {
  const RestoreReport({
    required this.restored,
    required this.notIncluded,
    required this.pendingForReview,
    required this.pendingNotResumed,
    required this.queuedInvitesNotResumed,
    this.preferences,
  });

  final Set<BackupCategory> restored;

  /// Categories the archive did not carry.
  final Set<BackupCategory> notIncluded;

  /// Unsent messages restored as inert review items (never queued).
  final int pendingForReview;

  /// Unsent messages the source had that were not carried over.
  final int pendingNotResumed;
  final int queuedInvitesNotResumed;

  /// The portable preferences document for the app to apply, or null.
  final Uint8List? preferences;
}

/// An unsent message brought over from the source device, kept outside the
/// live queue so it can never be sent automatically. The user may key it
/// again or dismiss it.
@immutable
final class RestoredPendingItem {
  const RestoredPendingItem({
    required this.id,
    required this.conversationId,
    required this.text,
    required this.queuedAt,
  });

  final String id;
  final String conversationId;
  final String text;
  final DateTime queuedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'text': text,
    'queuedAt': queuedAt.toUtc().toIso8601String(),
  };

  static RestoredPendingItem? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final conv = json['conversationId'];
    final text = json['text'];
    final at = DateTime.tryParse('${json['queuedAt']}');
    if (id is! String || conv is! String || text is! String || at == null) {
      return null;
    }
    return RestoredPendingItem(
      id: id,
      conversationId: conv,
      text: text,
      queuedAt: at,
    );
  }
}

/// Where restored pending items live, relative to
/// `IdentityService.dataDirectory()`; owned by the app after restore.
const String restoredPendingDoc = 'chat/restored_pending.json';

/// Optional capability of an [IdentityService] that writes complete,
/// whole-archive encrypted backups (F10). Legacy `exportBackup` /
/// `importBackup` stay for old archives.
///
/// Error codes: `wrong_passphrase` (cannot open: wrong passphrase, altered
/// or truncated), `invalid_backup`, `unsupported_backup_version`,
/// `backup_too_large`, `backup_busy` (data kept changing during export),
/// `wrong_password` (identity password for an encrypted profile).
abstract interface class EncryptedBackupService {
  /// Sizes per category for the export preview. Requires an open identity.
  Future<BackupInventory> backupInventory();

  /// A consistent snapshot of the selected categories, sealed with the
  /// passphrase. Networking pauses while the snapshot is taken.
  Future<Uint8List> exportEncryptedBackup(EncryptedBackupRequest request);

  /// Opens and validates [bytes] without changing anything.
  Future<BackupPreview> previewEncryptedBackup(
    Uint8List bytes,
    String passphrase,
  );

  /// Drops whatever [previewEncryptedBackup] kept open for a following
  /// restore (decrypted contents and the passphrase).
  void forgetPreview();

  /// Replaces the current identity with the backup's, transactionally: on
  /// any failure the previous installation stays in place. Restored pending
  /// messages and invitations never send, not even after a restart.
  Future<RestoreReport> restoreEncryptedBackup(
    Uint8List bytes,
    String passphrase, {
    String? identityPassword,
  });
}

/// Largest backup file (either format) the app reads or the backend
/// accepts: the archive is built and opened in memory, and opt-in
/// recordings alone may reach [BackupMedia.maxBytes].
const int maxBackupFileBytes = 192 * 1024 * 1024;

/// Magic of the encrypted envelope (`MCQE`).
const List<int> encryptedBackupMagic = [0x4D, 0x43, 0x51, 0x45];

/// Whether [bytes] look like an encrypted (F10) backup rather than a legacy
/// MCQB v1 archive. Cheap; does not validate.
bool isEncryptedBackup(Uint8List bytes) {
  if (bytes.length < encryptedBackupMagic.length) return false;
  for (var i = 0; i < encryptedBackupMagic.length; i++) {
    if (bytes[i] != encryptedBackupMagic[i]) return false;
  }
  return true;
}

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../util/posix_permissions.dart';
import '../logging/chat_logger.dart';
import 'backup_exclusion.dart';

/// On-disk layout of the (single) ditmesh identity.
///
/// ```text
/// <root>/                     e.g. <appSupport>/ditmesh/identity
///   identity.json             display name, status, Tox ID, hasPassword
///   profile/tox_profile.tox   Tox savedata (always encrypted on disk when
///                             a password is set; native encrypts each save)
///   data/chat_history/        Tim2Tox message history (JSON per conversation)
///   data/offline_message_queue.json
///   data/file_recv/  data/avatars/  data/scratch/
///   training/                 IdentityService.dataDirectory(): other
///                             modules' per-identity state (morse_trainer)
/// ```
///
/// `tox_profile.tox` is the file name Tim2Tox's `initWithPath` reads and
/// writes inside the profile directory (same as toxee's
/// `AppPaths.profileFileInDirectory`).
///
/// Backups: [backupExclusionRoot] (the parent of [root], e.g.
/// `<appSupport>/ditmesh`) is excluded from platform backups (iOS) through
/// [backupExclusion]. The parent, not [root], because [root] itself is
/// replaced by a rename on restore and deleted on reset, which would drop a
/// flag set on it; restore staging (`.ditmesh-import-*`) lives there too.
/// The independent network/probe profiles also live under this parent.
class IdentityPaths {
  const IdentityPaths(
    this.root, {
    this.backupExclusion = const NoBackupExclusion(),
  });

  /// Production layout under the platform application-support directory
  /// (Library/Application Support on macOS/iOS, the app's files dir on
  /// Android, XDG data dir on Linux, %APPDATA% on Windows).
  static Future<IdentityPaths> forApplicationSupport({
    ChatLogger logger = const SilentChatLogger(),
    BackupExclusion? backupExclusion,
  }) async {
    final base = await getApplicationSupportDirectory();
    return IdentityPaths(
      p.join(base.path, 'ditmesh', 'identity'),
      backupExclusion:
          backupExclusion ?? BackupExclusion.forPlatform(logger: logger),
    );
  }

  final String root;

  /// Marks [backupExclusionRoot] as not-for-backup; see the class docs.
  final BackupExclusion backupExclusion;

  /// The directory kept out of backups: the parent of [root].
  String get backupExclusionRoot => p.dirname(root);

  String get identityFile => p.join(root, 'identity.json');
  String get profileDirectory => p.join(root, 'profile');
  String get profileFile => p.join(profileDirectory, 'tox_profile.tox');
  String get dataDirectory => p.join(root, 'data');
  String get historyDirectory => p.join(dataDirectory, 'chat_history');
  String get offlineQueueFile =>
      p.join(dataDirectory, 'offline_message_queue.json');
  String get fileRecvDirectory => p.join(dataDirectory, 'file_recv');
  String get avatarsDirectory => p.join(dataDirectory, 'avatars');
  String get scratchDirectory => p.join(dataDirectory, 'scratch');
  String get trainingDirectory => p.join(root, 'training');

  /// Creates every directory the engine writes into. The identity root and
  /// its parent (where import staging lives) are made owner-only first, so
  /// nothing below them is ever reachable by other local accounts.
  Future<void> ensureDirectories() async {
    await PosixPermissions.createPrivateDirectory(p.dirname(root));
    await PosixPermissions.createPrivateDirectory(root);
    for (final dir in [
      profileDirectory,
      historyDirectory,
      fileRecvDirectory,
      avatarsDirectory,
      scratchDirectory,
      trainingDirectory,
    ]) {
      await Directory(dir).create(recursive: true);
    }
    await excludeFromBackup();
  }

  /// Creates [backupExclusionRoot] if needed and excludes it from backup.
  /// Never throws; called on every [ensureDirectories] (cheap, idempotent)
  /// so an existing install and a recreated tree are both covered.
  Future<void> excludeFromBackup() async {
    try {
      await Directory(backupExclusionRoot).create(recursive: true);
      await backupExclusion.exclude(backupExclusionRoot);
    } on Object {
      // BackupExclusion implementations log their own failures; a missing
      // flag must not block the identity.
    }
  }

  /// Excludes [backupExclusionRoot] only if it already exists; creates
  /// nothing. Run at startup (`inspect`) so an identity installed before the
  /// exclusion existed is covered even if it stays locked and never reaches
  /// [ensureDirectories]. Returns whether the exclusion was attempted.
  /// Never throws.
  Future<bool> excludeExistingFromBackup() async {
    try {
      if (!await Directory(backupExclusionRoot).exists()) return false;
      await backupExclusion.exclude(backupExclusionRoot);
    } on Object {
      // See [excludeFromBackup].
    }
    return true;
  }

  bool get profileExists => File(profileFile).existsSync();

  /// Prefix of the staging directories an import creates next to [root]
  /// (`identity_backup.dart`); a failed import may leave one holding the
  /// previous identity as its only recovery copy.
  static const String importStagePrefix = '.ditmesh-import-';

  /// Deletes the whole identity tree, and any import staging directory next
  /// to it (they hold an older copy of this identity). Irreversible.
  Future<void> deleteAll() async {
    final dir = Directory(root);
    if (await dir.exists()) await dir.delete(recursive: true);
    final parent = dir.parent;
    if (!await parent.exists()) return;
    await for (final entry in parent.list(followLinks: false)) {
      if (entry is Directory &&
          p.basename(entry.path).startsWith(importStagePrefix)) {
        await entry.delete(recursive: true);
      }
    }
  }
}

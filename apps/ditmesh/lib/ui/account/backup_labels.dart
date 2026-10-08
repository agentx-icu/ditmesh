import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/l10n_extension.dart';

/// User-facing name of a backup category (F10).
String backupCategoryLabel(S s, BackupCategory c) => switch (c) {
  BackupCategory.identity => s.backupXCategoryIdentity,
  BackupCategory.training => s.backupXCategoryTraining,
  BackupCategory.chatHistory => s.backupXCategoryChat,
  BackupCategory.conversationMeta => s.backupXCategoryMeta,
  BackupCategory.preferences => s.backupXCategoryPrefs,
  BackupCategory.media => s.backupXCategoryMedia,
  BackupCategory.pendingMessages => s.backupXCategoryPending,
};

/// What choosing [c] means, where that is not obvious from the name.
String? backupCategoryHint(S s, BackupCategory c) => switch (c) {
  BackupCategory.preferences => s.backupXPrefsHint,
  BackupCategory.media => s.backupXMediaHint,
  BackupCategory.pendingMessages => s.backupXPendingHint,
  _ => null,
};

/// [bytes] as KB / MB, one decimal for MB.
String formatBackupSize(S s, int bytes) {
  if (bytes < 1024 * 1024) {
    return s.backupXSizeKb((bytes / 1024).ceil().toString());
  }
  return s.backupXSizeMb((bytes / (1024 * 1024)).toStringAsFixed(1));
}

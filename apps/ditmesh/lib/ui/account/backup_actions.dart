import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../listen/workbench/recording_files.dart';
import 'backup_file_gateway.dart';
import 'encrypted_backup_page.dart';

/// File name for a backup of [identity]: readable, unique per identity, and
/// with an extension the restore picker can recognise.
String backupFileName(Identity identity) {
  final safeName = identity.displayName
      .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  final prefix = safeName.isEmpty ? 'identity' : safeName;
  return 'ditmesh-$prefix-${identity.publicKey.substring(0, 8)}.mcqbackup';
}

/// Global (window-coordinate) rect of the widget behind [context], as
/// `share_plus` expects for `sharePositionOrigin`; null when it has no laid
/// out box or an empty one (the plugin then centres the iPad popover).
Rect? shareOriginOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.attached || !box.hasSize) return null;
  final rect = box.localToGlobal(Offset.zero) & box.size;
  return rect.isEmpty ? null : rect;
}

/// Largest total of saved recordings a backup may carry (the container is
/// built in memory); the backend enforces the same limit.
const int maxBackupMediaBytes = BackupMedia.maxBytes;

/// Recordings are left out of backups by default (functional spec §11.3);
/// when there are saved ones, the learner may opt in. Null = cancelled.
Future<bool?> _askIncludeRecordings(
  BuildContext context,
  IdentityService identity,
) async {
  final (int count, int bytes) saved;
  try {
    final data = await identity.dataDirectory();
    final doc = File(p.join(data, BackupMedia.materialsDoc));
    // The same rule the backend exports with: referenced saved recordings.
    final referenced = BackupMedia.referenced(
      doc.existsSync() ? doc.readAsStringSync() : null,
    );
    saved = RecordingLibrary(p.dirname(data)).savedSizeSync(referenced);
  } on Object {
    return false;
  }
  if (saved.$1 == 0 || !context.mounted) return false;
  final s = context.s;
  final mb = (saved.$2 / (1024 * 1024)).toStringAsFixed(1);
  final tooLarge = saved.$2 > maxBackupMediaBytes;
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(s.accountBackupMediaTitle),
      content: Text(
        tooLarge
            ? s.accountBackupMediaTooLarge(mb)
            : s.accountBackupMediaBody(saved.$1, mb),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.actionCancel),
        ),
        if (!tooLarge)
          TextButton(
            key: const ValueKey('backup-include-media'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.accountBackupMediaInclude),
          ),
        FilledButton(
          key: const ValueKey('backup-without-media'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(s.accountBackupMediaSkip),
        ),
      ],
    ),
  );
}

/// Outcome of [exportBackupWithFeedback].
enum BackupExportResult { saved, cancelled, failed }

/// Exports the current identity through the [BackupFileGateway] and reports
/// the outcome with a snackbar: the complete encrypted flow
/// ([EncryptedBackupPage]) when the backend supports it, else the legacy
/// identity + training archive. Shared by the first-run wizard and the Me
/// page so both surfaces behave identically on every platform.
///
/// [anchor] is the context of the control that was tapped; its rect anchors
/// the iPad share-sheet popover (see [BackupFileGateway.saveBackup]). Pass
/// the button's own context (e.g. via a [Builder]), not the page's.
Future<BackupExportResult> exportBackupWithFeedback(
  BuildContext context, {
  BuildContext? anchor,
}) async {
  final shareOrigin = anchor == null ? null : shareOriginOf(anchor);
  final s = context.s;
  final identityService = context.read<IdentityService>();
  final gateway = context.read<BackupFileGateway>();
  final messenger = ScaffoldMessenger.maybeOf(context);
  final identity = identityService.current;
  if (identity == null) {
    messenger?.showSnackBar(SnackBar(content: Text(s.accountMeNoIdentity)));
    return BackupExportResult.failed;
  }
  // Backends that seal complete backups (F10) get the full flow: categories,
  // passphrase, whole-file encryption. The page reports its own outcome.
  if (identityService is EncryptedBackupService) {
    final result = await Navigator.of(context).push<BackupExportResult>(
      MaterialPageRoute(builder: (_) => const EncryptedBackupPage()),
    );
    return result ?? BackupExportResult.cancelled;
  }
  final includeMedia = await _askIncludeRecordings(context, identityService);
  if (includeMedia == null) return BackupExportResult.cancelled;
  try {
    final bytes = await identityService.exportBackup(
      includeMedia: includeMedia,
    );
    final saved = await gateway.saveBackup(
      bytes,
      fileName: backupFileName(identity),
      shareOrigin: shareOrigin,
    );
    messenger?.showSnackBar(
      SnackBar(
        content: Text(saved ? s.accountBackupSaved : s.accountBackupNotSaved),
      ),
    );
    return saved ? BackupExportResult.saved : BackupExportResult.cancelled;
  } on Object catch (e) {
    messenger?.showSnackBar(
      SnackBar(
        content: Text('${s.accountBackupFailed}: ${describeChatError(s, e)}'),
      ),
    );
    return BackupExportResult.failed;
  }
}

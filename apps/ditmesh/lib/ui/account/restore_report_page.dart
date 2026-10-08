import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/l10n_extension.dart';
import 'account_widgets.dart';
import 'backup_labels.dart';

/// What an encrypted backup holds (F10), shown after the passphrase opened
/// it and before anything is replaced.
class BackupPreviewCard extends StatelessWidget {
  const BackupPreviewCard({super.key, required this.preview});

  final BackupPreview preview;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final created = DateFormat.yMd(
      locale,
    ).add_Hm().format(preview.createdAt.toLocal());
    final key = preview.publicKey;
    final included = [
      for (final c in BackupCategory.values)
        if (preview.includes(c)) c,
    ];
    final excluded = [
      for (final c in BackupCategory.values)
        if (!preview.includes(c) && c != BackupCategory.identity) c,
    ];
    return Card(
      key: const ValueKey('restore-x-preview'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.restoreXPreviewTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '${preview.displayName} · ${key.length > 8 ? key.substring(0, 8) : key}',
              style: theme.textTheme.titleSmall,
            ),
            Text(s.restoreXCreated(created)),
            const SizedBox(height: 8),
            Text(s.restoreXIncluded, style: theme.textTheme.labelLarge),
            for (final c in included)
              Text(
                '• ${backupCategoryLabel(s, c)} '
                '(${formatBackupSize(s, preview.sizes[c]!.bytes)})',
              ),
            if (excluded.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(s.restoreXExcluded, style: theme.textTheme.labelLarge),
              for (final c in excluded) Text('• ${backupCategoryLabel(s, c)}'),
            ],
            if (preview.pendingMessages > 0) ...[
              const SizedBox(height: 8),
              Text(
                preview.pendingIncluded
                    ? s.restoreXPendingIncluded(preview.pendingMessages)
                    : s.restoreXPendingExcluded(preview.pendingMessages),
              ),
            ],
            if (preview.queuedInvites > 0)
              Text(s.restoreXReportInvites(preview.queuedInvites)),
            if (preview.profileNeedsPassword) ...[
              const SizedBox(height: 8),
              Text(s.restoreXIdentityPasswordNote),
            ],
          ],
        ),
      ),
    );
  }
}

/// The restoration report: what came back, what did not and why, and the
/// one migration rule (stop using the old device's copy).
class RestoreReportPage extends StatelessWidget {
  const RestoreReportPage({
    super.key,
    required this.report,
    this.preferencesFailed = false,
  });

  final RestoreReport report;

  /// The portable preferences could not be applied (the previous ones
  /// were kept).
  final bool preferencesFailed;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final restored = [
      for (final c in BackupCategory.values)
        if (report.restored.contains(c) &&
            !(c == BackupCategory.preferences && preferencesFailed))
          c,
    ];
    final missing = [
      for (final c in BackupCategory.values)
        if (!restored.contains(c)) c,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(s.restoreXReportTitle),
        automaticallyImplyLeading: false,
      ),
      body: AccountPageBody(
        children: [
          Text(s.restoreXReportRestored, style: theme.textTheme.titleSmall),
          for (final c in restored)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.check, color: theme.colorScheme.primary),
              title: Text(backupCategoryLabel(s, c)),
            ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              s.restoreXReportNotIncluded,
              style: theme.textTheme.titleSmall,
            ),
            for (final c in missing)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.remove),
                title: Text(backupCategoryLabel(s, c)),
              ),
          ],
          if (preferencesFailed) Text(s.restoreXReportPrefsFailed),
          if (report.pendingForReview > 0)
            Text(s.restoreXReportPendingReview(report.pendingForReview)),
          if (report.pendingNotResumed > 0)
            Text(s.restoreXReportPendingNotResumed(report.pendingNotResumed)),
          if (report.queuedInvitesNotResumed > 0)
            Text(s.restoreXReportInvites(report.queuedInvitesNotResumed)),
          const SizedBox(height: 16),
          Text(
            s.restoreXReportStopOld,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const ValueKey('restore-x-done'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(s.restoreXReportDone),
          ),
        ],
      ),
    );
  }
}

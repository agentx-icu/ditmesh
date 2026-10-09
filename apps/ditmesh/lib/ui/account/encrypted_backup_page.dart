import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../di/app_preferences.dart';
import '../../di/portable_preferences.dart';
import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../../i18n/locale_controller.dart';
import '../common/app_bar_title.dart';
import 'account_widgets.dart';
import 'backup_actions.dart';
import 'backup_file_gateway.dart';
import 'backup_labels.dart';

/// Complete encrypted backup (F10): choose categories → preview sizes →
/// passphrase → one consistent, whole-file encrypted archive → save/share,
/// with the platform's actual outcome. Pops with a [BackupExportResult].
class EncryptedBackupPage extends StatefulWidget {
  const EncryptedBackupPage({super.key});

  static const Key exportKey = ValueKey('backup-x-export');

  /// Minimum passphrase length the page accepts.
  static const int minPassphrase = 8;

  @override
  State<EncryptedBackupPage> createState() => _EncryptedBackupPageState();
}

class _EncryptedBackupPageState extends State<EncryptedBackupPage> {
  final _passphrase = TextEditingController();
  final _confirm = TextEditingController();
  late final Future<BackupInventory> _inventory;
  final Set<BackupCategory> _selected = {
    BackupCategory.training,
    BackupCategory.chatHistory,
    BackupCategory.conversationMeta,
    BackupCategory.preferences,
  };
  String? _passphraseError;
  String? _outcome;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final service = context.read<IdentityService>();
    _inventory = service is EncryptedBackupService
        ? (service as EncryptedBackupService).backupInventory()
        : Future.error(
            const ChatException('unsupported_backup_version', 'Unsupported'),
          );
  }

  @override
  void dispose() {
    _passphrase.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _export(BuildContext anchor, BackupInventory inventory) async {
    final s = context.s;
    final pass = _passphrase.text;
    final error = pass.length < EncryptedBackupPage.minPassphrase
        ? s.backupXPassphraseTooShort
        : pass != _confirm.text
        ? s.backupXPassphraseMismatch
        : null;
    setState(() {
      _passphraseError = error;
      _outcome = null;
    });
    if (error != null) return;
    final origin = shareOriginOf(anchor);
    final identityService = context.read<IdentityService>();
    final service = identityService as EncryptedBackupService;
    final gateway = context.read<BackupFileGateway>();
    final prefs = context.read<AppPreferences>();
    final locale = context.read<LocaleController>();
    final navigator = Navigator.of(context);
    final identity = identityService.current;
    if (identity == null) return;
    setState(() => _busy = true);
    BackupExportResult result;
    String message;
    try {
      final bytes = await service.exportEncryptedBackup(
        EncryptedBackupRequest(
          passphrase: pass,
          categories: {
            for (final c in _selected)
              if (_available(c, inventory)) c,
          },
          preferences: _selected.contains(BackupCategory.preferences)
              ? prefs.exportPortable(locale: locale)
              : null,
        ),
      );
      final saved = await gateway.saveBackup(
        bytes,
        fileName: backupFileName(identity),
        shareOrigin: origin,
      );
      result = saved ? BackupExportResult.saved : BackupExportResult.cancelled;
      message = saved ? s.accountBackupSaved : s.accountBackupNotSaved;
    } on Object catch (e) {
      result = BackupExportResult.failed;
      message = '${s.accountBackupFailed}: ${backupErrorMessage(s, e)}';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _outcome = message;
    });
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
    if (result == BackupExportResult.saved) navigator.pop(result);
  }

  bool _available(BackupCategory c, BackupInventory inv) => switch (c) {
    BackupCategory.identity => true,
    BackupCategory.preferences => true,
    BackupCategory.media =>
      inv.sizeOf(c).items > 0 && inv.sizeOf(c).bytes <= BackupMedia.maxBytes,
    _ => inv.sizeOf(c).items > 0,
  };

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(s.backupXTitle)),
      body: FutureBuilder<BackupInventory>(
        future: _inventory,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(backupErrorMessage(s, snap.error!)),
              ),
            );
          }
          final inv = snap.data;
          if (inv == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _body(context, inv);
        },
      ),
    );
  }

  Widget _body(BuildContext context, BackupInventory inv) {
    final s = context.s;
    final theme = Theme.of(context);
    var total = 0;
    for (final c in BackupCategory.values) {
      if (c == BackupCategory.identity ||
          (_selected.contains(c) && _available(c, inv))) {
        total += inv.sizeOf(c).bytes;
      }
    }
    final mediaSize = inv.sizeOf(BackupCategory.media);
    return AccountPageBody(
      maxWidth: 640,
      children: [
        Text(s.backupXIntro, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        for (final c in BackupCategory.values)
          if (c != BackupCategory.pendingMessages || inv.pendingMessages > 0)
            CheckboxListTile(
              key: ValueKey('backup-x-${c.name}'),
              contentPadding: EdgeInsets.zero,
              value: c == BackupCategory.identity ||
                  (_selected.contains(c) && _available(c, inv)),
              onChanged: c == BackupCategory.identity ||
                      !_available(c, inv) ||
                      _busy
                  ? null
                  : (v) => setState(
                      () => v == true ? _selected.add(c) : _selected.remove(c),
                    ),
              title: Text(backupCategoryLabel(s, c)),
              subtitle: Text(
                [
                  if (c == BackupCategory.identity) s.backupXRequired,
                  if (c == BackupCategory.media &&
                      mediaSize.bytes > BackupMedia.maxBytes)
                    s.backupXMediaTooLarge(formatBackupSize(s, mediaSize.bytes))
                  else if (c != BackupCategory.preferences)
                    s.backupXSizeLine(
                      inv.sizeOf(c).items,
                      formatBackupSize(s, inv.sizeOf(c).bytes),
                    ),
                  if (backupCategoryHint(s, c) case final String hint) hint,
                ].join('\n'),
              ),
            ),
        if (inv.queuedInvites > 0)
          Text(s.backupXInvitesNote(inv.queuedInvites)),
        if (inv.profileHasPassword) ...[
          const SizedBox(height: 8),
          Text(s.backupXIdentityPasswordNote),
        ],
        const SizedBox(height: 16),
        Text(
          s.backupXTotal(formatBackupSize(s, total)),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 16),
        PasswordField(
          key: const ValueKey('backup-x-passphrase'),
          controller: _passphrase,
          label: s.backupXPassphrase,
          showStrength: true,
          errorText: _passphraseError,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 8),
        PasswordField(
          key: const ValueKey('backup-x-confirm'),
          controller: _confirm,
          label: s.backupXPassphraseConfirm,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 4),
        Text(s.backupXPassphraseHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        Text(
          s.backupXMigrationNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 16),
        Builder(
          builder: (button) => FilledButton.icon(
            key: EncryptedBackupPage.exportKey,
            onPressed: _busy ? null : () => _export(button, inv),
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_outline),
            label: Text(_busy ? s.backupXExporting : s.backupXExport),
          ),
        ),
        if (_outcome case final String text) ...[
          const SizedBox(height: 8),
          Text(text, key: const ValueKey('backup-x-outcome')),
        ],
      ],
    );
  }
}

/// Localized message for backup / restore errors, including the codes only
/// backups use; everything else goes through the chat error table.
String backupErrorMessage(S s, Object error) => switch (error) {
  ChatException(code: 'wrong_passphrase') => s.restoreXWrongPassphrase,
  ChatException(code: 'unsupported_backup_version') => s.restoreXUnsupported,
  ChatException(code: 'invalid_backup') => s.accountRestoreInvalidFile,
  ChatException(code: 'backup_busy') => s.backupXBusy,
  ChatException(code: 'backup_too_large' || 'backup_media_too_large') =>
    s.backupXTooLarge,
  _ => describeChatError(s, error),
};

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../di/app_preferences.dart';
import '../../di/portable_preferences.dart';
import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../../i18n/locale_controller.dart';
import '../../startup/startup_controller.dart';
import '../common/app_bar_title.dart';
import 'account_routes.dart';
import 'account_widgets.dart';
import 'backup_file_gateway.dart';
import 'encrypted_backup_page.dart';
import 'restore_report_page.dart';

/// Pick a backup file → optional password → `importBackup`. Reached from the
/// welcome page and from the unlock screen ("restore instead").
///
/// A complete encrypted backup (F10, `MCQE`) takes a different path: backup
/// passphrase → validated preview → identity password when the profile
/// inside has one → explicit replacement confirmation → transactional
/// restore → report.
class RestoreBackupPage extends StatefulWidget {
  const RestoreBackupPage({super.key});

  @override
  State<RestoreBackupPage> createState() => _RestoreBackupPageState();
}

class _RestoreBackupPageState extends State<RestoreBackupPage> {
  final _password = TextEditingController();
  final _passphrase = TextEditingController();
  Uint8List? _bytes;
  BackupPreview? _preview;
  String? _passphraseError;
  String? _fileError;
  String? _passwordError;
  bool _busy = false;
  bool _picking = false;

  bool get _operationPending => _busy || _picking;

  late final IdentityService _identityService;

  @override
  void initState() {
    super.initState();
    _identityService = context.read<IdentityService>();
  }

  @override
  void dispose() {
    // Do not keep a decrypted archive around once the page is gone.
    final service = _identityService;
    if (service is EncryptedBackupService) {
      (service as EncryptedBackupService).forgetPreview();
    }
    _password.dispose();
    _passphrase.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (_operationPending) return;
    final s = context.s;
    final gateway = context.read<BackupFileGateway>();
    setState(() => _picking = true);
    try {
      final bytes = await gateway.pickBackup();
      if (!mounted || bytes == null) return;
      setState(() {
        _bytes = bytes;
        _preview = null;
        _fileError = null;
        _passwordError = null;
        _passphraseError = null;
      });
    } on ChatException catch (e) {
      if (!mounted) return;
      // invalid_backup (e.g. a file far too large to be a backup) is
      // backup-only and not in the shared chat error table.
      setState(
        () => _fileError = e.code == 'invalid_backup'
            ? s.accountRestoreInvalidFile
            : describeChatError(s, e),
      );
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _fileError = describeChatError(s, e));
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  bool get _encrypted {
    final bytes = _bytes;
    return bytes != null && isEncryptedBackup(bytes);
  }

  /// Opens the encrypted backup with the passphrase; changes nothing.
  Future<void> _openEncrypted() async {
    if (_operationPending) return;
    final s = context.s;
    final bytes = _bytes!;
    final service = switch (context.read<IdentityService>()) {
      final EncryptedBackupService b => b,
      _ => null,
    };
    if (service == null) {
      setState(() => _fileError = s.restoreXUnsupported);
      return;
    }
    setState(() {
      _busy = true;
      _passphraseError = null;
      _fileError = null;
    });
    try {
      final preview = await service.previewEncryptedBackup(
        bytes,
        _passphrase.text,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _preview = preview;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (e is ChatException && e.code == 'wrong_passphrase') {
          _passphraseError = backupErrorMessage(s, e);
        } else {
          _fileError = backupErrorMessage(s, e);
        }
      });
    }
  }

  Future<bool> _confirmReplace() async {
    final s = context.s;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(s.restoreXConfirmTitle),
        content: Text(s.restoreXConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.actionCancel),
          ),
          FilledButton(
            key: const ValueKey('restore-x-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.restoreXConfirm),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _restoreEncrypted(Uint8List bytes, BackupPreview preview) async {
    final s = context.s;
    final passphrase = _passphrase.text;
    final identityPassword = preview.profileNeedsPassword
        ? _password.text
        : null;
    final route = ModalRoute.of<void>(context);
    setState(() => _busy = true);
    final confirmed = await _confirmReplace();
    if (!mounted) return;
    if (!confirmed) {
      setState(() => _busy = false);
      return;
    }
    setState(() {
      _fileError = null;
      _passwordError = null;
    });
    final controller = context.read<StartupController>();
    final prefs = context.read<AppPreferences>();
    final locale = context.read<LocaleController>();
    try {
      final report = await controller.restoreEncryptedBackup(
        bytes,
        passphrase,
        identityPassword: identityPassword,
      );
      // Let the identity change reach the preference owners first, so the
      // restored mutes land under the restored identity.
      await Future<void>.delayed(Duration.zero);
      var prefsFailed = false;
      final doc = report.preferences;
      if (doc != null) {
        try {
          prefsFailed = !await prefs.applyPortable(doc, locale: locale);
        } on Object {
          prefsFailed = true;
        }
      }
      if (route == null || !route.isCurrent) {
        closeAccountRoute(route);
        return;
      }
      await route.navigator!.pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) =>
              RestoreReportPage(report: report, preferencesFailed: prefsFailed),
        ),
      );
    } on ChatException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (e.code == 'wrong_password') {
          _passwordError = describeChatError(s, e);
        } else {
          _fileError = backupErrorMessage(s, e);
        }
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _fileError = backupErrorMessage(s, e);
      });
    }
  }

  Future<void> _restore() async {
    if (_operationPending) return;
    final s = context.s;
    final bytes = _bytes;
    if (bytes == null) {
      setState(() => _fileError = s.accountRestoreNoFile);
      return;
    }
    if (isEncryptedBackup(bytes)) {
      final preview = _preview;
      return preview == null
          ? _openEncrypted()
          : _restoreEncrypted(bytes, preview);
    }
    setState(() {
      _busy = true;
      _fileError = null;
      _passwordError = null;
    });
    final controller = context.read<StartupController>();
    final route = ModalRoute.of<void>(context);
    try {
      await controller.restoreFromBackup(
        bytes,
        password: _password.text.isEmpty ? null : _password.text,
      );
      closeAccountRoute(route);
    } on ChatException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        switch (e.code) {
          case 'wrong_password':
            _passwordError = describeChatError(s, e);
          case 'invalid_backup':
            // Backup-only code; not part of the shared chat error table.
            _fileError = s.accountRestoreInvalidFile;
          default:
            _fileError = describeChatError(s, e);
        }
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _fileError = describeChatError(s, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final hasLockedIdentity = context.select<StartupController, bool>(
      (controller) => controller.phase == StartupPhase.locked,
    );
    final replacesIdentity =
        _identityService.current != null || hasLockedIdentity;
    final bytes = _bytes;
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(s.accountRestoreTitle)),
      body: AccountPageBody(
        children: [
          Text(s.accountRestoreBody, style: theme.textTheme.bodyMedium),
          if (replacesIdentity) ...[
            const SizedBox(height: 12),
            Text(
              s.accountRestoreReplacesWarning,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _operationPending ? null : _pick,
            icon: const Icon(Icons.folder_open),
            label: Text(s.accountRestoreChooseFile),
          ),
          if (bytes != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.accountRestoreFileChosenSize(bytes.length),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          if (_fileError != null) ...[
            const SizedBox(height: 8),
            Text(
              _fileError!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (_encrypted) ...[
            PasswordField(
              key: const ValueKey('restore-x-passphrase'),
              controller: _passphrase,
              label: s.backupXPassphrase,
              errorText: _passphraseError,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _openEncrypted(),
            ),
            const SizedBox(height: 8),
            if (_preview == null)
              OutlinedButton(
                key: const ValueKey('restore-x-open'),
                onPressed: _operationPending ? null : _openEncrypted,
                child: Text(s.restoreXCheck),
              )
            else ...[
              BackupPreviewCard(preview: _preview!),
              if (_preview!.profileNeedsPassword) ...[
                const SizedBox(height: 16),
                PasswordField(
                  key: const ValueKey('restore-x-identity-password'),
                  controller: _password,
                  label: s.restoreXIdentityPassword,
                  errorText: _passwordError,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ],
          ] else
            PasswordField(
              controller: _password,
              label: s.accountPasswordOptional,
              errorText: _passwordError,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _restore(),
            ),
          const SizedBox(height: 32),
          FilledButton(
            key: const ValueKey('restore-button'),
            onPressed: _operationPending || (_encrypted && _preview == null)
                ? null
                : _restore,
            child: Text(_busy ? s.accountRestoring : s.accountRestoreButton),
          ),
        ],
      ),
    );
  }
}

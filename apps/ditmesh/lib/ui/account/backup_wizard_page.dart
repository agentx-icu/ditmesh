import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../i18n/l10n_extension.dart';
import '../../startup/startup_controller.dart';
import '../common/app_bar_title.dart';
import 'account_widgets.dart';
import 'backup_actions.dart';
import 'tox_id_qr_dialog.dart';

/// Mandatory first-run backup step. There is no skip: the user must at least
/// tick the acknowledgement before the shell appears. Saving the file is
/// strongly encouraged but cannot be verified (the share sheet gives no
/// reliable result), so the checkbox is the gate.
class BackupWizardPage extends StatefulWidget {
  const BackupWizardPage({super.key, required this.mandatory});

  /// True when shown by the startup gate after creation. Reserved for a later
  /// "re-run the wizard" entry from the Me page.
  final bool mandatory;

  /// The save/share button; its label is platform-dependent, so tests find
  /// it by key.
  static const Key saveButtonKey = Key('backup_wizard_save');

  @override
  State<BackupWizardPage> createState() => _BackupWizardPageState();
}

class _BackupWizardPageState extends State<BackupWizardPage> {
  bool _acknowledged = false;
  bool _saving = false;
  BackupExportResult? _lastExport;
  String? _savedPath;

  Future<void> _save(BuildContext button) async {
    setState(() {
      _saving = true;
      _lastExport = null;
      _savedPath = null;
    });
    String? savedPath;
    final result = await exportBackupWithFeedback(
      context,
      anchor: button,
      inlineFeedback: true,
      onSavedPath: (path) => savedPath = path,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _lastExport = result;
      _savedPath = savedPath;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final identity = context.read<IdentityService>().current;
    final platform = theme.platform;
    final isMobile = backupUsesShare(platform);
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(s.accountBackupTitle),
        automaticallyImplyLeading: !widget.mandatory,
      ),
      body: AccountPageBody(
        aside: [
          if (identity != null)
            AccountPanel(
              children: [
                Text(s.accountToxId, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SelectableText(groupToxId(identity.toxId)),
                const SizedBox(height: 8),
                Text(
                  s.accountBackupShowQrHint,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          showToxIdQrDialog(context, identity.toxId),
                      icon: const Icon(Icons.qr_code_2),
                      label: Text(s.accountShowQr),
                    ),
                    TextButton.icon(
                      onPressed: () => copyToClipboard(context, identity.toxId),
                      icon: const Icon(Icons.copy),
                      label: Text(s.actionCopy),
                    ),
                  ],
                ),
              ],
            ),
        ],
        children: [
          AccountPanel(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(s.accountBackupBody, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              // A complete backup (F10) is sealed as a whole with a passphrase;
              // in a legacy archive only a password-protected key is encrypted.
              Text(
                context.read<IdentityService>() is EncryptedBackupService
                    ? s.backupXWizardInside
                    : identity?.hasPassword ?? false
                    ? s.accountBackupWhatIsInside
                    : s.accountBackupWhatIsInsidePlain,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Builder(
                // The button's own context anchors the iPad share popover.
                builder: (button) => FilledButton.icon(
                  key: BackupWizardPage.saveButtonKey,
                  onPressed: _saving ? null : () => _save(button),
                  icon: Icon(isMobile ? Icons.ios_share : Icons.save_alt),
                  label: Text(
                    isMobile
                        ? s.accountBackupShareFile
                        : s.accountBackupSaveFile,
                  ),
                ),
              ),
              if (_lastExport case final result?) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: BulletLine(
                    key: const ValueKey('backup-export-outcome'),
                    icon: result == BackupExportResult.saved && !isMobile
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    text: backupExportFeedback(
                      s,
                      platform,
                      result,
                      savedFileName: _savedPath == null
                          ? null
                          : p.basename(_savedPath!),
                    ),
                  ),
                ),
                if (_savedPath case final path? when !isMobile) ...[
                  const SizedBox(height: 8),
                  SelectableText(path),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      icon: const Icon(Icons.copy),
                      onPressed: () => copyToClipboard(context, path),
                      label: Text(s.accountBackupCopyLocation),
                    ),
                  ),
                ],
              ],
            ],
          ),
          const SizedBox(height: 12),
          AccountPanel(
            children: [
              CheckboxListTile(
                value: _acknowledged,
                onChanged: (v) => setState(() => _acknowledged = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(s.accountBackupAcknowledge),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _acknowledged
                    ? () => context
                          .read<StartupController>()
                          .completeBackupWizard()
                    : null,
                child: Text(s.accountBackupContinue),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

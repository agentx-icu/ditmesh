import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../i18n/l10n_extension.dart';
import '../../startup/startup_controller.dart';
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

  Future<void> _save(BuildContext button) async {
    setState(() => _saving = true);
    final result = await exportBackupWithFeedback(context, anchor: button);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _lastExport = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final identity = context.read<IdentityService>().current;
    final isMobile = switch (Theme.of(context).platform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(s.accountBackupTitle),
        automaticallyImplyLeading: !widget.mandatory,
      ),
      body: AccountPageBody(
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
            builder: (button) => FilledButton.tonalIcon(
              key: BackupWizardPage.saveButtonKey,
              onPressed: _saving ? null : () => _save(button),
              icon: Icon(isMobile ? Icons.ios_share : Icons.save_alt),
              label: Text(
                isMobile ? s.accountBackupShareFile : s.accountBackupSaveFile,
              ),
            ),
          ),
          if (_lastExport == BackupExportResult.saved) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    s.accountBackupSaved,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Text(
            s.accountBackupShowQrHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: identity == null
                ? null
                : () => showToxIdQrDialog(context, identity.toxId),
            icon: const Icon(Icons.qr_code_2),
            label: Text(s.accountShowQr),
          ),
          const SizedBox(height: 24),
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
                ? () => context.read<StartupController>().completeBackupWizard()
                : null,
            child: Text(s.accountBackupContinue),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../../startup/startup_controller.dart';
import 'account_widgets.dart';
import '../network/bootstrap_page.dart';
import 'restore_backup_page.dart';

/// Password prompt for an encrypted profile. The password is never persisted;
/// every cold start comes back here (same fail-closed stance as toxee).
class UnlockPage extends StatefulWidget {
  const UnlockPage({super.key});

  @override
  State<UnlockPage> createState() => _UnlockPageState();
}

class _UnlockPageState extends State<UnlockPage> {
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_password.text.isEmpty) return;
    final s = context.s;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<StartupController>().unlock(_password.text);
      // On success the gate swaps this page out; nothing to do here.
    } on Object catch (e) {
      // `wrong_password` and any other ChatException code map through the
      // shared table; anything else reads as the generic error.
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = describeChatError(s, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Scaffold(
      body: AccountPageBody(
        children: [
          const SizedBox(height: 48),
          Icon(Icons.lock_outline, size: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            s.accountUnlockTitle,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            s.accountUnlockBody,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          PasswordField(
            controller: _password,
            label: s.accountPassword,
            errorText: _error,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _unlock(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy || _password.text.isEmpty ? null : _unlock,
            child: Text(_busy ? s.accountUnlocking : s.accountUnlockButton),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RestoreBackupPage(),
              ),
            ),
            child: Text(s.accountUnlockRestoreInstead),
          ),
          TextButton.icon(
            key: const ValueKey('onboarding-network-bootstrap'),
            onPressed: () => BootstrapPage.open(context),
            icon: const Icon(Icons.hub_outlined),
            label: Text(s.bootstrapTitle),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

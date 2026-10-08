import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../../startup/startup_controller.dart';
import 'account_widgets.dart';

/// Display name + optional password (with strength hint and confirmation).
/// On success the page pops back to the gate, which is now showing the
/// mandatory backup wizard.
class CreateIdentityPage extends StatefulWidget {
  const CreateIdentityPage({super.key});

  @override
  State<CreateIdentityPage> createState() => _CreateIdentityPageState();
}

class _CreateIdentityPageState extends State<CreateIdentityPage> {
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _nameError;
  String? _confirmError;
  String? _submitError;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _wantsPassword => _password.text.isNotEmpty;

  Future<void> _submit() async {
    final s = context.s;
    final name = _name.text.trim();
    setState(() {
      _nameError = name.isEmpty ? s.accountDisplayNameRequired : null;
      _confirmError = _wantsPassword && _confirm.text != _password.text
          ? s.accountPasswordsDoNotMatch
          : null;
      _submitError = null;
    });
    if (_nameError != null || _confirmError != null) return;

    setState(() => _busy = true);
    final controller = context.read<StartupController>();
    final navigator = Navigator.of(context);
    try {
      await controller.createIdentity(
        displayName: name,
        password: _wantsPassword ? _password.text : null,
      );
      // The gate (route 0) now renders the backup wizard.
      navigator.popUntil((route) => route.isFirst);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _submitError = describeChatError(s, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.accountCreateTitle)),
      body: AccountPageBody(
        children: [
          Text(s.accountCreateBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          TextField(
            controller: _name,
            autofocus: true,
            textInputAction: TextInputAction.next,
            maxLength: 64,
            decoration: InputDecoration(
              labelText: s.accountDisplayName,
              hintText: s.accountDisplayNameHint,
              errorText: _nameError,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: _password,
            label: s.accountPasswordOptional,
            showStrength: true,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Text(
            s.accountPasswordScope,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (_wantsPassword) ...[
            const SizedBox(height: 16),
            PasswordField(
              controller: _confirm,
              label: s.accountConfirmPassword,
              errorText: _confirmError,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ],
          if (_submitError != null) ...[
            const SizedBox(height: 16),
            Text(
              _submitError!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? s.accountCreating : s.accountCreateButton),
          ),
        ],
      ),
    );
  }
}

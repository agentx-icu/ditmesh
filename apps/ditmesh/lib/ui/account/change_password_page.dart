import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import 'account_widgets.dart';

/// Set, change or remove the profile password. When the identity already has
/// one, the current password is required for either action.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, required this.hasPassword});

  final bool hasPassword;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  String? _currentError;
  String? _nextError;
  String? _confirmError;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _apply({required bool remove}) async {
    final s = context.s;
    setState(() {
      _currentError = null;
      _nextError = remove || _next.text.isNotEmpty
          ? null
          : s.accountNewPasswordRequired;
      _confirmError = !remove && _confirm.text != _next.text
          ? s.accountPasswordsDoNotMatch
          : null;
    });
    if (_nextError != null || _confirmError != null) return;

    setState(() => _busy = true);
    final service = context.read<IdentityService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await service.changePassword(
        oldPassword: widget.hasPassword ? _current.text : null,
        newPassword: remove ? null : _next.text,
      );
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            remove ? s.accountPasswordRemoved : s.accountPasswordUpdated,
          ),
        ),
      );
      navigator.pop();
    } on ChatException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (e.code == 'wrong_password') {
          _currentError = describeChatError(s, e);
        } else {
          _nextError = describeChatError(s, e);
        }
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _nextError = describeChatError(s, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final title = widget.hasPassword
        ? s.accountChangePassword
        : s.accountSetPassword;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AccountPageBody(
        children: [
          if (widget.hasPassword) ...[
            PasswordField(
              controller: _current,
              label: s.accountCurrentPassword,
              errorText: _currentError,
              autofocus: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
          ],
          PasswordField(
            controller: _next,
            label: s.accountNewPassword,
            errorText: _nextError,
            showStrength: true,
            autofocus: !widget.hasPassword,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: _confirm,
            label: s.accountConfirmPassword,
            errorText: _confirmError,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _apply(remove: false),
          ),
          const SizedBox(height: 12),
          Text(
            s.accountPasswordScope,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : () => _apply(remove: false),
            child: Text(s.actionSave),
          ),
          if (widget.hasPassword) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy ? null : () => _apply(remove: true),
              child: Text(s.accountRemovePassword),
            ),
          ],
        ],
      ),
    );
  }
}

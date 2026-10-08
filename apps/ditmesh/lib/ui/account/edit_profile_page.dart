import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import 'account_widgets.dart';

/// Display name and status message.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.identity});

  final Identity identity;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final _name = TextEditingController(text: widget.identity.displayName);
  late final _status = TextEditingController(
    text: widget.identity.statusMessage,
  );
  String? _nameError;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _status.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = context.s;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = s.accountDisplayNameRequired);
      return;
    }
    setState(() {
      _busy = true;
      _nameError = null;
      _error = null;
    });
    final service = context.read<IdentityService>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await service.updateProfile(
        displayName: name,
        statusMessage: _status.text.trim(),
      );
      messenger?.showSnackBar(SnackBar(content: Text(s.accountProfileUpdated)));
      navigator.pop();
    } on Object catch (e) {
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
      appBar: AppBar(title: Text(s.accountEditProfile)),
      body: AccountPageBody(
        children: [
          Text(s.accountEditProfileBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: 64,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: s.accountDisplayName,
              errorText: _nameError,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _status,
            maxLength: 128,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: s.accountStatusMessage,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(s.actionSave),
          ),
        ],
      ),
    );
  }
}

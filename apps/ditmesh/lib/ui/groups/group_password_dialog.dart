import 'package:flutter/material.dart';

import '../../i18n/l10n_extension.dart';

/// Asks for a group's password. Resolves to null when cancelled and to the
/// text as typed (spaces kept, possibly empty) when confirmed.
Future<String?> showGroupPasswordDialog(
  BuildContext context, {
  required String groupName,
}) => showDialog<String>(
  context: context,
  builder: (_) => _GroupPasswordDialog(groupName: groupName),
);

class _GroupPasswordDialog extends StatefulWidget {
  const _GroupPasswordDialog({required this.groupName});

  final String groupName;

  @override
  State<_GroupPasswordDialog> createState() => _GroupPasswordDialogState();
}

class _GroupPasswordDialogState extends State<_GroupPasswordDialog> {
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _confirm() => Navigator.of(context).pop(_password.text);

  @override
  Widget build(BuildContext context) {
    final S s = context.s;
    return AlertDialog(
      title: Text(s.chatGroupPasswordTitle(widget.groupName)),
      content: TextField(
        key: const ValueKey<String>('group_password_field'),
        controller: _password,
        autofocus: true,
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _confirm(),
        decoration: InputDecoration(
          labelText: s.chatGroupPasswordField,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.actionCancel),
        ),
        FilledButton(onPressed: _confirm, child: Text(s.chatJoin)),
      ],
    );
  }
}

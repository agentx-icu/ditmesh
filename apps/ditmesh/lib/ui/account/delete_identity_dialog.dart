import 'package:flutter/material.dart';

import '../../i18n/l10n_extension.dart';

/// Typed-confirmation dialog. Resolves true only when the user typed the
/// confirm word exactly and pressed Delete; the caller performs the deletion.
Future<bool> confirmDeleteIdentity(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => const DeleteIdentityDialog(),
  );
  return result ?? false;
}

class DeleteIdentityDialog extends StatefulWidget {
  const DeleteIdentityDialog({super.key});

  @override
  State<DeleteIdentityDialog> createState() => _DeleteIdentityDialogState();
}

class _DeleteIdentityDialogState extends State<DeleteIdentityDialog> {
  final _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  /// The confirm word is a localized string so the body, the hint and the
  /// check always agree.
  bool _confirmed(S s) => _typed.text.trim() == s.accountDeleteConfirmWord;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final confirmed = _confirmed(s);
    return AlertDialog(
      scrollable: true,
      icon: Icon(Icons.delete_forever, color: theme.colorScheme.error),
      title: Text(s.accountDeleteDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(s.accountDeleteDialogBody),
          const SizedBox(height: 16),
          TextField(
            controller: _typed,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (_confirmed(s)) Navigator.of(context).pop(true);
            },
            decoration: InputDecoration(
              hintText: s.accountDeleteConfirmHint,
              hintMaxLines: 2,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(s.actionCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: confirmed ? () => Navigator.of(context).pop(true) : null,
          child: Text(s.accountDeleteButton),
        ),
      ],
    );
  }
}

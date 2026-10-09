import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../common/field_label.dart';
import '../contacts/tox_id.dart';

/// Join an NGC group by its 64-hex chat id (+ optional password). Resolves
/// to true when the join was requested; the group shows up in the list once
/// the DHT finds a peer.
Future<bool> showJoinGroupSheet(
  BuildContext context, {
  required ChatService service,
}) async {
  final bool? joined = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: JoinGroupForm(service: service),
    ),
  );
  return joined ?? false;
}

class JoinGroupForm extends StatefulWidget {
  const JoinGroupForm({super.key, required this.service});

  final ChatService service;

  @override
  State<JoinGroupForm> createState() => _JoinGroupFormState();
}

class _JoinGroupFormState extends State<JoinGroupForm> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _chatId = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;

  /// Last backend failure, translated in [build].
  Object? _error;

  @override
  void dispose() {
    _chatId.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _error = null);
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await widget.service.joinGroup(
        normalizeToxId(_chatId.text),
        password: _password.text.isEmpty ? null : _password.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final S s = context.s;
    final Object? error = _error;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Form(
          key: _form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.chatJoinGroup, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _chatId,
                autofocus: true,
                minLines: 1,
                maxLines: 2,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: InputDecoration(
                  label: FieldLabel(s.chatChatIdLabel),
                  border: const OutlineInputBorder(),
                  errorText: error == null ? null : describeChatError(s, error),
                ),
                validator: (v) => validateChatIdInput(s, v),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  label: FieldLabel(s.chatPassword),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : () => unawaited(_submit()),
                icon: const Icon(Icons.login),
                label: Text(s.chatJoin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

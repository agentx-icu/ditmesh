import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';

/// Create a group. Kind is fixed to NGC; an "advanced" expander exposes the
/// legacy conference switch for interop with old clients (plan §5.4).
/// Resolves to the created group, or null when dismissed.
Future<Group?> showCreateGroupSheet(
  BuildContext context, {
  required ChatService service,
}) {
  return showModalBottomSheet<Group>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: CreateGroupForm(service: service),
    ),
  );
}

class CreateGroupForm extends StatefulWidget {
  const CreateGroupForm({super.key, required this.service});

  final ChatService service;

  @override
  State<CreateGroupForm> createState() => _CreateGroupFormState();
}

class _CreateGroupFormState extends State<CreateGroupForm> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  bool _advanced = false;
  bool _conference = false;
  bool _busy = false;

  /// Last backend failure, translated in [build].
  Object? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // One native creation at a time: Enter in the name field while the
    // first request is pending must not start a second group.
    if (_busy) return;
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final Group group = await widget.service.createGroup(
        _name.text.trim(),
        kind: _conference ? GroupKind.conference : GroupKind.group,
      );
      if (mounted) Navigator.of(context).pop(group);
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.chatCreateGroup, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                autofocus: true,
                readOnly: _busy,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: _busy ? null : (_) => unawaited(_submit()),
                decoration: InputDecoration(
                  labelText: s.chatGroupName,
                  border: const OutlineInputBorder(),
                  errorText: error == null ? null : describeChatError(s, error),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? s.chatGroupNameRequired : null,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _advanced = !_advanced),
                icon: Icon(_advanced ? Icons.expand_less : Icons.expand_more),
                label: Text(s.chatAdvanced),
                style: TextButton.styleFrom(alignment: Alignment.centerLeft),
              ),
              if (_advanced)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(s.chatLegacyConference),
                  subtitle: Text(s.chatLegacyConferenceHint),
                  value: _conference,
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _conference = v),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _busy ? null : () => unawaited(_submit()),
                icon: const Icon(Icons.group_add),
                label: Text(s.chatCreate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

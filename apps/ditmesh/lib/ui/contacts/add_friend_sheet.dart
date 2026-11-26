import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../../nearby/nearby_controller.dart';
import '../account/account_widgets.dart';
import '../account/tox_id_qr_dialog.dart';
import '../common/app_bar_title.dart';
import '../nearby/nearby_page.dart';
import '../common/close_owned_route.dart';
import '../common/field_label.dart';
import 'qr_scan_page.dart';
import 'tox_id.dart';

/// Page to paste or scan a Tox ID and send an optional greeting.
/// Resolves to true when a request was sent.
Future<bool> showAddFriendSheet(
  BuildContext context, {
  required ChatService service,
  String? ownToxId,
  bool? canScan,
}) async {
  final form = AddFriendForm(
    service: service,
    ownToxId: ownToxId,
    canScan:
        canScan ??
        switch (defaultTargetPlatform) {
          TargetPlatform.android ||
          TargetPlatform.iOS ||
          TargetPlatform.macOS => true,
          _ => false,
        },
  );
  final s = context.s;
  final sent = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (pageContext) => Scaffold(
        appBar: AppBar(title: AppBarTitle(s.chatAddFriend)),
        body: AccountPageBody(
          aside: [
            if (ownToxId != null)
              AccountPanel(
                children: [
                  Text(
                    s.chatMyToxId,
                    style: Theme.of(pageContext).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(groupToxId(ownToxId)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            unawaited(showToxIdQrDialog(pageContext, ownToxId)),
                        icon: const Icon(Icons.qr_code_2),
                        label: Text(s.accountShowQr),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            unawaited(copyToClipboard(pageContext, ownToxId)),
                        icon: const Icon(Icons.copy),
                        label: Text(s.actionCopy),
                      ),
                    ],
                  ),
                ],
              ),
          ],
          children: [
            AccountPanel(children: [form]),
          ],
        ),
      ),
    ),
  );
  return sent ?? false;
}

class AddFriendForm extends StatefulWidget {
  const AddFriendForm({
    super.key,
    required this.service,
    this.ownToxId,
    this.canScan = false,
  });

  final ChatService service;
  final String? ownToxId;

  /// Whether the QR scanner is available on the current platform.
  final bool canScan;

  @override
  State<AddFriendForm> createState() => _AddFriendFormState();
}

class _AddFriendFormState extends State<AddFriendForm> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _id = TextEditingController();
  final TextEditingController _message = TextEditingController();
  bool _messageSeeded = false;

  /// Backend rejection, kept as the [ChatException] code and translated in
  /// [build] so a locale change re-renders it.
  String? _serverErrorCode;
  bool _busy = false;
  bool _scanning = false;
  QrCameraIssue? _cameraIssue;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The greeting default is a localized string, so it cannot be seeded in
    // the field initializer; do it once the first time S is reachable.
    if (!_messageSeeded) {
      _messageSeeded = true;
      _message.text = context.s.chatDefaultRequestMessage;
    }
  }

  @override
  void dispose() {
    _id.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    if (_busy || _scanning) return;
    _scanning = true;
    try {
      QrCameraIssue? issue;
      final String? scanned = await QrScanPage.open(
        context,
        onUnavailable: (value) => issue = value,
      );
      if (!mounted) return;
      setState(() => _cameraIssue = scanned == null ? issue : null);
      if (scanned == null) return;
      _id.text = scanned;
      _form.currentState?.validate();
    } finally {
      _scanning = false;
    }
  }

  Future<void> _submit() async {
    if (_busy || _scanning) return;
    setState(() => _serverErrorCode = null);
    if (!(_form.currentState?.validate() ?? false)) return;
    final String fallback = context.s.chatDefaultRequestMessage;
    setState(() => _busy = true);
    final route = ModalRoute.of(context);
    try {
      await widget.service.addFriend(
        normalizeToxId(_id.text),
        message: _message.text.trim().isEmpty ? fallback : _message.text.trim(),
      );
      closeOwnedRoute(route, true);
    } on ChatException catch (e) {
      if (mounted) setState(() => _serverErrorCode = e.code);
    } on Object {
      if (mounted) setState(() => _serverErrorCode = '');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Field-level wording for the codes the validator also produces, the
  /// shared error table for everything else.
  String? _serverError(S s) => switch (_serverErrorCode) {
    null => null,
    'invalid_tox_id' => s.chatToxIdInvalid,
    'own_id' => s.chatToxIdOwn,
    'already_friend' => s.chatToxIdAlreadyFriend,
    final String code => chatErrorMessage(s, code),
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final S s = context.s;
    final String? serverError = _serverError(s);
    // Scrollable: the ID field autofocuses, so on a short phone the keyboard
    // inset plus the scan row could otherwise push the send button off the
    // sheet.
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Form(
          key: _form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.chatAddFriend, style: theme.textTheme.titleLarge),
              if (context.watch<NearbyController?>() != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: const Key('add_friend_nearby_button'),
                    onPressed: _busy ? null : () => NearbyPage.open(context),
                    icon: const Icon(Icons.radar),
                    label: Text(s.peopleNearby),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _id,
                autofocus: true,
                maxLines: 8,
                minLines: 1,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: InputDecoration(
                  label: FieldLabel(s.chatToxIdLabel),
                  border: const OutlineInputBorder(),
                  errorText: serverError,
                  errorMaxLines: 6,
                  // No suffixIcon on purpose. With a Tooltip in this slot the
                  // framework asserted "Invisible SemanticsNodes should not
                  // be added to the tree" while the sheet was dismissed after
                  // a send, on macOS and iOS alike (the tooltip's button node
                  // ended up with an inverted rect under the suffixIcon tag;
                  // integration_test/app_launch_test.dart). Without the
                  // tooltip the node is gone; the scan action lives below the
                  // field instead.
                ),
                validator: (v) =>
                    validateToxIdInput(s, v, ownToxId: widget.ownToxId),
                onChanged: (_) {
                  if (_serverErrorCode != null) {
                    setState(() => _serverErrorCode = null);
                  }
                },
              ),
              if (!widget.canScan || _cameraIssue != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    switch (_cameraIssue) {
                      QrCameraIssue.permissionDenied =>
                        s.chatScanQrPermissionHelp,
                      QrCameraIssue.unavailable => s.chatScanQrManualHint,
                      QrCameraIssue.unsupported ||
                      null => s.chatScanQrDesktopHint,
                    },
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (widget.canScan && _cameraIssue != QrCameraIssue.unsupported)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _busy ? null : () => unawaited(_scan()),
                    icon: Icon(
                      _cameraIssue == QrCameraIssue.unavailable
                          ? Icons.refresh
                          : Icons.qr_code_scanner,
                    ),
                    label: Text(
                      _cameraIssue == QrCameraIssue.unavailable
                          ? s.actionRetry
                          : s.chatScanQr,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _message,
                decoration: InputDecoration(
                  label: FieldLabel(s.chatRequestMessage),
                  border: const OutlineInputBorder(),
                ),
                maxLength: 200,
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _busy ? null : () => unawaited(_submit()),
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(s.chatSendRequest),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

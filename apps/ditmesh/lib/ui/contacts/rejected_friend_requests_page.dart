import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:flutter/material.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../account/account_widgets.dart';
import '../chat/chat_layout.dart';
import '../common/app_bar_title.dart';

class RejectedFriendRequestsPage extends StatefulWidget {
  const RejectedFriendRequestsPage({super.key, required this.filter});

  final FriendRequestFilter filter;

  @override
  State<RejectedFriendRequestsPage> createState() =>
      _RejectedFriendRequestsPageState();
}

class _RejectedFriendRequestsPageState
    extends State<RejectedFriendRequestsPage> {
  late Future<List<String>> _requests = widget.filter
      .rejectedFriendRequestKeys();
  bool _saving = false;

  Future<void> _allow(String publicKey) async {
    if (_saving) return;
    setState(() => _saving = true);
    final s = context.s;
    try {
      await widget.filter.allowFutureFriendRequests(publicKey);
      if (!mounted) return;
      _requests = widget.filter.rejectedFriendRequestKeys();
      showSnack(context, s.chatFutureRequestsAllowed);
    } on Object catch (error) {
      if (mounted) showSnack(context, describeChatError(s, error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(s.chatRejectedRequests)),
      body: AccountPageBody(
        maxWidth: 680,
        children: [
          AccountPanel(children: [Text(s.chatRejectedRequestsHelp)]),
          FutureBuilder<List<String>>(
            future: _requests,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return AccountPanel(
                  children: [
                    Text(describeChatError(s, snapshot.error!)),
                    TextButton(
                      onPressed: () => setState(
                        () => _requests = widget.filter
                            .rejectedFriendRequestKeys(),
                      ),
                      child: Text(s.actionRetry),
                    ),
                  ],
                );
              }
              final keys = snapshot.data;
              if (keys == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return AccountPanel(
                children: [
                  if (keys.isEmpty) Text(s.chatRejectedRequestsEmpty),
                  for (final key in keys) ...[
                    SelectableText(groupToxId(key)),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: _saving ? null : () => _allow(key),
                        child: Text(s.chatAllowFutureRequests),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

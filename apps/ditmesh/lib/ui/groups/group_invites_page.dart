import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/l10n_extension.dart';
import 'group_invites_inbox.dart';

/// The pending group invites on a page of their own: what a tapped invite
/// notification opens when the groups page (whose inbox is inline) is
/// covered by another flow the tap should not tear down.
class GroupInvitesPage extends StatelessWidget {
  const GroupInvitesPage({super.key, required this.service});

  final ChatService service;

  static Route<void> route(ChatService service) => MaterialPageRoute<void>(
    builder: (_) => GroupInvitesPage(service: service),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.s.navGroups)),
    body: ListView(children: [GroupInvitesInbox(service: service)]),
  );
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/l10n_extension.dart';
import '../contacts/contacts_page.dart';
import 'chat_scope.dart';
import 'conversation_route.dart';

/// A next step after actual self practice. Selecting a contact opens the real
/// composer; it never sends a message or treats a local note as delivery.
class FirstContactCard extends StatelessWidget {
  const FirstContactCard({super.key, required this.service});

  final ChatService service;

  void _contacts(BuildContext context) {
    final navigator = Navigator.of(context);
    unawaited(
      ContactsPage.open(
        context,
        service: service,
        identity: maybeIdentityService(context),
        onOpenConversation: (target) {
          navigator.pop();
          if (navigator.mounted) openConversationRoute(navigator, target);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Friend>>(
    stream: service.friendChanges,
    initialData: service.friends,
    builder: (context, snapshot) => Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.s.firstChatNextTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(context.s.firstChatOnline),
            TextButton.icon(
              key: const ValueKey('first-contact-next'),
              onPressed: () => _contacts(context),
              icon: const Icon(Icons.people_outline),
              label: Text(
                (snapshot.data?.isNotEmpty ?? false)
                    ? context.s.firstChatChooseFriend
                    : context.s.firstChatFriend,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

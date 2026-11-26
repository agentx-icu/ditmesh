import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/l10n_extension.dart';
import '../account/account_widgets.dart';
import '../common/app_bar_title.dart';
import '../contacts/contacts_page.dart';
import 'chat_scope.dart';
import 'conversation_route.dart';
import 'morse_pattern_text.dart';
import 'playback_timeline.dart';

/// A next step after actual self practice. Selecting a contact opens the real
/// composer; it never sends a message or treats a local note as delivery.
class FirstContactCard extends StatelessWidget {
  const FirstContactCard({
    super.key,
    required this.service,
    required this.practice,
    required this.onPlay,
  });

  final ChatService service;
  final ChatMessage practice;
  final VoidCallback onPlay;

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

  Future<void> _overview(BuildContext context) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) {
            final s = context.s;
            return Scaffold(
              appBar: AppBar(title: AppBarTitle(s.firstChatTitle)),
              body: AccountPageBody(
                maxWidth: 640,
                aside: [
                  AccountPanel(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.check_circle_outline),
                        title: Text(s.firstChatKeyTitle),
                      ),
                      ListTile(
                        leading: const Icon(Icons.headphones_outlined),
                        title: Text(s.firstChatListenTitle),
                        subtitle: Text(s.firstChatListenBody),
                      ),
                      ListTile(
                        leading: const Icon(Icons.person_add_outlined),
                        title: Text(s.firstChatFriendTitle),
                        subtitle: Text(s.firstChatFriendBody),
                      ),
                      ListTile(
                        leading: const Icon(Icons.swap_horiz),
                        title: Text(s.firstChatExchangeTitle),
                        subtitle: Text(s.firstChatReceiptBody),
                      ),
                    ],
                  ),
                ],
                children: [
                  AccountPanel(
                    children: [
                      Text(
                        s.deliveryLocalTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(s.chatSelfLocalOnly),
                      const SizedBox(height: 12),
                      MorsePatternText(
                        PlaybackTimeline.patternFor(practice.text),
                      ),
                      SelectableText(practice.text),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: onPlay,
                            icon: const Icon(Icons.play_arrow),
                            label: Text(s.chatPlay),
                          ),
                          FilledButton.icon(
                            onPressed: () => _contacts(context),
                            icon: const Icon(Icons.person_add_outlined),
                            label: Text(
                              service.friends.isEmpty
                                  ? s.firstChatFriend
                                  : s.firstChatChooseFriend,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

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
            TextButton(
              key: const ValueKey('first-contact-overview'),
              onPressed: () => unawaited(_overview(context)),
              child: Text(context.s.firstChatTitle),
            ),
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

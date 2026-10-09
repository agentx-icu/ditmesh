import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/l10n_extension.dart';
import 'first_chat_progress.dart';
import 'morse_pattern_text.dart';

/// A first conversation uses the real composer and playback. The guide never
/// pre-fills a draft, auto-sends a message or requests a friend automatically.
class FirstChatGuideCard extends StatelessWidget {
  const FirstChatGuideCard({
    super.key,
    required this.service,
    required this.onStart,
  });

  final ChatService service;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final progress = FirstChatProgress.of(context, service);
    return ListenableBuilder(
      listenable: progress,
      builder: (context, _) => StreamBuilder<List<Friend>>(
        stream: service.friendChanges,
        initialData: service.friends,
        builder: (context, snapshot) {
          if (progress.dismissed || (snapshot.data?.isNotEmpty ?? false)) {
            return const SizedBox.shrink();
          }
          return Card(
            key: const ValueKey('first-chat-guide-card'),
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.waving_hand_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.s.firstChatTitle,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        TextButton(
                          key: const ValueKey('first-chat-guide-start'),
                          onPressed: onStart,
                          child: Text(context.s.firstChatStart),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('first-chat-guide-dismiss'),
                    tooltip: context.s.firstChatDismiss,
                    onPressed: progress.dismiss,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Future<void> showFirstChatGuide(
  BuildContext context, {
  required VoidCallback onSelf,
  required VoidCallback onFriend,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (sheetContext) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(sheetContext).height * .85,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.s.firstChatTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _Step(
              title: context.s.firstChatKeyTitle,
              body: context.s.firstChatKeyBody,
              icon: Icons.touch_app_outlined,
            ),
            const MorsePatternText('− · − ·   − − · −'),
            FilledButton.icon(
              key: const ValueKey('first-chat-guide-self'),
              onPressed: () {
                Navigator.of(sheetContext).pop();
                onSelf();
              },
              icon: const Icon(Icons.person_outline),
              label: Text(context.s.firstChatSelf),
            ),
            const SizedBox(height: 16),
            _Step(
              title: context.s.firstChatListenTitle,
              body: context.s.firstChatListenBody,
              icon: Icons.headphones_outlined,
            ),
            const SizedBox(height: 16),
            _Step(
              title: context.s.firstChatFriendTitle,
              body: context.s.firstChatFriendBody,
              icon: Icons.qr_code_scanner,
            ),
            OutlinedButton.icon(
              key: const ValueKey('first-chat-guide-friend'),
              onPressed: () {
                Navigator.of(sheetContext).pop();
                onFriend();
              },
              icon: const Icon(Icons.person_add_outlined),
              label: Text(context.s.firstChatFriend),
            ),
            const SizedBox(height: 8),
            Text(context.s.firstChatOnline),
          ],
        ),
      ),
    ),
  ),
);

class _Step extends StatelessWidget {
  const _Step({required this.title, required this.body, required this.icon});
  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(body),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ],
  );
}

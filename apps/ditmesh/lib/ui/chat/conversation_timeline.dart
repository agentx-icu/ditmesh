import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/l10n_extension.dart';

/// A chronological viewport with a stable origin between the initial history
/// and earlier pages. Either end can grow without moving existing bubbles.
class ConversationTimeline extends StatelessWidget {
  const ConversationTimeline({
    super.key,
    required this.controller,
    required this.origin,
    required this.older,
    required this.messages,
    required this.bubbleBuilder,
    required this.hasMore,
    required this.loadingOlder,
    required this.historyFailed,
    required this.onLoadOlder,
    required this.newCount,
    required this.onLatest,
    this.showLatest = false,
  });

  /// Showing an older window (after a search jump): the way back to the
  /// latest messages is always offered, not only when new ones arrived.
  final bool showLatest;

  final ScrollController controller;
  final Key origin;
  final List<ChatMessage> older;
  final List<ChatMessage> messages;
  final Widget Function(ChatMessage) bubbleBuilder;
  final bool hasMore;
  final bool loadingOlder;
  final bool historyFailed;
  final VoidCallback? onLoadOlder;
  final int newCount;
  final VoidCallback onLatest;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      CustomScrollView(
        key: const ValueKey('conversation-history'),
        controller: controller,
        center: origin,
        slivers: [
          // Child zero stays nearest the origin; older records grow upward.
          SliverList.builder(
            itemCount: older.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) => index == older.length
                ? _historyEntry(context)
                : bubbleBuilder(older[older.length - 1 - index]),
          ),
          SliverPadding(
            key: origin,
            padding: const EdgeInsets.symmetric(vertical: 8),
            sliver: SliverList.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) => bubbleBuilder(messages[index]),
            ),
          ),
        ],
      ),
      if (newCount > 0 || showLatest)
        Positioned(
          bottom: 12,
          right: 12,
          child: FilledButton.icon(
            key: const ValueKey('new-messages'),
            onPressed: onLatest,
            icon: const Icon(Icons.arrow_downward),
            label: Text(
              newCount > 0
                  ? context.s.chatNewMessages(newCount)
                  : context.s.chatJumpToLatest,
            ),
          ),
        ),
    ],
  );

  Widget _historyEntry(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Center(
      // Keep the entry's measured height while loading so a reader at the
      // oldest visible bubble does not bounce when its button becomes a spinner.
      child: Stack(
        alignment: Alignment.center,
        children: [
          Visibility(
            visible: !loadingOlder,
            maintainSize: true,
            maintainState: true,
            maintainAnimation: true,
            child: TextButton(
              key: const ValueKey('load-earlier'),
              onPressed: onLoadOlder,
              child: Text(
                historyFailed
                    ? context.s.chatHistoryLoadFailed
                    : context.s.chatLoadEarlier,
              ),
            ),
          ),
          if (loadingOlder)
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    ),
  );
}

/// What the timeline area shows instead of messages: a history load error
/// with a retry (when [onRetry] is set) or the "no messages yet" hint.
class ConversationPlaceholder extends StatelessWidget {
  const ConversationPlaceholder({super.key, required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? retry = onRetry;
    if (retry == null) {
      return Center(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          TextButton(onPressed: retry, child: Text(context.s.chatRetryHistory)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:morse_core/morse_core.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/l10n_extension.dart';
import 'chat_layout.dart';
import 'morse_pattern_text.dart';
import 'morse_playback_settings.dart';
import 'self_badge.dart';

/// Actions a tile can ask its owner to perform.
enum ConversationAction { togglePin, markRead, delete }

/// One row of the conversation list: avatar, title, last message as text +
/// Morse pattern, time, unread badge and pin marker.
///
/// Touch platforms: swipe right to pin/unpin, swipe left to delete, long
/// press for the menu. Desktop: right-click (or long press) opens the same
/// menu; the overflow button is always there for discoverability.
///
/// The note to self ([Conversation.isSelf]) cannot be deleted: its menu has
/// no Delete and it only swipes in the pin direction, on every platform.
class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.selected,
    required this.onTap,
    required this.onAction,
    this.swipeEnabled,
  });

  final Conversation conversation;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<ConversationAction> onAction;

  /// Overrides the platform default (swipe only on touch platforms).
  final bool? swipeEnabled;

  @override
  Widget build(BuildContext context) {
    final Widget tile = _buildTile(context);
    if (!(swipeEnabled ?? isTouchPlatform)) return tile;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final S s = context.s;
    final bool deletable = !conversation.isSelf;
    return Dismissible(
      key: ValueKey<String>('dismiss_${conversation.id}'),
      direction: deletable
          ? DismissDirection.horizontal
          : DismissDirection.startToEnd,
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: scheme.primaryContainer,
        icon: conversation.pinned ? Icons.push_pin_outlined : Icons.push_pin,
        label: conversation.pinned ? s.chatUnpin : s.chatPin,
      ),
      secondaryBackground: deletable
          ? _SwipeBackground(
              alignment: Alignment.centerRight,
              color: scheme.errorContainer,
              icon: Icons.delete_outline,
              label: s.chatDelete,
            )
          : null,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onAction(ConversationAction.togglePin);
          return false; // pin never removes the row
        }
        if (deletable) onAction(ConversationAction.delete);
        return false; // the list rebuilds from the stream after deletion
      },
      child: tile,
    );
  }

  Widget _buildTile(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final ChatMessage? last = conversation.lastMessage;
    final bool hasDraft = conversation.draft.trim().isNotEmpty;
    // Listen-only training: a received last message is the answer, so the
    // preview hides its text and its dots/dashes (visually and for screen
    // readers) the same way the bubble does.
    final bool hidden =
        !hasDraft &&
        last != null &&
        !last.isMine &&
        MorsePlaybackSettings.of(context).listenOnly;
    final String previewText = hasDraft
        ? conversation.draft
        : hidden
        ? context.s.chatListenOnlyPreview
        : (last?.text ?? '');
    final String pattern = previewText.isEmpty || hidden
        ? ''
        : MorseEncoder.toPattern(previewText);
    final bool unread = conversation.unreadCount > 0;
    final String title = conversation.isSelf && conversation.title.isEmpty
        ? context.s.chatSelfMe
        : conversation.title;

    return GestureDetector(
      onSecondaryTapUp: (details) => _showMenu(context, details.globalPosition),
      onLongPressStart: (details) => _showMenu(context, details.globalPosition),
      child: ListTile(
        selected: selected,
        selectedTileColor: scheme.secondaryContainer.withValues(alpha: 0.5),
        onTap: onTap,
        leading: conversation.isSelf
            ? const SelfAvatar()
            : CircleAvatar(
                backgroundColor: conversation.kind == ConversationKind.group
                    ? scheme.tertiaryContainer
                    : scheme.primaryContainer,
                child: Icon(
                  conversation.kind == ConversationKind.group
                      ? Icons.groups
                      : Icons.person,
                  color: conversation.kind == ConversationKind.group
                      ? scheme.onTertiaryContainer
                      : scheme.onPrimaryContainer,
                ),
              ),
        title: _TitleLine(
          name: Row(
            children: [
              if (conversation.pinned)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(Icons.push_pin, size: 14, color: scheme.primary),
                ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: unread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (conversation.isSelf) const SelfBadge(),
            ],
          ),
          time: last == null
              ? null
              : formatMessageTime(context, last.timestamp),
          timeStyle: theme.textTheme.labelSmall?.copyWith(
            color: unread ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
        subtitle: previewText.isEmpty
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        if (hasDraft)
                          TextSpan(
                            text: context.s.chatDraftPrefix,
                            style: TextStyle(color: scheme.error),
                          ),
                        TextSpan(text: previewText),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: unread
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  MorsePatternText(
                    pattern,
                    maxLines: 1,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (unread) _UnreadBadge(count: conversation.unreadCount),
            PopupMenuButton<ConversationAction>(
              // The accessible name of the icon button, too.
              tooltip: context.s.chatConversationActions(title),
              onSelected: onAction,
              itemBuilder: (context) => _menuItems(context.s),
            ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<ConversationAction>> _menuItems(S s) => [
    PopupMenuItem(
      value: ConversationAction.togglePin,
      child: Text(conversation.pinned ? s.chatUnpin : s.chatPin),
    ),
    if (conversation.unreadCount > 0)
      PopupMenuItem(
        value: ConversationAction.markRead,
        child: Text(s.chatMarkRead),
      ),
    if (!conversation.isSelf)
      PopupMenuItem(
        value: ConversationAction.delete,
        child: Text(s.chatDelete),
      ),
  ];

  Future<void> _showMenu(BuildContext context, Offset globalPosition) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final ConversationAction? picked = await showMenu<ConversationAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(globalPosition, globalPosition),
        Offset.zero & overlay.size,
      ),
      items: _menuItems(context.s),
    );
    if (picked != null) onAction(picked);
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

/// The name with the time of the last message beside it, or under it when
/// the two do not fit one line: a 320 px phone at 2x text left the name no
/// room and the row overflowed past the unread badge.
class _TitleLine extends StatelessWidget {
  const _TitleLine({
    required this.name,
    required this.time,
    required this.timeStyle,
  });

  final Widget name;
  final String? time;
  final TextStyle? timeStyle;

  /// Width the name keeps beside the time, at text scale 1.
  static const double _minNameWidth = 96;

  @override
  Widget build(BuildContext context) {
    final String? time = this.time;
    if (time == null) return name;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final TextScaler scaler = MediaQuery.textScalerOf(context);
        final TextPainter painter = TextPainter(
          text: TextSpan(text: time, style: timeStyle),
          textDirection: Directionality.of(context),
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        final double timeWidth = painter.width;
        painter.dispose();
        if (box.maxWidth - timeWidth >= scaler.scale(_minNameWidth)) {
          return Row(
            children: [
              Expanded(child: name),
              Text(time, maxLines: 1, style: timeStyle),
            ],
          );
        }
        // Under the name it may wrap ("Sep 30, / 2025" beside a 99+ badge).
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            name,
            Text(time, style: timeStyle),
          ],
        );
      },
    );
  }
}

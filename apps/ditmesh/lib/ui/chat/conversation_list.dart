import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import 'chat_layout.dart';
import 'conversation_tile.dart';

/// Searchable, pinned-first conversation list bound to
/// [ChatService.conversationChanges].
///
/// Sorting: pinned first, then by last activity (last message time, falling
/// back to title). The list owns the search field; the owner decides what
/// "open" means (push on phones, select in master-detail).
class ConversationList extends StatefulWidget {
  const ConversationList({
    super.key,
    required this.service,
    required this.onOpen,
    this.selectedId,
    this.emptyText,
    this.swipeEnabled,
  });

  final ChatService service;
  final ValueChanged<Conversation> onOpen;
  final String? selectedId;

  /// Shown when there are no conversations at all; defaults to
  /// [S.chatNoConversations] in the current locale.
  final String? emptyText;
  final bool? swipeEnabled;

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final String q = _search.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Conversation> _visible(List<Conversation> all) {
    final List<Conversation> filtered = _query.isEmpty
        ? List<Conversation>.of(all)
        : all.where((c) {
            final String haystack =
                '${c.title} ${c.lastMessage?.text ?? ''} ${c.draft}'
                    .toLowerCase();
            return haystack.contains(_query);
          }).toList();
    filtered.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      final DateTime? ta = a.lastMessage?.timestamp;
      final DateTime? tb = b.lastMessage?.timestamp;
      if (ta != null && tb != null) return tb.compareTo(ta);
      if (ta != null) return -1;
      if (tb != null) return 1;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return filtered;
  }

  Future<void> _handle(Conversation c, ConversationAction action) async {
    final ChatService service = widget.service;
    final S s = context.s;
    try {
      switch (action) {
        case ConversationAction.togglePin:
          await service.setPinned(c.id, !c.pinned);
        case ConversationAction.markRead:
          await service.markRead(c.id);
        case ConversationAction.delete:
          final bool ok = await confirm(
            context,
            title: s.chatDeleteConversationTitle,
            body: s.chatDeleteConversationBody,
            confirmLabel: s.chatDelete,
          );
          if (ok) await service.deleteConversation(c.id);
      }
    } on Object catch (e) {
      if (mounted) showSnack(context, describeChatError(s, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = context.s;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: SearchBar(
            controller: _search,
            hintText: s.chatSearchConversations,
            leading: const Icon(Icons.search),
            trailing: [
              if (_query.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: MaterialLocalizations.of(context).clearButtonTooltip,
                  onPressed: _search.clear,
                ),
            ],
            elevation: const WidgetStatePropertyAll<double>(0),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Conversation>>(
            stream: widget.service.conversationChanges,
            initialData: widget.service.conversations,
            builder: (context, snapshot) {
              final List<Conversation> items = _visible(
                snapshot.data ?? const <Conversation>[],
              );
              if (items.isEmpty) {
                return _Empty(
                  text: _query.isEmpty
                      ? (widget.emptyText ?? s.chatNoConversations)
                      : s.chatNoSearchResults,
                );
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) {
                  final Conversation c = items[index];
                  return ConversationTile(
                    key: ValueKey<String>(c.id),
                    conversation: c,
                    selected: c.id == widget.selectedId,
                    onTap: () => widget.onOpen(c),
                    onAction: (a) => unawaited(_handle(c, a)),
                    swipeEnabled: widget.swipeEnabled,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../../i18n/chat_error_messages.dart';
import '../../../i18n/l10n_extension.dart';
import '../chat_layout.dart';
import '../conversation_timeline.dart';
import 'message_bookmarks.dart';

enum _Sender { anyone, me, them }

/// Searches the whole history of one conversation (functional spec §10.1):
/// case-insensitive body text, sender and date filters, bookmarks, newest
/// first, paged with a cursor. A new query cancels the old one's results.
/// Picking a result pops it so the conversation can jump there. Opening the
/// search marks nothing read and plays nothing.
class MessageSearchScreen extends StatefulWidget {
  const MessageSearchScreen({
    super.key,
    required this.service,
    required this.conversationId,
    required this.peerKey,
    required this.selfKey,
    required this.bookmarks,
    required this.hideText,
  });

  final ChatService service;
  final String conversationId;

  /// The c2c peer, or null in groups (then only Anyone / Me).
  final String? peerKey;
  final String selfKey;
  final MessageBookmarks bookmarks;

  /// Listen-only training: result text stays hidden until revealed.
  final bool hideText;

  @override
  State<MessageSearchScreen> createState() => _MessageSearchScreenState();
}

class _MessageSearchScreenState extends State<MessageSearchScreen> {
  final TextEditingController _query = TextEditingController();
  final List<ChatMessage> _results = <ChatMessage>[];
  final Set<String> _revealed = <String>{};
  Timer? _debounce;
  MessageSearchCursor? _next;
  _Sender _sender = _Sender.anyone;
  DateTimeRange? _range;
  bool _bookmarkedOnly = false;
  bool _loading = false;
  Object? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_search());
  }

  MessageSearchQuery get _q => MessageSearchQuery(
    text: _query.text,
    senderId: switch (_sender) {
      _Sender.anyone => null,
      _Sender.me => widget.selfKey,
      _Sender.them => widget.peerKey,
    },
    from: _range?.start,
    to: _range == null
        ? null
        : DateTime(_range!.end.year, _range!.end.month, _range!.end.day + 1),
  );

  /// The query the current [_next] cursor belongs to: "more" always pages
  /// that query, never a newer one with an old cursor.
  MessageSearchQuery? _pagedQuery;
  MessageSearchCancel? _cancel;

  /// Any change of query or filter: older searches are void at once (their
  /// results can no longer land) and their scans are cancelled.
  void _invalidate() {
    _generation++;
    _cancel?.cancel();
    _cancel = null;
    _results.clear();
    _next = null;
    _pagedQuery = null;
  }

  void _changed() {
    setState(_invalidate);
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_search()),
    );
  }

  /// Starts over (or, with [more], loads the next page of the same query).
  Future<void> _search({bool more = false}) async {
    if (more && (_pagedQuery == null || _next == null)) return;
    if (!more) {
      _debounce?.cancel();
      _invalidate();
    }
    final generation = _generation;
    final query = more ? _pagedQuery! : _q;
    final cursor = more ? _next : null;
    final cancel = _cancel ??= MessageSearchCancel();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.service.searchMessages(
        widget.conversationId,
        query,
        cursor: cursor,
        cancel: cancel,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _results.addAll(
          _bookmarkedOnly
              ? page.results.where(
                  (m) => widget.bookmarks.contains(widget.conversationId, m.id),
                )
              : page.results,
        );
        _next = page.next;
        _pagedQuery = query;
        _loading = false;
      });
    } on MessageSearchCancelled {
      return;
    } on Object catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _range,
    );
    if (!mounted) return;
    setState(() => _range = range);
    unawaited(_search());
  }

  @override
  void dispose() {
    _generation++;
    _cancel?.cancel();
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _query,
          autofocus: true,
          decoration: InputDecoration(
            hintText: s.chatSearchHint,
            border: InputBorder.none,
          ),
          onChanged: (_) => _changed(),
          onSubmitted: (_) => unawaited(_search()),
        ),
      ),
      body: Column(
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: <Widget>[
                for (final sender in _Sender.values)
                  if (sender != _Sender.them || widget.peerKey != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(switch (sender) {
                          _Sender.anyone => s.chatSearchAnyone,
                          _Sender.me => s.chatSearchMe,
                          _Sender.them => s.chatSearchThem,
                        }),
                        selected: _sender == sender,
                        onSelected: (_) {
                          setState(() => _sender = sender);
                          unawaited(_search());
                        },
                      ),
                    ),
                ActionChip(
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    _range == null
                        ? s.chatSearchAnyDate
                        : s.chatSearchDateRange(
                            MaterialLocalizations.of(
                              context,
                            ).formatShortDate(_range!.start),
                            MaterialLocalizations.of(
                              context,
                            ).formatShortDate(_range!.end),
                          ),
                  ),
                  onPressed: () => unawaited(_pickRange()),
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: Text(s.chatSearchBookmarked),
                  selected: _bookmarkedOnly,
                  onSelected: (v) {
                    setState(() => _bookmarkedOnly = v);
                    unawaited(_search());
                  },
                ),
              ],
            ),
          ),
          Expanded(child: _list(context)),
        ],
      ),
    );
  }

  Widget _list(BuildContext context) {
    final s = context.s;
    final error = _error;
    if (error != null) {
      return ConversationPlaceholder(
        text: describeChatError(s, error),
        onRetry: () => unawaited(_search()),
      );
    }
    if (_results.isEmpty && !_loading && _next == null) {
      return ConversationPlaceholder(text: s.chatSearchNoResults);
    }
    return ListView.builder(
      itemCount: _results.length + 1,
      itemBuilder: (context, i) {
        if (i == _results.length) {
          if (_loading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _next == null
              ? const SizedBox(height: 24)
              : TextButton(
                  onPressed: () => unawaited(_search(more: true)),
                  child: Text(s.chatSearchMore),
                );
        }
        return _ResultTile(
          message: _results[i],
          hidden:
              widget.hideText &&
              !_results[i].isMine &&
              !_revealed.contains(_results[i].id),
          bookmarked: widget.bookmarks.contains(
            widget.conversationId,
            _results[i].id,
          ),
          onReveal: () => setState(() => _revealed.add(_results[i].id)),
          onOpen: () => Navigator.of(context).pop(_results[i]),
        );
      },
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.message,
    required this.hidden,
    required this.bookmarked,
    required this.onReveal,
    required this.onOpen,
  });

  final ChatMessage message;
  final bool hidden;
  final bool bookmarked;
  final VoidCallback onReveal;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final who = message.isMine
        ? s.chatSearchMe
        : message.senderName ??
              (message.senderId.length > 8
                  ? message.senderId.substring(0, 8)
                  : message.senderId);
    return ListTile(
      minTileHeight: 56,
      leading: Icon(bookmarked ? Icons.bookmark : Icons.chat_bubble_outline),
      title: hidden
          ? ExcludeSemantics(
              child: Text(
                s.chatHiddenText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          : Text(message.text, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text('$who · ${formatMessageTime(context, message.timestamp)}'),
      trailing: hidden
          ? TextButton(onPressed: onReveal, child: Text(s.chatReveal))
          : null,
      onTap: onOpen,
    );
  }
}

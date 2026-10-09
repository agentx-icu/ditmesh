import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import 'conversation_menu.dart';
import 'message_status_icon.dart';

/// Reads the whole persisted history, including queue rows older than the
/// conversation's loaded page. Live status events override a scan's snapshot.
class PendingMessagesPage extends StatefulWidget {
  const PendingMessagesPage({super.key, required this.service});
  final ChatService service;

  @override
  State<PendingMessagesPage> createState() => _PendingMessagesPageState();
}

class _PendingMessagesPageState extends State<PendingMessagesPage> {
  final Map<String, ChatMessage> _rows = {};
  final Map<String, ChatMessage> _live = {};
  StreamSubscription<ChatMessage>? _events;
  StreamSubscription<List<Conversation>>? _conversations;
  StreamSubscription<bool>? _session;
  MessageSearchCancel? _cancel;
  int _generation = 0;
  bool _loading = true;
  Object? _error;
  Set<String> _visible = {};

  String _key(ChatMessage m) => '${m.conversationId}|${m.id}';
  bool _waiting(ChatMessage m) =>
      m.isMine &&
      (m.status == MessageStatus.pending ||
          m.status == MessageStatus.failed ||
          m.status == MessageStatus.sending);

  @override
  void initState() {
    super.initState();
    _visible = widget.service.conversations.map((c) => c.id).toSet();
    _events = widget.service.messageEvents.listen(_onEvent);
    _conversations = widget.service.conversationChanges.listen((conversations) {
      if (!mounted) return;
      final visible = conversations.map((c) => c.id).toSet();
      final added = visible.difference(_visible).isNotEmpty;
      _visible = visible;
      setState(() {
        _rows.removeWhere((_, m) => !visible.contains(m.conversationId));
        _live.removeWhere((_, m) => !visible.contains(m.conversationId));
      });
      if (added && widget.service.hasSession) unawaited(_load());
    });
    _session = widget.service.sessionChanges.listen((active) {
      if (!mounted) return;
      if (!active) {
        _cancel?.cancel();
        _generation++;
        setState(() {
          _rows.clear();
          _live.clear();
          _visible.clear();
          _loading = false;
          _error = const ChatException('not_connected', 'No active session');
        });
      } else {
        unawaited(_load());
      }
    });
    unawaited(_load());
  }

  void _onEvent(ChatMessage m) {
    if (!mounted || !m.isMine) return;
    if (!widget.service.conversations.any((c) => c.id == m.conversationId)) {
      return;
    }
    setState(() {
      final key = _key(m);
      if (_loading) _live[key] = m;
      if (_waiting(m)) {
        _rows[key] = m;
      } else {
        _rows.remove(key);
      }
    });
  }

  Future<void> _load() async {
    _cancel?.cancel();
    final cancel = _cancel = MessageSearchCancel();
    final generation = ++_generation;
    _live.clear();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!widget.service.hasSession) {
        throw const ChatException('not_connected', 'No active session');
      }
      final rows = <String, ChatMessage>{};
      final conversations = widget.service.conversations
          .where((c) => !c.isSelf)
          .toList();
      for (final c in conversations) {
        // One cancellable scan per conversation. Match only outgoing
        // delivery states instead of repeatedly paging every archived row.
        final page = await widget.service.searchMessages(
          c.id,
          const MessageSearchQuery(
            statuses: {
              MessageStatus.pending,
              MessageStatus.failed,
              MessageStatus.sending,
            },
          ),
          limit: 0x7fffffff,
          cancel: cancel,
        );
        if (!mounted || generation != _generation) return;
        for (final m in page.results) {
          final latest = _live[_key(m)] ?? m;
          if (_waiting(latest)) rows[_key(latest)] = latest;
        }
      }
      if (!mounted || generation != _generation) return;
      final visible = widget.service.conversations.map((c) => c.id).toSet();
      rows.removeWhere((_, m) => !visible.contains(m.conversationId));
      for (final m in _live.values) {
        if (_waiting(m) && visible.contains(m.conversationId)) {
          rows[_key(m)] = m;
        } else {
          rows.remove(_key(m));
        }
      }
      setState(() {
        _rows
          ..clear()
          ..addAll(rows);
        _loading = false;
        _live.clear();
      });
    } on MessageSearchCancelled {
      // A newer scan or identity replacement owns the screen.
    } on Object catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  @override
  void dispose() {
    _cancel?.cancel();
    _generation++;
    unawaited(_events?.cancel());
    unawaited(_conversations?.cancel());
    unawaited(_session?.cancel());
    super.dispose();
  }

  String _title(ChatMessage m) {
    for (final c in widget.service.conversations) {
      if (c.id == m.conversationId) return c.title;
    }
    return m.conversationId;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.pendingMessagesTitle),
        actions: [
          IconButton(
            tooltip: s.actionRetry,
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(s.pendingMessagesExplanation),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(describeChatError(s, _error!)),
            ),
          Expanded(
            child: rows.isEmpty && !_loading && _error == null
                ? Center(child: Text(s.pendingMessagesEmpty))
                : ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final m = rows[index];
                      return ListTile(
                        key: ValueKey('pending-row-${m.id}'),
                        title: Text(
                          _title(m),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          m.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        leading: MessageStatusIcon(m.status, message: m),
                        trailing: !widget.service.supportsSendControl
                            ? null
                            : IconButton(
                                key: ValueKey(
                                  m.status == MessageStatus.failed
                                      ? 'pending-retry-${m.id}'
                                      : 'pending-cancel-${m.id}',
                                ),
                                tooltip: m.status == MessageStatus.failed
                                    ? s.chatRetrySend
                                    : s.chatCancelSend,
                                onPressed: m.status == MessageStatus.sending
                                    ? null
                                    : () => ConversationMenu.sendControl(
                                        context,
                                        widget.service,
                                        m,
                                        retry: m.status == MessageStatus.failed,
                                      ),
                                icon: Icon(
                                  m.status == MessageStatus.failed
                                      ? Icons.refresh
                                      : Icons.close,
                                ),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

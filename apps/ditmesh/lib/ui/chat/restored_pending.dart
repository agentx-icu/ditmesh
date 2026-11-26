import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../i18n/l10n_extension.dart';
import '../../i18n/system_date_time.dart';
import '../common/app_bar_title.dart';
import '../account/account_widgets.dart';
import 'conversation_route.dart';
import 'conversation_target.dart';
import 'morse_pattern_text.dart';
import 'playback_timeline.dart';

/// Unsent messages a restore brought over from the previous device (F10),
/// kept in `<dataDirectory>/chat/restored_pending.json`, outside the
/// transport's queue: nothing here is ever sent. The user reviews them,
/// keys one again if it still matters, and dismisses them.
///
/// Reads and writes are synchronous: the document is tiny, and the widgets
/// that show it must work in widget tests' fake-async zone.
final class RestoredPendingStore {
  RestoredPendingStore(this.file);

  static Future<RestoredPendingStore?> forIdentity(
    IdentityService identity,
  ) async {
    if (identity.current == null) return null;
    final dir = await identity.dataDirectory();
    return RestoredPendingStore(File(p.join(dir, restoredPendingDoc)));
  }

  final File file;

  List<RestoredPendingItem> read() {
    try {
      return _readDocument();
    } on Object {
      return const [];
    }
  }

  List<RestoredPendingItem> _readDocument() {
    final String contents;
    try {
      contents = file.readAsStringSync();
    } on PathNotFoundException {
      return const [];
    }
    final decoded = jsonDecode(contents);
    final list = decoded is Map ? decoded['items'] : null;
    if (list is! List) throw const FormatException('Invalid restored messages');
    return [for (final e in list) ?RestoredPendingItem.fromJson(e)]
      ..sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
  }

  /// Removes the item with [id] (all items when null).
  void dismiss([String? id]) {
    final items = _readDocument();
    if (items.isEmpty) return;
    final kept = [
      for (final item in items)
        if (id != null && item.id != id) item,
    ];
    _write(kept);
  }

  void restoreItem(RestoredPendingItem item) => restoreItems([item]);

  void restoreItems(Iterable<RestoredPendingItem> restored) {
    final items = _readDocument();
    final ids = items.map((item) => item.id).toSet();
    final added = restored.where((item) => ids.add(item.id)).toList();
    if (added.isNotEmpty) _write([...items, ...added]);
  }

  void _write(List<RestoredPendingItem> items) {
    if (items.isEmpty) {
      file.deleteSync();
      return;
    }
    final tmp = File('${file.path}.tmp')
      ..writeAsStringSync(
        jsonEncode({
          'items': [for (final item in items) item.toJson()],
        }),
        flush: true,
      );
    tmp.renameSync(file.path);
  }
}

/// A strip above the conversation list while restored unsent messages wait
/// for review; hidden otherwise.
class RestoredPendingBanner extends StatefulWidget {
  const RestoredPendingBanner({super.key, this.reviewAction = false});

  final bool reviewAction;

  @override
  State<RestoredPendingBanner> createState() => _RestoredPendingBannerState();
}

class _RestoredPendingBannerState extends State<RestoredPendingBanner> {
  StreamSubscription<Identity?>? _sub;
  RestoredPendingStore? _store;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    final identity = context.read<IdentityService>();
    _sub = identity.identityChanges.listen((_) => _reload());
    _reload();
  }

  Future<void> _reload() async {
    final identity = context.read<IdentityService>();
    RestoredPendingStore? store;
    try {
      store = await RestoredPendingStore.forIdentity(identity);
    } on Object {
      store = null;
    }
    if (!mounted) return;
    setState(() {
      _store = store;
      _count = store?.read().length ?? 0;
    });
  }

  @override
  void dispose() {
    _sub?.cancel().ignore();
    super.dispose();
  }

  Future<void> _open() async {
    final store = _store;
    if (store == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RestoredPendingPage(store: store),
      ),
    );
    if (mounted) setState(() => _count = store.read().length);
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.tertiaryContainer,
      child: ListTile(
        key: const ValueKey('restored-pending-banner'),
        leading: Icon(Icons.outbox_outlined, color: scheme.onTertiaryContainer),
        title: Text(
          widget.reviewAction
              ? context.s.restoreXReviewAction(_count)
              : context.s.pendingReviewBanner(_count),
          style: TextStyle(color: scheme.onTertiaryContainer),
        ),
        trailing: Icon(Icons.chevron_right, color: scheme.onTertiaryContainer),
        onTap: _open,
      ),
    );
  }
}

/// The review list. Texts are selectable so they can be keyed again by
/// hand; there is deliberately no "send" action.
class RestoredPendingPage extends StatefulWidget {
  const RestoredPendingPage({super.key, required this.store});

  final RestoredPendingStore store;

  @override
  State<RestoredPendingPage> createState() => _RestoredPendingPageState();
}

class _RestoredPendingPageState extends State<RestoredPendingPage> {
  late List<RestoredPendingItem> _items = widget.store.read();
  final _messenger = GlobalKey<ScaffoldMessengerState>();
  final Map<String, RestoredPendingItem> _recentlyIgnored = {};
  int _undoGeneration = 0;

  void _showSaveError() {
    _messenger.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(context.s.pendingReviewSaveError)));
  }

  void _dismissOne(RestoredPendingItem item) {
    try {
      widget.store.dismiss(item.id);
    } on Object {
      _showSaveError();
      return;
    }
    setState(() => _items = widget.store.read());
    _recentlyIgnored[item.id] = item;
    final generation = ++_undoGeneration;
    final s = context.s;
    final snackbar = (_messenger.currentState?..removeCurrentSnackBar())
        ?.showSnackBar(
          SnackBar(
            content: Text(
              s.pendingReviewDismissedCount(_recentlyIgnored.length),
            ),
            action: SnackBarAction(
              label: s.pendingReviewUndo,
              onPressed: () {
                if (!mounted) return;
                try {
                  widget.store.restoreItems(_recentlyIgnored.values);
                } on Object {
                  _showSaveError();
                  return;
                }
                _recentlyIgnored.clear();
                setState(() => _items = widget.store.read());
              },
            ),
          ),
        );
    unawaited(
      snackbar?.closed.then<void>((_) {
        if (generation == _undoGeneration) _recentlyIgnored.clear();
      }),
    );
  }

  Future<void> _dismissAll() async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: Text(s.pendingReviewDismissAll),
          content: Text(s.pendingReviewDismissAllBody(_items.length)),
          actions: [
            TextButton(
              autofocus: true,
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(s.actionCancel),
            ),
            FilledButton(
              key: const ValueKey('restored-pending-confirm-all'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.errorContainer,
                foregroundColor: colors.onErrorContainer,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(s.pendingReviewDismissAll),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    try {
      widget.store.dismiss();
    } on Object {
      _showSaveError();
      return;
    }
    _messenger.currentState?.removeCurrentSnackBar();
    _recentlyIgnored.clear();
    setState(() => _items = widget.store.read());
  }

  String _fallbackTitle(String conversationId) {
    final key = conversationId.substring(conversationId.indexOf('_') + 1);
    return key.length > 8 ? '${key.substring(0, 8)}…' : key;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final chat = Provider.of<ChatService?>(context, listen: false);
    return ScaffoldMessenger(
      key: _messenger,
      child: Scaffold(
        appBar: AppBar(
          title: AppBarTitle(s.pendingReviewTitle),
          actions: [
            if (_items.isNotEmpty)
              TextButton(
                onPressed: _dismissAll,
                child: Text(s.pendingReviewDismissAll),
              ),
          ],
        ),
        body: StreamBuilder<List<Conversation>>(
          stream: chat?.conversationChanges,
          initialData: chat?.conversations,
          builder: (context, snapshot) {
            final available = {
              for (final conversation
                  in snapshot.data ?? const <Conversation>[])
                conversation.id: ConversationTarget.fromConversation(
                  conversation,
                ),
              for (final friend in chat?.friends ?? const <Friend>[])
                'c2c_${friend.publicKey}': ConversationTarget.fromFriend(
                  friend,
                ),
              for (final group in chat?.groups ?? const <Group>[])
                'group_${group.id}': ConversationTarget.fromGroup(group),
            };
            return AccountPageBody(
              maxWidth: 640,
              aside: [
                AccountPanel(children: [Text(s.pendingReviewBody)]),
              ],
              children: [
                AccountPanel(
                  children: [
                    if (_items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(s.pendingReviewEmpty),
                      ),
                    for (final item in _items)
                      ListTile(
                        key: ValueKey('restored-pending-${item.id}'),
                        title: Text(
                          available[item.conversationId]?.title ??
                              _fallbackTitle(item.conversationId),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.text.startsWith(ChatLocation.prefix)) ...[
                              Text(s.chatLocationLabel),
                              if (ChatLocation.tryDecode(item.text)
                                  case final location?)
                                SelectableText(
                                  '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                                )
                              else
                                Text(s.chatLocationInvalid),
                            ] else ...[
                              MorsePatternText(
                                PlaybackTimeline.patternFor(item.text),
                              ),
                              SelectableText(item.text),
                            ],
                            Text(
                              s.pendingReviewQueuedAt(
                                formatSystemDateTime(context, item.queuedAt),
                              ),
                            ),
                            Wrap(
                              spacing: 6,
                              children: [
                                if (available[item.conversationId]
                                    case final ConversationTarget target)
                                  TextButton.icon(
                                    onPressed: () => unawaited(
                                      pushConversation(context, target),
                                    ),
                                    icon: const Icon(Icons.chat_bubble_outline),
                                    label: Text(
                                      s.pendingReviewOpenConversation,
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      item.conversationId.startsWith('group_')
                                          ? s.pendingReviewMissingGroup
                                          : s.pendingReviewMissingContact,
                                    ),
                                  ),
                                Tooltip(
                                  message: s.pendingReviewDismiss,
                                  child: TextButton.icon(
                                    icon: const Icon(Icons.close),
                                    label: Text(s.pendingReviewIgnoreCopy),
                                    onPressed: () => _dismissOne(item),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

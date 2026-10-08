import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../i18n/l10n_extension.dart';

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
      if (!file.existsSync()) return const [];
      final decoded = jsonDecode(file.readAsStringSync());
      final list = decoded is Map ? decoded['items'] : null;
      if (list is! List) return const [];
      return [for (final e in list) ?RestoredPendingItem.fromJson(e)]
        ..sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
    } on Object {
      return const [];
    }
  }

  /// Removes the item with [id] (all items when null).
  void dismiss([String? id]) {
    final keep = id == null
        ? const <RestoredPendingItem>[]
        : read().where((i) => i.id != id).toList();
    if (keep.isEmpty) {
      if (file.existsSync()) file.deleteSync();
      return;
    }
    final tmp = File('${file.path}.tmp')
      ..writeAsStringSync(
        jsonEncode({'items': [for (final i in keep) i.toJson()]}),
        flush: true,
      );
    tmp.renameSync(file.path);
  }
}

/// A strip above the conversation list while restored unsent messages wait
/// for review; hidden otherwise.
class RestoredPendingBanner extends StatefulWidget {
  const RestoredPendingBanner({super.key});

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
          context.s.pendingReviewBanner(_count),
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

  void _dismiss([String? id]) {
    widget.store.dismiss(id);
    setState(() => _items = widget.store.read());
  }

  String _title(ChatService? chat, String conversationId) {
    final match = chat?.conversations
        .where((c) => c.id == conversationId)
        .firstOrNull;
    if (match != null) return match.title;
    final key = conversationId.substring(conversationId.indexOf('_') + 1);
    return key.length > 8 ? '${key.substring(0, 8)}…' : key;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final chat = Provider.of<ChatService?>(context, listen: false);
    final locale = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: AppBar(
        title: Text(s.pendingReviewTitle),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: () => _dismiss(),
              child: Text(s.pendingReviewDismissAll),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(s.pendingReviewBody),
          ),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(s.pendingReviewEmpty),
            ),
          for (final item in _items)
            ListTile(
              key: ValueKey('restored-pending-${item.id}'),
              title: Text(_title(chat, item.conversationId)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(item.text),
                  Text(
                    s.pendingReviewQueuedAt(
                      DateFormat.yMd(
                        locale,
                      ).add_Hm().format(item.queuedAt.toLocal()),
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                tooltip: s.pendingReviewDismiss,
                icon: const Icon(Icons.close),
                onPressed: () => _dismiss(item.id),
              ),
            ),
        ],
      ),
    );
  }
}

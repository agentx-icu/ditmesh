import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../chat/chat_layout.dart';
import '../common/app_bar_title.dart';
import '../contacts/tox_id.dart';
import '../responsive.dart';

/// Me → Blocked people: everyone the open identity blocked, with Unblock.
class BlockedPeoplePage extends StatefulWidget {
  const BlockedPeoplePage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const BlockedPeoplePage()));

  @override
  State<BlockedPeoplePage> createState() => _BlockedPeoplePageState();
}

class _BlockedPeoplePageState extends State<BlockedPeoplePage> {
  final Set<String> _busy = <String>{};

  Future<void> _unblock(ChatService service, String key) async {
    if (!_busy.add(key)) return;
    setState(() {});
    final S s = context.s;
    try {
      await service.unblockPeer(key);
      if (mounted) showSnack(context, s.moderationUnblocked);
    } on Object catch (e) {
      if (mounted) showSnack(context, describeChatError(s, e));
    } finally {
      if (mounted) setState(() => _busy.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = context.s;
    final ThemeData theme = Theme.of(context);
    final ChatService service = context.read<ChatService>();
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(s.moderationBlockedTitle)),
      body: ReadableBody(
        child: StreamBuilder<Set<String>>(
          stream: service.blockedPeerChanges,
          initialData: service.blockedPeers,
          builder: (context, snapshot) {
            final List<String> keys =
                (snapshot.data ?? const <String>{}).toList()..sort();
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    s.moderationBlockedNote,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (keys.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(s.moderationBlockedEmpty),
                  ),
                for (final String key in keys)
                  ListTile(
                    key: ValueKey<String>('blocked_$key'),
                    leading: const CircleAvatar(child: Icon(Icons.block)),
                    title: Text(shortKey(key, length: 16)),
                    trailing: TextButton(
                      onPressed: _busy.contains(key)
                          ? null
                          : () => unawaited(_unblock(service, key)),
                      child: Text(s.moderationUnblock),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

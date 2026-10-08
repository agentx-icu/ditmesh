import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import '../account/avatar_initial.dart';
import '../chat/chat_layout.dart';
import '../chat/conversation_target.dart';
import 'add_friend_sheet.dart';
import 'friend_request_inbox.dart';
import 'my_tox_id_sheet.dart';
import 'self_contact_tile.dart';

/// The note-to-self entry, friends (with online dots), the request inbox,
/// "add friend" and "my Tox ID". Tapping a friend hands a [ConversationTarget] to [onOpenConversation]
/// so the chat page decides between push and master-detail selection.
class ContactsPage extends StatelessWidget {
  const ContactsPage({
    super.key,
    required this.service,
    required this.identity,
    required this.onOpenConversation,
    this.canScan,
  });

  final ChatService service;
  final IdentityService? identity;
  final ValueChanged<ConversationTarget> onOpenConversation;

  /// Test override for the QR-scan affordance; defaults to the platform.
  final bool? canScan;

  /// [RouteSettings.name] of the route [open] pushes.
  static const String routeName = 'contacts';

  static Future<void> open(
    BuildContext context, {
    required ChatService service,
    required IdentityService? identity,
    required ValueChanged<ConversationTarget> onOpenConversation,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: routeName),
      builder: (_) => ContactsPage(
        service: service,
        identity: identity,
        onOpenConversation: onOpenConversation,
      ),
    ),
  );

  Future<void> _addFriend(BuildContext context) async {
    final S s = context.s;
    final bool sent = await showAddFriendSheet(
      context,
      service: service,
      ownToxId: identity?.current?.toxId,
      canScan: canScan,
    );
    if (sent && context.mounted) showSnack(context, s.chatRequestSent);
  }

  Future<void> _removeFriend(BuildContext context, Friend f) async {
    final S s = context.s;
    final bool ok = await confirm(
      context,
      title: s.chatRemoveFriendTitle,
      body: s.chatRemoveFriendBody,
      confirmLabel: s.chatRemove,
    );
    if (!ok) return;
    try {
      await service.removeFriend(f.publicKey);
    } on Object catch (e) {
      if (context.mounted) showSnack(context, describeChatError(s, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.chatContacts),
        actions: [
          IconButton(
            tooltip: s.chatMyToxId,
            icon: const Icon(Icons.qr_code_2),
            onPressed: () =>
                unawaited(showMyToxIdSheet(context, identity?.current)),
          ),
          IconButton(
            tooltip: s.chatAddFriend,
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () => unawaited(_addFriend(context)),
          ),
        ],
      ),
      body: StreamBuilder<List<Friend>>(
        stream: service.friendChanges,
        initialData: service.friends,
        builder: (context, snapshot) {
          final List<Friend> friends =
              List<Friend>.of(snapshot.data ?? const <Friend>[])..sort((a, b) {
                if (a.online != b.online) return a.online ? -1 : 1;
                return a.displayName.toLowerCase().compareTo(
                  b.displayName.toLowerCase(),
                );
              });
          return ListView(
            children: [
              SelfContactTile(
                service: service,
                identity: identity,
                onOpen: onOpenConversation,
              ),
              FriendRequestInbox(service: service),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  s.chatFriendsCount(friends.length),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (friends.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(s.chatNoFriends, textAlign: TextAlign.center),
                ),
              for (final Friend f in friends)
                _FriendTile(
                  key: ValueKey<String>('friend_${f.publicKey}'),
                  friend: f,
                  onTap: () =>
                      onOpenConversation(ConversationTarget.fromFriend(f)),
                  onRemove: () => unawaited(_removeFriend(context, f)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({
    super.key,
    required this.friend,
    required this.onTap,
    required this.onRemove,
  });

  final Friend friend;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final S s = context.s;
    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            child: Text(
              avatarInitial(friend.displayName),
              style: TextStyle(color: scheme.onPrimaryContainer),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: friend.online ? Colors.green : scheme.outlineVariant,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Text(friend.displayName),
      subtitle: Text(
        friend.statusMessage.isNotEmpty
            ? friend.statusMessage
            : (friend.online ? s.connectionOnline : s.connectionOffline),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (_) => onRemove(),
        itemBuilder: (_) => [
          PopupMenuItem(value: 'remove', child: Text(s.chatRemoveFriend)),
        ],
      ),
    );
  }
}

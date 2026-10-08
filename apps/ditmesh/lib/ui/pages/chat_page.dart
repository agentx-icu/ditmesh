import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../i18n/l10n_extension.dart';
import '../chat/chat_layout.dart';
import '../chat/chat_scope.dart';
import '../chat/conversation_list.dart';
import '../chat/conversation_route.dart';
import '../chat/conversation_screen.dart';
import '../chat/conversation_target.dart';
import '../chat/restored_pending.dart';
import '../contacts/contacts_page.dart';
import '../shell/shell_router.dart';
import 'placeholder_page.dart';

/// One-to-one Morse conversations over Tox.
///
/// Phone: the list fills the page and opening a conversation pushes a route.
/// Tablet / desktop (width ≥ [kMasterDetailMinWidth]): list + open
/// conversation side by side. Contacts (friends, requests, add friend, my
/// Tox ID) live behind the app-bar people icon.
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  /// Destination label, resolved in the current locale.
  static String title(S s) => s.navChat;

  /// One-line subtitle, resolved in the current locale.
  static String description(S s) => s.navChatDescription;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  ConversationTarget? _selected;
  StreamSubscription<ConversationTarget>? _shellConversations;
  StreamSubscription<void>? _shellContacts;

  @override
  void initState() {
    super.initState();
    final ShellRouter? router = context.read<ShellRouter?>();
    _shellConversations = router?.conversationRequests
        .where((t) => t.kind == ConversationKind.c2c)
        .listen(_openFromShell);
    _shellContacts = router?.contactsRequests.listen(
      (_) => _contactsFromShell(),
    );
  }

  @override
  void dispose() {
    unawaited(_shellConversations?.cancel());
    unawaited(_shellContacts?.cancel());
    super.dispose();
  }

  final DetailPaneKey _detailKey = DetailPaneKey();

  void _open(BuildContext context, ConversationTarget target) {
    if (isMasterDetail(context)) {
      setState(() => _selected = target);
      return;
    }
    unawaited(pushConversation(context, target));
  }

  /// A notification asked for [target]: the inline pane when this page is
  /// actually exposed on a wide layout, otherwise a route above whatever is
  /// open (reusing the conversation if it is already on top).
  void _openFromShell(ConversationTarget target) {
    if (!mounted) return;
    final bool exposed = ModalRoute.of(context)?.isCurrent ?? true;
    if (isMasterDetail(context) && exposed) {
      setState(() => _selected = target);
      return;
    }
    openConversationRoute(Navigator.of(context), target);
  }

  void _contactsFromShell() {
    if (!mounted) return;
    final ChatService? service = maybeChatService(context);
    if (service == null) return;
    final NavigatorState navigator = Navigator.of(context);
    if (topRoute(navigator)?.settings.name == ContactsPage.routeName) return;
    unawaited(_openContacts(context, service));
  }

  Future<void> _openContacts(BuildContext context, ChatService service) {
    final NavigatorState navigator = Navigator.of(context);
    return ContactsPage.open(
      context,
      service: service,
      identity: maybeIdentityService(context),
      onOpenConversation: (target) {
        navigator.pop();
        if (mounted) _open(context, target);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final S s = context.s;
    final ChatService? service = maybeChatService(context);
    if (service == null) {
      return PlaceholderPage(
        title: ChatPage.title(s),
        description: ChatPage.description(s),
        icon: Icons.chat_bubble_outline,
      );
    }
    final bool twoPane = isMasterDetail(context);
    // Window shrank below the breakpoint (iPad rotated to portrait): the
    // pane is gone, the conversation continues as a route - or, while a
    // dialog covers the page, stays mounted offstage until it can.
    final bool parked =
        !twoPane &&
        _selected != null &&
        !reopenCollapsedDetail(
          this,
          selection: () => _selected,
          forget: () => setState(() => _selected = null),
        );

    final Widget list = Scaffold(
      appBar: AppBar(
        title: Text(ChatPage.title(s)),
        actions: [
          _RequestsBadge(
            service: service,
            onPressed: () => unawaited(_openContacts(context, service)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Unsent messages a restore brought over (F10), for review only.
          const RestoredPendingBanner(),
          Expanded(
            child: ConversationList(
              service: service,
              selectedId: _selected?.id,
              emptyText: ChatPage.description(s),
              onOpen: (c) =>
                  _open(context, ConversationTarget.fromConversation(c)),
            ),
          ),
        ],
      ),
    );

    final ConversationTarget? selected = _selected;
    final Widget? detail = selected == null
        ? null
        : ConversationScreen(
            key: _detailKey.of(selected.id),
            target: selected,
            embedded: true,
            onClosed: () => setState(() => _selected = null),
          );
    if (!twoPane) {
      return singlePaneLayout(list: list, parkedDetail: parked ? detail : null);
    }
    return MasterDetail(master: list, detail: detail);
  }
}

/// Contacts button with a badge for pending friend requests.
class _RequestsBadge extends StatelessWidget {
  const _RequestsBadge({required this.service, required this.onPressed});

  final ChatService service;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FriendRequest>>(
      stream: service.friendRequestChanges,
      initialData: service.friendRequests,
      builder: (context, snapshot) {
        final int count = snapshot.data?.length ?? 0;
        return IconButton(
          tooltip: context.s.chatContacts,
          onPressed: onPressed,
          icon: Badge.count(
            count: count,
            isLabelVisible: count > 0,
            child: const Icon(Icons.people_outline),
          ),
        );
      },
    );
  }
}

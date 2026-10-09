import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../i18n/l10n_extension.dart';
import '../chat/chat_layout.dart';
import '../chat/chat_scope.dart';
import '../chat/conversation_route.dart';
import '../chat/conversation_screen.dart';
import '../chat/conversation_target.dart';
import '../common/app_bar_title.dart';
import '../groups/create_group_sheet.dart';
import '../groups/group_join_feedback.dart';
import '../groups/group_list.dart';
import '../groups/join_group_sheet.dart';
import '../shell/shell_router.dart';
import 'placeholder_page.dart';

/// Group nets: many operators on one shared Morse channel.
///
/// Same master-detail rule as the chat page; group conversations reuse
/// [ConversationScreen], which shows the conference note and the member /
/// leave actions for groups.
class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  /// Destination label, resolved in the current locale.
  static String title(S s) => s.navGroups;

  /// One-line subtitle, resolved in the current locale.
  static String description(S s) => s.navGroupsDescription;

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  ConversationTarget? _selected;
  final DetailPaneKey _detailKey = DetailPaneKey();
  StreamSubscription<ConversationTarget>? _shellConversations;

  @override
  void initState() {
    super.initState();
    _shellConversations = context
        .read<ShellRouter?>()
        ?.conversationRequests
        .where((t) => t.kind == ConversationKind.group)
        .listen(_openFromShell);
  }

  @override
  void dispose() {
    unawaited(_shellConversations?.cancel());
    super.dispose();
  }

  void _open(BuildContext context, Group group) {
    final ConversationTarget target = ConversationTarget.fromGroup(group);
    if (isMasterDetail(context)) {
      setState(() => _selected = target);
      return;
    }
    unawaited(pushConversation(context, target));
  }

  /// A notification asked for [target]; see `ChatPage._openFromShell`.
  void _openFromShell(ConversationTarget target) {
    if (!mounted) return;
    final bool exposed = ModalRoute.of(context)?.isCurrent ?? true;
    if (isMasterDetail(context) && exposed) {
      setState(() => _selected = target);
      return;
    }
    openConversationRoute(Navigator.of(context), target);
  }

  Future<void> _create(BuildContext context, ChatService service) async {
    final Group? group = await showCreateGroupSheet(context, service: service);
    if (group != null && context.mounted) _open(context, group);
  }

  Future<void> _join(BuildContext context, ChatService service) async {
    final String joinRequested = context.s.chatJoinRequested;
    final bool joined = await showJoinGroupSheet(context, service: service);
    if (joined && context.mounted) showSnack(context, joinRequested);
  }

  @override
  Widget build(BuildContext context) {
    final S s = context.s;
    final ChatService? service = maybeChatService(context);
    if (service == null) {
      return PlaceholderPage(
        title: GroupsPage.title(s),
        description: GroupsPage.description(s),
        icon: Icons.groups_outlined,
      );
    }
    final bool twoPane = isMasterDetail(context);
    // Same as the chat page: rotating to portrait keeps the group open.
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
        title: AppBarTitle(GroupsPage.title(s)),
        actions: [
          IconButton(
            tooltip: s.chatJoinGroup,
            icon: const Icon(Icons.login),
            onPressed: () => unawaited(_join(context, service)),
          ),
          IconButton(
            tooltip: s.chatCreateGroup,
            icon: const Icon(Icons.group_add_outlined),
            onPressed: () => unawaited(_create(context, service)),
          ),
        ],
      ),
      body: StreamBuilder<List<Group>>(
        stream: service.groupChanges,
        initialData: service.groups,
        builder: (context, snapshot) {
          final List<Group> groups = snapshot.data ?? const <Group>[];
          final ConversationTarget? selected = _selected;
          if (selected != null && !groups.any((g) => g.id == selected.peerId)) {
            // Left (or was removed from) the open group: drop the pane.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _selected?.id == selected.id) {
                setState(() => _selected = null);
              }
            });
          }
          return Column(
            children: [
              if (groups.isEmpty && service.groupInvites.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Text(
                    GroupsPage.description(s),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Expanded(
                child: GroupList(
                  service: service,
                  selectedId: _selected?.peerId,
                  onOpen: (g) => _open(context, g),
                ),
              ),
            ],
          );
        },
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
    // Above both layouts: a refusal is reported whatever the pane shows.
    return GroupJoinFeedback(
      service: service,
      child: twoPane
          ? MasterDetail(master: list, detail: detail)
          : singlePaneLayout(list: list, parkedDetail: parked ? detail : null),
    );
  }
}

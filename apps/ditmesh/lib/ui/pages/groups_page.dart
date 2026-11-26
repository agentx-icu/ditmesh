import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../i18n/l10n_extension.dart';
import '../account/account_widgets.dart';
import '../chat/chat_layout.dart';
import '../chat/chat_scope.dart';
import '../chat/conversation_route.dart';
import '../chat/conversation_screen.dart';
import '../chat/conversation_target.dart';
import '../common/app_bar_title.dart';
import '../groups/create_group_sheet.dart';
import '../groups/group_join_feedback.dart';
import '../groups/group_invites_page.dart';
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
  bool _selectedWasListed = false;
  bool _joinInline = false;
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

  void _selectDetail(ConversationTarget? target) {
    if (_selected?.id != target?.id) {
      _selectedWasListed = false;
      _detailKey.rememberSearchAnchor(null);
    }
    setState(() => _selected = target);
  }

  void _open(BuildContext context, Group group) {
    final ConversationTarget target = ConversationTarget.fromGroup(group);
    if (isMasterDetail(context)) {
      _selectDetail(target);
      return;
    }
    unawaited(pushConversation(context, target));
  }

  /// A notification asked for [target]; see `ChatPage._openFromShell`.
  void _openFromShell(ConversationTarget target) {
    if (!mounted) return;
    final bool exposed = ModalRoute.of(context)?.isCurrent ?? true;
    if (isMasterDetail(context) && exposed) {
      _selectDetail(target);
      return;
    }
    openConversationRoute(Navigator.of(context), target);
  }

  Future<void> _create(BuildContext context, ChatService service) async {
    final Group? group = await showCreateGroupSheet(context, service: service);
    // A notification can open another conversation while creation is pending.
    if (group != null &&
        context.mounted &&
        TickerMode.valuesOf(context).enabled &&
        ModalRoute.isCurrentOf(context) == true) {
      _open(context, group);
    }
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
          detail: _detailKey,
          selection: () => _selected,
          forget: () => _selectDetail(null),
        );

    final Widget list = Scaffold(
      appBar: AppBar(
        title: AppBarTitle(GroupsPage.title(s)),
        actions: [
          StreamBuilder<List<GroupInvite>>(
            stream: service.groupInviteChanges,
            initialData: service.groupInvites,
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return IconButton(
                key: const ValueKey('groups-invites-open'),
                tooltip: s.chatGroupInvitesCount(count),
                onPressed: () =>
                    Navigator.of(context).push(GroupInvitesPage.route(service)),
                icon: Badge(
                  label: Text('$count'),
                  child: const Icon(Icons.mail_outline),
                ),
              );
            },
          ),
          if (!twoPane || _selected != null)
            IconButton(
              tooltip: s.chatJoinGroup,
              icon: const Icon(Icons.login),
              onPressed: () {
                if (twoPane) {
                  unawaited(_join(context, service));
                } else {
                  setState(() => _joinInline = !_joinInline);
                }
              },
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
          if (selected != null) {
            if (groups.any((g) => g.id == selected.peerId)) {
              _selectedWasListed = true;
            } else if (_selectedWasListed && service.hasSession) {
              // Startup may send a notification target before the group
              // directory arrives. Only close a group that was listed.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted &&
                    identical(_selected, selected) &&
                    service.hasSession &&
                    !service.groups.any((g) => g.id == selected.peerId)) {
                  _selectDetail(null);
                }
              });
            }
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
                  footer: !twoPane && _joinInline
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          child: AccountPanel(
                            children: [
                              JoinGroupForm(
                                service: service,
                                onJoined: () {
                                  setState(() => _joinInline = false);
                                  showSnack(context, s.chatJoinRequested);
                                },
                              ),
                            ],
                          ),
                        )
                      : null,
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
            onClosed: () => _selectDetail(null),
            onSearchAnchor: _detailKey.rememberSearchAnchor,
          );
    // Above both layouts: a refusal is reported whatever the pane shows.
    return GroupJoinFeedback(
      service: service,
      child: twoPane
          ? MasterDetail(
              master: list,
              detail:
                  detail ??
                  AccountPageBody(
                    maxWidth: 640,
                    children: [
                      AccountPanel(
                        children: [
                          JoinGroupForm(
                            service: service,
                            onJoined: () =>
                                showSnack(context, s.chatJoinRequested),
                          ),
                        ],
                      ),
                    ],
                  ),
            )
          : singlePaneLayout(list: list, parkedDetail: parked ? detail : null),
    );
  }
}

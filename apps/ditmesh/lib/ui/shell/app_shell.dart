import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

import '../../i18n/l10n_extension.dart';
import '../../notifications/connection_banner_policy.dart';
import '../../notifications/notification_center.dart';
import '../../notifications/notification_composer.dart';
import '../../notifications/notification_payload.dart';
import '../chat/conversation_route.dart';
import '../chat/conversation_target.dart';
import '../groups/group_invites_page.dart';
import '../pages/chat_page.dart';
import '../pages/groups_page.dart';
import '../pages/me_page.dart';
import '../pages/reference_page.dart';
import '../diagnostics/connection_diagnostics_page.dart';
import '../responsive.dart';
import 'shell_router.dart';

/// One top-level destination. Kept as data so the bar and the rail render the
/// same list and cannot drift apart. The label is resolved against the
/// current locale at build time, so a language switch relabels the bar.
class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });

  final String Function(S s) label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}

const List<ShellDestination> kShellDestinations = [
  ShellDestination(
    label: ChatPage.title,
    icon: Icons.chat_bubble_outline,
    selectedIcon: Icons.chat_bubble,
    page: ChatPage(),
  ),
  ShellDestination(
    label: GroupsPage.title,
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups,
    page: GroupsPage(),
  ),
  ShellDestination(
    label: ReferencePage.title,
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book,
    page: ReferencePage(),
  ),
  ShellDestination(
    label: MePage.title,
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    page: MePage(),
  ),
];

/// Responsive root: bottom [NavigationBar] on compact widths, side
/// [NavigationRail] otherwise. The identity startup gate protects every
/// destination; Chat is the initial screen on every platform.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final ShellRouter _router = ShellRouter();
  NotificationCenter? _center;
  StreamSubscription<NotificationTapTarget>? _taps;

  /// Keeps the page stack mounted when the layout class flips. Rotating a
  /// phone to landscape (or unfolding a foldable) crosses the 600 px
  /// breakpoint, which moves the body from `Scaffold.body` into the rail's
  /// `Row`; without a global key every tab's state (open chat pane, scroll
  /// positions, reference/translator input) was thrown away on rotation.
  final GlobalKey _bodyKey = GlobalKey(debugLabel: 'shell-body');

  final List<ShellDestination> _destinations = kShellDestinations;

  int _tabOf(Type page) =>
      _destinations.indexWhere((d) => d.page.runtimeType == page);

  void _select(int index) {
    if (index < 0 || index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  void initState() {
    super.initState();
    // Notification taps open what they point at. The centre keeps the
    // newest tap until it is routed here, so a tap that cold-started the
    // app (or came while the unlock screen showed) is not lost.
    // NotificationCenter is null in tests and where notifications are off.
    _center = context.read<NotificationCenter?>();
    _taps = _center?.tapTargets.listen((_) => _routePendingTap());
    WidgetsBinding.instance.addPostFrameCallback((_) => _routePendingTap());
  }

  @override
  void dispose() {
    unawaited(_taps?.cancel());
    unawaited(_router.dispose());
    super.dispose();
  }

  void _routePendingTap() {
    if (!mounted) return;
    final NotificationTapTarget? tap = _center?.takePendingTap();
    switch (tap) {
      case null:
        return;
      case OpenConversationTarget(:final conversationId):
        final ConversationTarget target = _targetFor(conversationId);
        _select(
          _tabOf(target.kind == ConversationKind.group ? GroupsPage : ChatPage),
        );
        _router.openConversation(target);
      case FriendRequestTarget():
        _select(_tabOf(ChatPage));
        _router.openContacts();
      case GroupInviteTarget():
        _showGroupInvites();
    }
  }

  /// The invite inbox is inline on the groups page: uncover it by leaving
  /// conversations only. When another flow (settings, contacts, …) still
  /// covers the shell, open the invites on a page above it instead.
  void _showGroupInvites() {
    _select(_tabOf(GroupsPage));
    final NavigatorState navigator = Navigator.of(context);
    navigator.popUntil(
      (route) => route.settings.name != kConversationRouteName,
    );
    final ChatService chat = context.read<ChatService>();
    final bool covered = !identical(
      topRoute(navigator),
      ModalRoute.of(context),
    );
    if (covered && chat.groupInvites.isNotEmpty) {
      unawaited(navigator.push(GroupInvitesPage.route(chat)));
    }
  }

  ConversationTarget _targetFor(String conversationId) {
    final chat = context.read<ChatService>();
    final existing = chat.conversations
        .where((c) => c.id == conversationId)
        .firstOrNull;
    if (existing != null) return ConversationTarget.fromConversation(existing);
    final bool group = conversationId.startsWith('group_');
    final String peer = conversationId.substring(
      conversationId.indexOf('_') + 1,
    );
    return ConversationTarget(
      id: conversationId,
      title: NotificationComposer.shortKey(peer),
      kind: group ? ConversationKind.group : ConversationKind.c2c,
    );
  }

  /// Body plus the "offline for a while" strip; the policy decides when the
  /// strip shows so it never flaps on short reconnects.
  Widget _withBanner(Widget body) {
    final policy = context.read<ConnectionBannerPolicy>();
    return Column(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: policy.offlineBannerVisible,
          builder: (context, visible, _) =>
              visible ? const _OfflineBanner() : const SizedBox.shrink(),
        ),
        Expanded(child: body),
      ],
    );
  }

  /// Bottom-bar labels stay on one line: clamped like the AppBar title, and
  /// further down when a translation is still wider than its quarter.
  double _barLabelScale(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final ThemeData theme = Theme.of(context);
    final double slot =
        (media.size.width - media.padding.horizontal) / _destinations.length;
    return fitLabelsTextScale(
      context,
      labels: [for (final d in _destinations) d.label(context.s)],
      style:
          (theme.navigationBarTheme.labelTextStyle?.resolve(const {
                    WidgetState.selected,
                  }) ??
                  theme.textTheme.labelMedium)
              ?.copyWith(fontWeight: FontWeight.w600),
      width: slot - 8,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final layout = layoutClassOf(context);
    final body = KeyedSubtree(
      key: _bodyKey,
      child: Provider<ShellRouter>.value(
        value: _router,
        child: _withBanner(
          IndexedStack(
            index: _selectedIndex,
            // Hidden tabs keep their state but stop animating; a conversation
            // left open on another tab reads this to stay silent.
            children: [
              for (final (i, d) in _destinations.indexed)
                TickerMode(enabled: i == _selectedIndex, child: d.page),
            ],
          ),
        ),
      ),
    );

    switch (layout) {
      case LayoutClass.compact:
        return Scaffold(
          // Sideways insets (a phone in landscape below the 600 px
          // breakpoint, a notched tablet) are the pages' to keep clear of.
          body: SafeArea(top: false, bottom: false, child: body),
          bottomNavigationBar: MediaQuery.withClampedTextScaling(
            maxScaleFactor: _barLabelScale(context),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _select,
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: d.label(s),
                  ),
              ],
            ),
          ),
        );
      case LayoutClass.expanded:
        return Scaffold(
          body: Row(
            children: [
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: kBarLabelMaxTextScale,
                child: NavigationRail(
                  // A phone in landscape is ~320-430 px tall: four labelled
                  // destinations overflow there at large text scales.
                  scrollable: true,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _select,
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label(s)),
                      ),
                  ],
                ),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              // The rail already keeps clear of a leading notch; the pages
              // keep clear of the trailing one and must not inset again.
              // Read below the Scaffold (a Builder): the shell's own context
              // still has the keyboard inset the Scaffold body has consumed.
              Expanded(
                child: Builder(
                  builder: (inner) => MediaQuery.removePadding(
                    context: inner,
                    removeLeft: Directionality.of(inner) == TextDirection.ltr,
                    removeRight: Directionality.of(inner) == TextDirection.rtl,
                    child: SafeArea(top: false, bottom: false, child: body),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}

/// Tox has no server: while we are offline nothing can arrive. Shown after the
/// [ConnectionBannerPolicy] threshold, on every platform, above the content.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.cloud_off, size: 18, color: scheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.s.shellOfflineBanner,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
              TextButton(
                key: const ValueKey('offline-banner-details'),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onErrorContainer,
                ),
                onPressed: () => ConnectionDiagnosticsPage.open(context),
                child: Text(context.s.diagBannerDetails),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/l10n_extension.dart';
import '../responsive.dart';
import 'chat_layout.dart';
import 'conversation_header.dart';
import 'conversation_target.dart';
import 'morse_playback_settings.dart';
import 'playback_settings_sheet.dart';

/// The conversation app bar: title + subtitle and [ConversationActions],
/// sized against the width the bar actually gets (a master-detail pane is
/// narrower than the window).
class ConversationAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ConversationAppBar({
    super.key,
    required this.service,
    required this.target,
    required this.settings,
    required this.embedded,
    required this.onMenu,
  });

  final ChatService service;
  final ConversationTarget target;
  final MorsePlaybackSettings settings;
  final bool embedded;
  final ValueChanged<String> onMenu;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final bool leading =
          !embedded &&
          (ModalRoute.of(context)?.impliesAppBarDismissal ?? false);
      return AppBar(
        automaticallyImplyLeading: !embedded,
        title: ConversationTitle(service: service, target: target),
        actions: [
          ConversationActions(
            settings: settings,
            isGroup: target.kind == ConversationKind.group,
            canModerate: target.kind == ConversationKind.c2c && !target.isSelf,
            inline: inlineConversationActions(
              context,
              title: conversationTitleText(context.s, target),
              barWidth: box.maxWidth,
              hasLeading: leading,
            ),
            onMenu: onMenu,
          ),
        ],
      );
    },
  );
}

/// How many of the demotable actions (training mode, then playback
/// settings) stay inline: 2 keeps all of them, 1 moves playback settings
/// into the overflow menu, 0 moves both.
///
/// Measured rather than a width breakpoint because the title's width depends
/// on the name, the language and the text scale: a short call sign keeps
/// every icon on a phone, a long group name at 2x text loses both. The
/// auto-play toggle and the overflow button never move — auto-play is a
/// state indicator that has to stay visible.
int inlineConversationActions(
  BuildContext context, {
  required String title,
  required double barWidth,
  required bool hasLeading,
}) {
  final MediaQueryData media = MediaQuery.of(context);
  final ThemeData theme = Theme.of(context);
  final TextPainter painter = TextPainter(
    text: TextSpan(
      text: title,
      style: theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge,
    ),
    textDirection: Directionality.of(context),
    textScaler: appBarTitleTextScaler(media.textScaler),
    maxLines: 1,
  )..layout();
  final double titleWidth = painter.width;
  painter.dispose();
  // The AppBar's SafeArea drops the notch insets; the leading back button is
  // a kToolbarHeight square; the title gets middle spacing on both sides;
  // every action is a 48 px icon button (auto-play + overflow are fixed).
  final double room =
      barWidth -
      media.padding.horizontal -
      (hasLeading ? kToolbarHeight : 0) -
      NavigationToolbar.kMiddleSpacing * 2 -
      titleWidth;
  const double button = kMinInteractiveDimension;
  for (int inline = 2; inline > 0; inline--) {
    if ((2 + inline) * button <= room) return inline;
  }
  return 0;
}

/// App-bar actions of a conversation: training mode, auto-play, playback
/// settings and the overflow menu (members / clear history / leave, and
/// block in a conversation with another person).
///
/// [inline] is how many of training mode and playback settings show as
/// icons (see [inlineConversationActions]); the rest become overflow-menu
/// entries labelled with the same strings as the icons' tooltips.
class ConversationActions extends StatelessWidget {
  const ConversationActions({
    super.key,
    required this.settings,
    required this.isGroup,
    required this.onMenu,
    this.inline = 2,
    this.canModerate = false,
  });

  final MorsePlaybackSettings settings;
  final bool isGroup;

  /// A conversation with another person: offer Block.
  final bool canModerate;
  final ValueChanged<String> onMenu;
  final int inline;

  void _toggleTraining(BuildContext context) {
    final S s = context.s;
    settings.trainingMode = !settings.trainingMode;
    showSnack(
      context,
      settings.trainingMode ? s.chatTrainingModeOn : s.chatTrainingModeOff,
    );
  }

  void _openPlayback(BuildContext context) =>
      unawaited(showPlaybackSettingsSheet(context, settings));

  void _onSelected(BuildContext context, String action) {
    switch (action) {
      case 'training':
        _toggleTraining(context);
      case 'playback':
        _openPlayback(context);
      default:
        onMenu(action);
    }
  }

  @override
  Widget build(BuildContext context) {
    final S s = context.s;
    final bool trainingInline = inline >= 1;
    final bool playbackInline = inline >= 2;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (trainingInline)
          IconButton(
            tooltip: s.chatTrainingMode,
            isSelected: settings.trainingMode,
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(Icons.school),
            onPressed: () => _toggleTraining(context),
          ),
        IconButton(
          tooltip: s.chatAutoPlay,
          isSelected: settings.autoPlay,
          icon: const Icon(Icons.volume_off_outlined),
          selectedIcon: const Icon(Icons.volume_up),
          onPressed: () {
            settings.autoPlay = !settings.autoPlay;
            showSnack(
              context,
              settings.autoPlay ? s.chatAutoPlayOn : s.chatAutoPlayOff,
            );
          },
        ),
        if (playbackInline)
          IconButton(
            tooltip: s.chatPlaybackSettings,
            icon: const Icon(Icons.speed),
            onPressed: () => _openPlayback(context),
          ),
        PopupMenuButton<String>(
          onSelected: (a) => _onSelected(context, a),
          itemBuilder: (_) => [
            if (!trainingInline)
              CheckedPopupMenuItem(
                value: 'training',
                checked: settings.trainingMode,
                child: Text(s.chatTrainingMode),
              ),
            if (!playbackInline)
              PopupMenuItem(
                value: 'playback',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.speed),
                  title: Text(s.chatPlaybackSettings),
                ),
              ),
            // History search lives in the menu: the bar's icons are measured
            // against the title and already fold on phones.
            PopupMenuItem(
              value: 'search',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.search),
                title: Text(s.chatSearchMessages),
              ),
            ),
            if (isGroup)
              PopupMenuItem(value: 'members', child: Text(s.chatMembers)),
            if (isGroup)
              PopupMenuItem(
                value: 'practice',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.school_outlined),
                  title: Text(s.groupPracticeTitle),
                ),
              ),
            CheckedPopupMenuItem(
              value: 'listenOnly',
              checked: settings.listenOnly,
              child: Text(s.chatListenOnly),
            ),
            PopupMenuItem(
              value: 'connection',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.network_check),
                title: Text(s.diagTitle),
              ),
            ),
            PopupMenuItem(value: 'clear', child: Text(s.chatClearHistory)),
            if (isGroup)
              PopupMenuItem(value: 'leave', child: Text(s.chatLeaveGroup)),
            if (canModerate)
              PopupMenuItem(
                value: 'block',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.block),
                  title: Text(s.moderationBlock),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:morse_core/morse_core.dart' show TelegraphGroups;
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/l10n_extension.dart';
import '../telegraph/telegraph_interpret_sheet.dart';
import 'chat_layout.dart';
import 'message_status_icon.dart';
import 'morse_pattern_text.dart';
import 'playback_timeline.dart';
import 'playback_word_text.dart';
import '../appearance/style_tokens.dart';

/// A chat bubble with the three layers from plan §5.3: Morse pattern, plain
/// text (hidden in training mode until revealed) and a play button.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.trainingMode,
    required this.revealed,
    required this.playing,
    required this.onPlay,
    required this.onReveal,
    this.activeMark,
    this.activeWord,
    this.playbackControls,
    this.onPlaybackSettings,
    this.showSender = false,
    this.listenOnly = false,
    this.onPractice,
    this.onBookmark,
    this.bookmarked = false,
    this.onRetry,
    this.onCancelSend,
  });

  /// Local bookmark toggle (null hides it).
  final VoidCallback? onBookmark;
  final bool bookmarked;

  /// Our failed message: retry under the same id; our queued message:
  /// cancel before it leaves the device. Null when not applicable.
  final VoidCallback? onRetry;
  final VoidCallback? onCancelSend;

  /// Four-digit groups in visible text may be interpreted as Chinese
  /// telegraph code — only on request; numbers are never converted (F13).
  bool get _canInterpret =>
      !_textHidden && TelegraphGroups.hasGroups(message.text);

  bool get _hasActions =>
      onPlaybackSettings != null ||
      _canInterpret ||
      onPractice != null ||
      onBookmark != null ||
      onRetry != null ||
      onCancelSend != null;

  /// Listen-only training: also hide the dots and dashes until revealed.
  final bool listenOnly;

  /// Received messages: open copy practice.
  final VoidCallback? onPractice;

  final ChatMessage message;
  final bool trainingMode;
  final bool revealed;
  final bool playing;
  final int? activeMark;
  final int? activeWord;
  final Widget? playbackControls;
  final VoidCallback? onPlaybackSettings;
  final VoidCallback onPlay;
  final VoidCallback onReveal;

  /// Group chats show who keyed the message.
  final bool showSender;

  bool get _textHidden =>
      (trainingMode || listenOnly) && !revealed && !message.isMine;

  bool get _patternHidden => listenOnly && !revealed && !message.isMine;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final radius = StyleTokens.of(context)?.bubbleRadius ?? 16;
    final S s = context.s;
    final bool mine = message.isMine;
    final Color background = mine
        ? scheme.primaryContainer
        : scheme.surfaceContainerHigh;
    final Color foreground = mine
        ? scheme.onPrimaryContainer
        : scheme.onSurface;
    final String pattern = PlaybackTimeline.patternFor(message.text);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: EdgeInsets.fromLTRB(mine ? 48 : 12, 4, mine ? 12 : 48, 4),
          child: Material(
            color: background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(radius),
              topRight: Radius.circular(radius),
              bottomLeft: Radius.circular(mine ? radius : radius.clamp(0, 4)),
              bottomRight: Radius.circular(mine ? radius.clamp(0, 4) : radius),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showSender && !mine)
                    Text(
                      message.senderName ?? _shortKey(message.senderId),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.tertiary,
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _patternHidden
                            ? ExcludeSemantics(
                                child: Text(
                                  s.chatListenOnlyHidden,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : MorsePatternText(
                                pattern,
                                activeMark: activeMark,
                                style: theme.textTheme.bodyLarge,
                                color: foreground.withValues(alpha: 0.75),
                                highlightColor: scheme.primary,
                              ),
                      ),
                      IconButton(
                        tooltip: playing ? s.chatStop : s.chatPlay,
                        onPressed: pattern.isEmpty ? null : onPlay,
                        icon: Icon(
                          playing ? Icons.stop_circle : Icons.play_circle,
                          color: scheme.primary,
                        ),
                      ),
                      if (_hasActions)
                        PopupMenuButton<_LearnAction>(
                          key: ValueKey<String>('learn-menu-${message.id}'),
                          tooltip: s.chatMessageLearnActions,
                          icon: const Icon(Icons.more_vert),
                          onSelected: (v) => switch (v) {
                            _LearnAction.playback => onPlaybackSettings,
                            _LearnAction.telegraph =>
                              () => showTelegraphInterpretation(
                                context,
                                message.text,
                              ),
                            _LearnAction.practice => onPractice,
                            _LearnAction.bookmark => onBookmark,
                            _LearnAction.retry => onRetry,
                            _LearnAction.cancel => onCancelSend,
                          }?.call(),
                          itemBuilder: (_) => [
                            if (onPlaybackSettings != null)
                              PopupMenuItem(
                                value: _LearnAction.playback,
                                child: Text(s.chatMessagePlayback),
                              ),
                            if (onRetry != null)
                              PopupMenuItem(
                                value: _LearnAction.retry,
                                child: Text(s.chatRetrySend),
                              ),
                            if (onCancelSend != null)
                              PopupMenuItem(
                                value: _LearnAction.cancel,
                                child: Text(s.chatCancelSend),
                              ),
                            if (onBookmark != null)
                              PopupMenuItem(
                                value: _LearnAction.bookmark,
                                child: Text(
                                  bookmarked
                                      ? s.chatRemoveBookmark
                                      : s.chatAddBookmark,
                                ),
                              ),
                            if (onPractice != null)
                              PopupMenuItem(
                                value: _LearnAction.practice,
                                child: Text(s.chatPracticeMessage),
                              ),
                            if (_canInterpret)
                              PopupMenuItem(
                                value: _LearnAction.telegraph,
                                child: Text(s.telegraphInterpretAction),
                              ),
                          ],
                        ),
                    ],
                  ),
                  if (_textHidden)
                    _HiddenText(onReveal: onReveal)
                  else
                    PlaybackWordText(
                      text: message.text,
                      activeWord: activeWord,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: foreground,
                      ),
                    ),
                  ?playbackControls,
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        formatMessageTime(context, message.timestamp),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: foreground.withValues(alpha: 0.7),
                        ),
                      ),
                      if (bookmarked) ...[
                        Icon(
                          Icons.bookmark,
                          size: 14,
                          semanticLabel: s.chatBookmarked,
                          color: foreground.withValues(alpha: 0.7),
                        ),
                      ],
                      if (mine) ...[
                        MessageStatusIcon(message.status, message: message),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _shortKey(String key) =>
      key.length > 8 ? key.substring(0, 8) : key;
}

/// Distinct from the app bar's `String` menu.
enum _LearnAction {
  playback,
  practice,
  bookmark,
  retry,
  cancel,
  telegraph,
}

class _HiddenText extends StatelessWidget {
  const _HiddenText({required this.onReveal});

  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // Wrap, not Row: on a phone the bubble is ~330 px wide and the hint plus
    // the button do not always fit on one line.
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Icon(
          Icons.visibility_off_outlined,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        Text(
          context.s.chatHiddenText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(onPressed: onReveal, child: Text(context.s.chatReveal)),
      ],
    );
  }
}

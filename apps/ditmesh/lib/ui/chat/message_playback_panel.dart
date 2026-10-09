import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';
import '../../i18n/l10n_extension.dart';
import 'morse_playback_controller.dart';
import 'morse_playback_settings.dart';
import 'playback_settings_sheet.dart';
import 'playback_timeline.dart';

Future<void> showMessagePlaybackPanel(
  BuildContext context, {
  required ChatMessage message,
  required MorsePlaybackSettings settings,
  required MorsePlaybackController playback,
}) async {
  final service = Provider.of<ChatService?>(context, listen: false);
  final latest = ValueNotifier(message);
  var active = true;
  var liveUpdate = false;
  // Subscribe before pushing the route: metadata may arrive before its first
  // frame. A delayed history read must never replace a newer live row.
  final subscription = service?.messageEvents.listen((row) {
    if (active &&
        row.id == message.id &&
        row.conversationId == message.conversationId &&
        row.senderId == message.senderId) {
      liveUpdate = true;
      latest.value = row;
    }
  });
  if (service != null) {
    unawaited(
      service
          .loadAround(message.conversationId, message.id, before: 0, after: 0)
          .then((rows) {
            if (active && !liveUpdate && rows.isNotEmpty) {
              latest.value = rows.first;
            }
          })
          .catchError((Object _) {}),
    );
  }
  try {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ValueListenableBuilder<ChatMessage>(
              valueListenable: latest,
              builder: (context, row, _) => MessagePlaybackPanel(
                message: row,
                settings: settings,
                playback: playback,
              ),
            ),
          ),
        ),
      ),
    );
  } finally {
    active = false;
    await subscription?.cancel();
    latest.dispose();
  }
}

/// The controls always label word positions numerically. Neither the visual
/// controls nor their semantics contain the text hidden by listen-only mode.
class MessagePlaybackPanel extends StatelessWidget {
  const MessagePlaybackPanel({
    super.key,
    required this.message,
    required this.settings,
    required this.playback,
  });
  final ChatMessage message;
  final MorsePlaybackSettings settings;
  final MorsePlaybackController playback;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([playback, settings]),
    builder: (context, _) {
      final s = context.s;
      final timeline = PlaybackTimeline(
        message.text,
        settings.timing,
        recording: message.recording,
        original: true,
      );
      final count = timeline.words.length;
      final first = count == 0 ? 0 : settings.repeatStart.clamp(0, count - 1);
      final last = count == 0
          ? 0
          : (settings.repeatEnd ?? count - 1).clamp(first, count - 1);
      final active = playback.playingId == message.id;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.chatMessagePlayback,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.chatOriginalRhythm),
            subtitle: Text(
              timeline.isOriginal
                  ? s.chatOriginalAvailable
                  : s.chatOriginalUnavailable,
            ),
            value: settings.originalRhythm && timeline.isOriginal,
            onChanged: timeline.isOriginal
                ? (value) => settings.originalRhythm = value
                : null,
          ),
          TextButton(
            onPressed: () =>
                unawaited(showPlaybackSettingsSheet(context, settings)),
            child: Text(s.chatPlaybackSettings),
          ),
          if (active) MessagePlaybackProgress(playback: playback),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              IconButton(
                key: const ValueKey('player-previous'),
                tooltip: s.chatPreviousWord,
                onPressed: active && playback.activeWord > 0
                    ? () => unawaited(playback.previousWord())
                    : null,
                icon: const Icon(Icons.skip_previous),
              ),
              IconButton(
                key: const ValueKey('player-pause'),
                tooltip: playback.manuallyPaused ? s.chatResume : s.chatPause,
                onPressed: active
                    ? () => playback.manuallyPaused
                          ? playback.resume()
                          : playback.pause()
                    : null,
                icon: Icon(
                  playback.manuallyPaused ? Icons.play_arrow : Icons.pause,
                ),
              ),
              IconButton(
                key: const ValueKey('player-next'),
                tooltip: s.chatNextWord,
                onPressed: active && playback.activeWord + 1 < count
                    ? () => unawaited(playback.nextWord())
                    : null,
                icon: const Icon(Icons.skip_next),
              ),
              IconButton(
                tooltip: s.chatStop,
                onPressed: active ? playback.stop : null,
                icon: const Icon(Icons.stop),
              ),
            ],
          ),
          if (count > 0) ...[
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _WordSelector(
                  key: const ValueKey('player-range-start'),
                  label: s.chatRangeStart,
                  count: count,
                  value: first,
                  min: 0,
                  onChanged: (value) => settings.repeatStart = value,
                ),
                _WordSelector(
                  key: const ValueKey('player-range-end'),
                  label: s.chatRangeEnd,
                  count: count,
                  value: last,
                  min: first,
                  onChanged: (value) => settings.repeatEnd = value,
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.chatLoopRange),
              value: settings.repeatLoop,
              onChanged: (value) => settings.repeatLoop = value,
            ),
          ],
          FilledButton.icon(
            key: const ValueKey('player-repeat-range'),
            onPressed: count == 0
                ? null
                : () => unawaited(
                    playback.play(
                      message.id,
                      message.text,
                      settings.timing,
                      toneHz: settings.toneHz,
                      recording: message.recording,
                      original: settings.originalRhythm,
                      firstWord: first,
                      lastWord: last,
                      loop: settings.repeatLoop,
                    ),
                  ),
            icon: const Icon(Icons.replay),
            label: Text(s.chatRepeatRange),
          ),
        ],
      );
    },
  );
}

class _WordSelector extends StatelessWidget {
  const _WordSelector({
    super.key,
    required this.label,
    required this.count,
    required this.value,
    required this.min,
    required this.onChanged,
  });
  final String label;
  final int count;
  final int value;
  final int min;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      DropdownButton<int>(
        itemHeight: (48 * MediaQuery.textScalerOf(context).scale(14) / 14)
            .clamp(48, 144),
        value: value,
        items: [
          for (var i = min; i < count; i++)
            DropdownMenuItem(
              value: i,
              child: Semantics(
                label: context.s.chatWordNumber(i + 1),
                child: ExcludeSemantics(child: Text('${i + 1}')),
              ),
            ),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    ],
  );
}

class MessagePlaybackProgress extends StatelessWidget {
  const MessagePlaybackProgress({super.key, required this.playback});
  final MorsePlaybackController playback;
  @override
  Widget build(BuildContext context) {
    final total = playback.total.inMilliseconds;
    final elapsed = playback.elapsed.inMilliseconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          playback.usingOriginal
              ? context.s.chatOriginalPlaying
              : context.s.chatListenerPlaying,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        Semantics(
          label: context.s.chatPlaybackProgress,
          value: '${total > 0 ? (elapsed / total * 100).round() : 0}%',
          child: ExcludeSemantics(
            child: LinearProgressIndicator(
              value: total > 0 ? (elapsed / total).clamp(0, 1) : 0,
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          children: [
            Text('${_time(playback.elapsed)} / ${_time(playback.total)}'),
            if (playback.wordCount > 0)
              Text(
                context.s.chatWordProgress(
                  playback.activeWord + 1,
                  playback.wordCount,
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _time(Duration duration) =>
      '${duration.inSeconds ~/ 60}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
}

class InlineMessagePlayback extends StatelessWidget {
  const InlineMessagePlayback({super.key, required this.playback});
  final MorsePlaybackController playback;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 8),
      MessagePlaybackProgress(playback: playback),
      Wrap(
        children: [
          IconButton(
            tooltip: context.s.chatPreviousWord,
            onPressed: playback.activeWord > 0
                ? () => unawaited(playback.previousWord())
                : null,
            icon: const Icon(Icons.skip_previous),
          ),
          IconButton(
            tooltip: playback.manuallyPaused
                ? context.s.chatResume
                : context.s.chatPause,
            onPressed: () =>
                playback.manuallyPaused ? playback.resume() : playback.pause(),
            icon: Icon(
              playback.manuallyPaused ? Icons.play_arrow : Icons.pause,
            ),
          ),
          IconButton(
            tooltip: context.s.chatNextWord,
            onPressed: playback.activeWord + 1 < playback.wordCount
                ? () => unawaited(playback.nextWord())
                : null,
            icon: const Icon(Icons.skip_next),
          ),
        ],
      ),
    ],
  );
}

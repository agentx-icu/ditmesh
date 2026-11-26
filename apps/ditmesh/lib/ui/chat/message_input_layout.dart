part of 'message_input.dart';

extension _ComposerLayout on _MessageInputState {
  Widget _buildComposer(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final S s = context.s;
    final MorsePlaybackSettings settings = MorsePlaybackSettings.of(context);
    // Live keying sounds at the listener's tone, not the sink's default.
    widget.playback.keyingToneHz = settings.toneHz;
    final String pattern = PlaybackTimeline.patternFor(_text.text);
    final int left = _bytesLeft;
    final bool tooLong = left < 0;
    final double paneHeight =
        widget.paneHeight ?? MediaQuery.sizeOf(context).height;
    final bool compact = paneHeight < _MessageInputState.compactHeight;
    final bool tall = paneHeight >= 560;
    final Widget keyer = KeyingInput(
      key: ValueKey<InputMode>(_mode),
      mode: _mode == InputMode.straightKey
          ? KeyingMode.straightKey
          : KeyingMode.paddles,
      timing: settings.timing,
      // Keyers take their sink from playback, which yields to live keying.
      sink: widget.playback.keyingSink,
      clock: widget.playback.clock,
      onText: _appendDecoded,
      onRecordedText: (chunk) {
        _writer.recording.append(_text.text, chunk);
        _appendDecoded(chunk.text);
      },
      controller: _keying,
      onPendingChanged: (pending) {
        if (mounted) _change(() => _keyingPending = pending);
      },
      height: compact ? 64 : (tall ? 132 : 96),
    );
    // The field is keyed, not typed. It never steals focus from the keyer.
    final Widget field = TextField(
      controller: _text,
      focusNode: _focus,
      readOnly: true,
      canRequestFocus: false,
      minLines: 1,
      maxLines: tall ? 4 : 2,
      decoration: InputDecoration(
        hintText: s.chatKeyMessage,
        border: const OutlineInputBorder(),
        isDense: true,
        errorText: tooLong ? s.chatTooLong : null,
      ),
    );
    final VoidCallback? onDelete = _text.text.isEmpty ? null : _deleteLast;
    final Widget delete = Tooltip(
      message: s.chatDeleteLast,
      excludeFromSemantics: true,
      child: TextButton.icon(
        onPressed: onDelete,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(48, 48),
        ),
        icon: const Icon(Icons.backspace_outlined),
        label: Text(
          s.actionDelete,
          semanticsLabel: s.chatDeleteLast,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    final Widget actions = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_sendEnabled && widget.peerOffline)
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Tooltip(
                message: s.chatDraftOfflineQueue,
                excludeFromSemantics: true,
                child: Text(
                  s.chatDraftOfflineQueue,
                  key: const ValueKey('draft-offline-queue-hint'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textScaler: MediaQuery.textScalerOf(
                    context,
                  ).clamp(maxScaleFactor: 1.5),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ListenableBuilder(
          listenable: widget.playback,
          builder: (context, _) {
            final previewing =
                widget.playback.playingId == _previewId ||
                widget.playback.queuedIds.contains(_previewId);
            return IconButton(
              key: const ValueKey('draft-preview'),
              tooltip: previewing ? s.chatStopPreview : s.chatPreviewDraft,
              onPressed:
                  previewing ||
                      (!_sending &&
                          (_text.text.trim().isNotEmpty || _keyingPending))
                  ? () {
                      if (previewing) {
                        widget.playback.stop();
                      } else {
                        _preview(settings);
                      }
                    }
                  : null,
              icon: Icon(previewing ? Icons.stop : Icons.play_arrow),
            );
          },
        ),
        IconButton.filled(
          tooltip: s.chatSend,
          onPressed: _sendEnabled ? () => unawaited(_send()) : null,
          icon: _sending
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
        ),
      ],
    );

    return Material(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            conversationSidePadding(context),
            8,
            conversationSidePadding(context),
            6,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final bool horizontal = width >= (compact ? 500 : 720);
              const double columnGap = 12;
              final double keyWidth = horizontal
                  ? (width * .44).clamp(0, 460).toDouble()
                  : width;
              final double draftWidth = horizontal
                  ? (width - keyWidth - columnGap).clamp(0, 680).toDouble()
                  : width;
              // Keep the same two subtrees when crossing a layout breakpoint.
              // A key that is held during resize keeps its focus and timing.
              return Flex(
                direction: horizontal ? Axis.horizontal : Axis.vertical,
                mainAxisAlignment: horizontal
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.start,
                mainAxisSize: horizontal ? MainAxisSize.max : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: keyWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InputModeSelector(
                          mode: _mode,
                          showLabels:
                              keyWidth >= 300 &&
                              MediaQuery.textScalerOf(context).scale(14) <= 21,
                          onChanged: (m) => _changeMode(m, settings),
                        ),
                        keyer,
                      ],
                    ),
                  ),
                  const SizedBox(width: columnGap, height: 6),
                  SizedBox(
                    width: draftWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: field),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: draftWidth * .64,
                              ),
                              child: delete,
                            ),
                          ],
                        ),
                        actions,
                        if (!compact)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: MorsePatternText(
                                  pattern.isEmpty ? ' ' : pattern,
                                  maxLines: 2,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  s.chatBytesLeftCount(left),
                                  textAlign: TextAlign.end,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: tooLong
                                        ? scheme.error
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

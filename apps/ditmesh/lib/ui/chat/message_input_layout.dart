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

    // Short screens (a phone in landscape): the pad shrinks, the mode switch
    // joins the draft row and the preview row goes, so the conversation
    // keeps most of the height.
    final bool compact =
        MediaQuery.sizeOf(context).height < _MessageInputState.compactHeight;
    final Widget selector = LayoutBuilder(
      builder: (context, constraints) => InputModeSelector(
        mode: _mode,
        // Icon-only below ~420 px so the segments fit a phone.
        showLabels: !compact && constraints.maxWidth >= 420,
        onChanged: (m) => _changeMode(m, settings),
      ),
    );
    final Widget keyer = KeyingInput(
      key: ValueKey<InputMode>(_mode),
      mode: _mode == InputMode.straightKey
          ? KeyingMode.straightKey
          : KeyingMode.paddles,
      timing: settings.timing,
      // Keyers take the sink from playback, which yields to them.
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
      height: compact ? 64 : 132,
      showHint: !compact,
    );
    final Widget draftRow = Padding(
      padding: EdgeInsets.fromLTRB(compact ? 6 : 12, 6, 6, compact ? 6 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (compact) ...[
            SizedBox(width: 120, child: selector),
            const SizedBox(width: 6),
          ],
          Expanded(
            // Keyed, not typed: no soft keyboard, and focus stays
            // on the key so desktop keying keeps working.
            child: TextField(
              controller: _text,
              focusNode: _focus,
              readOnly: true,
              canRequestFocus: false,
              minLines: 1,
              maxLines: compact ? 2 : 4,
              decoration: InputDecoration(
                hintText: s.chatKeyMessage,
                border: const OutlineInputBorder(),
                isDense: true,
                errorText: tooLong ? s.chatTooLong : null,
              ),
            ),
          ),
          IconButton(
            tooltip: s.chatDeleteLast,
            onPressed: _text.text.isEmpty ? null : _deleteLast,
            icon: const Icon(Icons.backspace_outlined),
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
      ),
    );

    return Material(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!compact)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: selector,
              ),
            keyer,
            draftRow,
            if (!compact)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Row(
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
                    // Flexible: at 2x text the counter must not overflow.
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
              ),
          ],
        ),
      ),
    );
  }
}

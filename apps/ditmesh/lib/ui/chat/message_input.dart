import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:morse_core/morse_core.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import 'chat_layout.dart';
import 'chat_scope.dart';
import 'keying_input.dart';
import 'input_mode.dart';
import 'input_mode_selector.dart';
import 'local_message_sends.dart';
import 'morse_pattern_text.dart';
import 'morse_playback_controller.dart';
import 'morse_playback_settings.dart';

/// Input modes from plan §5.3: straight key or iambic paddles, never typed
/// text. Decoded characters land in a read-only draft field; delete-last
/// fixes mistakes before sending.
export 'input_mode.dart';

// Share write ordering across editors for the same service and conversation.
// A pending dispose flush must finish before a reopened editor's newer draft.
final _draftWriters = Expando<Map<String, _DraftWriter>>();

_DraftWriter _writerFor(ChatService service, String id) {
  final writers = _draftWriters[service] ??= {};
  return writers.putIfAbsent(
    id,
    () => _DraftWriter((writer) {
      if (identical(writers[id], writer)) writers.remove(id);
    }),
  );
}

class _DraftWriter {
  _DraftWriter(this._invalidate);
  final void Function(_DraftWriter) _invalidate;
  Future<void> _tail = Future<void>.value();
  Future<void> get settled => _tail;
  int pending = 0;
  String latest = '';
  String savedDraft = '';
  Object? error;
  bool valid = true;
  TextEditingController? _controller;
  int _editors = 0;
  StreamSubscription<Identity?>? _identitySub;

  TextEditingController acquire(
    String initialDraft,
    IdentityService? identity,
  ) {
    if (_editors == 0 && pending == 0 && error == null) {
      savedDraft = latest = initialDraft;
    }
    _editors++;
    if (_identitySub == null && identity != null) {
      final key = identity.current?.publicKey;
      _identitySub = identity.identityChanges.listen((value) {
        if (value == null || value.publicKey != key) {
          valid = false;
          _invalidate(this);
          unawaited(_identitySub?.cancel());
          _identitySub = null;
        }
      });
    }
    return _controller ??= TextEditingController(
      text: pending > 0 || error != null ? latest : initialDraft,
    );
  }

  void _releaseIdleObserver() {
    if (_editors == 0 && pending == 0 && error == null) {
      _invalidate(this);
      unawaited(_identitySub?.cancel());
      _identitySub = null;
    }
  }

  void release() {
    if (--_editors == 0) {
      _controller?.dispose();
      _controller = null;
      _releaseIdleObserver();
    }
  }

  Future<void> save(String draft, Future<void> Function() write) {
    latest = draft;
    pending++;
    return _tail = _tail.then((_) async {
      try {
        await write();
      } finally {
        pending--;
        _releaseIdleObserver();
      }
    });
  }
}

/// The compose area: mode selector, keying pad, read-only draft field with
/// live Morse preview and remaining-byte counter, send button. Drafts are
/// persisted through [ChatService.setDraft] (debounced, flushed on dispose).
class MessageInput extends StatefulWidget {
  const MessageInput({
    super.key,
    required this.service,
    required this.conversationId,
    required this.playback,
    this.initialDraft = '',
    this.onSent,
  });

  final ChatService service;
  final String conversationId;
  final MorsePlaybackController playback;
  final String initialDraft;
  final ValueChanged<ChatMessage>? onSent;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput>
    with WidgetsBindingObserver
    implements IdentityDataStore {
  static const Duration _draftDebounce = Duration(milliseconds: 400);

  /// Below this window height the composer switches to its compact layout.
  static const double compactHeight = 520;

  late final _DraftWriter _writer = _writerFor(
    widget.service,
    widget.conversationId,
  );
  // Multiple routes can open the same conversation. Share their text so each
  // editor observes every edit revision, and an older send cannot clear it.
  late final TextEditingController _text = _writer.acquire(
    widget.initialDraft,
    _identity,
  );
  final FocusNode _focus = FocusNode();
  final KeyingInputController _keying = KeyingInputController();
  bool _keyingPending = false;
  InputMode _mode = InputMode.straightKey;
  Timer? _draftTimer;
  late String _lastDraft;
  int _editRevision = 0;
  bool _sending = false;
  IdentityService? _identity;
  String? _identityKey;
  bool _acceptDrafts = true;
  StreamSubscription<Identity?>? _identitySub;
  bool _identityInvalidated = false;

  @override
  void initState() {
    super.initState();
    _mode = MorsePlaybackSettings.of(context, listen: false).inputMode;
    _identity = maybeIdentityService(context);
    _lastDraft = _text.text;
    _identityKey = _identity?.current?.publicKey;
    _identitySub = _identity?.identityChanges.listen((identity) {
      if (identity == null || identity.publicKey != _identityKey) {
        _identityInvalidated = true;
        _acceptDrafts = false;
        _draftTimer?.cancel();
      } else if (!_identityInvalidated) {
        // Failed replacement republishes the old identity without a null
        // boundary. A committed same-key restore must keep this editor stale.
        _acceptDrafts = true;
      }
    });
    final identity = _identity;
    if (identity is PersistentIdentityService) identity.registerDataStore(this);
    _text.addListener(_onChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_identitySub?.cancel());
    final identity = _identity;
    if (identity is PersistentIdentityService) {
      identity.unregisterDataStore(this);
    }
    _draftTimer?.cancel();
    unawaited(_persistDraft());
    _text.removeListener(_onChanged);
    _writer.release();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    // Selection/focus changes do not create a new draft revision.
    if (_text.text == _lastDraft) return;
    _lastDraft = _text.text;
    _editRevision++;
    setState(() {});
    _draftTimer?.cancel();
    _draftTimer = Timer(_draftDebounce, () => unawaited(_persistDraft()));
  }

  Future<void> _persistDraft() {
    final String draft = _lastDraft;
    if (!_acceptDrafts || !_writer.valid) return _writer.settled;
    if (_writer.pending > 0 && draft == _writer.latest) return _writer.settled;
    if (_writer.pending == 0 &&
        draft == _writer.savedDraft &&
        _writer.error == null) {
      return _writer.settled;
    }
    final service = widget.service;
    final conversationId = widget.conversationId;
    return _writer.save(draft, () async {
      if (!_acceptDrafts ||
          !_writer.valid ||
          (_identity != null &&
              _identity?.current?.publicKey != _identityKey)) {
        return;
      }
      try {
        await service.setDraft(conversationId, draft);
        _writer.savedDraft = draft;
        _writer.error = null;
      } on Object catch (error) {
        _writer.error = error;
        debugPrint('[MessageInput] draft save failed: $error');
      }
    });
  }

  @override
  Future<void> flush() async {
    _draftTimer?.cancel();
    await _persistDraft();
    if (_writer.error != null && _acceptDrafts && _writer.valid) {
      throw StateError('Could not save compose draft: ${_writer.error}');
    }
  }

  @override
  Future<void> prepareForReplacement() {
    _acceptDrafts = false;
    _draftTimer?.cancel();
    return _writer.settled;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(
        flush().catchError((Object error) {
          debugPrint('[MessageInput] background flush failed: $error');
        }),
      );
    }
  }

  int get _bytesUsed => utf8.encode(_text.text).length;

  int get _bytesLeft => widget.service.maxMessageBytes - _bytesUsed;

  bool get _canSend =>
      !_sending && _text.text.trim().isNotEmpty && _bytesLeft >= 0;

  /// Send is offered while a character is still being keyed: pressing it
  /// commits that character first.
  bool get _sendEnabled =>
      _canSend || (!_sending && _keyingPending && _bytesLeft >= 0);

  Future<void> _send() async {
    // Finish the character being keyed so it ends THIS message instead of
    // starting the next one; then re-check text and byte budget.
    _keying.complete();
    if (!_canSend) return;
    final String text = _text.text.trim();
    final int revision = _editRevision;
    final S s = context.s;
    setState(() => _sending = true);
    try {
      final ChatMessage sent = await widget.service.sendText(
        widget.conversationId,
        text,
      );
      LocalMessageSends.forService(widget.service).publish(sent);
      if (!mounted) return;
      _draftTimer?.cancel();
      if (_editRevision == revision) _text.clear();
      unawaited(_persistDraft());
      widget.onSent?.call(sent);
    } on Object catch (e) {
      if (mounted) showSnack(context, describeChatError(s, e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _changeMode(InputMode mode, MorsePlaybackSettings settings) {
    // The keyer is replaced: commit what it was keying first.
    _keying.complete();
    setState(() => _mode = mode);
    settings.inputMode = mode;
  }

  void _appendDecoded(String text) {
    final String current = _text.text;
    // A word gap right after nothing (or after a space) adds no information.
    if (text == ' ' && (current.isEmpty || current.endsWith(' '))) return;
    _text.value = TextEditingValue(
      text: current + text,
      selection: TextSelection.collapsed(offset: current.length + text.length),
    );
  }

  void _deleteLast() {
    final String current = _text.text;
    if (current.isEmpty) return;
    final String next = current.substring(0, current.length - 1);
    _text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final S s = context.s;
    final MorsePlaybackSettings settings = MorsePlaybackSettings.of(context);
    // Live keying sounds at the listener's tone, not the sink's default.
    widget.playback.keyingToneHz = settings.toneHz;
    final String pattern = MorseEncoder.toPattern(_text.text);
    final int left = _bytesLeft;
    final bool tooLong = left < 0;

    // Short screens (a phone in landscape): the pad shrinks, the mode switch
    // joins the draft row and the preview row goes, so the conversation
    // keeps most of the height.
    final bool compact = MediaQuery.sizeOf(context).height < compactHeight;
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
      controller: _keying,
      onPendingChanged: (pending) {
        if (mounted) setState(() => _keyingPending = pending);
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

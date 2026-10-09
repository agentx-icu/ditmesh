import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/chat_error_messages.dart';
import '../../i18n/l10n_extension.dart';
import 'chat_layout.dart';
import 'chat_scope.dart';
import 'keying_input.dart';
import 'keyed_draft_recording.dart';
import 'input_mode.dart';
import 'input_mode_selector.dart';
import 'local_message_sends.dart';
import 'compose_editing.dart';
import 'morse_pattern_text.dart';
import 'playback_timeline.dart';
import 'morse_playback_controller.dart';
import 'morse_playback_settings.dart';

/// Input modes from plan §5.3: straight key or iambic paddles, never typed
/// text. Decoded characters land in a read-only draft field; delete-last
/// fixes mistakes before sending.
export 'input_mode.dart';

part 'message_draft_writer.dart';
part 'message_input_layout.dart';

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

  /// False while the composer is leaving the tree (route popped, pane
  /// collapsed). The keyer commits a half-keyed character on dispose; by
  /// then the field is inert, so that text goes to the draft directly.
  bool _live = true;

  @override
  void deactivate() {
    _live = false;
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _live = true;
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
    _writer.recording.reconcile(_lastDraft);
    _editRevision++;
    setState(() {});
    _draftTimer?.cancel();
    _draftTimer = Timer(_draftDebounce, () => unawaited(_persistDraft()));
  }

  Future<void> _persistDraft() {
    // A teardown commit by another editor of this conversation, not yet in
    // the shared controller, outranks this editor's copy of the text.
    final String draft = _writer.teardownCommit ?? _lastDraft;
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
        // Judged here, inside the serialised save: one notice per failure
        // streak, however many saves were queued behind it. Only a storage
        // failure is reported: a ChatException is the service refusing
        // (not connected, conversation gone), which the screen reports.
        final bool firstFailure = _writer.error == null;
        _writer.error = error;
        debugPrint('[MessageInput] draft save failed: $error');
        if (firstFailure &&
            error is! ChatException &&
            mounted &&
            Scaffold.maybeOf(context) != null &&
            _live &&
            _acceptDrafts &&
            _writer.valid &&
            (_identity == null ||
                _identity?.current?.publicKey == _identityKey)) {
          showSnack(context, context.s.chatDraftSaveFailed);
        }
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

  String get _previewId => 'draft:${widget.conversationId}';

  void _preview(MorsePlaybackSettings settings) {
    _keying.complete();
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    unawaited(
      widget.playback.toggle(
        _previewId,
        text,
        settings.timing,
        toneHz: settings.toneHz,
        recording: _writer.recording.forText(text),
        original: settings.originalRhythm,
      ),
    );
  }

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
        recording: _writer.recording.forText(text),
      );
      LocalMessageSends.forService(widget.service).publish(sent);
      if (!mounted) return;
      widget.playback.cancelMessages({_previewId});
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
    // Another editor of this conversation (the two-pane collapse mounts the
    // route's composer before the pane's one goes) shares the controller:
    // a commit must land there, or that editor's next save overwrites it.
    final bool shared = _writer.editors > 1;
    final String current = _live || shared ? _text.text : _lastDraft;
    // A word gap right after nothing (or after a space) adds no information.
    if (text == ' ' && (current.isEmpty || current.endsWith(' '))) return;
    if (!_live) {
      // Leaving mid-character (Android back / predictive back, the iOS
      // swipe, the two-pane collapse): the keyer flushed on dispose. The
      // tree is locked and this field's editable is already detached, so
      // record the text for the dispose-time draft flush instead of
      // notifying the controller now.
      _lastDraft = current + text;
      _editRevision++;
      if (shared) {
        // The other editor shows the shared controller: record the commit
        // as the canonical draft (its dispose flush, should it leave in this
        // same frame, persists that instead of its stale text) and hand it
        // to the controller once the frame is over, unless no editor is
        // left to show it.
        final _DraftWriter writer = _writer..teardownCommit = _lastDraft;
        final TextEditingController controller = _text;
        scheduleMicrotask(() {
          final String? commit = writer.teardownCommit;
          writer.teardownCommit = null;
          if (commit == null || writer.editors == 0) return;
          controller.value = TextEditingValue(
            text: commit,
            selection: TextSelection.collapsed(offset: commit.length),
          );
        });
      }
      return;
    }
    _text.value = TextEditingValue(
      text: current + text,
      selection: TextSelection.collapsed(offset: current.length + text.length),
    );
  }

  void _deleteLast() {
    final String current = _text.text;
    if (current.isEmpty) return;
    // A prosign or unread pattern went in as one token: it goes as one.
    final String next = withoutLastKeyedUnit(current);
    _text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  void _change(VoidCallback change) => setState(change);

  @override
  Widget build(BuildContext context) => _buildComposer(context);
}

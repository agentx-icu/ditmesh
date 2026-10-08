part of 'message_input.dart';

// The per-conversation draft writer shared by every open composer of the
// same conversation: one controller, ordered writes, identity invalidation.

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

  /// Editors currently sharing this writer (and its controller).
  int get editors => _editors;

  /// A character committed by an editor that was leaving the tree while
  /// another editor shared the controller: the canonical draft until the
  /// controller has taken it (after the locked unmount frame). Every save
  /// in between, including the other editor's own dispose flush, must
  /// persist this rather than its stale copy of the text.
  String? teardownCommit;
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

import 'dart:async';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

/// Counts the session boundaries of one [ChatService] (connect, disconnect,
/// an identity restore), so an action prepared in one session — a Retry on
/// a refusal, a password prompt for an invite — can tell that it would now
/// land in another one and drop itself.
final class ChatSessionEpoch {
  ChatSessionEpoch(this.service, {void Function()? onBoundary}) {
    _sub = service.sessionChanges.listen((up) {
      // The replay of the current value on listen is not a boundary.
      if (_last != null && _last != up) {
        _value++;
        onBoundary?.call();
      }
      _last = up;
    });
  }

  final ChatService service;
  int _value = 0;
  bool? _last;
  bool _disposed = false;
  StreamSubscription<bool>? _sub;

  /// The session as it is now, for [ChatSessionToken.isCurrent] later.
  ChatSessionToken capture() => ChatSessionToken._(this, _value);

  void dispose() {
    _disposed = true;
    unawaited(_sub?.cancel());
  }
}

/// One captured session of one service (see [ChatSessionEpoch.capture]).
/// It keeps its own tracker, so a replacement tracker (another service, a
/// fresh count) can never make it look current again.
final class ChatSessionToken {
  ChatSessionToken._(this._epoch, this._value);

  final ChatSessionEpoch _epoch;
  final int _value;

  /// Whether the captured session is still open and [inUse] is still the
  /// service it belongs to.
  bool isCurrent(ChatService inUse) =>
      !_epoch._disposed &&
      identical(_epoch.service, inUse) &&
      _epoch._value == _value &&
      inUse.hasSession;
}

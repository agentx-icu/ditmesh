import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../notifications/notification_center.dart';

/// Whether the user is looking at one conversation right now, and what
/// depends on it:
///
/// - the [NotificationCenter]'s active conversation (no banner for what is
///   on screen), claimed with an owner token so a newer screen of the same
///   conversation keeps its claim when an older one goes away;
/// - marking messages read: only while attended, so a conversation left open
///   on a hidden tab, under a dialog or in a backgrounded app does not
///   swallow unread counts and banners. A read that could not be marked
///   (unattended, or `markRead` failed) stays pending and is retried.
///
/// "Attended" = its tickers run (visible shell tab, route not covered by an
/// opaque one), its route is the current one (no dialog or sheet on top)
/// and the app is in the foreground.
class ConversationAttention with WidgetsBindingObserver {
  ConversationAttention({
    required ChatService service,
    required String conversationId,
    NotificationCenter? center,
    VoidCallback? onSessionStarted,
  }) : _service = service,
       _id = conversationId,
       _center = center,
       _foreground = _isForeground(WidgetsBinding.instance.lifecycleState) {
    WidgetsBinding.instance.addObserver(this);
    // A chat session starting is when a failed history load or read can
    // succeed (it may start while the network is still connecting).
    _session = service.sessionChanges.listen((up) {
      if (_disposed || !up) return;
      onSessionStarted?.call();
      if (_readPending) _retryRead();
    });
  }

  final ChatService _service;
  final String _id;
  final NotificationCenter? _center;
  final Object _owner = Object();
  StreamSubscription<bool>? _session;

  bool _tickers = true;
  bool _routeCurrent = true;
  bool _foreground;
  bool _readPending = false;
  int _readRequests = 0;
  bool _marking = false;
  bool _disposed = false;

  bool get attended => _tickers && _routeCurrent && _foreground;

  static bool _isForeground(AppLifecycleState? state) =>
      state == null ||
      state == AppLifecycleState.resumed ||
      state == AppLifecycleState.inactive;

  /// Call from `didChangeDependencies` (TickerMode and the route status are
  /// inherited, so a change re-runs it).
  void update(BuildContext context) {
    final bool tickers = TickerMode.valuesOf(context).enabled;
    final bool routeCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    if (tickers == _tickers && routeCurrent == _routeCurrent) return;
    _tickers = tickers;
    _routeCurrent = routeCurrent;
    // Runs during build: act once the frame is done.
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  /// Call once after the first frame.
  void start() => _apply();

  /// The latest messages are on screen: mark them read now if the user is
  /// looking, otherwise as soon as they are.
  void markRead() {
    _readPending = true;
    _readRequests++;
    _apply();
  }

  /// A new chance for a pending read (reconnect): counts as a new request,
  /// so one already in flight is followed by another attempt.
  void _retryRead() {
    _readRequests++;
    _apply();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bool foreground = _isForeground(state);
    if (foreground == _foreground) return;
    _foreground = foreground;
    if (_readPending) {
      _retryRead();
    } else {
      _apply();
    }
  }

  void _apply() {
    if (_disposed) return;
    if (!attended) {
      _center?.releaseActiveConversation(_owner);
      return;
    }
    _center?.claimActiveConversation(_id, _owner);
    if (_readPending) unawaited(_flushRead());
  }

  Future<void> _flushRead() async {
    if (_marking) return;
    _marking = true;
    final int request = _readRequests;
    var marked = false;
    try {
      await _service.markRead(_id);
      marked = true;
    } on Object {
      // Not connected, or no row yet: stays pending for the next chance.
    } finally {
      _marking = false;
    }
    if (_disposed) return;
    if (marked && request == _readRequests) {
      _readPending = false;
    } else if (request != _readRequests) {
      // Asked again while marking (a new message, a reconnect, a resume):
      // that request was folded into this one, so honour it now — after a
      // success to cover the newer message, after a failure to retry.
      _apply();
    }
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_session?.cancel());
    _center?.releaseActiveConversation(_owner);
  }
}

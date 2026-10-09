part of 'conversation_screen.dart';

/// Search / jump, clear history, leave group and the overflow menu of
/// [ConversationScreen]; the state's fields are declared here abstractly
/// and provided by `_ConversationScreenState`.
mixin _ConversationMenuActions on State<ConversationScreen> {
  ChatService get _service;
  MorsePlaybackController get _playback;
  LocalMessageSends get _localSends;
  ScrollController get _scroll;
  List<ChatMessage> get _older;
  List<ChatMessage> get _messages;
  Set<String> get _revealed;
  Map<String, ChatMessage> get _pendingStatuses;
  bool get _loading;
  set _loading(bool value);
  set _loadingOlder(bool value);
  bool get _loadingOlderNow;
  set _hasMore(bool value);
  bool get _clearing;
  set _clearing(bool value);
  set _historyLimit(int value);
  int get _generation;
  set _generation(int value);
  set _newMessages(int value);
  set _error(Object? value);
  set _olderError(Object? value);
  String get _id;
  bool get _isGroup;
  Future<void> _load();
  void _markRead();
  void _scrollToEnd();

  /// Showing a search result's surroundings, detached from the live end.
  bool _jumpedAway = false;
  bool _loadingNewer = false;

  /// Live arrivals while jumped away, merged at the live end.
  final List<ChatMessage> _parked = <ChatMessage>[];

  /// Rows per page when paging around a jumped window.
  static const int _aroundPage = 50;

  /// Earlier rows before a jumped window, anchored on its oldest row (the
  /// live-end window read cannot find that origin).
  Future<void> _loadOlderAround() async {
    final anchor = _older.isNotEmpty ? _older.first : _messages.first;
    final int generation = _generation;
    setState(() {
      _loadingOlder = true;
      _olderError = null;
    });
    try {
      final rows = await _service.loadAround(
        _id,
        anchor.id,
        before: _aroundPage,
        after: 0,
      );
      if (!mounted || generation != _generation) return;
      final earlier = rows.where((m) => m.id != anchor.id).toList();
      setState(() {
        _older.insertAll(0, earlier);
        _hasMore = earlier.length == _aroundPage;
        _loadingOlder = false;
      });
    } on Object catch (e) {
      if (mounted && generation == _generation) {
        setState(() {
          _olderError = e;
          _loadingOlder = false;
        });
      }
    }
  }

  /// Later rows after a jumped window. Fewer than a page means the live
  /// end was reached: the window becomes the live timeline again.
  Future<void> _loadNewerAround() async {
    if (_loadingNewer || _messages.isEmpty || _loading || _clearing) return;
    _loadingNewer = true;
    final anchor = _messages.last;
    final int generation = _generation;
    try {
      final rows = await _service.loadAround(
        _id,
        anchor.id,
        before: 0,
        after: _aroundPage,
      );
      if (!mounted || generation != _generation || !_jumpedAway) return;
      final later = rows.where((m) => m.id != anchor.id).toList();
      final reachedEnd = later.length < _aroundPage;
      setState(() {
        final known = {for (final m in _messages) m.id};
        _messages.addAll(later.where((m) => known.add(m.id)));
        if (reachedEnd) {
          // Arrivals during the request are not lost; they stay unread
          // until the reader actually scrolls to them.
          _messages.addAll(_parked.where((m) => known.add(m.id)));
          _parked.clear();
          _jumpedAway = false;
        }
      });
    } on Object {
      // Scrolling again retries.
    } finally {
      _loadingNewer = false;
    }
  }

  /// The profile's bookmarks, once resolved.
  MessageBookmarks? _bookmarkStore;

  Future<void> _initBookmarks() async {
    final store = await MessageBookmarks.of(context);
    if (!mounted) return;
    setState(() => _bookmarkStore = store..addListener(_onBookmarks));
    unawaited(_reconcileBookmarks(store));
  }

  /// Drops this conversation's bookmarks whose message no longer exists
  /// (deleted elsewhere, cleared on another device's restore, ...).
  Future<void> _reconcileBookmarks(MessageBookmarks store) async {
    final missing = <String>{};
    for (final b in store.inConversation(_id)) {
      try {
        final rows = await _service.loadAround(
          _id,
          b.messageId,
          before: 0,
          after: 0,
        );
        if (rows.isEmpty) missing.add(b.messageId);
      } on Object {
        return; // Not connected: try again next time.
      }
    }
    if (missing.isNotEmpty && mounted) {
      await store.removeMissing(_id, missing).catchError((Object _) {});
    }
  }

  void _onBookmarks() {
    if (mounted) setState(() {});
  }

  /// The store to write to: a retired one (profile replaced, or a failed
  /// replacement rolled back) is swapped for the current profile's store.
  Future<MessageBookmarks?> _liveBookmarks() async {
    final store = _bookmarkStore;
    if (store == null || !store.isRetired || !mounted) return store;
    final fresh = await MessageBookmarks.of(context);
    if (!mounted) return fresh;
    store.removeListener(_onBookmarks);
    setState(() => _bookmarkStore = fresh..addListener(_onBookmarks));
    return fresh;
  }

  void _showLatest() {
    if (_jumpedAway) {
      // Drop the whole historical window; live arrivals during the reload
      // land in the emptied list and are merged by `_load`.
      _jumpedAway = false;
      _generation++;
      _parked.clear();
      setState(() {
        _older.clear();
        _messages.clear();
        _newMessages = 0;
        // Outstanding page loads belong to the dropped window.
        _loadingOlder = false;
        _loadingNewer = false;
      });
      unawaited(_load());
      return;
    }
    setState(() => _newMessages = 0);
    _scrollToEnd();
    _markRead();
  }

  /// Opens history search; a picked result is shown at the top of the
  /// timeline with its surrounding history. Neither marks anything read.
  Future<void> _search() async {
    final bookmarks = await MessageBookmarks.of(context);
    if (!mounted) return;
    final ChatMessage? hit = await ConversationMenu.openSearch(
      context,
      service: _service,
      target: widget.target,
      bookmarks: bookmarks,
    );
    if (hit == null || !mounted) return;
    final int generation = ++_generation;
    try {
      final rows = await _service.loadAround(_id, hit.id);
      if (!mounted || generation != _generation) return;
      if (rows.isEmpty) {
        // Gone (cleared / deleted): its bookmark no longer resolves.
        try {
          await bookmarks.removeMissing(_id, {hit.id});
        } on Object {
          // Kept dirty; retried by the store.
        }
        if (mounted) showSnack(context, context.s.chatMessageGone);
        return;
      }
      final at = rows.indexWhere((m) => m.id == hit.id);
      setState(() {
        _jumpedAway = true;
        _older
          ..clear()
          ..addAll(rows.take(at));
        _messages
          ..clear()
          ..addAll(rows.skip(at));
        _hasMore = at > 0;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
      });
    } on Object catch (e) {
      if (mounted) showSnack(context, describeChatError(context.s, e));
    }
  }

  Group? _group() {
    if (!_isGroup) return null;
    for (final Group g in _service.groups) {
      if (g.id == widget.target.peerId) return g;
    }
    return null;
  }

  Future<void> _leaveGroup() async {
    final bool left = await ConversationMenu.leaveGroup(
      context,
      _service,
      widget.target.peerId,
    );
    if (!left || !mounted) return;
    _closeConversation();
  }

  /// Leaves this screen: the master-detail owner clears its selection, a
  /// pushed route is removed (even when another route sits above it).
  void _closeConversation() {
    if (widget.embedded) {
      widget.onClosed?.call();
      return;
    }
    final ModalRoute<Object?>? route = ModalRoute.of(context);
    if (route == null) return;
    if (route.isCurrent) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).removeRoute(route);
    }
  }

  /// The blocked keys this screen last applied (null before the first
  /// replay of [ChatService.blockedPeerChanges]).
  Set<String>? _blockedSeen;

  /// A block (from this screen, a member list or anywhere else) hides at
  /// once: a blocked peer's direct conversation closes; in a group their
  /// rows go, queued or playing Morse of them included, and loads still in
  /// flight are dropped and redone (they may have read the rows before the
  /// block). An unblock reloads the history so their rows come back. The
  /// service filters everything that arrives later.
  void _onBlockedPeers(Set<String> blocked) {
    if (!mounted) return;
    final Set<String>? seen = _blockedSeen;
    _blockedSeen = {...blocked};
    final ConversationTarget target = widget.target;
    if (!_isGroup) {
      if (!target.isSelf && blocked.contains(target.peerId.toUpperCase())) {
        _closeConversation();
      }
      return;
    }
    if (seen != null && seen.difference(blocked).isNotEmpty) {
      _reloadAfterBlocking();
      return;
    }
    bool hidden(ChatMessage m) =>
        !m.isMine && blocked.contains(m.senderId.toUpperCase());
    final Set<String> ids = {
      for (final m in [..._older, ..._messages, ..._parked])
        if (hidden(m)) m.id,
    };
    if (ids.isNotEmpty) {
      _playback.cancelMessages(ids);
      setState(() {
        _older.removeWhere(hidden);
        _messages.removeWhere(hidden);
        _parked.removeWhere(hidden);
        _revealed.removeAll(ids);
      });
    }
    if (_loading || _loadingOlderNow) _reloadAfterBlocking();
  }

  /// Drops every outstanding page load and reads the live window again. A
  /// search-jumped window is historical: like [_showLatest], it is dropped
  /// whole so its rows are not merged after the latest page.
  void _reloadAfterBlocking() {
    final bool wasJumped = _jumpedAway;
    _generation++;
    _jumpedAway = false;
    _parked.clear();
    setState(() {
      _older.clear();
      if (wasJumped) {
        _messages.clear();
        _newMessages = 0;
      }
      _loadingOlder = false;
      _loadingNewer = false;
    });
    unawaited(_load());
  }

  Future<void> _clearHistory() async {
    final S s = context.s;
    final String body = await ConversationLearning.clearHistoryBody(
      context,
      _id,
    );
    if (!mounted) return;
    final bool ok = await confirm(
      context,
      title: s.chatClearHistory,
      body: body,
      confirmLabel: s.chatClearHistory,
    );
    if (!ok || !mounted || _clearing) return;
    final bool wasLoading = _loading;
    final ids = {
      for (final m in [..._older, ..._messages]) m.id,
      ..._pendingStatuses.keys,
    };
    // Invalidate outstanding loads before deletion. New arrivals remain live.
    _generation++;
    setState(() {
      _clearing = true;
      _loading = false;
      _loadingOlder = false;
    });
    // A message being deleted must not keep sounding or wait in the queue.
    _playback.cancelMessages(ids);
    try {
      await _service.clearHistory(_id);
      _localSends.recordClear(_id, ids);
      if (!mounted) return;
      // Back to the live timeline at once: arrivals during the bookmark
      // cleanup below must show — and so must rows that arrived (and were
      // parked) while the clear itself was running.
      _jumpedAway = false;
      final arrived = _parked.where((m) => !ids.contains(m.id)).toList();
      _parked.clear();
      setState(() {
        _messages.removeWhere((m) => ids.contains(m.id));
        final known = {for (final m in _messages) m.id};
        _messages.addAll(arrived.where((m) => known.add(m.id)));
        _older.clear();
        _newMessages = 0;
      });
      // Clearing history invalidates its bookmarks; failures are kept dirty
      // and retried by the store.
      try {
        await (await _liveBookmarks())?.removeConversation(_id);
      } on Object {
        // The store stays dirty and rewrites on its next flush.
      }
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => ids.contains(m.id));
        _older.clear();
        _revealed.clear();
        _pendingStatuses.clear();
        _historyLimit = 50;
        _hasMore = false;
        _error = _olderError = null;
      });
      _scrollToEnd();
    } on Object catch (e) {
      if (mounted) {
        showSnack(context, describeChatError(s, e));
        if (wasLoading) unawaited(_load());
      }
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  Future<void> _onMenu(String action) async {
    switch (action) {
      case 'members':
        final Group? group = _group();
        if (group != null) {
          await showGroupMembersSheet(context, service: _service, group: group);
        }
      case 'leave':
        await _leaveGroup();
      case 'search':
        await _search();
      case 'practice':
        await GroupPracticePage.open(
          context,
          conversationId: _id,
          groupTitle: _group()?.name ?? '',
        );
      case 'connection':
        await ConnectionDiagnosticsPage.open(context, conversationId: _id);
      case 'clear':
        await _clearHistory();
      case 'block':
        await confirmAndBlock(
          context,
          service: _service,
          publicKey: widget.target.peerId,
          name: conversationTitleText(context.s, widget.target),
          scope: BlockScope.contact,
        );
      case 'listenOnly':
        final settings = ConversationPlaybackPreferences.settingsFor(
          context,
          _id,
          listen: false,
        );
        settings.listenOnly = !settings.listenOnly;
    }
  }
}

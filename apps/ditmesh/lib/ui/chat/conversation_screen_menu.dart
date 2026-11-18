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

  /// The last later-rows read of this window failed: reported once per
  /// failure streak (scrolling again retries silently).
  bool _newerFailed = false;

  /// Bumped by every picked search result: of two picks whose reads
  /// overlap, only the later one installs its window.
  int _searchRequest = 0;

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
      _newerFailed = false;
      setState(() {
        final known = {for (final m in _messages) m.id};
        _messages.addAll(later.where((m) => known.add(m.id)));
        if (reachedEnd) {
          // Arrivals during the request are not lost; they stay unread
          // until the reader actually scrolls to them.
          _messages.addAll(_parked.where((m) => known.add(m.id)));
          _parked.clear();
          _jumpedAway = false;
          widget.onSearchAnchor?.call(null);
        }
      });
    } on Object catch (e) {
      // Scrolling again retries; a failure streak of this window is
      // reported once.
      debugLog(() => '[Conversation] loading later rows failed: $e');
      if (mounted &&
          generation == _generation &&
          _jumpedAway &&
          !_newerFailed) {
        _newerFailed = true;
        showSnack(context, describeChatError(context.s, e));
      }
    } finally {
      // A newer window (another jump, the latest page) owns the flag now.
      if (generation == _generation) _loadingNewer = false;
    }
  }

  /// The profile's bookmarks, once resolved.
  MessageBookmarks? _bookmarkStore;

  Future<void> _initBookmarks() async {
    final store = await MessageBookmarks.of(context);
    if (!mounted) return;
    setState(() => _bookmarkStore = store..addListener(_onBookmarks));
  }

  void _onBookmarks() {
    if (mounted) setState(() {});
  }

  void _showLatest() {
    if (_jumpedAway) {
      // Drop the whole historical window; live arrivals during the reload
      // land in the emptied list and are merged by `_load`.
      _jumpedAway = false;
      widget.onSearchAnchor?.call(null);
      _generation++;
      _newerFailed = false;
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
    await _jumpToMessage(hit.id);
  }

  Future<void> _loadInitialHistory() async {
    final String? anchor = widget.initialMessageId;
    if (anchor != null) {
      // Park live arrivals until the transferred search window is ready.
      final int generation = _generation;
      _jumpedAway = true;
      if (await _jumpToMessage(anchor) ||
          !mounted ||
          generation != _generation) {
        return;
      }
      _jumpedAway = false;
      _messages.addAll(_parked);
      _parked.clear();
      _newMessages = 0;
    }
    await _load();
  }

  Future<bool> _jumpToMessage(String id) async {
    widget.onSearchAnchor?.call(id);
    // Nothing is invalidated until the window is installed: a jump that
    // finds nothing (or fails) leaves the loads in flight to finish.
    final int generation = _generation;
    final int request = ++_searchRequest;
    try {
      final rows = await _service.loadAround(_id, id);
      if (!mounted || generation != _generation || request != _searchRequest) {
        return false;
      }
      final at = rows.indexWhere((m) => m.id == id);
      if (at < 0) {
        // A blocked sender's row can become invisible without being deleted.
        widget.onSearchAnchor?.call(null);
        showSnack(context, context.s.chatMessageGone);
        return false;
      }
      // Outstanding page loads belong to the window being replaced.
      _generation++;
      _newerFailed = false;
      setState(() {
        _loadingOlder = false;
        _loadingNewer = false;
        _error = null;
        _olderError = null;
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
      return true;
    } on Object catch (e) {
      if (mounted && generation == _generation && request == _searchRequest) {
        widget.onSearchAnchor?.call(null);
        showSnack(context, describeChatError(context.s, e));
      }
      return false;
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

  late Set<String> _blockedSeen;

  /// A block (from this screen, a member list or anywhere else) hides at
  /// once: a blocked peer's direct conversation closes; in a group their
  /// rows go, queued or playing Morse of them included, and loads still in
  /// flight are dropped and redone (they may have read the rows before the
  /// block). An unblock reloads the history so their rows come back. The
  /// service filters everything that arrives later.
  void _onBlockedPeers(Set<String> blocked) {
    if (!mounted) return;
    final Set<String> seen = _blockedSeen;
    _blockedSeen = {...blocked};
    final ConversationTarget target = widget.target;
    if (!_isGroup) {
      if (!target.isSelf && blocked.contains(target.peerId.toUpperCase())) {
        _closeConversation();
      }
      return;
    }
    if (setEquals(seen, blocked)) return;
    if (seen.difference(blocked).isNotEmpty) {
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
    widget.onSearchAnchor?.call(null);
    _newerFailed = false;
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

  void _onHistoryCleared(String conversationId) {
    if (!mounted || _clearing || conversationId != _id) return;
    _reloadClearedHistory();
  }

  void _reloadClearedHistory() {
    _playback.cancelMessages({
      for (final m in [..._older, ..._messages, ..._parked]) m.id,
    });
    _generation++;
    _jumpedAway = false;
    widget.onSearchAnchor?.call(null);
    _newerFailed = false;
    setState(() {
      _parked.clear();
      _older.clear();
      _messages.clear();
      _pendingStatuses.clear();
      _revealed.clear();
      _newMessages = 0;
      _loadingOlder = _loadingNewer = false;
      _olderError = null;
    });
    unawaited(_load());
  }

  Future<void> _clearHistory() async {
    final S s = context.s;
    final bool ok = await confirm(
      context,
      title: s.chatClearHistory,
      body: s.chatClearHistoryBody,
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
      _loadingNewer = false;
    });
    final bookmarks = ConversationMenu.bookmarksForRemoval(context);
    try {
      await _service.clearHistory(_id);
      _localSends.recordClear(_id, ids);
      if (mounted) _reloadClearedHistory();
      await ConversationMenu.forgetBookmarks(bookmarks, _id);
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
      case 'shareLocation':
        final conversation = widget.target.id;
        final generation = _generation;
        await ConversationLocationActions.share(
          context,
          service: _service,
          target: widget.target,
          isCurrent: () =>
              mounted &&
              generation == _generation &&
              widget.target.id == conversation &&
              !_clearing,
        );
      case 'viewLocation':
        final conversation = widget.target.id;
        final generation = _generation;
        await ConversationLocationActions.view(
          context,
          service: _service,
          target: widget.target,
          isCurrent: () =>
              mounted &&
              generation == _generation &&
              widget.target.id == conversation &&
              !_clearing,
        );
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

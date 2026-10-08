part of 'notification_center.dart';

/// What follows the identity and the OS: the foreground-only permission
/// request and withdrawing notifications that belong to another identity.
extension _NotificationSession on NotificationCenter {
  /// The one automatic permission request: in the foreground only (a prompt
  /// cannot show from the background), once the plugin is ready. When the
  /// app was in the background then, the next resume asks instead. An OS
  /// that already decided answers without prompting.
  void _askPermissionIfForeground() {
    if (!_ready ||
        _disposed ||
        _permissionAsked ||
        !_platform.needsRuntimePermission ||
        !_isForeground.value) {
      return;
    }
    unawaited(ensurePermission());
  }

  /// A peer was blocked: their lines leave the banners still showing them.
  /// A banner with nothing else left is withdrawn; one that still holds
  /// other members' lines is re-posted with those, silently (blocking must
  /// not alert again). Later messages never arrive (the service filters
  /// them).
  ///
  /// Banners a previous run posted are not in [_inbox], so their lines are
  /// unknown: a peer newly blocked in this run takes down their direct
  /// conversation's banner and every group banner of this identity that is
  /// not tracked here (the first replay only records the list).
  void _onBlocked(Set<String> blocked) {
    if (_disposed) return;
    final Set<String>? seen = _blockedSeen;
    _blockedSeen = {...blocked};
    final Set<String> added = seen == null
        ? const <String>{}
        : blocked.difference(seen);
    for (final String key in added) {
      unawaited(_clearConversation('c2c_$key'));
    }
    if (added.isNotEmpty) {
      for (final Group g in _chat.groups) {
        final String id = 'group_${g.id}';
        if (_inbox.containsKey(id)) continue;
        unawaited(
          _cancel(OpenConversationTarget(id, account: _account).encode()),
        );
      }
    }
    if (blocked.isEmpty) return;
    bool hidden(ChatMessage m) =>
        !m.isMine && blocked.contains(m.senderId.toUpperCase());
    for (final String id in _inbox.keys.toList()) {
      final List<ChatMessage> lines = _inbox[id]!;
      if (!lines.any(hidden)) continue;
      lines.removeWhere(hidden);
      if (lines.isEmpty) {
        unawaited(_clearConversation(id));
      } else {
        _repostSilently(id, lines);
      }
    }
  }

  void _repostSilently(String id, List<ChatMessage> recent) {
    final ChatMessage latest = recent.last;
    final Conversation? conversation = _conversationFor(id);
    final bool isGroup =
        (conversation?.kind ?? NotificationComposer.kindFromId(id)) ==
        ConversationKind.group;
    final NotificationRequest composed = _composer.message(
      message: latest,
      title:
          conversation?.title ??
          (isGroup
              ? NotificationComposer.shortKey(
                  NotificationComposer.peerFromId(id),
                )
              : NotificationComposer.senderLabel(latest)),
      isGroup: isGroup,
      lines: [
        for (final ChatMessage m in recent)
          _composer.inboxLine(m, isGroup: isGroup),
      ],
    );
    final int generation = _ledger.posted(id, latest);
    unawaited(
      _post(
        NotificationRequest(
          id: composed.id,
          channel: composed.channel,
          title: composed.title,
          body: composed.body,
          payload: composed.payload,
          groupKey: composed.groupKey,
          lines: composed.lines,
          summary: composed.summary,
          sound: false,
          silentUpdate: true,
        ),
        stillWanted: () => _ledger.isCurrent(id, generation),
      ),
    );
  }

  /// Another identity (or none): everything posted belongs to the old one.
  /// The first identity to open after start is not a change (a cold-start
  /// tap waiting for it must survive).
  void _onIdentity(Identity? identity) {
    final String? account = NotificationCenter.accountOf(identity);
    final String? previous = _account;
    if (account == previous) return;
    _account = account;
    if (previous == null) {
      // The first identity of this run: banners an earlier run posted for a
      // different identity (it was deleted or replaced, e.g. a restore from
      // the unlock screen) are withdrawn; its own stay.
      if (account != null) unawaited(_withdrawForeign(account));
      return;
    }
    _pendingTap = null;
    _inbox.clear();
    _ledger.reset();
    _knownFriendRequests.clear();
    _knownInvites.clear();
    _activeConversation = null;
    _activeOwner = null;
    if (_ready && !_disposed) {
      unawaited(
        _notifications.cancelAll().catchError(
          (Object error, StackTrace stack) =>
              NotificationCenter._report('cancelAll', error, stack),
        ),
      );
    }
  }

  Future<void> _withdrawForeign(String account) async {
    if (!_ready || _disposed) return;
    try {
      final List<String> active = await _notifications.activePayloads();
      for (final String payload in active) {
        // The identity may have changed while the list was read: a cleanup
        // for an identity that is no longer current must not touch the
        // banners of the one that is.
        if (_disposed || _account != account) return;
        final String? owner = NotificationTapTarget.parse(payload)?.account;
        if (owner != null && owner != account) await _cancel(payload);
      }
    } catch (error, stack) {
      NotificationCenter._report(
        'withdraw foreign notifications',
        error,
        stack,
      );
    }
  }

  /// A grant made earlier (another run, the system Settings) without asking:
  /// no dialog.
  Future<bool> _checkPermission() async {
    try {
      final bool granted = await _notifications.isPermissionGranted();
      if (granted) _permissionGranted = true;
      return granted;
    } catch (error, stack) {
      NotificationCenter._report('isPermissionGranted', error, stack);
      return false;
    }
  }

  Future<bool> _requestPermission() async {
    try {
      final bool granted = await _notifications.requestPermission();
      if (granted) _permissionGranted = true;
      return granted;
    } catch (error, stack) {
      NotificationCenter._report('requestPermission', error, stack);
      return false;
    } finally {
      _permissionRequest = null;
    }
  }

  // ---- OS channel state ---------------------------------------------------

  Future<void> _refreshBlockedChannels() async {
    if (!_ready || _disposed) return;
    final Set<NotificationChannelKind> blocked = await _notifications
        .blockedChannels();
    if (_disposed || setEquals(blocked, _blocked.value)) return;
    _blocked.value = blocked;
  }

  // ---- Badge -------------------------------------------------------------------

  void _updateBadge(int total) {
    if (!_platform.supportsBadge || _disposed) return;
    _badgeWriter.write(total);
  }

  // ---- Lookups -----------------------------------------------------------------

  Conversation? _conversationFor(String id) {
    for (final Conversation c in _chat.conversations) {
      if (c.id == id) return c;
    }
    return null;
  }

  String? _friendName(String publicKey) {
    for (final Friend f in _chat.friends) {
      if (f.publicKey == publicKey && f.displayName.trim().isNotEmpty) {
        return f.displayName.trim();
      }
    }
    return null;
  }
}

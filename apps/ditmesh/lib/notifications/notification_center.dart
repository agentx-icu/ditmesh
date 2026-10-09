import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../l10n/generated/s.dart';
import 'badge_api.dart';
import 'badge_writer.dart';
import 'local_notifications_api.dart';
import 'message_banner_ledger.dart';
import 'notification_composer.dart';
import 'notification_payload.dart';
import 'notification_platform.dart';
import 'notification_prefs.dart';

part 'notification_center_session.dart';

/// Posts OS notifications for chat events and keeps the unread badge in step
/// with the conversation list.
///
/// Rules for an inbound message (`!isMine`, status `received`):
/// - never while the app is in the foreground **and** the conversation is the
///   one claimed by [claimActiveConversation] (the user is looking at it);
/// - never for a conversation muted in [NotificationPrefs], or when
///   notifications are disabled there;
/// - otherwise one notification per conversation, replaced in place, with
///   the last [NotificationComposer.maxInboxLines] messages as inbox lines
///   on Android and a `threadIdentifier` stack on iOS/macOS.
///
/// Friend requests and group invites notify on their own channels. A friend
/// request notifies only when it arrived after [start] (its `receivedAt`):
/// requests the backend restores from disk after connecting keep their old
/// arrival time and are not announced again on every launch. Invites present
/// when [start] runs are treated as already seen.
///
/// Every payload is tagged with the current identity
/// ([NotificationTapTarget.account]); when the identity changes, all posted
/// notifications are withdrawn and a tap on a leftover banner of another
/// identity is ignored.
///
/// Connection state deliberately never produces an OS notification — see
/// `ConnectionBannerPolicy` for the in-app banner.
///
/// Taps: the latest tap is kept as the pending tap until the shell's router
/// takes it ([takePendingTap]); [tapTargets] only signals that one arrived.
/// That covers the cold-start tap and taps while the unlock screen shows (no
/// router is mounted yet), and a newer tap always supersedes an older one.
///
/// Permission: requested only while the app is in the foreground (once the
/// plugin is initialised, and again on the next resume if it was not), or
/// explicitly via [ensurePermission]; posting never prompts.
///
/// Wiring: the orchestrator constructs this once per session and calls
/// [start]; the conversation screen claims / releases the active
/// conversation with an owner token. All plugin access goes through the
/// injected [LocalNotificationsApi] and [BadgeApi].
///
/// Text is resolved through [strings] at post time (default `currentS()`, or
/// the `StringsResolver` the orchestrator owns), so a language change shows
/// up in the next notification; banners already posted are not relabelled.
class NotificationCenter {
  NotificationCenter({
    required ChatService chat,
    required LocalNotificationsApi notifications,
    required BadgeApi badge,
    required NotificationPrefs prefs,
    required ValueListenable<bool> isForeground,
    IdentityService? identity,
    NotificationPlatform? platform,
    String Function(String text)? patternOf,
    S Function()? strings,
    DateTime Function()? clock,
  }) : _chat = chat,
       _identity = identity,
       _clock = clock ?? DateTime.now,
       _notifications = notifications,
       _badge = badge,
       _prefs = prefs,
       _isForeground = isForeground,
       _platform = platform ?? NotificationPlatform.detect(),
       _composer = NotificationComposer(
         prefs: prefs,
         platform: platform ?? NotificationPlatform.detect(),
         patternOf: patternOf,
         strings: strings,
         account: () => accountOf(identity?.current),
       );

  /// The account tag for [identity]: the first 16 hex of its public key.
  static String? accountOf(Identity? identity) {
    final String? key = identity?.publicKey;
    if (key == null || key.length < 16) return null;
    return key.substring(0, 16).toUpperCase();
  }

  final ChatService _chat;
  final IdentityService? _identity;
  final DateTime Function() _clock;
  final LocalNotificationsApi _notifications;
  final BadgeApi _badge;
  final NotificationPrefs _prefs;
  final ValueListenable<bool> _isForeground;
  final NotificationPlatform _platform;
  final NotificationComposer _composer;

  final ValueNotifier<Set<NotificationChannelKind>> _blocked =
      ValueNotifier<Set<NotificationChannelKind>>(
        const <NotificationChannelKind>{},
      );

  final StreamController<NotificationTapTarget> _taps =
      StreamController<NotificationTapTarget>.broadcast();

  StreamSubscription<ChatMessage>? _messageSub;
  StreamSubscription<List<FriendRequest>>? _friendRequestSub;
  StreamSubscription<List<GroupInvite>>? _inviteSub;
  StreamSubscription<List<Conversation>>? _conversationSub;
  StreamSubscription<Identity?>? _identitySub;
  StreamSubscription<Set<String>>? _blockedSub;
  Set<String>? _blockedSeen;

  /// Messages per conversation id behind the currently visible notification.
  /// Kept raw and formatted on every post, so a privacy change (hiding the
  /// content) also applies to the lines already shown.
  final Map<String, List<ChatMessage>> _inbox = <String, List<ChatMessage>>{};
  final MessageBannerLedger _ledger = MessageBannerLedger();
  final Set<String> _knownFriendRequests = <String>{};
  final Set<String> _knownInvites = <String>{};

  String? _activeConversation;
  Object? _activeOwner;
  NotificationTapTarget? _pendingTap;
  int _tapCount = 0;
  String? _account;
  DateTime? _startedAt;
  bool _started = false;
  bool _ready = false;
  bool _disposed = false;

  bool _permissionGranted = false;
  bool _permissionAsked = false;
  Future<bool>? _permissionRequest;

  late final BadgeWriter _badgeWriter = BadgeWriter(
    _badge,
    isDisposed: () => _disposed,
    onError: (error, stack) => _report('badge', error, stack),
  );

  /// Signals each accepted tap. The router reacts by calling
  /// [takePendingTap], which returns the newest one.
  Stream<NotificationTapTarget> get tapTargets => _taps.stream;

  /// The newest tap nobody has routed yet (including the one that
  /// cold-started the app); clears it. Null when there is none.
  NotificationTapTarget? takePendingTap() {
    final NotificationTapTarget? tap = _pendingTap;
    _pendingTap = null;
    // Checked here, not on arrival: a cold-start tap comes in before the
    // identity is open. A leftover banner of another identity is dropped.
    final String? account = tap?.account;
    final String? current = _currentAccount;
    if (account != null && current != null && account != current) return null;
    return tap;
  }

  String? get activeConversation => _activeConversation;

  /// Whether the OS backend initialised; false on unsupported platforms or
  /// after a plugin failure (the badge and the streams keep working).
  bool get isReady => _ready;

  /// Whether this platform asks the user before showing notifications.
  bool get needsPermission =>
      _platform.supportsOsNotifications && _platform.needsRuntimePermission;

  /// Channels the user has turned off in the OS settings (Android channel
  /// importance `none`): the permission reads as granted, but every post to
  /// such a channel is dropped by the OS. Read at [start] and again each
  /// time the app returns to the foreground, since the user changes it in
  /// Settings while the app is in the background.
  ValueListenable<Set<NotificationChannelKind>> get blockedChannels => _blocked;

  /// [owner] (a conversation screen) shows [conversationId] to the user
  /// right now. While the app is in the foreground its notification is
  /// dismissed immediately and no new one is posted.
  void claimActiveConversation(String conversationId, Object owner) {
    _activeConversation = conversationId;
    _activeOwner = owner;
    if (_isForeground.value) unawaited(_clearConversation(conversationId));
  }

  /// [owner] stopped showing its conversation. A no-op when another owner
  /// has claimed since (a newer screen of the same conversation must keep
  /// its claim when an older one goes away).
  void releaseActiveConversation(Object owner) {
    if (!identical(_activeOwner, owner)) return;
    _activeOwner = null;
    _activeConversation = null;
  }

  /// Language changed: let the OS-facing metadata follow (Android channel
  /// names). Forwarded whenever this platform has OS notifications, ready or
  /// not: the API remembers a change that arrives while it initialises.
  Future<void> refreshStrings() async {
    if (_disposed || !_platform.supportsOsNotifications) return;
    await _notifications.refreshStrings();
  }

  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    // Before any await: a request that arrives while the plugin initialises
    // is newer than the start and must still notify.
    _startedAt = _clock();
    _account = accountOf(_identity?.current);
    // Any tap from here on is newer than the launch payload (a tap during
    // the plugin's initialisation included).
    final int tapsBefore = _tapCount;
    _isForeground.addListener(_onForegroundChanged);
    if (_platform.supportsOsNotifications) {
      _ready = await _notifications.initialize(onTap: _onTap);
    }
    if (_disposed) return;
    unawaited(_refreshBlockedChannels());
    _knownInvites.addAll(_chat.groupInvites.map((GroupInvite i) => i.inviteId));
    _onFriendRequests(_chat.friendRequests);
    _messageSub = _chat.messageEvents.listen(_onMessage);
    _friendRequestSub = _chat.friendRequestChanges.listen(_onFriendRequests);
    _inviteSub = _chat.groupInviteChanges.listen(_onGroupInvites);
    _conversationSub = _chat.conversationChanges.listen(_onConversations);
    _identitySub = _identity?.identityChanges.listen(_onIdentity);
    _blockedSub = _chat.blockedPeerChanges.listen(_onBlocked);
    // The identity may already be open (or have opened while the plugin
    // initialised, with no replay to tell us): sync, and withdraw another
    // identity's leftovers for it.
    final String? now = accountOf(_identity?.current);
    if (now != null) {
      _account = now;
      unawaited(_withdrawForeign(now));
    }
    if (_ready) {
      // A tap that came in meanwhile is newer than the launch payload and
      // must not be overwritten by it.
      final String? launch = await _notifications.takeLaunchPayload();
      if (launch != null && !_disposed && _tapCount == tapsBefore) {
        _onTap(launch);
      }
      _askPermissionIfForeground();
    }
  }

  /// Requests the OS permission if this platform has one. Safe to call
  /// repeatedly and before [start]; a grant is remembered, a denial is not
  /// (the OS returns a remembered denial instantly without re-prompting).
  ///
  /// This may show a system dialog: call it from a user action (a settings
  /// tile) or in the foreground. Posting never prompts.
  Future<bool> ensurePermission() {
    if (!_platform.needsRuntimePermission) {
      return Future<bool>.value(_platform.supportsOsNotifications);
    }
    if (_permissionGranted) return Future<bool>.value(true);
    _permissionAsked = true;
    return _permissionRequest ??= _requestPermission();
  }

  /// Every release happens SYNCHRONOUSLY before the first `await`: the
  /// owning scope's `dispose()` cannot wait, and a cancelled broadcast
  /// subscription may hand back a root-zone completed future that FakeAsync
  /// never resumes, which would leave the later subscriptions and the
  /// controllers open. The futures are only awaited afterwards.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (_started) _isForeground.removeListener(_onForegroundChanged);
    _blocked.dispose();
    final pending = <Future<void>>[
      ?_messageSub?.cancel(),
      ?_friendRequestSub?.cancel(),
      ?_inviteSub?.cancel(),
      ?_conversationSub?.cancel(),
      ?_identitySub?.cancel(),
      ?_blockedSub?.cancel(),
      _taps.close(),
    ];
    _messageSub = null;
    _friendRequestSub = null;
    _inviteSub = null;
    _conversationSub = null;
    _identitySub = null;
    _blockedSub = null;
    await Future.wait(pending);
  }

  // ---- Inbound events --------------------------------------------------------

  void _onMessage(ChatMessage message) {
    if (message.isMine ||
        message.isUpdate ||
        message.status != MessageStatus.received) {
      return;
    }
    final String id = message.conversationId;
    if (_isForeground.value && _activeConversation == id) return;
    if (!_prefs.enabled || _prefs.isMuted(id)) return;

    final Conversation? conversation = _conversationFor(id);
    final bool isGroup =
        (conversation?.kind ?? NotificationComposer.kindFromId(id)) ==
        ConversationKind.group;
    final String title =
        conversation?.title ??
        (isGroup
            ? NotificationComposer.shortKey(NotificationComposer.peerFromId(id))
            : NotificationComposer.senderLabel(message));

    final List<ChatMessage> recent = _inbox.putIfAbsent(
      id,
      () => <ChatMessage>[],
    );
    recent.add(message);
    if (recent.length > NotificationComposer.maxInboxLines) {
      recent.removeRange(0, recent.length - NotificationComposer.maxInboxLines);
    }
    final List<String> lines = [
      for (final ChatMessage m in recent)
        _composer.inboxLine(m, isGroup: isGroup),
    ];
    final int generation = _ledger.posted(id, message);
    unawaited(
      _post(
        _composer.message(
          message: message,
          title: title,
          isGroup: isGroup,
          lines: lines,
        ),
        stillWanted: () => _ledger.isCurrent(id, generation),
      ),
    );
  }

  void _onFriendRequests(List<FriendRequest> requests) {
    final DateTime? since = _startedAt;
    final Set<String> current = <String>{};
    for (final FriendRequest request in requests) {
      current.add(request.publicKey);
      final bool fresh = since != null && !request.receivedAt.isBefore(since);
      if (_knownFriendRequests.add(request.publicKey) &&
          fresh &&
          _prefs.enabled) {
        final String key = request.publicKey;
        unawaited(
          _post(
            _composer.friendRequest(request),
            stillWanted: () => _knownFriendRequests.contains(key),
          ),
        );
      }
    }
    // Answered (or withdrawn) requests: forget them so a repeat notifies
    // again, and take their banner down.
    for (final String gone in _knownFriendRequests.difference(current)) {
      unawaited(_cancel(FriendRequestTarget(gone, account: _account).encode()));
    }
    _knownFriendRequests
      ..clear()
      ..addAll(current);
  }

  void _onGroupInvites(List<GroupInvite> invites) {
    final Set<String> current = <String>{};
    for (final GroupInvite invite in invites) {
      current.add(invite.inviteId);
      if (_knownInvites.add(invite.inviteId) && _prefs.enabled) {
        final String inviteId = invite.inviteId;
        unawaited(
          _post(
            _composer.groupInvite(
              invite,
              fromName: _friendName(invite.fromPublicKey),
            ),
            stillWanted: () => _knownInvites.contains(inviteId),
          ),
        );
      }
    }
    for (final String gone in _knownInvites.difference(current)) {
      unawaited(_cancel(GroupInviteTarget(gone, account: _account).encode()));
    }
    _knownInvites
      ..clear()
      ..addAll(current);
  }

  void _onConversations(List<Conversation> conversations) {
    var total = 0;
    final Set<String> live = <String>{};
    for (final Conversation conversation in conversations) {
      live.add(conversation.id);
      total += conversation.unreadCount;
      // Read in-app (markRead) or from another surface: drop the banner.
      if (_inbox.containsKey(conversation.id) &&
          _ledger.showsRead(conversation)) {
        unawaited(_clearConversation(conversation.id));
      }
    }
    // Deleted conversations: drop their banners (a materialised list:
    // _clearConversation mutates _inbox synchronously).
    for (final String id in _ledger.deleted(_inbox.keys, live)) {
      unawaited(_clearConversation(id));
    }
    _updateBadge(total);
  }

  void _onForegroundChanged() {
    if (!_isForeground.value) return;
    final String? id = _activeConversation;
    if (id != null) unawaited(_clearConversation(id));
    _askPermissionIfForeground();
    unawaited(_refreshBlockedChannels());
  }

  void _onTap(String payload) {
    final NotificationTapTarget? target = NotificationTapTarget.parse(payload);
    if (target == null || _disposed) return;
    _tapCount++;
    _pendingTap = target;
    _taps.add(target);
  }

  String? get _currentAccount => accountOf(_identity?.current) ?? _account;

  // ---- Posting -----------------------------------------------------------------

  /// Posts [request] when the permission allows it. Never prompts: the
  /// permission is asked in the foreground (see [_askPermissionIfForeground]);
  /// a grant from an earlier run or from Settings is picked up silently.
  /// [stillWanted] is re-checked after that await so a banner the user made
  /// moot meanwhile (opened, read, answered) is not shown stale.
  Future<void> _post(
    NotificationRequest request, {
    required bool Function() stillWanted,
  }) async {
    if (!_ready || _disposed) return;
    final String? account = _account;
    if (_platform.needsRuntimePermission &&
        !_permissionGranted &&
        !await _checkPermission()) {
      return;
    }
    // Let the event's other listeners (the open conversation claiming or
    // reading it) run first, also when no permission check was awaited: an
    // async broadcast stream queued their deliveries before this one ran.
    await Future<void>.microtask(() {});
    // A post for an identity that was switched away meanwhile is stale
    // whatever stillWanted says (the new one may reuse a key or invite id).
    if (_disposed || _account != account || !stillWanted()) return;
    try {
      await _notifications.show(request);
    } catch (error, stack) {
      _report('show(${request.payload})', error, stack);
    }
  }

  Future<void> _clearConversation(String conversationId) async {
    _inbox.remove(conversationId);
    _ledger.cleared(conversationId);
    await _cancel(
      OpenConversationTarget(conversationId, account: _account).encode(),
    );
  }

  Future<void> _cancel(String payload) async {
    if (!_ready || _disposed) return;
    try {
      await _notifications.cancel(stableNotificationId(payload));
    } catch (error, stack) {
      _report('cancel($payload)', error, stack);
    }
  }

  static void _report(String what, Object error, StackTrace stack) {
    debugPrint('[NotificationCenter] $what failed: $error\n$stack');
  }
}

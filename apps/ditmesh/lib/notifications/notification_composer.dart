import 'package:morse_core/morse_core.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../i18n/current_strings.dart';
import '../l10n/generated/s.dart';
import 'local_notifications_api.dart';
import 'notification_payload.dart';
import 'notification_platform.dart';
import 'notification_prefs.dart';

/// Turns chat events into [NotificationRequest]s. Pure: no I/O, no state
/// beyond the injected [NotificationPrefs] (read at call time) and platform.
///
/// User-facing text comes from [strings], resolved on every call (default
/// [currentS], which follows the app's `LocaleController`), so a language
/// switch applies to the very next notification. Notifications already on
/// screen keep the language they were posted in.
final class NotificationComposer {
  NotificationComposer({
    required NotificationPrefs prefs,
    required NotificationPlatform platform,
    String Function(String text)? patternOf,
    S Function()? strings,
    String? Function()? account,
  }) : _prefs = prefs,
       _platform = platform,
       _patternOf = patternOf ?? MorseEncoder.toPattern,
       _strings = strings ?? currentS,
       _account = account ?? _noAccount;

  static String? _noAccount() => null;

  /// Android inbox style shows at most this many lines; older ones roll off.
  static const int maxInboxLines = 5;

  final NotificationPrefs _prefs;
  final NotificationPlatform _platform;
  final String Function(String text) _patternOf;
  final S Function() _strings;

  /// The identity payloads are tagged with ([NotificationTapTarget.account]).
  final String? Function() _account;

  /// One inbox line: `text  pattern` (either part optional per prefs), with
  /// a `Sender: ` prefix inside groups where the title is the group name.
  String inboxLine(ChatMessage message, {required bool isGroup}) {
    final String line = _parts(message).join('  ');
    return isGroup ? '${senderLabel(message)}: $line' : line;
  }

  /// Notification body: text and pattern on separate lines.
  String body(ChatMessage message, {required bool isGroup}) {
    final String text = _parts(message).join('\n');
    return isGroup ? '${senderLabel(message)}: $text' : text;
  }

  NotificationRequest message({
    required ChatMessage message,
    required String title,
    required bool isGroup,
    required List<String> lines,
  }) {
    final String conversationId = message.conversationId;
    final String payload = OpenConversationTarget(
      conversationId,
      account: _account(),
    ).encode();
    final bool grouped = lines.length > 1;
    return NotificationRequest(
      id: stableNotificationId(payload),
      channel: NotificationChannelKind.messages,
      title: PeerText.singleLine(title),
      body: body(message, isGroup: isGroup),
      payload: payload,
      groupKey: _platform.supportsGrouping
          ? 'ditmesh.messages.$conversationId'
          : null,
      lines: grouped ? List<String>.unmodifiable(lines) : const <String>[],
      summary: grouped ? _strings().notificationNewMessages(lines.length) : null,
      sound: _prefs.sound,
    );
  }

  NotificationRequest friendRequest(FriendRequest request) {
    final S s = _strings();
    final String payload = FriendRequestTarget(
      request.publicKey,
      account: _account(),
    ).encode();
    final String who = shortKey(request.publicKey);
    // The wording is a stranger's text: shown only when the user lets
    // notifications carry message text at all.
    final String text = _prefs.showText
        ? PeerText.singleLine(request.message)
        : '';
    return NotificationRequest(
      id: stableNotificationId(payload),
      channel: NotificationChannelKind.friendRequests,
      title: s.notificationFriendRequestTitle,
      body: text.isEmpty
          ? s.notificationFriendRequestFrom(who)
          : s.notificationFriendRequestBody(who, text),
      payload: payload,
      groupKey: _platform.supportsGrouping ? 'ditmesh.friend_requests' : null,
      sound: _prefs.sound,
    );
  }

  NotificationRequest groupInvite(GroupInvite invite, {String? fromName}) {
    final S s = _strings();
    final String payload = GroupInviteTarget(
      invite.inviteId,
      account: _account(),
    ).encode();
    return NotificationRequest(
      id: stableNotificationId(payload),
      channel: NotificationChannelKind.groupInvites,
      title: s.notificationGroupInviteTitle(
        PeerText.singleLine(invite.groupName),
      ),
      body: s.notificationGroupInviteBody(
        PeerText.singleLine(fromName ?? shortKey(invite.fromPublicKey)),
      ),
      payload: payload,
      groupKey: _platform.supportsGrouping ? 'ditmesh.group_invites' : null,
      sound: _prefs.sound,
    );
  }

  List<String> _parts(ChatMessage message) {
    final List<String> parts = <String>[];
    final String text = PeerText.clean(message.text).trim();
    if (_prefs.showText && text.isNotEmpty) parts.add(text);
    if (_prefs.showPattern) {
      final String pattern = _patternOf(text);
      if (pattern.isNotEmpty) parts.add(pattern);
    }
    if (parts.isEmpty) parts.add(_strings().notificationNewMessage);
    return parts;
  }

  static String senderLabel(ChatMessage message) {
    final String? raw = message.senderName;
    final String name = raw == null ? '' : PeerText.singleLine(raw);
    return name.isEmpty ? shortKey(message.senderId) : name;
  }

  /// First 8 hex chars of a public key, the same abbreviation the fake
  /// backend and the contacts UI use for nameless peers.
  static String shortKey(String key) =>
      key.length > 8 ? key.substring(0, 8) : key;

  /// Conversation kind from its id alone (no conversation row yet).
  static ConversationKind kindFromId(String id) =>
      id.startsWith('group_') ? ConversationKind.group : ConversationKind.c2c;

  /// The peer / group part of a conversation id.
  static String peerFromId(String id) {
    final int separator = id.indexOf('_');
    return separator < 0 ? id : id.substring(separator + 1);
  }
}

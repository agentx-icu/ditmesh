import 'package:flutter/foundation.dart';

/// What a tapped notification asks the app to do. Encoded into the plugin's
/// string payload and parsed back on tap (also on cold start via
/// `LocalNotificationsApi.takeLaunchPayload`).
///
/// Wire format: `conv:<conversationId>`, `friend_req:<publicKey>`,
/// `group_invite:<inviteId>`, each optionally followed by `#<account>` —
/// the identity the notification was posted for (first 16 hex of its public
/// key), so a banner left over from a deleted or replaced identity is not
/// routed into the next one. Conversation ids are the contract's
/// `c2c_<pk>` / `group_<id>`, kept verbatim so the orchestrator can hand
/// them straight to the chat UI.
@immutable
sealed class NotificationTapTarget {
  const NotificationTapTarget({this.account});

  static const String _conversation = 'conv:';
  static const String _friendRequest = 'friend_req:';
  static const String _groupInvite = 'group_invite:';
  static const String _accountSeparator = '#';

  /// The identity this target belongs to, or null when the payload predates
  /// account tags (then it is accepted for any identity).
  final String? account;

  /// Null for an empty or unrecognised payload.
  static NotificationTapTarget? parse(String payload) {
    var body = payload.trim();
    String? account;
    final int hash = body.lastIndexOf(_accountSeparator);
    if (hash >= 0) {
      account = body.substring(hash + 1);
      body = body.substring(0, hash);
      if (account.isEmpty) account = null;
    }
    String? value(String prefix) {
      if (!body.startsWith(prefix)) return null;
      final String v = body.substring(prefix.length);
      return v.isEmpty ? null : v;
    }

    if (value(_conversation) case final String id) {
      return OpenConversationTarget(id, account: account);
    }
    if (value(_friendRequest) case final String pk) {
      return FriendRequestTarget(pk, account: account);
    }
    if (value(_groupInvite) case final String id) {
      return GroupInviteTarget(id, account: account);
    }
    return null;
  }

  String get _body;

  String encode() {
    final String? a = account;
    return a == null ? _body : '$_body$_accountSeparator$a';
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationTapTarget &&
      other.runtimeType == runtimeType &&
      other._body == _body &&
      other.account == account;

  @override
  int get hashCode => Object.hash(runtimeType, _body, account);

  @override
  String toString() => '$runtimeType(${encode()})';
}

final class OpenConversationTarget extends NotificationTapTarget {
  const OpenConversationTarget(this.conversationId, {super.account});

  final String conversationId;

  @override
  String get _body => '${NotificationTapTarget._conversation}$conversationId';
}

final class FriendRequestTarget extends NotificationTapTarget {
  const FriendRequestTarget(this.publicKey, {super.account});

  final String publicKey;

  @override
  String get _body => '${NotificationTapTarget._friendRequest}$publicKey';
}

final class GroupInviteTarget extends NotificationTapTarget {
  const GroupInviteTarget(this.inviteId, {super.account});

  final String inviteId;

  @override
  String get _body => '${NotificationTapTarget._groupInvite}$inviteId';
}

/// Deterministic, non-negative 31-bit notification id for [key] (normally an
/// encoded [NotificationTapTarget]).
///
/// FNV-1a rather than `String.hashCode`: Dart does not promise that
/// `hashCode` is stable across processes, and we want to be able to cancel a
/// banner that an earlier run of the app posted (opening a conversation
/// after a cold start must still dismiss its notification).
int stableNotificationId(String key) {
  var hash = 0x811C9DC5;
  for (final int unit in key.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}

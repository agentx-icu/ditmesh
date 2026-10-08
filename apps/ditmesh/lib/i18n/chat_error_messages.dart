import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../l10n/generated/s.dart';

/// Localized text for a [ChatException.code]; unknown codes fall back to
/// [S.errorUnknown]. Codes are the contract's stable strings, so this is the
/// one place where they meet the ARB keys.
String chatErrorMessage(S s, String code) => switch (code) {
  'wrong_password' => s.errorWrongPassword,
  'peer_offline' => s.errorPeerOffline,
  'invalid_tox_id' => s.errorInvalidToxId,
  'already_friend' => s.errorAlreadyFriend,
  'own_id' => s.errorOwnId,
  'group_not_found' => s.errorGroupNotFound,
  'message_too_long' => s.errorMessageTooLong,
  'peer_blocked' => s.errorPeerBlocked,
  _ => s.errorUnknown,
};

/// [chatErrorMessage] for any thrown object: a [ChatException] is mapped by
/// code, everything else reads as [S.errorUnknown].
String describeChatError(S s, Object error) => switch (error) {
  ChatException(:final code) => chatErrorMessage(s, code),
  _ => s.errorUnknown,
};

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../../i18n/l10n_extension.dart';

/// Tox ID = 32-byte public key + 4-byte nospam + 2-byte checksum, hex.
const int kToxIdLength = ToxAddress.length;

/// NGC chat id = 32-byte public key, hex.
const int kChatIdLength = 64;

final RegExp _hex = RegExp(r'^[0-9A-Fa-f]+$');

/// Strips whitespace and a `tox:` URI prefix; upper-cases the hex.
String normalizeToxId(String raw) {
  String s = raw.trim();
  if (s.toLowerCase().startsWith('tox:')) s = s.substring(4);
  return s.replaceAll(RegExp(r'\s+'), '').toUpperCase();
}

/// See [ToxAddress.isValid] (length, hex and checksum).
bool isValidToxId(String value) => ToxAddress.isValid(value);

bool isValidChatId(String value) =>
    value.length == kChatIdLength && _hex.hasMatch(value);

/// Why a typed Tox ID is not acceptable; widgets translate it with
/// [describeToxIdError] so this file holds no user-facing text.
enum ToxIdError {
  /// Not 76 hex characters after [normalizeToxId], or a bad checksum.
  invalid,

  /// The public-key half matches the local identity's own Tox ID.
  own,
}

/// Locale-independent check behind the add-friend form: null when valid.
/// [ownToxId] (when known) rejects adding yourself before a round-trip to
/// the backend.
ToxIdError? validateToxId(String? raw, {String? ownToxId}) {
  final String id = normalizeToxId(raw ?? '');
  if (!isValidToxId(id)) return ToxIdError.invalid;
  if (ownToxId != null &&
      id.substring(0, kChatIdLength) ==
          normalizeToxId(ownToxId).substring(0, kChatIdLength)) {
    return ToxIdError.own;
  }
  return null;
}

/// The localized field error for a [ToxIdError].
String describeToxIdError(S s, ToxIdError error) => switch (error) {
  ToxIdError.invalid => s.chatToxIdInvalid,
  ToxIdError.own => s.chatToxIdOwn,
};

/// Form-field validator for the add-friend sheet: null when valid, else the
/// localized message to show.
String? validateToxIdInput(S s, String? raw, {String? ownToxId}) {
  final ToxIdError? error = validateToxId(raw, ownToxId: ownToxId);
  return error == null ? null : describeToxIdError(s, error);
}

/// Whether [raw] is a 64-hex NGC chat id (whitespace / `tox:` tolerated).
bool isValidChatIdInput(String? raw) =>
    isValidChatId(normalizeToxId(raw ?? ''));

/// Form-field validator for the join-group sheet.
String? validateChatIdInput(S s, String? raw) =>
    isValidChatIdInput(raw) ? null : s.chatChatIdInvalid;

/// `ABCD1234…` for lists and avatars.
String shortKey(String key, {int length = 8}) =>
    key.length > length ? '${key.substring(0, length)}…' : key;

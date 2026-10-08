import 'dart:convert';

import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import '../adapters/key_value_store.dart';
import 'message_mapper.dart';

/// Native keeps unanswered friend applications only in process memory.
/// Retain their wording and arrival time until accepted or dismissed locally.
///
/// Also owns DitMesh's list of rejected senders. It is keyed by public key
/// alone (a rejected sender does not come back by rewording the request),
/// which is why it cannot live in Tim2Tox's `dismissed_friend_applications`:
/// Tim2Tox keys that list by `key|wording` and drops bare keys as legacy.
class FriendRequestStore {
  FriendRequestStore(this._store, {required String accountPrefix})
    : _key = 'ditmesh_pending_friend_requests_$accountPrefix',
      _dismissedKey = 'ditmesh_dismissed_friend_requests_$accountPrefix';

  /// Rejected senders remembered; the oldest roll off.
  static const int maxDismissed = 500;

  final KeyValueStore _store;
  final String _key;
  final String _dismissedKey;

  /// Rejected senders (at most [maxDismissed]). The first call for an
  /// identity migrates the senders of the `key|wording` fingerprints Tim2Tox
  /// recorded before this list existed; after that Tim2Tox's own (uncapped)
  /// list is not consulted, so the cap holds.
  Future<Set<String>> dismissedKeys(
    Iterable<String> tim2toxFingerprints,
  ) async {
    final own = _store.getStringList(_dismissedKey);
    if (own != null) return own.toSet();
    final migrated = <String>{
      for (final fingerprint in tim2toxFingerprints)
        if (fingerprint.contains('|'))
          ConversationIds.normalizeKey(fingerprint.split('|').first),
    }.toList();
    if (migrated.isEmpty) return const <String>{};
    if (migrated.length > maxDismissed) {
      migrated.removeRange(0, migrated.length - maxDismissed);
    }
    await _store.setStringList(_dismissedKey, migrated);
    return migrated.toSet();
  }

  /// Adds [publicKey] to the rejected senders (migrating
  /// [tim2toxFingerprints] first, see [dismissedKeys]).
  Future<void> dismiss(
    String publicKey, {
    required Iterable<String> tim2toxFingerprints,
  }) async {
    final current = await dismissedKeys(tim2toxFingerprints);
    final list = [
      ...current.where((k) => k != publicKey),
      publicKey,
    ];
    if (list.length > maxDismissed) {
      list.removeRange(0, list.length - maxDismissed);
    }
    await _store.setStringList(_dismissedKey, list);
  }

  List<FriendRequest> get pending {
    final result = <FriendRequest>[];
    for (final raw in _store.getStringList(_key) ?? const <String>[]) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) continue;
        final key = decoded['publicKey'];
        final message = decoded['message'];
        final timestamp = decoded['receivedAt'];
        if (key is! String ||
            message is! String ||
            timestamp is! int ||
            !ConversationIds.publicKey.hasMatch(key)) {
          continue;
        }
        result.add(
          FriendRequest(
            publicKey: key,
            // Cleaned on the way out too: entries stored by an older build
            // were saved before wording was sanitised.
            message: PeerText.clean(message),
            receivedAt: DateTime.fromMicrosecondsSinceEpoch(timestamp),
          ),
        );
      } on FormatException {
        continue;
      } on ArgumentError {
        // A damaged timestamp must not prevent other requests from loading.
        continue;
      }
    }
    return result;
  }

  Future<void> save(List<FriendRequest> pending) => _store.setStringList(_key, [
    for (final request in pending)
      jsonEncode({
        'publicKey': request.publicKey,
        'message': request.message,
        'receivedAt': request.receivedAt.microsecondsSinceEpoch,
      }),
  ]);
}

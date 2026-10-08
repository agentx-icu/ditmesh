import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/ditmesh_chat.dart';
import 'package:ditmesh_chat/src/chat/friend_request_store.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'helpers/fakes.dart';

void main() {
  test(
    'malformed request timestamps do not hide valid persisted requests',
    () async {
      final store = MemoryKeyValueStore();
      final requests = FriendRequestStore(store, accountPrefix: 'SELF');
      await requests.save([
        FriendRequest(
          publicKey: kPeerKey,
          message: 'CQ',
          receivedAt: DateTime.utc(2026),
        ),
      ]);
      const key = 'ditmesh_pending_friend_requests_SELF';
      await store.setStringList(key, [
        ...store.getStringList(key)!,
        jsonEncode({
          'publicKey': kSelfKey,
          'message': 'bad',
          'receivedAt': 9223372036854775807,
        }),
      ]);
      expect(requests.pending.single.message, 'CQ');
    },
  );

  test('rejected senders: migrated once from Tim2Tox, then capped', () async {
    final store = MemoryKeyValueStore();
    final requests = FriendRequestStore(store, accountPrefix: 'P');
    final legacy = ['${'A' * 64}|CQ'];
    expect(await requests.dismissedKeys(legacy), {'A' * 64});
    // After migration Tim2Tox's (uncapped) list is no longer consulted.
    expect(await requests.dismissedKeys(['${'B' * 64}|hi']), {'A' * 64});
    for (var i = 0; i < FriendRequestStore.maxDismissed + 5; i++) {
      await requests.dismiss(
        i.toRadixString(16).padLeft(64, '0'),
        tim2toxFingerprints: legacy,
      );
    }
    final kept = await requests.dismissedKeys(legacy);
    expect(kept, hasLength(FriendRequestStore.maxDismissed));
    expect(kept, isNot(contains('A' * 64)), reason: 'oldest rolls off');
  });

  test('persisted wording is cleaned when read back', () async {
    final store = MemoryKeyValueStore();
    final requests = FriendRequestStore(store, accountPrefix: 'P');
    await requests.save([
      FriendRequest(
        publicKey: 'C' * 64,
        message: 'hi\u202Eevil',
        receivedAt: DateTime.utc(2026),
      ),
    ]);
    expect(requests.pending.single.message, 'hievil');
  });
}

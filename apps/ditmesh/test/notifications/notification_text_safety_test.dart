import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/l10n/generated/s.dart';
import 'package:ditmesh/notifications/notifications.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

final S en = lookupS(const Locale('en'));

void main() {
  NotificationComposer composer(NotificationPrefs prefs) => NotificationComposer(
    prefs: prefs,
    platform: NotificationPlatform.android,
    strings: () => en,
  );

  test('peer names and text lose bidi overrides and control characters', () {
    final prefs = NotificationPrefs(showPattern: false);
    addTearDown(prefs.dispose);
    final ChatMessage m = ChatMessage(
      id: 'm1',
      conversationId: 'group_tox_1',
      senderId: 'B' * 64,
      // Renders as "Alice" in a right-to-left override.
      senderName: '\u202Eecila\u202C',
      text: 'CQ\u0007 DE\u2066 X',
      timestamp: DateTime(2026),
      status: MessageStatus.received,
      isMine: false,
    );
    final NotificationRequest n = composer(prefs).message(
      message: m,
      title: 'Net\u202E',
      isGroup: true,
      lines: const <String>[],
    );
    expect(n.title, 'Net');
    expect(n.body, 'ecila: CQ DE X');
  });

  test('a friend request shows no stranger text when content is hidden', () {
    final prefs = NotificationPrefs(showText: false);
    addTearDown(prefs.dispose);
    final NotificationRequest n = composer(prefs).friendRequest(
      FriendRequest(
        publicKey: 'B' * 64,
        message: 'visit evil.example',
        receivedAt: DateTime(2026),
      ),
    );
    expect(n.body, en.notificationFriendRequestFrom('B' * 8));
  });

  test('Linux bodies are escaped for markup-capable servers', () {
    expect(
      FlutterLocalNotificationsApi.escapeLinuxBodyMarkup(
        '<a href="x">win</a> & <b>bold</b>',
      ),
      '&lt;a href="x"&gt;win&lt;/a&gt; &amp; &lt;b&gt;bold&lt;/b&gt;',
    );
  });
}

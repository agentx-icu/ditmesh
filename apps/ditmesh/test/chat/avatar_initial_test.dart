import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/ui/account/avatar_initial.dart';
import 'package:ditmesh/ui/contacts/contacts_page.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

import 'test_support.dart';

void main() {
  group('avatarInitial', () {
    test('takes the first grapheme, upper-cased', () {
      expect(avatarInitial('ann'), 'A');
      expect(avatarInitial('Ölaf'), 'Ö');
      expect(avatarInitial('张三'), '张');
    });

    test('keeps a surrogate pair / emoji cluster whole', () {
      expect(avatarInitial('😀 Ham'), '😀');
      expect(avatarInitial('👍🏽ok'), '👍🏽');
      expect(avatarInitial('🇩🇪 DL1ABC'), '🇩🇪');
    });

    test('skips leading whitespace; blank names fall back to ?', () {
      expect(avatarInitial('  bob'), 'B');
      expect(avatarInitial(''), '?');
      expect(avatarInitial('   '), '?');
    });
  });

  // Peer nicknames are arbitrary UTF-8 from the Tox network. The contacts
  // tile used `substring(0, 1)`, which cuts an emoji's surrogate pair in half
  // and hands the engine malformed UTF-16.
  testWidgets('contacts: a friend whose name starts with an emoji', (
    tester,
  ) async {
    await pumpChat(tester, (h) {
      h.service.addFakeFriend(
        Friend(publicKey: kPeerKey, displayName: '😀 Ham', online: true),
      );
      return ContactsPage(
        service: h.service,
        identity: h.identity,
        onOpenConversation: (_) {},
        canScan: false,
      );
    });
    expect(tester.takeException(), isNull);
    expect(
      find.descendant(of: find.byType(CircleAvatar), matching: find.text('😀')),
      findsOneWidget,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh/notifications/message_banner_ledger.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

const String kConv = 'c2c_ann';
final DateTime kAt = DateTime.utc(2026, 10, 3, 12);

ChatMessage message(String id, DateTime at) => ChatMessage(
  id: id,
  conversationId: kConv,
  senderId: 'ann',
  text: 'CQ',
  timestamp: at,
  status: MessageStatus.received,
  isMine: false,
);

Conversation read({ChatMessage? last, int unread = 0}) => Conversation(
  id: kConv,
  kind: ConversationKind.c2c,
  title: 'Ann',
  lastMessage: last,
  unreadCount: unread,
);

void main() {
  group('showsRead', () {
    test('a read snapshot of an older message with the same timestamp does '
        'not clear the newer banner', () {
      final MessageBannerLedger ledger = MessageBannerLedger();
      final ChatMessage m1 = message('m1', kAt);
      final ChatMessage m2 = message('m2', kAt);
      ledger.posted(kConv, m1);
      ledger.posted(kConv, m2);
      expect(ledger.showsRead(read(last: m1)), isFalse);
    });

    test('the banner message itself, or a newer one, read clears it', () {
      final MessageBannerLedger ledger = MessageBannerLedger();
      final ChatMessage m1 = message('m1', kAt);
      ledger.posted(kConv, m1);
      expect(ledger.showsRead(read(last: m1)), isTrue);
      expect(
        ledger.showsRead(
          read(last: message('m2', kAt.add(const Duration(seconds: 1)))),
        ),
        isTrue,
      );
    });

    test('an older, absent or unread last message keeps the banner', () {
      final MessageBannerLedger ledger = MessageBannerLedger();
      final ChatMessage m1 = message('m1', kAt);
      ledger.posted(kConv, m1);
      expect(
        ledger.showsRead(
          read(last: message('m0', kAt.subtract(const Duration(seconds: 1)))),
        ),
        isFalse,
      );
      expect(ledger.showsRead(read()), isFalse);
      expect(ledger.showsRead(read(last: m1, unread: 1)), isFalse);
    });
  });

  group('generations', () {
    test('clearing reclaims the entry and a stale post stays stale', () {
      final MessageBannerLedger ledger = MessageBannerLedger();
      final int stale = ledger.posted(kConv, message('m1', kAt));
      ledger.cleared(kConv);
      expect(ledger.trackedCount, 0);
      expect(ledger.isCurrent(kConv, stale), isFalse);
    });

    test('a post after a reclaim never reuses a stale generation', () {
      final MessageBannerLedger ledger = MessageBannerLedger();
      final int stale = ledger.posted(kConv, message('m1', kAt));
      ledger.cleared(kConv);
      final int fresh = ledger.posted(kConv, message('m2', kAt));
      expect(fresh, isNot(stale));
      expect(ledger.isCurrent(kConv, stale), isFalse);
      expect(ledger.isCurrent(kConv, fresh), isTrue);
      expect(ledger.trackedCount, 1);
    });

    test('a newer post supersedes an older pending one', () {
      final MessageBannerLedger ledger = MessageBannerLedger();
      final int first = ledger.posted(kConv, message('m1', kAt));
      final int second = ledger.posted(kConv, message('m2', kAt));
      expect(ledger.isCurrent(kConv, first), isFalse);
      expect(ledger.isCurrent(kConv, second), isTrue);
    });
  });
}

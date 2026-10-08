import 'package:flutter_test/flutter_test.dart';
import 'package:ditmesh_chat/src/chat/history_page.dart';
import 'package:tim2tox_dart/models/chat_message.dart' as t2t;

final DateTime _t0 = DateTime.utc(2026, 10, 3);

t2t.ChatMessage _row(
  int minute, {
  String? id,
  String from = 'PEER',
  String text = 'CQ',
  String? filePath,
}) => t2t.ChatMessage(
  msgID: id,
  fromUserId: from,
  text: text,
  timestamp: _t0.add(Duration(minutes: minute)),
  isSelf: false,
  filePath: filePath,
);

void main() {
  test('paging before the in-memory window reads the archive', () async {
    // Memory holds minutes 1000..1999 (Tim2Tox's in-memory cap), the
    // archive the older 0..999.
    final memory = [for (var m = 1000; m < 2000; m++) _row(m, id: 'm$m')];
    final archive = [for (var m = 0; m < 1000; m++) _row(m, id: 'm$m')];
    var archiveReads = 0;
    final page = await readHistoryPage(
      memory,
      limit: 50,
      before: _t0.add(const Duration(minutes: 1000)),
      archive: () async {
        archiveReads++;
        return archive;
      },
    );
    expect(archiveReads, 1);
    expect(page, hasLength(50));
    expect(page.first.msgID, 'm950');
    expect(page.last.msgID, 'm999');
  });

  test('a full page from memory does not touch the archive', () async {
    final memory = [for (var m = 0; m < 100; m++) _row(m, id: 'm$m')];
    final page = await readHistoryPage(
      memory,
      limit: 50,
      archive: () async => fail('archive must not be read'),
    );
    expect(page.first.msgID, 'm50');
  });

  test('id-less rows are de-duplicated individually, not all at once', () async {
    final memory = [_row(5, text: 'in memory')];
    final archive = [
      _row(5, text: 'in memory'), // the same row, archived too
      _row(1, text: 'older A'),
      _row(2, text: 'older B'),
    ];
    final page = await readHistoryPage(
      memory,
      limit: 50,
      archive: () async => archive,
    );
    expect(page.map((r) => r.text), ['older A', 'older B', 'in memory']);
  });

  test('file rows are not chat text', () async {
    final page = await readHistoryPage(
      [_row(1, id: 'a'), _row(2, id: 'f', text: '', filePath: '/tmp/x.bin')],
      limit: 50,
      archive: () async => null,
    );
    expect(page.map((r) => r.msgID), ['a']);
  });

  test('hidden rows do not count as unread', () {
    final rows = [
      _row(1, id: 'old'),
      _row(2, id: 'text'),
      _row(3, id: 'file', text: '', filePath: '/tmp/x.bin'),
    ];
    // Tim2Tox says 2 unread: the text and the (hidden) file row.
    expect(visibleUnread(2, rows), 1);
    expect(visibleUnread(0, rows), 0);
    // More unread than history holds: the rest counts as is.
    expect(visibleUnread(5, rows), 2 + 2);
  });

  test('unread follows arrival order, not timestamps', () {
    final rows = [
      _row(5, id: 'read'),
      // Arrived last but sent earlier (clock skew / offline delivery).
      _row(1, id: 'late text'),
    ];
    expect(visibleUnread(1, rows), 1);
    final withFile = [
      _row(5, id: 'read'),
      _row(1, id: 'late file', text: '', filePath: '/tmp/x'),
    ];
    expect(visibleUnread(1, withFile), 0);
  });

  test('hidden rows never shorten a page (shows applies before the limit)', () async {
    // 60 rows, every other one from a blocked member.
    final memory = [
      for (var m = 0; m < 60; m++)
        _row(m, id: 'm$m', from: m.isOdd ? 'BLOCKED' : 'PEER'),
    ];
    final page = await readHistoryPage(
      memory,
      limit: 20,
      archive: () async => null,
      shows: (r) => r.fromUserId != 'BLOCKED',
    );
    expect(page, hasLength(20));
    expect(page.every((r) => r.fromUserId == 'PEER'), isTrue);
    expect(page.last.msgID, 'm58');
  });

  test('unread counts only shown rows; rows past memory need countArchived', () {
    final history = [
      _row(1, from: 'PEER'),
      _row(2, from: 'BLOCKED'),
      _row(3, from: 'PEER'),
    ];
    bool shows(t2t.ChatMessage r) => r.fromUserId != 'BLOCKED';
    expect(visibleUnread(3, history, shows: shows), 2);
    // Five unread but only three in memory: two archived rows of unknown
    // sender count only when nobody is blocked.
    expect(visibleUnread(5, history, shows: shows), 4);
    expect(visibleUnread(5, history, shows: shows, countArchived: false), 2);
  });
}

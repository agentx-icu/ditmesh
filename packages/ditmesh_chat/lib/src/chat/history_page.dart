import 'package:tim2tox_dart/models/chat_message.dart' as t2t;

import 'message_mapper.dart';

/// One page of a conversation's text history, oldest first: the newest
/// [limit] chat-text rows strictly before [before] (or overall).
///
/// Tim2Tox keeps only the newest rows of a conversation in [memory]; older
/// ones live in an archive that [archive] loads (null when there is none).
/// The archive is read whenever the page AFTER the cursor is short, so
/// paging past the in-memory window keeps working. Rows are de-duplicated
/// across the two by their native id, or — for rows without one — by time,
/// sender and text, so one id-less row never hides every other id-less row.
///
/// [shows] selects the rows that count (default: chat text); it is applied
/// before [limit], so hidden rows (a blocked peer's) never shorten a page.
Future<List<t2t.ChatMessage>> readHistoryPage(
  List<t2t.ChatMessage> memory, {
  required int limit,
  DateTime? before,
  required Future<List<t2t.ChatMessage>?> Function() archive,
  bool Function(t2t.ChatMessage) shows = MessageMapper.isChatText,
}) async {
  List<t2t.ChatMessage> window(Iterable<t2t.ChatMessage> rows) => [
    for (final r in rows)
      if (shows(r) &&
          (before == null || r.timestamp.isBefore(before)))
        r,
  ];
  final rows = List<t2t.ChatMessage>.of(memory);
  if (window(rows).length < limit + 1) {
    final archived = await archive();
    if (archived != null) {
      final seen = rows.map(historyRowKey).toSet();
      rows.addAll(archived.where((r) => seen.add(historyRowKey(r))));
    }
  }
  var page = window(rows);
  t2t.sortChatMessagesChronologically(page);
  if (page.length > limit) page = page.sublist(page.length - limit);
  return page;
}

/// Identity of a history row across memory and archive: the native id, or
/// the mapper's deterministic fallback id for rows without one.
String historyRowKey(t2t.ChatMessage r) =>
    r.msgID ?? MessageMapper.fallbackId(r);

/// Tim2Tox counts every inbound row as unread ([unread]), including ones
/// DitMesh does not show (custom packets, file rows): only the chat-text rows
/// among the last [unread] inbound rows of [history] count. [history] is in
/// arrival order (Tim2Tox appends), which is what the counter follows — a
/// late message with an older timestamp is still among the unread ones, so
/// the rows are NOT sorted by time here. Unread rows not in [history]
/// (archived) count as they are.
///
/// [shows] selects the rows that count (default: chat text). Unread rows
/// past [history] are counted only with [countArchived]; with blocked
/// peers they may be hidden ones, so the count stops at what is known.
int visibleUnread(
  int unread,
  List<t2t.ChatMessage> history, {
  bool Function(t2t.ChatMessage) shows = MessageMapper.isChatText,
  bool countArchived = true,
}) {
  if (unread <= 0) return 0;
  final rows = history;
  var seen = 0;
  var visible = 0;
  for (var i = rows.length - 1; i >= 0 && seen < unread; i--) {
    final m = rows[i];
    if (m.isSelf) continue;
    seen++;
    if (shows(m)) visible++;
  }
  return countArchived ? visible + (unread - seen) : visible;
}

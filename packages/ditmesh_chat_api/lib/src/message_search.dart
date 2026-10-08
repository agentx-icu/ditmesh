import 'package:meta/meta.dart';

import 'models.dart';

/// What to look for in a conversation's history
/// ([ChatService.searchMessages]).
@immutable
final class MessageSearchQuery {
  const MessageSearchQuery({this.text = '', this.senderId, this.from, this.to});

  /// Case-insensitive substring of the message body; empty matches every
  /// body (filter-only searches).
  final String text;

  /// Only messages from this sender public key (any case).
  final String? senderId;

  /// Inclusive lower bound on [ChatMessage.timestamp].
  final DateTime? from;

  /// Exclusive upper bound on [ChatMessage.timestamp].
  final DateTime? to;

  bool get isEmpty =>
      text.trim().isEmpty && senderId == null && from == null && to == null;

  bool matches(ChatMessage m) {
    final needle = text.trim().toLowerCase();
    if (needle.isNotEmpty && !m.text.toLowerCase().contains(needle)) {
      return false;
    }
    final sender = senderId;
    if (sender != null && m.senderId.toUpperCase() != sender.toUpperCase()) {
      return false;
    }
    if (from != null && m.timestamp.isBefore(from!)) return false;
    if (to != null && !m.timestamp.isBefore(to!)) return false;
    return true;
  }
}

/// Lets a caller abandon a running [ChatService.searchMessages]: the
/// implementation stops scanning at its next chunk boundary and the call
/// completes with [MessageSearchCancelled].
final class MessageSearchCancel {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

/// Thrown by [ChatService.searchMessages] when its [MessageSearchCancel]
/// fired before the scan finished.
final class MessageSearchCancelled implements Exception {
  const MessageSearchCancelled();

  @override
  String toString() => 'MessageSearchCancelled';
}

/// Position after the last result of a page: results are ordered newest
/// first by (timestamp, id), so the next page holds the rows strictly after
/// this key in that order. Equal timestamps are told apart by id, so no row
/// is lost or repeated between pages.
@immutable
final class MessageSearchCursor {
  const MessageSearchCursor({required this.timestamp, required this.id});

  factory MessageSearchCursor.after(ChatMessage m) =>
      MessageSearchCursor(timestamp: m.timestamp, id: m.id);

  final DateTime timestamp;
  final String id;

  /// Whether [m] comes after this cursor in newest-first order.
  bool precedes(ChatMessage m) => MessageOrder.newestFirst(this, m) < 0;

  @override
  bool operator ==(Object other) =>
      other is MessageSearchCursor &&
      other.timestamp == timestamp &&
      other.id == id;

  @override
  int get hashCode => Object.hash(timestamp, id);
}

/// One page of [ChatService.searchMessages] results, newest first.
@immutable
final class MessageSearchPage {
  const MessageSearchPage({required this.results, this.next});

  final List<ChatMessage> results;

  /// Cursor for the following page; null when this was the last one.
  final MessageSearchCursor? next;

  bool get hasMore => next != null;
}

/// The one ordering every implementation pages by: timestamp descending,
/// then id descending.
abstract final class MessageOrder {
  /// Negative when [a] sorts before [b] (is newer).
  static int newestFirst(Object a, Object b) {
    final (ta, ia) = _key(a);
    final (tb, ib) = _key(b);
    final byTime = tb.compareTo(ta);
    return byTime != 0 ? byTime : ib.compareTo(ia);
  }

  static (DateTime, String) _key(Object o) => switch (o) {
    final ChatMessage m => (m.timestamp, m.id),
    final MessageSearchCursor c => (c.timestamp, c.id),
    _ => throw ArgumentError.value(o, 'o', 'not a message or cursor'),
  };

  /// Filters [all] by [query], orders newest first and cuts the page after
  /// [cursor]. Shared by every [ChatService] implementation so they page
  /// identically.
  static MessageSearchPage page(
    Iterable<ChatMessage> all,
    MessageSearchQuery query, {
    MessageSearchCursor? cursor,
    int limit = 20,
  }) {
    if (limit <= 0) throw ArgumentError.value(limit, 'limit', 'must be > 0');
    final hits =
        all
            .where(query.matches)
            .where((m) => cursor == null || cursor.precedes(m))
            .toList()
          ..sort(newestFirst);
    final more = hits.length > limit;
    final results = more ? hits.sublist(0, limit) : hits;
    return MessageSearchPage(
      results: List<ChatMessage>.unmodifiable(results),
      next: more ? MessageSearchCursor.after(results.last) : null,
    );
  }

  /// [before] older and [after] newer rows around [messageId] in [all]
  /// (any order), oldest first; empty when the id is unknown.
  static List<ChatMessage> around(
    Iterable<ChatMessage> all,
    String messageId, {
    int before = 25,
    int after = 25,
  }) {
    final rows = all.toList()..sort((a, b) => newestFirst(b, a));
    final index = rows.indexWhere((m) => m.id == messageId);
    if (index < 0) return const <ChatMessage>[];
    final start = index - before < 0 ? 0 : index - before;
    final end = index + after + 1 > rows.length
        ? rows.length
        : index + after + 1;
    return List<ChatMessage>.unmodifiable(rows.sublist(start, end));
  }
}

/// Outcome of [ChatService.retryMessage] / [ChatService.cancelPendingMessage].
enum MessageActionResult {
  /// Retried (re-queued under the same local id) or cancelled.
  success,

  /// The message moved on before the request landed: a drain already handed
  /// it to transport (it may be delivered), or it is no longer failed.
  stateChanged,

  /// Not possible for this message: note-to-self, a received message, a
  /// status the action does not apply to, or a transport without the
  /// capability ([ChatService.supportsSendControl] false).
  unavailable,

  /// Persisting the change failed; the message keeps its previous status.
  failure,
}

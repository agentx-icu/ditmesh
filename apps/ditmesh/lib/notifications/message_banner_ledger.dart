import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

/// Per-conversation bookkeeping that tells [NotificationCenter] whether a
/// message banner is still current.
///
/// A post waits on the permission check before it reaches the OS. Meanwhile
/// the user may read the conversation (its banner is cleared) or a newer
/// message may post a fresher banner. Each event bumps the conversation's
/// generation; a post captured at an older generation is dropped, so it can
/// neither resurrect a read banner nor replace a newer one.
///
/// Generations come from one monotonic counter and a cleared conversation's
/// entry is removed, so the ledger only holds conversations with a live
/// banner; a missing entry never matches a captured generation.
final class MessageBannerLedger {
  final Map<String, int> _generation = <String, int>{};
  final Map<String, ChatMessage> _latest = <String, ChatMessage>{};
  Set<String> _live = <String>{};
  int _sequence = 0;

  /// Number of conversations currently tracked (for tests).
  int get trackedCount => _generation.length;

  /// A new message banner for [id] showing [message]; supersedes every
  /// earlier post. Returns the generation the post must still match.
  int posted(String id, ChatMessage message) {
    _latest[id] = message;
    return _generation[id] = ++_sequence;
  }

  /// The banner of [id] was cancelled (read, opened, deleted).
  void cleared(String id) {
    _latest.remove(id);
    _generation.remove(id);
  }

  /// Another identity: nothing tracked so far belongs to it.
  void reset() {
    _latest.clear();
    _generation.clear();
    _live = <String>{};
  }

  /// Whether a post captured at [generation] is still the newest for [id].
  bool isCurrent(String id, int generation) => _generation[id] == generation;

  /// Whether [conversation] reads as read *after* its latest banner: its
  /// last message is that banner's message, or strictly newer. A snapshot
  /// published late (unread still 0, last message older, absent, or another
  /// message with the same timestamp) proves nothing and keeps the banner.
  bool showsRead(Conversation conversation) {
    if (conversation.unreadCount != 0) return false;
    final ChatMessage? latest = _latest[conversation.id];
    if (latest == null) return true;
    final ChatMessage? last = conversation.lastMessage;
    if (last == null) return false;
    return last.id == latest.id || last.timestamp.isAfter(latest.timestamp);
  }

  /// Of [ids], those present in the previous snapshot and missing from
  /// [live] (deleted); then remembers [live]. A conversation not listed yet
  /// (its first message arrived before the list caught up) is not deleted.
  List<String> deleted(Iterable<String> ids, Set<String> live) {
    final Set<String> previous = _live;
    _live = live;
    return ids
        .where((String id) => previous.contains(id) && !live.contains(id))
        .toList();
  }
}

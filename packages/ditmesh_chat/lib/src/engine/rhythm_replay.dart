import 'package:tim2tox_dart/models/chat_message.dart';
import '../chat/recording_metadata.dart';
import 'rhythm_protocol.dart';

/// Selects the recorded direct messages a sender replays when the rhythm
/// handshake with their peer completes again.
///
/// A recorded send succeeds once its packets are accepted into toxcore's
/// lossless send buffer. A peer that drops silently stays online for up to
/// 32 s, and the connection teardown then discards whatever was still
/// buffered, so the message is lost although its row says sent. Only the
/// peer's `ack` control flips the row to received; until then the row itself
/// is the outbox. The receiver deduplicates by envelope id and acknowledges a
/// duplicate again, so a replay is safe even when the original did arrive.
///
/// Limits: only the in-memory window of the conversation is scanned (the
/// latest rows the history store keeps cached), which is also the only window
/// a delivery ACK can update. Rows older than [maxAge] are left alone, and at
/// most [maxRows] are replayed per handshake, oldest first, so successive
/// reconnects make progress through a longer backlog. A row whose alias never
/// reached disk (a crash right after the send, including between a queue
/// drain's durable item removal and its history save) is not replayed after
/// restart. A receiver that cleared its history after storing a message whose
/// ACK was lost may receive it again. The transport leaves out rows that
/// still have an offline-queue item: the drain owns those sends, and a
/// cancelled or failed tombstone must not be resent.
abstract final class RhythmReplay {
  static const maxAge = Duration(hours: 72);
  static const maxRows = 32;

  /// The wire id of a row sent as a recorded envelope, or null. A recorded
  /// send that fell back to plain text keeps its `dmr:` msgID but carries the
  /// native id as its alias, and is never replayed as an envelope.
  static String? wireId(ChatMessage row) {
    for (final alias in row.altMsgIds) {
      if (!alias.startsWith('dmr:')) continue;
      final id = alias.substring(4);
      if (RhythmProtocol.validId(id)) return id;
    }
    return null;
  }

  static bool eligible(ChatMessage row, DateTime now) =>
      row.isSelf &&
      row.groupId == null &&
      row.filePath == null &&
      !row.isReceived &&
      !row.isFailed &&
      !row.isCancelled &&
      row.text.isNotEmpty &&
      now.difference(row.timestamp) <= maxAge &&
      wireId(row) != null &&
      RecordingMetadata.decode(row.cloudCustomData) != null;

  /// Eligible rows of [history], oldest first, at most [maxRows].
  static List<ChatMessage> candidates(List<ChatMessage> history, DateTime now) {
    final rows = [
      for (var i = 0; i < history.length; i++)
        if (eligible(history[i], now)) (index: i, row: history[i]),
    ];
    // List.sort is not stable; the index keeps equal timestamps in order.
    rows.sort((a, b) {
      final byTime = a.row.timestamp.compareTo(b.row.timestamp);
      return byTime != 0 ? byTime : a.index.compareTo(b.index);
    });
    return [for (final entry in rows.take(maxRows)) entry.row];
  }
}

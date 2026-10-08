import 'package:meta/meta.dart';

/// What the durable outbox holds for one identity, read from the queue the
/// transport drains (not from the history rows a screen happened to load).
@immutable
final class PendingOutboxSummary {
  const PendingOutboxSummary({required this.count, this.oldest});

  static const PendingOutboxSummary empty = PendingOutboxSummary(count: 0);

  /// Queued messages, each counted once.
  final int count;

  /// Enqueue time of the oldest queued message; null when [count] is 0.
  final DateTime? oldest;

  @override
  bool operator ==(Object other) =>
      other is PendingOutboxSummary &&
      other.count == count &&
      other.oldest == oldest;

  @override
  int get hashCode => Object.hash(count, oldest);
}

/// Optional capability of a `ChatService` whose offline queue can be read
/// (F09 connection diagnostics). A service that does not implement it leaves
/// the pending count *unknown*; the UI must not guess one from history.
abstract interface class OutboxInspector {
  /// The durable outbox of the open identity, for [conversationId] or for
  /// every conversation when null. Null when it cannot be read right now
  /// (no chat session: the queue of a detached identity is not loaded).
  /// Read-only: never retries, drains or discards anything.
  PendingOutboxSummary? pendingOutbox({String? conversationId});
}

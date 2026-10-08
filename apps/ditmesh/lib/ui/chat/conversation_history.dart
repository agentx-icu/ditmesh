import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

class HistoryWindow {
  const HistoryWindow(this.messages, this.limit, this.boundary);
  final List<ChatMessage> messages;
  final int limit;
  final int boundary;
}

/// An asynchronous read may take its snapshot after more live messages arrive.
/// Expand again when they displace the stable origin from the requested window.
Future<HistoryWindow?> readHistoryWindow(
  ChatService service,
  String conversationId, {
  required String origin,
  required int limit,
  required int Function() loadedCount,
  required bool Function() isCurrent,
}) async {
  while (true) {
    final messages = await service.loadHistory(conversationId, limit: limit);
    if (!isCurrent()) return null;
    final boundary = messages.indexWhere((m) => m.id == origin);
    if (boundary >= 0) return HistoryWindow(messages, limit, boundary);
    final expanded = loadedCount() + 50;
    if (expanded <= limit) throw StateError('History origin unavailable');
    limit = expanded;
  }
}

/// Both lists follow backend order, including equal timestamps. A late query
/// can omit the beginning of [current]; retain it rather than shrink the view.
List<ChatMessage> mergeEarlierHistory(
  List<ChatMessage> current,
  List<ChatMessage> fetched,
) {
  final known = {for (final m in current) m.id};
  final firstShared = fetched.indexWhere((m) => known.contains(m.id));
  if (firstShared < 0) return [...fetched, ...current];
  return [
    ...fetched.take(firstShared),
    ...current,
    ...fetched.skip(firstShared).where((m) => !known.contains(m.id)),
  ];
}

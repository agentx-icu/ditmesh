import 'package:flutter/foundation.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';

/// Identifies successful local sends for every open conversation route.
/// ChatService's stream also carries historical outgoing status updates; the
/// send result gives the UI explicit creation information without timestamps.
class LocalMessageSends extends ChangeNotifier {
  LocalMessageSends._();
  static final _instances = Expando<LocalMessageSends>();

  static LocalMessageSends forService(ChatService service) =>
      _instances[service] ??= LocalMessageSends._();

  ChatMessage? latest;
  final Map<String, Set<String>> _cleared = {};

  void recordClear(String conversationId, Set<String> ids) {
    (_cleared[conversationId] ??= {}).addAll(ids);
  }

  void publish(ChatMessage message) {
    // A row may have been created before clear while sendText still awaited
    // persistence. Its late completion must not recreate that deleted row.
    if (_cleared[message.conversationId]?.contains(message.id) ?? false) return;
    latest = message;
    notifyListeners();
  }
}

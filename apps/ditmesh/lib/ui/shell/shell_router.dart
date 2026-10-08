import 'dart:async';

import '../chat/conversation_target.dart';

/// Carries "open this" requests from the shell (a tapped notification) to
/// the page that owns the destination: the chat and groups pages open
/// conversations their own way (inline pane on wide layouts, a route on
/// phones), the chat page opens contacts. Provided by `AppShell` to the
/// pages below it.
class ShellRouter {
  final StreamController<ConversationTarget> _conversations =
      StreamController<ConversationTarget>.broadcast();
  final StreamController<void> _contacts = StreamController<void>.broadcast();

  Stream<ConversationTarget> get conversationRequests =>
      _conversations.stream;

  Stream<void> get contactsRequests => _contacts.stream;

  void openConversation(ConversationTarget target) {
    if (!_conversations.isClosed) _conversations.add(target);
  }

  void openContacts() {
    if (!_contacts.isClosed) _contacts.add(null);
  }

  Future<void> dispose() async {
    await Future.wait([_conversations.close(), _contacts.close()]);
  }
}

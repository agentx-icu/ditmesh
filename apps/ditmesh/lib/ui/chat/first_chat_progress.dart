import 'package:flutter/widgets.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

/// Dismissal belongs to the open identity. AppPreferences restores and saves
/// it; isolated widget tests use one in-memory instance per chat service.
class FirstChatProgress extends ChangeNotifier {
  bool _dismissed = false;
  bool get dismissed => _dismissed;

  void dismiss() => restore(true);

  void restore(bool value) {
    if (_dismissed == value) return;
    _dismissed = value;
    notifyListeners();
  }

  static final Expando<FirstChatProgress> _fallback = Expando();

  static FirstChatProgress of(BuildContext context, ChatService service) {
    try {
      return context.read<FirstChatProgress>();
    } on ProviderNotFoundException {
      return _fallback[service] ??= FirstChatProgress();
    }
  }
}

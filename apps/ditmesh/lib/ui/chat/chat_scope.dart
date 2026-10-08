import 'package:flutter/widgets.dart';
import 'package:ditmesh_chat_api/ditmesh_chat_api.dart';
import 'package:provider/provider.dart';

/// The chat UI reads its services from Provider (wired in `main.dart` by the
/// startup gate). These helpers return null instead of throwing when the
/// providers are absent so the shell still renders a placeholder before the
/// gate is installed and in shell-level widget tests.
ChatService? maybeChatService(BuildContext context, {bool listen = false}) {
  try {
    return Provider.of<ChatService>(context, listen: listen);
  } on ProviderNotFoundException {
    return null;
  }
}

IdentityService? maybeIdentityService(BuildContext context) {
  try {
    return Provider.of<IdentityService>(context, listen: false);
  } on ProviderNotFoundException {
    return null;
  }
}

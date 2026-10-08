/// In-memory fakes for widget tests and UI development without a Tox node.
///
/// Implemented by the chat-ui agent (wave 2). Keep them here so the app,
/// the account UI and the chat UI share one fake backend.
library;

export 'src/testing/fake_chat_service.dart';
export 'src/testing/fake_identity_service.dart';
export 'src/testing/fake_network_bootstrap_service.dart';

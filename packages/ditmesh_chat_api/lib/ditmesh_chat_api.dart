/// Contract between the ditmesh UI and the chat backend.
///
/// The UI (apps/ditmesh) depends ONLY on this package. The Tim2Tox-backed
/// implementation lives in `packages/ditmesh_chat` and is the only package
/// allowed to import `tim2tox_dart` / the Tencent SDK (enforced by
/// tool/import_guard.dart). Tests use in-memory fakes from `testing.dart`.
///
/// Public API contract v0.1: extend freely, do not rename or remove without
/// updating every consumer.
library;

export 'src/backup_media.dart';
export 'src/encrypted_backup.dart';
export 'src/chat_service.dart';
export 'src/identity_service.dart';
export 'src/message_search.dart';
export 'src/models.dart';
export 'src/outbox.dart';
export 'src/peer_text.dart';
export 'src/tox_address.dart';
export 'src/network_bootstrap.dart';

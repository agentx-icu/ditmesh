[简体中文](./README.zh-CN.md)

# ditmesh_chat_api

Pure-Dart contract between the DitMesh UI and the chat backend. The UI depends
only on this package; `packages/ditmesh_chat` implements it on Tim2Tox and is
the only package allowed to import Tim2Tox or the Tencent SDK
(`tool/import_guard.dart`).

## Contents

| File | What |
|---|---|
| `lib/src/models.dart` | `Identity`, `IdentityState`, `Friend`, `FriendRequest`, `Conversation`, `ChatMessage`, `Group`, `GroupMember`, `GroupInvite`, `ConnectionStatus`, `MessageStatus`, `GroupKind`, `ChatException` |
| `lib/src/identity_service.dart` | `IdentityService`: inspect / create / unlock / open / password / profile / basic backup / connect / delete / `dataDirectory()`; `PersistentIdentityService.persist()` and `IdentityDataStore` flush barriers |
| `lib/src/encrypted_backup.dart` | `EncryptedBackupService`: complete encrypted backups by `BackupCategory`, with inventory, preview and `RestoreReport` |
| `lib/src/backup_media.dart` | The rule for which saved workbench recordings an opt-in backup carries |
| `lib/src/chat_service.dart` | `ChatService`: friends, requests, blocking, conversations, history, `sendText` (optional `KeyedRecording`), cancel/retry, `messageEvents`, groups, invites |
| `lib/src/keyed_recording.dart` | `KeyedRecording`: validated original mark/gap timing of a keyed message |
| `lib/src/message_search.dart` | Paged, cancellable history search |
| `lib/src/outbox.dart` | `OutboxInspector`: what the durable send queue holds |
| `lib/src/network_bootstrap.dart` | `NetworkBootstrapService`: automatic / manual / LAN node configuration and probes |
| `lib/src/peer_text.dart`, `lib/src/tox_address.dart` | Cleaning of peer-supplied text; Tox ID validation shared by forms, QR, backend and fakes |
| `lib/testing.dart` | `FakeIdentityService`, `FakeChatService`, `FakeNetworkBootstrapService` — in-memory fakes shared by widget tests and the `DITMESH_FAKE_BACKEND` demo mode |

## Design notes

- **Identity first.** Chat and the per-identity practice data both need an
  open identity. The startup gate calls `inspect()` before rendering anything,
  and other modules persist per-identity data under `dataDirectory()`.
- **Text stays interoperable.** Every message is UTF-8 text that any Tim2Tox
  client (toxee) can read. An optional `KeyedRecording` carries the sender's
  original timing to compatible DitMesh peers; the transport is described in
  the [keyed-rhythm contract](../../doc/rfcs/2026-10-09-keyed-rhythm.md).
  Without it, the receiver plays the text at the listener's own speed.
- **Offline is normal.** Tox has no server store. Sends to an offline peer
  return `MessageStatus.pending` and are flushed by the backend when the peer
  comes online; the UI must explain this instead of showing an error. A queued
  send can be cancelled (`cancelled`) and a failed one retried under the same
  message ID.
- **Status means what it says.** `sent` is local transport acceptance;
  `delivered` needs a peer receipt (for a group, at least one member). Neither
  implies reading or listening.
- **Streams replay.** Each listener of a `ChatService` `*Changes` stream
  first receives the current value, then every change; any number of
  listeners may subscribe, and the synchronous getter always matches. Do not
  rely on `isBroadcast`: the Tim2Tox backend's streams report false, the
  fakes' report true. `NetworkBootstrapService.changes` and `FakeIdentityService`'s
  identity and connection streams are plain broadcast streams without replay,
  so read the getter before listening.

## Versioning

Contract v0.1 (`pubspec.yaml` 0.1.0). Extend additively; renaming or removing
a member requires updating `packages/ditmesh_chat`, the fakes and every UI
consumer in the same change.

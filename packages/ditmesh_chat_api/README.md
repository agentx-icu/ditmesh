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
| `lib/src/identity_service.dart` | `IdentityService`: inspect / create / unlock / open / password / profile / backup / connect / delete / `dataDirectory()` |
| `lib/src/chat_service.dart` | `ChatService`: friends, requests, conversations, history, `sendText`, `messageEvents`, groups, invites |
| `lib/testing.dart` | `FakeIdentityService`, `FakeChatService` — in-memory fakes shared by widget tests and the `DITMESH_FAKE_BACKEND` dev mode |

## Design notes

- **Identity first.** Training also requires an identity (product decision
  2026-09-30). The startup gate calls `inspect()` before rendering anything and
  other modules persist per-identity data under `dataDirectory()`.
- **Plain text on the wire.** `sendText` carries UTF-8 text only; any Tim2Tox
  client (toxee) reads it. Morse rendering happens on the receiving side at the
  listener's own speed. Keyed-timing transport is a v2 feature that needs an
  upstream Tim2Tox change (plan §5.2).
- **Offline is normal.** Tox has no server store. Sends to an offline peer
  return `MessageStatus.pending` and are flushed by the backend when the peer
  comes online; the UI must explain this instead of showing an error.
- **Streams replay.** Every `*Changes` stream is broadcast and replays the
  current value to new listeners; the synchronous getter always matches.

## Versioning

Contract v0.1. Extend additively; renaming or removing a member requires
updating `packages/ditmesh_chat` and every UI consumer in the same change.

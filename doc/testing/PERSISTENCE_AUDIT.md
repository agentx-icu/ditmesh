[简体中文](./PERSISTENCE_AUDIT.zh-CN.md)

# DitMesh persistence audit — 2026-10-09

This inventory documents chat storage, save barriers and backup restoration. Executed checks are recorded in [VALIDATION.md](../VALIDATION.md).

## Storage inventory

`<support>` is the platform application-support directory. `<identity>` is `<support>/ditmesh/identity`. Installed bundles and the current working directory do not hold user data.

| Durable content | Production storage | Restart and ownership |
|---|---|---|
| Tox profile, friends and native group memberships | `<identity>/profile/tox_profile.tox` | Native savedata restores the current identity. With a password, each native save is encrypted; group persistence is enabled by the pinned-source overlay. |
| Display name, status, Tox ID and password flag | `<identity>/identity.json` and native self profile | Atomic record replacement; serialized identity mutations; malformed records do not crash inspection. |
| Password verifier | Identity-keyed `flutter_secure_storage` | Platform Keychain/Keystore/desktop secure store; failed profile/password operations roll back. Passwords are absent from ordinary preferences. |
| Messages, read state and unread counts | `<identity>/data/chat_history/` | Debounced saves have an explicit flush barrier. Unread state is reconstructed from durable history. |
| Optional original keyed timing | Message metadata in history and the authoritative outbox | Validated mark/gap spans survive history reload, queued-send restart and selected encrypted history/pending backup components. Late metadata enriches the existing message. |
| Offline direct/group outbox | `<identity>/data/offline_message_queue.json` | Restart preserves queued sends and their pending status. Delivery/retry keeps the message identifier rather than creating duplicate bubbles. |
| Friend requests, rejection records and Tim2Tox host metadata | Account-scoped `shared_preferences` | Requests and group metadata survive reconnect. Identity removal clears its scoped keys. |
| Drafts, pinned/hidden conversations and queued invitations | Account-scoped `shared_preferences` | Offline edits persist; replaced editors cannot write into a new identity. |
| Copy-practice state and bookmarks (material files saved by earlier versions stay in place) | `<identity>/training/` | File stores serialize immutable snapshots. |
| Optional recorded practice audio | `<identity>/media/recordings/` | Export includes referenced recordings only when selected. No file-transfer UI is exposed. |
| Appearance | `appearance.preferences` in `<support>/settings.json` | Style and brightness are saved together before publication. Failure retains the previous visible choice. New/corrupt records use Modern Calm/system mode. |
| Language, playback/input/decoder settings and notification choices | `<support>/settings.json` | Restored before providers become available; failed writes remain available for retry. |
| Muted conversations | `notifications.muted.<full-public-key>` in `settings.json` | Identity-scoped; only committed identity deletion/replacement clears the old list. |
| First-chat guide dismissal | `chat.guide.<full-public-key>` in `settings.json` | Identity-scoped, reopenable from Chat; failed writes remain retryable and late hydration cannot overwrite a newer local choice. |
| Conversation listening preferences | `chat.conversations.<full-public-key>` in `settings.json` | Each conversation retains speed/spacing/tone, original-source preference and repeat range/loop. Identity replacement detaches old models; global defaults seed a new conversation. |
| Window bounds/maximized, close-to-tray and tray sounds | Desktop keys in `settings.json` | Bounds are checked against current displays; failed saves revert the visible model. |
| Public bootstrap configuration | Global `shared_preferences` | Independent of identity deletion and replacement; startup uses current saved configuration. LAN/probe instances have separate private profiles. |

Playback, microphone streams, held keys, connection status, selected tab and translator scratch text are session state.

## Durability and backups

Background, backup/export, identity replacement and desktop quit use store flush barriers. Independent stores all receive a flush attempt when another fails. An unresolved save failure prevents desktop exit and permits retry. Controllers belonging to the replaced identity stop writing before its files are swapped.

A failed restore retains the previous identity and notification settings. Staging directories sit beside the identity root; restore validates paths and stages the full replacement before committing. The identity parent is excluded from iOS platform backups so staging and renamed roots retain the exclusion.

DitMesh's encrypted backup supports selected identity, chat history, conversation metadata, pending messages, practice and referenced audio components, with a restore preview. Global application settings are outside that archive. A basic identity backup or interoperable `.tox` import is a smaller operation and does not imply a complete chat restore. Backup passphrases and profile passwords serve separate purposes.

## Verification and limits

Use [the test pyramid](TEST_PYRAMID.md) and [validation record](../VALIDATION.md) for current commands and results. Native tests reload stores/preferences rather than relying only on a process cache. Two real Tox processes cover encrypted restart, durable queued delivery and automatic group rejoin; desktop E2E exercises actual platform storage plugins.

JSON backup recovery handles malformed/incomplete files. A multi-file identity/secure-store update is not a filesystem-wide transaction; power loss and force-kill at every write boundary are outside the executed coverage. Linux requires an accessible Secret Service/keyring; Windows requires the secure-store plugin's C++ ATL build components.

If the operating system cannot provide an application-support directory, the app's logged in-memory preference fallback cannot persist across restart. Production native-backend failure is surfaced to the user instead of silently starting a demo session.

[简体中文](./README.zh-CN.md)

# ditmesh_chat

Tim2Tox-backed implementation of [`ditmesh_chat_api`](../ditmesh_chat_api):
identity, friends, conversations, plain-text messages and groups over the Tox
P2P network. **This is the only package in the workspace allowed to import
`tim2tox_dart` or the Tencent Cloud Chat SDK** (`tool/import_guard.dart`
enforces it). The app talks to the contract; it touches this package only to
build the backend:

```dart
final backend = await DitmeshChatBackend.create(logger: CallbackChatLogger(myLog));
switch (await backend.identity.inspect()) {
  case IdentityState.none:   await backend.identity.create(displayName: 'W1AW', password: pw);
  case IdentityState.locked: await backend.identity.unlock(pw);
  case IdentityState.ready:  await backend.identity.open();
}
await backend.identity.connect();          // init → login → startPolling
backend.chat.conversationChanges.listen(...);
```

## Architecture (plan §3.2 "B variant")

```
apps/ditmesh ──► ditmesh_chat_api (contract) ◄── ditmesh_chat
                                                  │  DitmeshChatBackend
                                                  ├─ Tim2ToxIdentityService   identity.json, tox_profile.tox, password verifier, backup
                                                  ├─ Tim2ToxChatService        friends / conversations / messages / groups (+ parts)
                                                  ├─ Tim2ToxEngine            one FfiChatService per connected session
                                                  ├─ adapters/                Tim2Tox host interfaces (prefs, bootstrap, scratch, logger)
                                                  └─ native/                  setNativeLibraryName('tim2tox_ffi')
                                                          │
                                third_party/tim2tox/dart  │  FfiChatService (Dart)  ──ffi──►  libtim2tox_ffi (c-toxcore, --no-toxav)
```

**One data path.** Unlike toxee's hybrid runtime, DitMesh installs neither
`Tim2ToxSdkPlatform` nor the UIKit and never calls `TIMManager.initSDK`.
Everything flows `FfiChatService` → `Tim2ToxFfi` → `libtim2tox_ffi`, and the
service listens to `FfiChatService.messages` / polls `getFriendList`,
`getFriendApplications`, `knownGroups`, `getPendingGroupInvites` every
`pollInterval` (3 s). The patched SDK's process-global custom-callback hook
(`NativeLibraryManager.customCallbackHandler`, which toxee's
`Tim2ToxSdkPlatform` owns) is owned here by `engine/native_callbacks.dart`
(`NativeCustomCallbacks`): it routes `friendAddResult` to the pending
`addFriend` completer and the `DartNotifyGroup*` notifications
(`groupQuitNotification`, `groupJoinNotification`, `groupJoinFailedNotification`,
`groupInviteNotification`) to the live session, session-scoped exactly like
toxee; `groupChatIdStored` / `groupTypeStored` trigger the pull-side
`syncGroupIdentitiesFromNative()` instead of a preferences write, and
`clearHistoryMessage` is ignored. Without this hook the SDK drops every custom
callback and `addFriend` only returns after its 30 s timeout (found by the
native smoke test on macOS, 2026-09-30).

### Identity lifecycle

| State | Meaning | Transition |
|---|---|---|
| `none` | no `tox_profile.tox` | `create()` (bootstrap instance mints the Tox ID, then is disposed) |
| `locked` | verifier holds a password **or** the file is Tox-encrypted | `unlock(pw)` |
| `ready` | plain profile, or unlocked this run | `connect()` / `disconnect()` |

Encryption at rest: with a password, `tox_profile.tox` is encrypted on disk
**at all times**. `connect()` stages the password with Tim2Tox
(`setProfilePassphrase`) before `init`; native code opens the encrypted
profile and encrypts every save, so a running, backgrounded or killed app
never leaves a plaintext profile behind (a plaintext file from an older build
is migrated by the first save). A password change while connected re-keys
the live session (`rekeyLiveProfilePassphrase`) and rolls back on any later
failure. `disconnect()` still encrypts a plaintext file it finds, and keeps
retrying on later disconnects. The PBKDF2-HMAC-SHA256 verifier
(`flutter_secure_storage`: Keychain / Keystore / libsecret / DPAPI) is the
authority on "has a password" for plaintext legacy files; for an encrypted
profile, successful `tox_pass_decrypt` proves the password and repairs a
stale verifier after an interrupted password change or restore. Message
history, drafts and pending requests are **not** covered by the password
(Tim2Tox stores history as plain JSON); identity files are owner-only
(0700 / 0600) and excluded from OS backups.

`PersistentIdentityService.persist()` awaits savedata, debounced history,
outbox mutations and registered `IdentityDataStore` writes before suspension
or export. Replacement prepares those stores before removing their files;
the identity stream publishes `null` only after replacement succeeds, then
publishes the restored identity even when its public key is unchanged.

On disk (`IdentityPaths`, under the platform application-support directory):

```
ditmesh/identity/
  identity.json              display name, status, Tox ID, hasPassword
  profile/tox_profile.tox    Tox savedata
  data/chat_history/  data/offline_message_queue.json  data/file_recv/  data/avatars/  data/scratch/
  training/                  IdentityService.dataDirectory() — other modules' per-identity state
```

### Backup format (`exportBackup` / `importBackup`)

`BackupContainer`: a dependency-free, length-prefixed archive.

```
"MCQB" | version u8 = 1 | flags u8 (bit0: profile encrypted) | count u32
entry*: pathLen u16 | path (UTF-8, '/'-separated) | size u64 | bytes
```

Entries: `identity.json`, `tox_profile.tox` (encrypted with the identity
password when one is set), `training/<relative path>` for every file under
`dataDirectory()`. Paths are validated on decode (no `..`, no absolute paths,
no backslashes or Windows drive prefixes). Export flushes registered data
stores first. Import stages every archive entry before replacing the current
tree and rolls back a failed directory swap. The archive contains identity,
Tox savedata and training files; chat history, queue and preferences remain
outside this format. `importBackup` replaces the current identity; an encrypted
profile requires the password (`wrong_password` otherwise) and carries it
over into the verifier so the restored identity unlocks with the same one.

### Messages

- `sendText` → `sendTextWithResult` (C2C) / `sendGroupTextWithResult` (group).
  Texts over `maxMessageBytes` (**1322**, `TOX_MAX_MESSAGE_LENGTH − 50`) throw
  `message_too_long`: Tim2Tox would fragment them into separate messages.
- Tim2Tox queues sends to an offline friend / not-yet-connected group and
  returns a `pending` row; the row is re-emitted on `messageEvents` as `sent`
  when the drain succeeds. The durable queue preserves `pending` across
  restart even though upstream history reload clears its transient flag.
  Tim2Tox does not carry a distinct failure flag on
  this path (`_markPendingItemFailed` also flips `isPending: false`), so
  `failed` is not produced today — tracked for the upstream `tim2tox_core` split.
- `cloudCustomData` is **local only** in Tim2Tox (never sent over Tox); DitMesh
  does not use it (plan §5.2 layer 1 is plain text).
- Conversations are derived: history ids ∪ friends ∪ groups, minus hidden
  (deleted) ones; unread from Tim2Tox's read barrier; pinned/draft/hidden from
  `ConversationMetaStore` (account-scoped keys in `shared_preferences`).
- Pending friend requests retain wording and arrival time in an account-scoped
  cache until acceptance or rejection. Dismissed requests are scoped too;
  the existing single-identity unscoped dismissal list is adopted once.

### What still goes through the Tencent bindings, and why

`FfiChatService` compiles against the (patched) Tencent SDK, and a few
operations reach Tox only through its `Dart*` compat exports, which
`libtim2tox_ffi` implements. `NativeLibrarySetup.ensure()` — called by
`DitmeshChatBackend.create()` before the first `FfiChatService` — runs
`setNativeLibraryName('tim2tox_ffi')` exactly as toxee's `LoggingBootstrap`
does, so those bindings load our library instead of `dart_native_imsdk`.

| Operation | Path | Note |
|---|---|---|
| `leaveGroup` | `FfiChatService.quitGroup` → `NativeLibraryManager.bindings.DartQuitGroup` | as in toxee |
| `groupMembers` | `GroupBindings.members` → `DartGetGroupMemberList` | same call tim2tox's platform makes; deduped by public key |
| `inviteToGroup` (friend online) | `GroupBindings.invite` → `DartInviteUserToGroup` | bypasses `TIMGroupManager`, whose wrapper refuses without `TIMManager.initSDK` |
| `inviteToGroup` (friend offline) | queued in `ConversationMetaStore`, sent when the friend comes online | Tim2Tox's own replay uses `TIMGroupManager` and therefore needs `initSDK`; ours does not |

`TIMManager.initSDK` is deliberately never called: it installs the SDK's own
native message listeners — the second inbound path toxee needs
`BinaryReplacementHistoryHook` to reconcile.

### `tencent_cloud_chat_common` stub

`tim2tox_dart`'s pubspec requires `tencent_cloud_chat_common` (a UIKit widget
package with a large plugin tree: TUICore, hive, audioplayers, …). Only
`Tim2ToxSdkPlatform` imports it, and nothing DitMesh compiles reaches that
file. `third_party/stubs/tencent_cloud_chat_common` is an empty package that
satisfies pub; the root `pubspec_overrides.yaml` points at it. If a future
tim2tox change makes `FfiChatService` reach `Tim2ToxSdkPlatform`, compilation
fails loudly (missing imports) rather than silently pulling the UIKit in.
Remove the stub when upstream ships a UIKit-free `tim2tox_core` (plan §3.2 D).

## Bootstrap

```bash
export PATH=/home/user/flutter/bin:$PATH
dart run tool/bootstrap_deps.dart     # submodule → vendor SDK → patches → root pubspec_overrides.yaml
dart pub get                          # workspace root
flutter analyze packages/ditmesh_chat
flutter test packages/ditmesh_chat    # needs-native test skips itself without the library
dart run tool/bootstrap_deps.dart --offline-check-only   # CI: prove the tree matches the lock
```

`tool/bootstrap_deps.dart` (ported from toxee, UIKit branches removed):

1. `git submodule sync` / `update --init -- third_party/tim2tox` (pinned to
   the same commit toxee uses, `9d4245a`; nested c-toxcore submodules are not
   initialised — only the native build needs them).
2. Downloads `tencent_cloud_chat_sdk` per
   `third_party/tim2tox/tool/tencent_cloud_chat_sdk.lock.json` (8.9.7540+3,
   SHA-256 verified) into `third_party/tencent_cloud_chat_sdk/`.
3. Applies tim2tox's 22-patch series with tim2tox's own `apply_sdk_patches.dart`
   (patch 0001 adds `setNativeLibraryName`).
3b. Applies DitMesh's own overlay `third_party/overlays/tencent_cloud_chat_sdk/`
   (`tool/vendor_overlay.dart`): the plugin's *platform* halves are replaced
   by no-op plugin classes and every Tencent binary is removed — the
   `TXIMSDK_Plus_iOS_XCFramework` / `TXIMSDK_Plus_Mac` / `HydraAsync` pods, the
   `com.tencent.imsdk:imsdk-plus` AAR and `libdart_native_imsdk.so`, and
   `ImSDK.dll` / `dart_native_imsdk.dll`. DitMesh only uses the plugin's Dart
   bindings (pointed at `libtim2tox_ffi`), so nothing the app calls is lost;
   the generated plugin registrants still find their classes. The overlay's
   hash is recorded as `overlay_sha256` in the vendor state (checked by
   `--offline-check-only`); toxee keeps the full plugin because its hybrid
   runtime needs it.
4. Writes the **root** `pubspec_overrides.yaml` (`tim2tox_dart`,
   `tencent_cloud_chat_sdk`, `tencent_cloud_chat_common` → paths) — a pub
   workspace reads overrides at the root only. State for `--offline-check-only`
   lives in `third_party/.vendor_state.json`.

Generated, never committed: `third_party/tencent_cloud_chat_sdk/`,
`third_party/.vendor_state.json` (both in `third_party/.gitignore`) and the
root `pubspec_overrides.yaml` (add it to the root `.gitignore`).

## Native library prerequisites

The Dart package compiles without it, but every runtime path needs
`libtim2tox_ffi` built **without ToxAV** (DitMesh has no calls):

```bash
# from a toxee checkout with tool/ci/build_tim2tox.sh, or tim2tox's own build.sh
tool/ci/build_tim2tox.sh --no-toxav          # Linux x86_64 / Windows x64 / macOS x86_64+arm64 / Android arm64-v8a / iOS arm64
```

| Platform | Artefact and where `Tim2ToxFfi.open()` looks | Minimum OS |
|---|---|---|
| macOS | `libtim2tox_ffi.dylib` next to the executable, `../Frameworks/`, or `tim2tox/build/ffi/` | 10.15 |
| Linux | `libtim2tox_ffi.so` next to the executable or `../lib/` | — |
| Windows | `tim2tox_ffi.dll` next to the executable or `../lib/` | 10 |
| Android | `libtim2tox_ffi.so` in `jniLibs/<abi>/` (System.loadLibrary) | API 21 |
| iOS | `tim2tox_ffi.framework` embedded in the bundle | 13 |

Dev loops can pin an absolute path with
`DitmeshChatBackend.create(nativeLibraryPathOverride: ...)` (must be set before
the library is first opened). Mobile parity: the whole package is shared Dart;
nothing here is desktop-specific. `flutter_secure_storage` 11.x is used
because its Windows plugin depends on `win32 ^6`, the major the app's
`share_plus` needs.

## Tests

`flutter test packages/ditmesh_chat` runs without the native library:

- `identity_service_test.dart` — inspect/create/unlock/open state machine,
  encryption-at-rest around connect/disconnect, verifier-vs-file authority,
  changePassword, backup export/import round trip, deleteIdentity (fake
  `ProfileCrypto`, in-memory secure store, fake `ChatEngine`).
- `chat_service_test.dart` — the real `FfiChatService` over a `Tim2ToxFfi`
  binding fake (Flutter test binding + mocked `path_provider` channel, as in
  toxee): offline send → `pending`, inbound → `received` + unread, conversation
  derivation/sorting, pinned/draft/delete persistence, group mapping, invite
  queueing, validation errors, session detach.
- `backup_container_test.dart`, `prefs_adapter_test.dart`,
  `password_verifier_test.dart` (RFC 7914 PBKDF2 vectors).
- `identity_persistence_test.dart`, `transport_persistence_test.dart`,
  `key_value_store_test.dart`, `message_mapper_test.dart` — interrupted writes,
  replacement barriers, registered-store flushing, persisted group unread and
  invites, preference errors and queued message status after restart.

### Native smoke test (`@Tags(['needs-native'])`)

`test/native_smoke_test.dart` drives the real library single-process: create
identity → connect → reach the DHT → queue a send to an offline peer → create /
list members / leave a group (`DartGetGroupMemberList`, `DartQuitGroup`) →
disconnect. It skips itself when the library cannot be opened; in CI exclude it
explicitly with `flutter test --exclude-tags=needs-native`. On a dev machine:

```bash
bash tool/ci/build_tim2tox.sh --target macos-arm64 --mode release   # or linux-x86_64 …
cd packages/ditmesh_chat && TIM2TOX_FFI_LIB=$PWD/../../build/native/macos-arm64/libtim2tox_ffi.dylib \
  flutter test --tags needs-native test/native_smoke_test.dart
```

Passes in about 10 s on a Mac (2026-09-30): identity → DHT → friend request
(resolved by the routed `friendAddResult`) → queued send → group create /
members / leave → disconnect.

`test/native_persistence_test.dart` creates a password-protected identity,
updates its profile, adds an offline friend, creates an NGC, queues text and
saves a draft/pin. A fresh backend on the same paths must restore each value
and decrypt the savedata. It does not wait for DHT connectivity:

```bash
TIM2TOX_FFI_LIB=/absolute/path/to/libtim2tox_ffi.dylib \
  flutter test --no-pub test/native_persistence_test.dart
```

A two-peer exchange needs two processes (Tim2Tox's default singleton instance
model — multi-instance exists only for its own auto_tests): run the smoke
twice with different `IdentityPaths` roots and add each other's Tox ID, or
drive it against a toxee instance; that campaign is the M0b spike in the plan.

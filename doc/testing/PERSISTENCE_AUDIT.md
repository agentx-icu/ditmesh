[简体中文](./PERSISTENCE_AUDIT.zh-CN.md)

# Persistence audit — 2026-10-01

Worktree: `codex/persistence-audit`, based on `3972bc6`. This audit covers the
shared Dart implementation and the native storage plugins for all five release
targets. It uses disposable identities, directories and preference keys.

## Storage inventory

`<support>` is `path_provider`'s application-support directory;
`<identity>` is `<support>/ditmesh/identity`. No user data is stored relative to
the process working directory or inside the installed application bundle.

| Durable content | Production storage | Scope / restart behavior |
|---|---|---|
| Tox identity, friend relationships, native group memberships and native profile | `<identity>/profile/tox_profile.tox` | The real Tox engine reloads savedata. Password protection encrypts the stopped profile; the running engine needs decrypted savedata. |
| Display name, status, Tox ID, password flag | `<identity>/identity.json` plus native self profile | Atomic record replacement; native and record changes are serialized. Malformed records do not crash inspection. |
| Password verifier | `flutter_secure_storage`, keyed by identity | Native Keychain/Keystore/desktop secure store; failed password/profile transactions roll back the verifier. Encrypted savedata repairs a stale verifier after an interrupted rotation. |
| Message history, read flags and derived C2C/group unread counters | `<identity>/data/chat_history/` | Debounced history writes have an explicit flush barrier. Group unread restores from history. |
| Offline C2C/group outbox | `<identity>/data/offline_message_queue.json` | Queue entries survive restart; their presence restores pending status instead of incorrectly reporting sent. |
| Pending friend requests, rejection list | Account-scoped `shared_preferences` | Request text/time survive restart. The old single-account global rejection list migrates once and is cleared when that identity is replaced/deleted. |
| Group invites, names/types/chat IDs, quit groups, peer metadata, read receipts and other Tim2Tox host preferences | Account-scoped `shared_preferences` | Native/host metadata is rebound on connect. Removal includes suffix keys and full-ID draft/read-receipt keys. |
| Conversation drafts, pinned/hidden conversations | Account-scoped `shared_preferences` | The app metadata store supports offline edits. Compose drafts flush before background/quit and reject writes from replaced editors. |
| Lesson progress, SRS cards, session statistics/history | `<identity>/training/training/progress.json` | Existing directory layout retained; fresh controllers reload committed data. Invalid documents recover a valid previous-save backup. |
| Training defaults, playback/pedagogy parameters | `<identity>/training/training/settings.json` | Identity-scoped, validated, serialized and included in the training backup bundle. |
| Appearance style and brightness mode | `appearance.preferences` in `<support>/settings.json` | Saved together before publishing a change. Failed writes retain the previous visible choice. Old `app.theme` records remain a fallback; background/quit waits for pending appearance writes. |
| Language, notification privacy/sound, chat playback/training/input mode, reference playback, microphone decoder settings | `<support>/settings.json` | Restored before providers are exposed. Failed changes remain dirty for a later flush retry; unrelated saves cannot erase their failure. |
| Muted conversations | `notifications.muted.<full-public-key>` in `settings.json` | Kept per identity, cleared only after committed deletion/replacement. Failed replacement keeps the original mute list. |
| Window bounds/maximized, close-to-tray, tray sound choice | Desktop keys in `settings.json` | Bounds are validated against current displays. Choice write failures revert the model to allow retry; exit waits for pending preference writes. |
| Bootstrap and download preferences | Global `shared_preferences` | Preserved when deleting/importing an identity. Optional file-transfer/avatar host data remains under `<identity>/data/`; it is not a v1 UI feature. |

Current audio playback, microphone streams/buffers, key press state, connection
status, selected tab, translator scratch text and unfinished exercise answers
are session state. Completed training and user-selected decoder/playback settings
are durable. No password is stored in ordinary preferences.

## Verified fixes

- Wired previously transient app settings to the existing settings file, including
  input mode, reference settings and manual microphone tuning.
- Serialized JSON read/write/delete operations by path and captured immutable
  snapshots. A reset or delayed save cannot resurrect old training data. Syntax,
  structure and numeric validation preserve a usable previous backup.
- Serialized identity mutations, staged imports before replacement, and rolled
  back failed profile/password operations. A failed import never publishes a
  null identity or clears the old account's notification choices.
- Added identity data-store barriers around background, export, replacement and
  deletion. Old controllers/editors stop writing before files are replaced;
  aborted operations resume the old account. Independent flushes all run even
  if another store fails. Desktop quit stops on an unresolved durability error.
- Persisted pending friend requests and corrected identity cleanup/migration.
  Reconciled message status against the durable offline queue after real restart.
- Fixed a reproduced macOS Keychain `-34018` failure with the plugin-supported
  legacy Keychain configuration for this unprovisioned distribution. iOS keeps
  the data-protection Keychain and declares Keychain Sharing.
- Added disposable native storage integration tests to the test pyramid. Linux
  e2e CI now creates an isolated D-Bus session and unlocked GNOME Keyring for
  the real Secret Service test.

## Validation and limits

Final checks: **477 app tests**, **401 package tests** (including the final 71-test chat suite), and **2 native Tox tests** passed. The three available platform storage suites each passed **4 tests**. All seven package/app analyzer runs reported **zero issues**; the 500-line complexity gate, import guard, ARB sync and `git diff --check` passed.

Logs are retained in this worktree under `build/persistence-audit/`: `app.log`, `packages.log`, `chat.log`, `native-tox.log`, `macos.log`, `ios.log`, `android.log`, `gates.log` and the external review logs. Run `tool/test_pyramid.sh --level unit`, `--level widget`, `--level gates` and `--level e2e --device <id>` to reproduce the corresponding checks; supply `TIM2TOX_FFI_LIB` and run `flutter test --tags=needs-native` in `packages/ditmesh_chat` for native Tox tests.

| Target | Executed evidence | Remaining native coverage |
|---|---|---|
| macOS arm64 | Four real storage integration tests; real Tox encrypted-account/friend/NGC/outbox/history/draft/pin restart regression | No power-loss or forcibly killed process test |
| iOS 18.4, iPhone 16 Plus simulator | Four real file-store, Keychain and preferences-reload tests | Physical device and real Tox restart not executed |
| Android 16 / API 36 arm64 emulator | Four real file-store, secure-storage and preferences-reload tests | Physical device and real Tox restart not executed |
| Windows | Shared Dart regressions; inspected plugin registration, writable support paths and build prerequisites | No Windows host available; native tests not executed |
| Linux | Shared Dart regressions; inspected plugin registration, XDG support paths and Secret Service prerequisites; CI YAML/shell checks | No Linux host available; native tests and changed CI job not executed |

Integration tests instantiate fresh stores and reload native preferences to avoid
passing solely because a process cache still holds the value. They do not claim
a power-loss or force-kill guarantee. JSON backups protect malformed/incomplete
files; multi-file identity/secure-store updates are not a filesystem-wide ACID
transaction. Windows requires the Visual Studio C++ ATL components used by the
secure-store plugin. Linux needs a running, accessible Secret Service/keyring
in addition to the build-time `libsecret` headers.

The existing identity export format contains identity metadata, the Tox profile
and training files. It does **not** export chat history, the offline queue,
account preferences or global settings; restore intentionally replaces local
identity data and clears stale account preferences. This is an identity/training
backup, not a full-device backup.

If the OS application-support directory is unavailable, the existing startup
fallback uses in-memory app preferences and logs the failure. That fallback
cannot provide restart persistence.

Read-only external Claude Opus review was requested for the plan (including an
identical retry) but failed because the review account reached its session
limit. The actual final diff review and its identical Opus retry also failed with
`You've hit your session limit` (exit 1; session-end hook cancelled). No external
review succeeded. All local verification above completed; independent source
review findings were reproduced, fixed and covered by regressions. See
`build/persistence-audit/diff-review.log` for both attempts.

## Commit/merge verification

The pre-commit rerun passed 477 app tests with `--concurrency=1` and 71 chat
tests; both analyzers reported zero issues and the project gates passed. The
default parallel app rerun encountered two timing failures in the unchanged
account-test harness: a SnackBar reverse callback after teardown and an I/O
loading `pumpAndSettle` timeout. Its `settle()` pumps frames inside `runAsync`,
where Flutter uses real timers. The six onboarding tests passed independently.
The concurrent harness issue remains; serial execution provides the verified
pre-commit result without changing production behavior. Logs are retained with
the other audit evidence.


## GitHub master integration

Integrated master `2042b63` with the persistence commit `e750aeb`, preserving
all five appearance styles, the Modern Calm default and the refreshed gallery.
The appearance record takes precedence over legacy `app.theme`; missing or
damaged records retain the legacy theme. App/identity lifecycle flushes now
wait for pending appearance writes. Appearance failures retain the previous
visible choice and remain available for an explicit retry.

Fresh integration checks passed **512 app tests** with `--concurrency=1`
(one existing skipped test), **401 package tests**, **12 screenshot-import
tests**, **2 native Tox tests** and **4 macOS storage tests**. All seven
analyzers and the complexity, import, ARB and diff/format checks passed.
The file-reopen appearance regression uses real asynchronous I/O directly;
widget coverage and the pending-appearance shutdown barrier remain in place.
iOS and Android evidence above belongs to the original audit; those native
suites were not rerun for this merge. Windows/Linux native coverage remains
limited as documented above.

The Opus integration-plan review and identical retry failed due to the
reviewer session quota. Integration evidence is stored in
`build/persistence-audit/remote-merge-*.log`. The original checkout's 19
uncommitted installer files were verified byte-for-byte unchanged.

The final integration actual-diff Opus review and identical retry also failed
with `You've hit your session limit` (exit 1). No external review succeeded;
all local checks above passed. Both attempts are retained in
`build/persistence-audit/remote-merge-diff-review.log`.

[简体中文](./CROSS_PLATFORM_AUDIT.zh-CN.md)

# Cross-platform audit and fixes — 2026-10-22

Continuation of session `2040fe6b-e1a5-4700-b27d-83749f68844b`, starting from DitMesh `879d1d5` in the existing `agentx/xplat-checklist-audit` worktree. Targets: Android, iOS/iPadOS, macOS, Windows and Linux. Toolchain: Flutter 3.41.9 / Dart 3.11.5; macOS arm64, Xcode 26.4.1.

This is a source audit plus explicitly named local tests. A **verified** row states the bounded scope actually exercised; it never certifies every OS/device combination. Earlier runs remain in [VALIDATION.md](../VALIDATION.md), with their original revision and limitations.

Store follow-up (2026-10-23): [current channels, P4/P8/P9/W4/X6 evidence and owner blockers](../release/STORE_READINESS.md). This dated record does not overwrite the historical validation below.

## I2 follow-up — active shell shortcuts (2026-10-23)

`desktop/shell_shortcuts_test.dart` sends actual Flutter key-down/up/repeat events
through `DitmeshApp` with the fake backend on macOS, Windows and Linux platform
variants. It verifies the primary modifier, wrong-modifier rejection, one request
per held key, existing search/filter focus, selection of Chat from another tab,
Contacts route reuse/back behavior and untouched editor/IME/dialog state. The
existing pure binding suite is supplementary. The exposed shell now installs
K/N only; Shift+M remains unbound without a shared sidetone owner. Localized
tooltips publish K/N. Native keyboard/trackpad, non-US layouts, iPad Full Keyboard
Access and the native iPadOS 26 menu are not established by widget variants.

## Confirmed changes

- Acquire a process lock for the entire desktop application-support root before preferences/backend startup; secondary processes request owner activation. Keep the lock inode and let OS process termination release it. Independently spawned processes verify contention, activation and crash release.
- Verify an actual Linux StatusNotifier host before hiding; default close-to-tray off, expose the choice in Me, omit a sound menu with no audio owner, preserve normal bounds across maximized/fullscreen/minimized states, and handle framework quit through the same awaited session barrier. macOS Dock reopen is bridged to the shell.
- Let the QR plugin own lifecycle handling; the old supplied controller silently disabled that behavior. A platform fake verifies inactive stop and resumed restart. Physical camera/privacy UI is still unverified.
- Reject future identity, training progress/settings, audio-material and group-practice schemas at decode/write boundaries and through controller loading. Independently check primary and backup before replacement. The history overlay preserves newer data without breaking durable receipt handling; identity and learning errors explain upgrading in all ten languages.
- Replace page-covering flashes with a bounded indicator and reduced-motion behavior; probe actual vibrator hardware, explain missing Linux capture tools, and remove an unused default torch plugin while retaining explicit TorchApi injection.
- Use system 12/24-hour formatting in backup previews, diagnostics, pending messages and group practice. Move the mute shortcut off macOS's reserved Cmd+M. Generate larger tray rasters.
- Declare Linux recorder/host-probe runtime dependencies. Reject Android tagged builds missing release-signing inputs, while branch validation remains available.
- Correct existing retransmission tests to wait for a durable ACK/queue-drain condition before simulating link loss. A visible row or 500ms of quiet did not establish completion; the old test sometimes delivered the supposedly lost original ACK during reconnect.

## Evidence

Final local verification after independent review:

- All seven package suites: **1,250 passed**, two existing opt-in DSP skips (`tool/test_pyramid.sh --level unit`).
- Full application suite: **1,500 passed**, 36 opt-in layout/screenshot skips (`--level widget`). This includes independent-process lock/activation/crash-release, QR pause/resume, future-schema/backup, quit failure/retry and system-time regressions.
- Analyzer: all packages, app and tools report zero issues. Complexity, import and UI literal guards pass. The final application analyzer was rerun after removing an unused test import; no production change followed.
- Android release-signing, release-configuration and macOS runtime fixtures: **19 passed**. Packaging fixtures use command-local Xcode `SDKROOT`; the host's default CommandLineTools SDK 27 is incompatible with its Xcode 26.4 linker.
- Final macOS release UI build: **passed, 32.8 MB**. Overlay `bootstrap_deps.dart --offline-check-only` and `git diff --check` pass.

The independent review found and reproduced primary/current + backup/future overwrite and Android explicit-12-hour/24-hour-locale errors; both now have passing regression tests. Training and history upgrade errors are also mapped to actionable UI text. The macOS release UI build uses `DITMESH_FAKE_BACKEND=true` and `DITMESH_ALLOW_MISSING_FFI=1`: it compiles Dart, native plugins and AppDelegate, but does **not** verify the real Tox runtime or a distributable signed release. Existing upstream Tim2Tox is kept read-only; reproducible patches belong in the app overlay.

## Checklist

| ID | Status | Evidence / remaining check |
| --- | --- | --- |
| L1 | verified | Widget layout regressions cover phone/window stress sizes; native matrix remains separate. |
| L2 | verified | ui/responsive.dart and chat/chat_layout.dart use current window width; resize widget tests. |
| L3 | needs device | Real OS rotation/fold/display changes across breakpoints; existing simulator evidence is in VALIDATION.md. |
| L4 | needs device | Widget safe-area tests pass; inspect real cutouts, system/caption bars and iPad windows. |
| L5 | needs device | Keyboard widget profiles pass; floating/split iPad keyboards still need hardware. |
| L6 | needs device | Android/iOS orientation declarations inspected; OS-imposed rotation and resizable-window checks owed. |
| L7 | verified | Layout regression suite exercises bounded dialogs, sheets and scrollable content. |
| L8 | needs device | Separating fold/occluding hinge and posture preservation require a foldable profile. |
| D1 | verified | Existing text-scale layout regression coverage; largest OS accessibility categories still need device checks. |
| D2 | verified | Ten ARBs, translator metadata and generated messages validated by arb_consistency_test.dart. |
| D3 | needs device | 36px macOS template and 64px Linux tray rasters generated; mixed fractional-scale inspection owed. |
| D4 | needs device | Move the installed window between mixed-DPI monitors and change scale while running. |
| D5 | needs device | Platform asset tests and new raster sizes cover declarations; inspect actual installed tray/icons. |
| D6 | needs device | Light/dark source and widget cases reviewed; measured contrast and OS color filters remain owed. |
| D7 | verified | morse_io flash_overlay_test.dart: bounded lamp, reduced-motion steady indicator and input passthrough. |
| I1 | needs device | Touch/focus widgets reviewed; measure every essential control on smallest supported device. |
| I2 | needs device | Active K/N shell behavior is verified by `desktop/shell_shortcuts_test.dart` key-event/route/IME tests on macOS/Windows/Linux variants. Shift+M stays unbound; native input and iPad menus remain owed. |
| I3 | not applicable | Morse composer is read-only and sends keyed input; ordinary text fields do not use Enter-to-send. |
| I4 | needs device | PopScope/source and prior Android back evidence reviewed; release predictive-back/iOS gestures owed. |
| I5 | needs device | Semantics/keying tests pass; VoiceOver, TalkBack, Narrator and Orca end-to-end flows remain owed. |
| I6 | verified | i18n/system_date_time_test.dart verifies locale date order plus system 12/24-hour behavior. |
| I7 | verified | morse_io key cancellation, held-key and focus/semantics regressions run in package tests. |
| I8 | not applicable | No verified HTTPS deep-link entry point is advertised; Tox IDs are copied/scanned in-app. |
| I9 | needs device | Backup gateway consumes picker bytes immediately and bounds reads; real share/provider grant lifetime owed. |
| B1 | verified | qr_scan_lifecycle_test.dart exercises camera stop/resume; Listen and training lifecycle policy tests. |
| B2 | verified | Application preference, outbox, training and receipt write barriers covered by service/filesystem tests. |
| B3 | needs device | Cold notification taps, OS process kill and interrupted picker recreation need installed-device checks. |
| B4 | to do | No guaranteed mobile background delivery. Existing Android budget estimate needs conservative policy/device confirmation. |
| B5 | needs device | Desktop independent-process contention/activation/crash-release passes; Android multi-engine/iPad scenes owed. |
| B6 | verified | Durable outbox/receive/ownership tests, including waiting for actual ACK transmission before simulating loss. |
| B7 | verified | Future identity, owned training documents and history reject incompatible reads/writes; primary plus future-backup regressions preserve both files (overlay 0015). |
| B8 | verified | Offline durable queue, send intents, identity isolation and replacement tests; no central server conflict model. |
| P1 | needs device | Optional camera/microphone and Apple purpose strings/entitlements inspected; merged release declarations owed. |
| P2 | needs device | QR/Listen/notification denial tests cover UI policy; native denial/revoke/recovery flows owed. |
| P3 | verified | QR error and notification/channel fallback regressions plus unavailable-haptics hardware probe tests. |
| P4 | to do | Privacy manifests exist; owner must reconcile final SDK manifests, store privacy answers and release identity. |
| P5 | needs device | Encrypted backup/secure-store tests run; Android auto backup remains intentionally disabled for Tox identities. |
| P6 | needs device | Picker is consumed immediately; cloud/removable providers and restart/revoked-grant paths still need testing. |
| P7 | to do | No universal capture-prevention claim. Define and validate chat/app-switcher snapshot policy per platform. |
| P8 | not applicable | No purchases, subscriptions or paid entitlements. |
| P9 | to do | Persistent blocking/terms/support links exist; no actionable moderator report pipeline or verified store-console answers. |
| M1 | needs device | Audio session/source behavior and leases tested; physical silent switch/focus/interruption checks owed. |
| M2 | needs device | Real wired/Bluetooth/speaker route changes and disconnections. |
| M3 | needs device | Mocked QR lifecycle regression passes; confirm OS privacy indicator stops on real devices. |
| M4 | verified | App sends Morse/text and encrypted backup bytes; cross-platform backup/format unit coverage. |
| M5 | verified | Backup reads bounded by maxBackupFileBytes; microphone PCM is streamed; no full-size chat photo/video decode. |
| M6 | needs device | All five OS notification backends configured; source/service tests do not prove installed toast/tap behavior. |
| M7 | needs device | Optional hardware declarations and haptics probe; camera-less/Chromebook/XR native paths require devices. |
| M8 | not applicable | No screen/system-audio/remote-input capture feature. |
| W1 | needs device | Pure work-area and normal/maximized/fullscreen/minimized persistence tests; native mixed-DPI/Wayland checks owed. |
| W2 | needs device | Tray-host capability, default close-to-tray off and awaited quit tested; native close/reopen/logout checks separated. |
| W3 | verified | Application-support/temp paths, atomic file writes and desktop root ownership; no writes next to executable. |
| W4 | to do | Formal Apple/Windows signing/notarization and clean installer lifecycle checks require owner configuration/platform hosts. |
| F1 | to do | Measure release frame pacing at actual refresh rates and realistic conversation sizes. |
| F2 | to do | Record per-platform startup/install/download budgets and actual release measurements; macOS UI build size is only one sample. |
| F3 | needs device | Adaptive Tox event polling and audio/wake leases reviewed/tested; battery/thermal behavior requires hardware. |
| X1 | needs device | All five shipping targets reviewed; real phone/tablet/foldable/desktop device matrix is incomplete. |
| X2 | verified | Application layout regressions run; opt-in 17-profile crawl/visual matrix has separate CI evidence. |
| X3 | needs device | Widget resizing is not an OS rotation/fold/display test. |
| X4 | verified | This report explicitly separates mocked/widget/source evidence from installed/device behavior. |
| X5 | verified | Shared schema/flash/haptics fixes reach mobile and desktop; MorseCQ-only backup changes are not copied to chat. |
| X6 | to do | macOS release UI build compiles native changes; real-backend packaging/install/upgrade matrix still owed. |
| X7 | needs device | Interrupted OS UI, permission revocation and background process death still need a device campaign. |
| X8 | needs device | Existing network/DHT tests and VALIDATION.md retained; carrier NAT64/VPN/captive portal/device handover owed. |
| X9 | to do | Source-built FFI/runner and same-build Dart symbols have separate CI archival and final native identity gates; see STORE_READINESS for exact coverage and final-head evidence. Real device crash symbolication, exact vendor symbols and production collection/retention policy remain outstanding; this row is not closed by symbol pairing alone. |

## Release and device work still required

The table is the backlog; unverified work is not silently treated as passed. Formal certificates, notarization, Windows/Linux installed-app sessions, real mobile hardware, store-console answers and a moderator receiving/response process cannot be supplied by local unit tests. Privacy/capture and background-delivery policies need explicit product decisions, not invented guarantees. Preserve existing DitMesh encrypted-export policy; MorseCQ's offline-learning auto-backup policy does not apply to Tox identities.

Reference checks on 2026-10-22: [Dart file-lock semantics](https://api.dart.dev/dart-io/RandomAccessFile/lock.html), [Android app signing](https://developer.android.com/studio/publish/app-signing), [Apple UGC requirements](https://developer.apple.com/app-store/review/guidelines/#user-generated-content). The installed mobile_scanner 7.4.2 source documents that lifecycle observation applies only when the widget owns its controller; record_linux 1.3.1 invokes parecord/pactl rather than linking them.

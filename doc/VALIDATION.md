[简体中文](./VALIDATION.zh-CN.md)

# Verification record — 2026-10-08

Verified source revision: `21224e60ddfe03a90db298b1ba82360e0b0d844e`. Toolchain: Flutter 3.41.9 / Dart 3.11.5.

## Automated checks

| Check | Result |
|---|---|
| [Analyze](https://github.com/agentx-icu/ditmesh/actions/runs/37737114668) | Strict analysis, source guards and package/application tests passed. |
| Application suite | 1344 passed; 2 opt-in image exporters skipped. |
| Package suites | Chat 269, API 79, core 92, DSP 107, audio I/O 124, trainer 212 and radio tools 18 passed. DSP has 2 existing skipped first-block noise-floor cases. |
| [Native and platform builds](https://github.com/agentx-icu/ditmesh/actions/runs/37737115108) | All 13 required jobs passed: six native targets, six application builds and quality checks. |
| Native integration | 11 passed and 1 separate peer-worker entry skipped on each Linux/macOS target. The standalone two-process tests passed on Linux and both macOS architectures. |
| Real-peer delivery | Bidirectional direct/group messages, encrypted profile restart, durable queued sending exactly once and automatic group rejoin passed. |
| Network behavior | LAN sockets and two-client connectivity, node-key validation, cancellation, probe isolation and instance preservation passed. |
| Packaging regressions | 9 macOS runtime, 8 packaging/overlay/cache and 19 screenshot-import checks passed. |
| [Desktop E2E](https://github.com/agentx-icu/ditmesh/actions/runs/37737114750) | macOS, Linux and Windows UI navigation, persistence and all 13 screenshot scenes passed in English and Chinese. |
| [Visual matrix](https://github.com/agentx-icu/ditmesh/actions/runs/37737114693) | 38 profiles / 76 PNGs covering ten languages, five styles, light/dark and phone/desktop layouts. |

The DSP skips concern unusually quiet first noise blocks that can produce a spurious leading symbol. The opt-in application exporters are exercised by the screenshot and visual workflows.

## Screenshots and packages

The [gallery](screenshots/README.md) contains **156 frames**: 13 scenes × English/Chinese × macOS/iPhone/iPad/Android/Linux/Windows.

| Target | Verified packages |
|---|---|
| Android | APK and AAB |
| iOS | IPA |
| macOS | ARM64 and Intel PKG/ZIP |
| Linux | x86_64 DEB, RPM and tar.gz |
| Windows | x64 MSI and ZIP |

All **12 packages** from the platform build were downloaded and checked for complete asset coverage, SHA-256, archive integrity and bundled native libraries. Both macOS architectures passed inspection of every embedded Mach-O against the application minimum of **13.0**. Package checks also covered the signal-tower icon and Apple permission translations for all ten languages.

Commands for reproducing these checks are in the [test guide](testing/TEST_PYRAMID.md), [build guide](operations/BUILD_AND_DEPLOY.md) and [capture guide](../tool/screenshots/README.md).

## Local chat-experience worktree — 2026-10-09

Branch `codex/chat-onboarding-playback`, based on `71c9e95`, was checked locally on macOS ARM64 with Flutter 3.41.9 / Dart 3.11.5. The earlier CI and package evidence above belongs to its stated release revision.

| Check | Local result |
|---|---|
| Backend / pure API | Backend suite: 345 passed, 5 native/worker opt-ins skipped; API: 89 passed. The separate native run below covers the native opt-ins. |
| Application / Morse I/O | Application: 1576 passed, 2 opt-in image exports skipped; Morse I/O: 143 passed. |
| Native integration / callbacks | 12 native integration and 7 callback checks passed, 1 separate peer-worker entry skipped; both real peer workers passed through the coordinator. |
| Real recorded delivery | Direct and NGC complete playable timings, distinct identical text, actual receipts, encrypted restart, durable recorded queue and group rejoin passed. |
| Review regressions | Overflow bounds, receipt after queue removal, legacy null-ID queues, late metadata without extra arrivals, logout during negotiation, peer restart/old hello/stale ACK, prepare/resume keying priority, failed receive/retry/recovery, clear/session invalidation and bounded pending-state reclamation passed. |
| Guide / delivery | Independent spec and quality reviews approved. A 3× text test scrolls both headers and opens the friend flow. |
| Original capture / player | Independent spec review approved. Full 320×640 and 667×375 screens at 3× text support keying, sending, original replay and pause; the delivery target remains at least 48×48. |
| Final code review | Independent Codex whole-tree review approved after reproduced layout, prepare/resume, durability and expired-capacity findings were fixed; receive/transport final review passed 10 targeted tests. |
| Dependency integrity / source checks | Offline bootstrap and clean pinned submodule passed; application/packages/tool analysis reports zero issues with `--fatal-infos`; complexity, import and UI-literal guards passed. |
| Packaging / import checks | 8 packaging, 9 macOS runtime and 19 screenshot-import checks passed. |
| macOS application | Debug build, cold-start navigation smoke and 4 native persistence checks passed. A fresh file store restored guide dismissal and per-conversation listening/original-rhythm/range preferences. |

The native library used Homebrew libsodium 1.0.21 for this local run after pinned 1.0.20 download endpoints timed out; the repository's release pin remains 1.0.20. Local linking warns that the Homebrew dylib requires macOS 26, so this run does not verify distribution on macOS 13. The packaging test and application build use the Xcode 26.4 SDK explicitly because the installed Command Line Tools 27 SDK is incompatible with the selected linker.

Final real-peer evidence directory: `/var/folders/cz/1y3n3_k12g5d1jmk7m425kr00000gn/T/ditmesh_real_peers_tqvectwq`. The new recording transport contract is documented in [the implemented RFC](rfcs/2026-10-09-keyed-rhythm.md).

## Simulator / emulator evidence (2026-10-10)

**This is simulator and emulator evidence, not real-device evidence.** No phone or tablet was attached. Everything below ran on one Mac (Apple silicon) against branch `agentx/simulator-validation`, based on `46691f8`, with Flutter 3.41.9 / Dart 3.11.5 debug builds. The real-device matrix of the mobile-device review stays owed.

| Target | Image | Notes |
|---|---|---|
| iOS Simulator | iPhone 17 Pro, iOS 26.4 (23E254a), Xcode 26.4 | Dynamic Island, home indicator. Tim2Tox simulator XCFramework (arm64 + x86_64) built from this tree. |
| Android Emulator | `sdk_gphone64_arm64`, Android 16 / API 36, Google APIs, build BE2A.250530.026.F3, headless | Gesture navigation, 4 KB pages (no 16 KB image installed, so P1 was not run). `libtim2tox_ffi.so` arm64 built from this tree with NDK r28.2. |

Chat ran on the **real Tox backend**: the two devices befriended each other over the public DHT and exchanged messages. `DITMESH_FAKE_BACKEND` was used only for the existing launch and persistence smoke tests. The remote-controlled probe `apps/ditmesh/integration_test/device_matrix_test.dart` drove the UI and logged lifecycle, connection and message events with timestamps; OS actions came from `xcrun simctl` and `adb`. Production debug builds (`flutter build ios --simulator` / `flutter build apk`) were used wherever a relaunch had to keep app data, because `flutter test` uninstalls the app when it ends. Orientation changes were requested by the app (`SystemChrome.setPreferredOrientations`), not by rotating the device. From about 01:16 local time another session's MorseCQ tests shared the Android emulator and sometimes took the foreground; runs that depend on the foreground were repeated or checked afterwards.

| Item | Result |
|---|---|
| Launch / persistence smoke (fake backend) | `app_launch_test` and `persistence_test`, 5/5 on each device. |
| Identity, DHT, friendship (real backend) | Online after 12 s (iOS) and 8 to 9 s (Android). Friend request arrived in about 5 s; both peers online within about 40 s; messages delivered in about 1.5 s. |
| L1, Android | Background periods of 10 s, 120 s and 900 s. About 10 s after leaving the foreground, Android 16 puts the app's UID into the `APP_BACKGROUND` firewall chain (`dumpsys netpolicy`). The peer sees the friend go offline after 33 to 40 s, and the process is frozen after about 70 s (`ActivityManager: freezing`). The 60 s `mayBeDisconnected` hint fired at +60 s. Messages sent after the cut arrived 11 to 13 s after resume. **Finding:** the 60 s Android budget hint is optimistic on stock API 36; receiving actually stops after about 10 s. Still needs device confirmation. |
| L1, iOS | Not measurable: the Simulator kept the app running through 900 s in the background (continuous heartbeat, messages still received). `beginBackgroundTask` was taken, and the 30 s `mayBeDisconnected` hint fired on time. The timing is owed on a device. |
| L3 | Android: a message received 5 s after going to the background posted on `ditmesh_messages` (importance 4). iOS: SpringBoard logged badge updates while the app was in the background; banners were not inspected visually. |
| L9 | Android, after 900 s (frozen): `mayBeDisconnected`, then `foreground` and `reconnectRequested`; connecting to online in 5 s. Pass. |
| L8, L5 | Not attempted (tapping a notification was not automated). Owed. |
| N1, Android | Wi-Fi off (switch to emulated cellular) and back on: no interruption, delivery in about 1.5 s both ways. Airplane mode: the self status stayed `online` for 73 s after the radio went off. After airplane mode ended: online after 5.5 s, friend online after 24 s. |
| N1, message loss (**bug, not fixed**) | A message sent in the roughly 10 s between the peer going away silently and the sender noticing stays `sent` and is never delivered, not even after both sides are back online (2 of 2 runs). Tim2Tox does not resend a message whose delivery receipt never arrived (`third_party/tim2tox/dart/lib/service/ffi_chat_service.dart`, `applyNativeDeliveryAck`), while toxcore drops unacknowledged messages when a friend goes offline. Needs an overlay or an upstream fix. |
| N2, N3, N7, N9 | Device only (carrier NAT64, VPN / Private Relay / portal, battery, iOS Local Network privacy, which the Simulator does not enforce). Not attempted. |
| A3, A5 | Device only (audio routes, audio focus). Not attempted. |
| T1, rotation with a keyed draft | Landscape and back on both devices: the draft kept, 0 Flutter errors. Insets were left and right 62 / bottom 20 (iOS landscape) and left 52 (Android landscape). Pass. |
| T9, large text | iOS accessibility XXXL (3.12×) and Android font scale 2.0: chat list, conversation and Me page with 0 Flutter errors. The composer scrolls and the history area shrinks. Pass. |
| T7, P5, P6, P7 | Not attempted: the iOS Simulator has no camera, and the emulator needs a virtual-scene QR setup; no iPad was run (one simulator only). |
| P8 | Android per-app language: de-DE and zh-CN applied live, and the reset returned to the system language. Pass. |
| P9 | Blocking `ditmesh_messages` in Android settings shows "Blocked in system settings" on the Me page; unblocking removes it on return. Pass. |
| P11 | Android 16: BACK and a left-edge swipe both pop the conversation. BACK at the shell root finishes the activity (`detached`; the process survives, and a relaunch starts a new task), and the relaunch reopens the identity. Pass with the D1 fix. |
| D1 | iOS sends to a peer in airplane mode (outbox 1). The app goes to the background and is terminated 1 s later. The relaunch reconnects. After airplane mode ends, the receiver's history holds exactly one copy and the sender's row is delivered. **Pass after the fix below.** |
| D1, cold start (**bug, fixed**) | Before the fix, every cold start of an existing identity failed on both platforms with `identity_mismatch` and stayed `Offline`, retries included. The engine compared the Tox address before logging in, but Tim2Tox reports the self address only after login. Fixed in `packages/ditmesh_chat/lib/src/engine/chat_engine.dart`. The new `test/native_cold_start_test.dart` (needs-native) reopens in a child process: it failed before the fix and passes after. A restart in the same process hides the bug. |
| D1, draft after kill (**bug, not fixed**) | iOS: if the app is killed about 2 s after a send, the sent text comes back as the conversation draft (2 of 2 runs). After 15 s it is gone. A user could send it twice. Cause not confirmed. |
| Screen reader | TalkBack (Android): the shell exposes labelled controls ("Chat, Tab 1 of 4", "Contacts", "Tap to reconnect"). VoiceOver is not available in the Simulator, so it is owed on a device. |

Local gates for the fix: `ditmesh_chat` 386 unit tests and 13 native tests passed (1 skipped) (macOS arm64 library built from this tree); the real-peer harness passed (DM, NGC, encrypted restart, durable queue, NGC rejoin); `tool/test_pyramid.sh --level gates` passed. `tool/build_ios_ffi.sh` without options failed under macOS's bash 3.2 (empty array under `set -u`) and is fixed.

Still owed on real devices: L1 timing on iOS and on a vendor Android, L5, L8, N1 to N3, N7, N9, A1, A3, A5, T2 (gesture-zone press), T7, T8 copy feedback, P1 (16 KB device), P5, P6 and P7 on an iPad, VoiceOver.

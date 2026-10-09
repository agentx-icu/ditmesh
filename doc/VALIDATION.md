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

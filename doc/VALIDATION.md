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

[简体中文](./TEST_PYRAMID.zh-CN.md)

# Testing

Run from the repository root:

```bash
bash tool/test_pyramid.sh --level gates
bash tool/test_pyramid.sh --level unit
bash tool/test_pyramid.sh --level widget
bash tool/test_pyramid.sh --level e2e --device macos
```

| Layer | Coverage | Location |
|---|---|---|
| Gates | Strict analysis, complexity, imports and UI localization | `tool/` |
| Unit | Morse engines, audio I/O, chat contracts, queues and transport services | `packages/*/test` |
| Widget and service integration | Startup, identities, direct/group chat, network settings, reference, radio tools, notifications, desktop shell and appearance | `apps/ditmesh/test` |
| Native integration | Encrypted profiles, backup restore, persistence, LAN nodes and isolated probes | `packages/ditmesh_chat/test` |
| Platform E2E | Actual startup, plugin initialization, navigation, radio-tool calculations, keying by real touch and hardware-keyboard events, group creation, appearance, identity deletion, persistence and 13 scenes in English/Chinese | `apps/ditmesh/integration_test` |

The E2E workflow runs every fake-backend integration test on macOS, Linux and Windows, an Android emulator (API 34, x86_64) and an iPhone simulator when enabled by the `ci:e2e` PR label or manual dispatch; `tool/ci/run_integration_tests.sh <device>` runs the same set on any device, one app launch per file. UI walks use `DITMESH_FAKE_BACKEND=true` and seeded conversations. The persistence test reopens real application-support stores and platform secure storage using disposable files and keys. The manual real-backend probe `integration_test/device_matrix_test.dart` is excluded; see `doc/VALIDATION.md` §"Simulator / emulator evidence" for how to run it by hand.

Required Linux and both macOS native jobs run:

```bash
python3 packages/ditmesh_chat/test/helpers/run_real_peers.py --library <built-FFI-library>
```

Two native processes exchange local UDP messages, restart encrypted profiles, drain queued messages exactly once and rejoin groups. Tagged native tests also cover LAN hosting, node probes, cancellation and preservation of the active chat instance. Public DHT startup can be enabled with `DITMESH_PUBLIC_DHT_SMOKE=true`.

The visual workflow renders 38 profiles / 76 PNGs across ten languages, five styles, light/dark and phone/desktop layouts. Capture commands are in the [screenshot guide](../../tool/screenshots/README.md).

The Layout workflow runs `apps/ditmesh/test/layout/layout_crawl_test.dart` on every push to `master` and every pull request, in four shards. It boots the app over the screenshot demo data and performs a bounded traversal from the shell's four tabs and the two training screens chat opens (copy practice of a received message, group practice): recursion depth 2, at most 60 taps and 20 long presses per screen traversal, and at most 12 reopens per action. It does not enumerate every product route. It uses 17 representative window profiles: small and regular phones (portrait, landscape, landscape with the keyboard up, 2x text, German, Russian), an Android split-screen half, iPad Split View 1/3, tablets in both orientations, and desktop windows from the 360 x 640 minimum to a 3440 px ultrawide at device pixel ratios from 1 to 3 (including 1.25, 1.5 and 2.625). It fails on any overflow or constraint error, on text that lies under a notch, status bar or home indicator, on interface text cut short (app-bar titles, field hints and labels, button and tab labels), and on list rows, fields or buttons stretched wider than 1100 px. It measures with Noto (the test font's square glyphs make Latin text far too wide). Locally pass `--dart-define=DITMESH_LAYOUT_CRAWL=true`, and for realistic text widths `--dart-define=DITMESH_MATRIX_FONT=<font>`; `DITMESH_CRAWL_ONLY=<profile,...>` narrows the run and `DITMESH_CRAWL_OUT=<dir>` writes one problem list per profile. Without `DITMESH_LAYOUT_CRAWL` the test is skipped. The fast cases for each defect it found are in `test/layout/layout_regressions_test.dart` and run with the widget suite. The 51 explicit destination assertions below cover only scanner, WAV import and key editing; a clean bounded crawl does not qualify every product or native feature.

## Layout-host coverage follow-up (2026-10-26)

The earlier crawl recorded non-layout plugin/async errors as `OTHER` without failing. The known host gaps affected 107 profile × scene states (141 records) in the PR36/PR39 baseline: scanner event/orientation streams, WAV selection and native key-test audio. A green overflow count did not prove those destinations rendered. The crawler now fails on every recorded non-layout error and visible `ErrorWidget`, preserves scene/stack evidence, and rejects failed taps rather than counting them as successful. Existing layout detectors and traversal budgets are unchanged.

Each shell profile explicitly opens the real Contacts → scanner route and asserts its current camera-view destination, imports a valid WAV through the real platform-picker adapter and asserts workbench info/waveform, and opens the real key-profile editor with a prepared key-test sink. `destinations-<profile>.json` records these successful assertions alongside the original TXT reports. The test host restores scanner/file-picker singletons after unmount, supplies an in-memory WAV and per-page audio factories, and retains cancellation, valid/invalid QR, ownership and disposal regressions. Explicitly supplied audio objects still take precedence; without a factory production uses the original native implementation.

The host is evidence of those widget contracts, not native camera permissions, a system file dialog, physical sound or a complete functional/screenshot matrix. Other pages may deliberately catch unavailable-native-audio errors in this pure widget host; their actual sound remains unverified, and their diagnostics are not suppressed. The negative fixtures prove that a broken page, stray async error and missing required destination cannot receive a pass.

Add regressions at the lowest layer that can observe the behavior. Use widget tests for screen behavior, service integration for lifecycle and wiring, native tests for transport, and platform E2E for plugins. Current counts and CI links are in the [validation record](../VALIDATION.md); storage behavior is in the [persistence audit](PERSISTENCE_AUDIT.md).

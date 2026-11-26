[简体中文](./TEST_PYRAMID.zh-CN.md)

# Testing

Bootstrap and resolve the workspace dependencies, then run the checks from the repository root. Use `flutter devices` to find a device ID for E2E. [Workspace setup](../operations/BUILD_AND_DEPLOY.md).

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
| Platform E2E | Actual startup, plugin initialization, navigation, privacy and location UI, radio-tool calculations, keying by real touch and hardware-keyboard events, group creation, appearance, identity deletion, persistence and 13 scenes in English/Chinese | `apps/ditmesh/integration_test` |

## Platform E2E and device probes

The E2E workflow runs the fake-backend suite on macOS, Linux, Windows, an Android emulator (API 34, x86_64), and an iPhone simulator. It runs on demand with the `ci:e2e` PR label or manual dispatch, which also has a `windows_only` option. Run the same UI suite locally with `bash tool/ci/run_integration_tests.sh <device-id>`, one app launch per file. The UI walks seed conversations. The persistence test uses disposable files and keys in the real application-support directory and platform secure storage. The location privacy UI test supplies controlled permission and position values to exercise the screens. [E2E workflow](../../.github/workflows/e2e.yml).

The real-environment probes are opt-in. Stage the matching native library before a real-network run. Use a clean test device or simulator for Flutter integration tests because test install/uninstall can affect existing app data.

| Probe in `apps/ditmesh/integration_test/` | How to run |
|---|---|
| `network_device_test.dart` | Add `--dart-define=DITMESH_NETWORK_DEVICE_TEST=true` to its `flutter test` command. It opens a temporary identity and checks real native cold-start and restart connectivity. |
| `location_device_test.dart` | Add `--dart-define=DITMESH_LOCATION_DEVICE_TEST=true` to its `flutter test` command. It checks the actual OS permission and location provider without recording coordinates. [Location probe and interoperability evidence](NEARBY_INTEROP.md). |
| `device_matrix_test.dart` | Manual real-backend probe for lifecycle, connection and message events. [Simulator and emulator evidence](../VALIDATION.md#simulator--emulator-evidence-2026-10-10). |

## Native peer integration

The required Linux and macOS jobs run a two-process harness after staging the native library. From the repository root on macOS, run the same harness with the local library for your Mac.

```bash
python3 packages/ditmesh_chat/test/helpers/run_real_peers.py \
  --library "build/native/macos-$(uname -m)/libtim2tox_ffi.dylib"
```

On Linux x86_64, pass `build/native/linux-x86_64/libtim2tox_ffi.so` as `--library`. Two native processes exchange local UDP messages, restart encrypted profiles, drain queued messages exactly once and rejoin groups. The real-peer test also exchanges group messages while the Dart DHT status is set to offline. Tagged native tests cover LAN hosting, node probes, cancellation and preservation of the active chat instance. Set `DITMESH_PUBLIC_DHT_SMOKE=true` when running the native smoke test to include public DHT startup.

## Visual and layout coverage

The visual workflow renders 34 profiles / 68 PNGs across ten languages, four styles, light/dark and phone/desktop layouts. Capture commands are in the [screenshot guide](../../tool/screenshots/README.md).

The Layout workflow runs `apps/ditmesh/test/layout/layout_crawl_test.dart` on every push to `master` and every pull request, in four shards. It boots the app over the screenshot demo data and performs a bounded traversal from the shell's four tabs and the two training screens chat opens (copy practice of a received message, group practice): recursion depth 2, at most 60 taps and 20 long presses per screen traversal, and at most 12 reopens per action. It does not enumerate every product route. It uses 17 representative window profiles: small and regular phones (portrait, landscape, landscape with the keyboard up, 2x text, German, Russian), an Android split-screen half, iPad Split View 1/3, tablets in both orientations, and desktop windows from the 360 x 640 minimum to a 3440 px ultrawide at device pixel ratios from 1 to 3 (including 1.25, 1.5 and 2.625). It fails on any overflow or constraint error, on text that lies under a notch, status bar or home indicator, on interface text cut short (app-bar titles, field hints and labels, button and tab labels), and on list rows, fields or buttons stretched wider than 1100 px. It measures with Noto (the test font's square glyphs make Latin text far too wide). Locally pass `--dart-define=DITMESH_LAYOUT_CRAWL=true`, and for realistic text widths `--dart-define=DITMESH_MATRIX_FONT=<font>`; `DITMESH_CRAWL_ONLY=<profile,...>` narrows the run and `DITMESH_CRAWL_OUT=<dir>` writes one problem list per profile. Without `DITMESH_LAYOUT_CRAWL` the test is skipped. The fast cases for each defect it found are in `test/layout/layout_regressions_test.dart` and run with the widget suite. The 51 explicit destination assertions below cover only scanner, WAV import and key editing; a clean bounded crawl does not qualify every product or native feature.

## Layout-host coverage follow-up (2026-10-26)

The earlier crawl recorded non-layout plugin/async errors as `OTHER` without failing. The known host gaps affected 107 profile × scene states (141 records) in the PR36/PR39 baseline: scanner event/orientation streams, WAV selection and native key-test audio. A green overflow count did not prove those destinations rendered. The crawler now fails on every recorded non-layout error and visible `ErrorWidget`, preserves scene/stack evidence, and rejects failed taps rather than counting them as successful. Existing layout detectors and traversal budgets are unchanged.

Each shell profile explicitly opens the real Contacts → scanner route and asserts its current camera-view destination, imports a valid WAV through the real platform-picker adapter and asserts workbench info/waveform, and opens the real key-profile editor with a prepared key-test sink. `destinations-<profile>.json` records these successful assertions alongside the original TXT reports. The test host restores scanner/file-picker singletons after unmount, supplies an in-memory WAV and per-page audio factories, and retains cancellation, valid/invalid QR, ownership and disposal regressions. Explicitly supplied audio objects still take precedence; without a factory production uses the original native implementation.

The host is evidence of those widget contracts, not native camera permissions, a system file dialog, physical sound or a complete functional/screenshot matrix. Other pages may deliberately catch unavailable-native-audio errors in this pure widget host; their actual sound remains unverified, and their diagnostics are not suppressed. The negative fixtures prove that a broken page, stray async error and missing required destination cannot receive a pass.

The strict late-error gate also exposed group-practice deletion returning through a stale Navigator after its save completed. `groups_practice_delete_lifecycle_test.dart` uses a controlled delayed `TrainingDocStore` backed by `InMemoryTrainingDocStore` and checks the stored-document deletion result without closing a later page or touching a disposed Navigator, including replacement while the confirmation dialog is open. Current-page deletion and write-failure retry remain covered; after a successful save only the original active route is closed, by popping it when current or removing that exact route from beneath a later page so returning cannot reopen a deleted-session loader.

Add regressions at the lowest layer that can observe the behavior. Use widget tests for screen behavior, service integration for lifecycle and wiring, native tests for transport, and platform E2E for plugins. Current counts and CI links are in the [validation record](../VALIDATION.md); storage behavior is in the [persistence audit](PERSISTENCE_AUDIT.md).

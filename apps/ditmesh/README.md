[简体中文](./README.zh-CN.md)

# DitMesh application

The Flutter application shell for DitMesh. Feature logic lives in the
workspace packages; this app wires them into a responsive Material 3 UI with
the Chat / Groups / Reference / Me destinations.

| Package | Used for |
|---|---|
| [`ditmesh_chat_api`](../../packages/ditmesh_chat_api/README.md) | The only chat contract the UI depends on, plus in-memory fakes |
| [`ditmesh_chat`](../../packages/ditmesh_chat/README.md) | Tim2Tox backend, built only in `lib/di/real_backend_factory.dart` |
| [`morse_core`](../../packages/morse_core/README.md) | Alphabet, timing, encoder, keyed decoder, Chinese telegraph code |
| [`morse_io`](../../packages/morse_io/README.md) | Sidetone, haptics, flash, straight key and iambic keyer |
| [`morse_dsp`](../../packages/morse_dsp/README.md) | Microphone Morse decoding |
| [`morse_trainer`](../../packages/morse_trainer/README.md) | Drills, scoring and progress for copy practice, group practice and the listening workbench |
| [`radio_tools`](../../packages/radio_tools/README.md) | Radio tools reached from Reference: locator, bands, power, SWR, feedline, L-network matching, RF circuits, link budget, CW speed, RST, sunrise, NCDXF beacons, UTC |

## Source layout

| Path | Contents |
|---|---|
| `lib/main.dart`, `lib/di/` | Start-up, settings store, backend selection (`DITMESH_FAKE_BACKEND`), `AppScope` / `AppServices` |
| `lib/startup/` | Privacy consent, native-library check, identity gate, unlock and failure screens |
| `lib/ui/` | Screens: `chat/`, `groups/`, `contacts/`, `reference/`, `account/` (Me, backups), `network/`, `appearance/`, `listen/`, `learn/`, `tools/`, `shell/` |
| `lib/keying/`, `lib/training/` | Keyer profiles and device bindings; practice sessions and per-identity training stores |
| `lib/nearby/`, `lib/ui/nearby/` | Location permissions, location sharing and nearby discovery ([guide](../../doc/reference/LOCATION_AND_NEARBY.md)) |
| `lib/notifications/`, `lib/lifecycle/` | OS notifications, badge, background budget and reconnection ([guide](lib/notifications/README.md)) |
| `lib/desktop/` | Window, tray and shortcuts on macOS, Windows and Linux ([guide](lib/desktop/README.md)) |
| `lib/l10n/`, `lib/i18n/` | ARB files for ten languages and locale resolution ([guide](lib/l10n/README.md)) |
| `test/` | Widget and service tests, including `test/layout/` (layout crawler) |
| `integration_test/` | Platform E2E, screenshot capture and opt-in device probes ([test guide](../../doc/testing/TEST_PYRAMID.md)) |

## Run

Bootstrap and resolve dependencies at the repository root before running the app. [Build and run](../../README.md#build-and-run).

### Real Tox backend

Stage the Tim2Tox library for your target first. From the repository root, the example below uses macOS. For other targets, select a device ID from `flutter devices`. [Native build commands](../../doc/operations/BUILD_AND_DEPLOY.md#local-builds).

```bash
(cd apps/ditmesh && flutter run -d macos)
```

### UI-only development

Set `DITMESH_ALLOW_MISSING_FFI=1` for the native packaging step and `DITMESH_FAKE_BACKEND=true` for Dart. The in-memory backend starts with no identity and an empty chat list. The screenshot harness seeds demo conversations separately. [Capture guide](../../tool/screenshots/README.md).

```bash
(cd apps/ditmesh && DITMESH_ALLOW_MISSING_FFI=1 \
  flutter run -d macos --dart-define=DITMESH_FAKE_BACKEND=true)
```

### App checks

```bash
flutter analyze apps/ditmesh
(cd apps/ditmesh && flutter test --exclude-tags=needs-native)
bash tool/test_pyramid.sh --level e2e --device macos
```

Run the checks from the repository root. The E2E command opens a real app window with the fake backend. The maintenance and testing guides cover workspace-wide checks and the real-peer transport suite. [Maintenance guide](../../doc/HANDOVER.md) · [Test guide](../../doc/testing/TEST_PYRAMID.md).

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
| `lib/startup/` | Native-library check, identity gate, unlock and failure screens |
| `lib/ui/` | Screens: `chat/`, `groups/`, `contacts/`, `reference/`, `account/` (Me, backups), `network/`, `appearance/`, `listen/`, `learn/`, `tools/`, `shell/` |
| `lib/keying/`, `lib/training/` | Keyer profiles and device bindings; practice sessions and per-identity training stores |
| `lib/notifications/`, `lib/lifecycle/` | OS notifications, badge, background budget and reconnection ([guide](lib/notifications/README.md)) |
| `lib/desktop/` | Window, tray and shortcuts on macOS, Windows and Linux ([guide](lib/desktop/README.md)) |
| `lib/l10n/`, `lib/i18n/` | ARB files for ten languages and locale resolution ([guide](lib/l10n/README.md)) |
| `test/` | Widget and service tests, including `test/layout/` (layout crawler) |
| `integration_test/` | Platform E2E and screenshot capture; `device_matrix_test.dart` is a manual real-backend probe |

## Run

From the repository root, after the bootstrap described in the
[root README](../../README.md#build-and-run):

```bash
dart pub get                                   # workspace root only
flutter analyze apps/ditmesh
(cd apps/ditmesh && flutter test --exclude-tags=needs-native)
(cd apps/ditmesh && flutter run -d macos)      # or linux / windows / a device
```

`flutter run` needs the native Tim2Tox library for the current target (see
[build and packaging](../../doc/operations/BUILD_AND_DEPLOY.md)). For UI work
without it, use the in-memory fake backend (it starts with no identity and
empty chat; the screenshot harness in `tool/screenshots/` seeds demo
conversations). The macOS Podfile refuses a missing library unless
`DITMESH_ALLOW_MISSING_FFI=1` is set:

```bash
(cd apps/ditmesh && DITMESH_ALLOW_MISSING_FFI=1 flutter run -d macos --dart-define=DITMESH_FAKE_BACKEND=true)
```

The fake backend exists for tests and demos only; a production build with a
missing or failing native backend shows the failure instead of starting a demo
session. Contributor rules are in [`CLAUDE.md`](../../CLAUDE.md) and the
[maintenance guide](../../doc/HANDOVER.md).

[简体中文](./README.zh-CN.md)

# Product screenshots (cross-platform)

One command boots the real app on a real device or desktop window, seeds demo
data, walks every product scene in English and Chinese, and publishes the
frames into the committed `doc/screenshots/<platform>/<locale>/`.

```bash
tool/screenshots/capture.sh                          # macOS (default), en + zh
tool/screenshots/capture.sh --platforms macos,ios,ipad,android
tool/screenshots/capture.sh --platforms android --device emulator-5554
tool/screenshots/capture.sh --locales zh --keep      # one language, keep staging
DITMESH_SHOT_THEME=dark tool/screenshots/capture.sh  # env → --dart-define (see knobs)
```

Platforms: `macos`, `linux`, `windows` (the host desktop), `ios` (an iPhone
simulator), `ipad` (an iPad simulator), `android` (emulator or device). The
device is picked from `flutter devices` by platform, or given with `--device`.
Android emulators must already be running. `ios` and `ipad` produce App Store
Connect screenshots: without `--device` the script boots the 6.9" iPhone
(iPhone 17 Pro Max, else 16 Pro Max: 1320×2868) or the 13" iPad (iPad Pro
13-inch M5, else M4: 2064×2752) simulator itself, captures at the native
pixel ratio as RGB PNGs, and `verify` refuses any other size or an alpha
channel (`doc/release/APP_STORE.md` §10).

To publish captures from another host, download the screenshot artifact from a
successful CI run of the same UI revision, then pass the artifact's `screenshots`
directory. This mode preserves the source and applies the same completeness,
size and distinct-frame checks before publishing; it does not drive a device.
Source and output must be separate, non-overlapping directories. Selected
source directories and PNGs must be regular entries, without symlinks.

```bash
tool/screenshots/capture.sh --platforms linux --from /path/to/artifact/screenshots
```

Import regression checks run in Analyze CI and locally with
`python3 tool/screenshots/capture_import_test.py`; they create disposable PNG fixtures and do not require an existing screenshot gallery.

## How it works

The pipeline is a normal `integration_test`:

| piece | file |
|---|---|
| orchestrator (device pick, `flutter drive`, verify, publish) | `tool/screenshots/capture.sh` |
| the walk: scenes × locales on the real UI | `apps/ditmesh/integration_test/screenshots_test.dart` |
| seed data (hero, friends, QSO, net, request, a week of training) | `apps/ditmesh/integration_test/support/seed_data.dart` |
| navigation + the scene list `kScenes` | `apps/ditmesh/integration_test/support/scene_walk.dart` |
| Flutter-layer capture, window sizing, theme pin | `apps/ditmesh/integration_test/support/shot_harness.dart` |
| host side: writes the PNGs | `apps/ditmesh/test_driver/integration_test.dart` |

- **Backend**: `--dart-define=DITMESH_FAKE_BACKEND=true`. No Tox node, no
  disk; the fake services are seeded in-process through the test hooks of
  `package:ditmesh_chat_api/testing.dart` (`addFakeFriend`, `receiveMessage`,
  `addFakeGroupMember`, …) and local practice fixtures for chat-assisted exercises.
- **Capture**: the app is wrapped in a `RepaintBoundary` and each scene is
  `toImage`d from the Flutter layer. This is the same on all six targets,
  needs no OS permission and never grabs another window. (Flutter 3.41.9's
  `integration_test` has a native `takeScreenshot` only for Android and iOS.)
  The PNG bytes ride in `binding.reportData` (base64) to the `flutter drive`
  host, which writes `<platform>/<locale>/<scene>.png`.
- **Desktop window**: the harness resizes and centres the real window to
  `DITMESH_SHOT_WINDOW` (default `1280x800`) through `window_manager`. That
  sizes the outer frame, so the harness measures the title bar and borders
  and resizes once more until the Flutter view itself is the requested size.
  macOS may clamp a window larger than the visible frame; there a smaller
  size is accepted and logged. On Linux and Windows any mismatch fails the
  run.
- **Pixel ratio**: 1.0 on desktop, the native ratio on iOS (App Store sizes),
  `min(dpr, 2)` on Android; override with `DITMESH_SHOT_PIXEL_RATIO`. iOS
  frames are encoded without alpha.
- **Appearance**: pinned to Modern Calm, matching the README product concept.
  Brightness is pinned to light (`DITMESH_SHOT_THEME=light|dark|system`) so the
  frames do not follow the host's appearance or saved style preferences.
- **Knob validation**: a malformed or out-of-range knob fails the run instead
  of falling back to the default — window edges in (0, 8192], pixel ratio in
  [0.25, 4], theme one of the three names.
- **Every frame is asserted**: before each capture the walk checks the scene's
  screen and its seeded content (bubbles, friends, translator output) and
  taps only hit-testable targets. A `pumpAndSettle` timeout (an endless
  animation) is tolerated; any other error fails the run.
- **Locales**: each locale is a separate pass with its own seed copy (Chinese
  frames show Chinese names and a Chinese group; the Morse text stays in CW
  abbreviations, which is what is keyed on the air).
- **Publish gate**: a platform is copied into `doc/screenshots/` only when its
  local `flutter drive` or the source CI capture succeeded, every scene of every locale exists, is at least
  8 KiB, and no two frames are byte-identical (`cmp`, not just a checksum).
  The replacement set is assembled next to the target and swapped in whole;
  a failed platform leaves the committed frames untouched. Staging
  (`DITMESH_SHOT_STAGING`, else a temp dir) is kept on any failure. A
  `--locales` subset is verified but not published into the gallery, which
  must always hold every locale; use `--out` for a partial set. `--device`
  ids are checked against the requested platform.

`flutter test integration_test/screenshots_test.dart -d <device>` runs the
same walk as a plain UI test (every scene must render without an overflow or a
missing widget) and discards the frames; `tool/test_pyramid.sh --level e2e`
uses it that way.

## Scenes

`welcome`, `create_identity`, `backup_wizard` (first run), then from a seeded
identity: `chat_list`, `conversation`, `contacts`, `groups`,
`group_conversation`, `reference`, `translator`, `listen`, `me`.

Adding a scene: navigate + `shots.capture(tester, locale, 'name')` in
`scene_walk.dart`, add the name to `kScenes` there and to `SCENES` in
`capture.sh`, and add a row to `doc/screenshots/README.md`.

## Traps (all hit while building this)

- Two `pumpWidget` calls with a same-typed root **update** the existing element
  instead of replacing it, and `AppScope` keeps its first backend. Every app
  root in the walk carries a distinct `key`.
- `pumpAndSettle` throws on an endless animation (blinking caret, spinner);
  `settle()` in the harness catches that and moves on.
- A SnackBar sits over the composer's send button for 4 s; a synthetic tap
  lands on the toast and `flutter test` only prints a warning. Clear it
  (`ScaffoldMessenger.clearSnackBars()`) or assert on the result, never on the
  typed text.
- Android needs `ditmeshAllowMissingFfi` for a UI-only build (no
  `libtim2tox_ffi.so` staged); `capture.sh` exports it as
  `ORG_GRADLE_PROJECT_ditmeshAllowMissingFfi=true`. It also needs an arm64
  JDK on `JAVA_HOME` — a non-interactive ssh shell does not source the
  profile that sets it.
- From an ssh session the macOS window still renders and captures (the
  Flutter layer does not depend on the compositor), but do not steal focus
  while a run is in progress.

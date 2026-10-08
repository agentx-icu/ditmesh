[简体中文](./TEST_PYRAMID.zh-CN.md)

# The test pyramid

Four levels, bottom up. Each level is cheap enough to run before every push at
its own tier; the top one needs a device and is run on macOS before a release
and from the opt-in `e2e.yml` workflow.

```bash
tool/test_pyramid.sh                     # all levels, host desktop as the device
tool/test_pyramid.sh --level unit
tool/test_pyramid.sh --level e2e --device macos
```

| level | what | where | runs on | count (2026-10-03) |
|---|---|---|---|---|
| **gates** | analyzer (zero issues), 500-LOC complexity, import guard, UI literal guard | `tool/*.dart` | every push, CI `analyze.yml` | — |
| **unit** | pure-Dart engines (`morse_core`, `morse_trainer`, `morse_dsp`, `radio_tools`), the chat contract and its in-memory fakes (`ditmesh_chat_api`), the Tim2Tox transport (`ditmesh_chat`, `needs-native` smoke excluded), Flutter I/O sinks and keyers (`morse_io`) | `packages/*/test` | every push, CI `analyze.yml` | 543 |
| **widget** | every screen with the fake backend, at phone and desktop sizes; startup gate, onboarding, chat, learn, stats, reference, listen, notifications, desktop shell, i18n | `apps/ditmesh/test` | every push, CI `analyze.yml` | 867 |
| **integration (in-process)** | services wired the way `main()` wires them: `AppScope` → `AppServices` → fakes; the headless Tox smoke when `libtim2tox_ffi` is present (`needs-native`, `native.yml`) | `apps/ditmesh/test/di`, `packages/ditmesh_chat/test/native*_test.dart` | with the widget tier; native workflow | part of the counts above |
| **e2e (real UI)** | the app's own `main()` on the real platform, driven the way a first-time user clicks: onboarding → every tab → a drill → add a friend and send a line → translator → Me; plus the screenshot walk of 17 scenes × 2 locales | `apps/ditmesh/integration_test` | macOS before release; `e2e.yml` on demand; verified on macOS, iOS simulator and Android emulator (2026-09-30) | 7 tests, 34 frames per platform |

The e2e tier also runs `integration_test/persistence_test.dart`: real application-support file stores, Keychain/Keystore and an uncached native preferences reload using disposable files and keys. Run it on every release target; a file-store unit test cannot prove native plugin permissions.

Storage scope, findings and platform verification limits are recorded in the [persistence audit](./PERSISTENCE_AUDIT.md).

The e2e tier always runs with `--dart-define=DITMESH_FAKE_BACKEND=true`: the
in-memory backend creates no Tox identity and keeps no profile, so every
launch starts at onboarding. What does touch the device: the launch test runs
the real `main()`, so the app's normal `settings.json` (language, window
bounds) is written to its application-support directory; the screenshot walk
writes its seeded progress and fake profile under a temporary directory that
the test deletes at the end.

## What each tier is for

- **Unit** proves the maths and the protocol: timing, decoding, scoring, SRS,
  the fake services' behaviour that the widget tier relies on.
- **Widget** proves each screen's behaviour hermetically and fast (about 40 s
  for the whole app), on both layouts. It is where a bug's regression test
  normally lands.
- **In-process integration** proves the wiring, not the screens: that
  `AppScope` provides what the tree reads, that teardown order is right.
- **e2e** proves the things nothing below can: plugin initialisation on the
  real platform (window manager, tray, notifications, audio), the real
  `main()`, real navigation and text input, and — through the screenshots —
  that every scene renders without overflow in both languages.

## Bugs only the top tier found (2026-09-30, first run)

1. **Every debug launch on desktop crashed at first frame**: `AppScope`
   exposed the `DesktopShellController` (a `ChangeNotifier`) through a plain
   `Provider`, which provider's debug check rejects. Hermetic tests pass
   `desktopShell: null` and release builds skip the assert, so nothing lower
   could see it. Regression test now at the integration tier
   (`test/di/app_scope_desktop_shell_test.dart`).
2. **Add-friend sheet** tripped a framework semantics assertion ("invisible
   SemanticsNodes") while sliding away, on macOS and again on iOS: a
   `Tooltip` inside the Tox-ID field's suffix slot, laid out with a negative
   height by the shrinking sheet. The scan action is now a labelled button
   below the field on mobile (desktop keeps its hint line); the field has no
   suffix icon on any platform.
3. **Accuracy-trend chart** labelled sessions `1 2 3 5 6 7` (rounded
   fractional stride) and painted the axis caption over the last tick. Seen in
   the screenshots; fixed with an integer stride and a caption row.

## Adding tests

Put a test at the lowest tier that can observe the behaviour. A screen's
behaviour → widget. A wiring or lifecycle fact → `test/di`. Anything that
needs a plugin or the real `main()` → `integration_test/`, and add it to the
existing walk rather than a new file when it is a scene (see
`tool/screenshots/README.md`).

The required Linux and both macOS native CI jobs also run `python3 packages/ditmesh_chat/test/helpers/run_real_peers.py --library <built-FFI-library>`. Two separate native processes exchange real localhost UDP messages, restart encrypted profiles, drain a durable queue exactly once and rejoin the original group. Public DHT startup is an optional probe (`DITMESH_PUBLIC_DHT_SMOKE=true`); it is independent of the hermetic required delivery gate.

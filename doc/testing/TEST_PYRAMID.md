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
| Widget and service integration | Startup, identities, direct/group chat, network settings, reference, notifications, desktop shell and appearance | `apps/ditmesh/test` |
| Native integration | Encrypted profiles, backup restore, persistence, LAN nodes and isolated probes | `packages/ditmesh_chat/test` |
| Platform E2E | Actual startup, plugin initialization, navigation, persistence and 13 scenes in English/Chinese | `apps/ditmesh/integration_test` |

The E2E workflow runs on macOS, Linux and Windows when enabled by the `ci:e2e` PR label or manual dispatch. UI walks use `DITMESH_FAKE_BACKEND=true` and seeded conversations. The persistence test reopens real application-support stores and platform secure storage using disposable files and keys.

Required Linux and both macOS native jobs run:

```bash
python3 packages/ditmesh_chat/test/helpers/run_real_peers.py --library <built-FFI-library>
```

Two native processes exchange local UDP messages, restart encrypted profiles, drain queued messages exactly once and rejoin groups. Tagged native tests also cover LAN hosting, node probes, cancellation and preservation of the active chat instance. Public DHT startup can be enabled with `DITMESH_PUBLIC_DHT_SMOKE=true`.

The visual workflow renders 38 profiles / 76 PNGs across ten languages, five styles, light/dark and phone/desktop layouts. Capture commands are in the [screenshot guide](../../tool/screenshots/README.md).

The Layout workflow runs `apps/ditmesh/test/layout/layout_crawl_test.dart` on every push to `master` and every pull request, in four shards. It boots the app over the screenshot demo data and taps through every reachable screen, dialog and sheet, from the shell's four tabs and from the two training screens chat opens (copy practice of a received message, group practice). It does this at 17 window profiles: small and regular phones (portrait, landscape, landscape with the keyboard up, 2x text, German, Russian), an Android split-screen half, iPad Split View 1/3, tablets in both orientations, and desktop windows from the 360 x 640 minimum to a 3440 px ultrawide at device pixel ratios from 1 to 3 (including 1.25, 1.5 and 2.625). It fails on any overflow or constraint error, on text that lies under a notch, status bar or home indicator, on interface text cut short (app-bar titles, field hints and labels, button and tab labels), and on list rows, fields or buttons stretched wider than 1100 px. It measures with Noto (the test font's square glyphs make Latin text far too wide). Locally pass `--dart-define=DITMESH_LAYOUT_CRAWL=true`, and for realistic text widths `--dart-define=DITMESH_MATRIX_FONT=<font>`; `DITMESH_CRAWL_ONLY=<profile,...>` narrows the run and `DITMESH_CRAWL_OUT=<dir>` writes one problem list per profile. Without `DITMESH_LAYOUT_CRAWL` the test is skipped. The fast cases for each defect it found are in `test/layout/layout_regressions_test.dart` and run with the widget suite.

Add regressions at the lowest layer that can observe the behavior. Use widget tests for screen behavior, service integration for lifecycle and wiring, native tests for transport, and platform E2E for plugins. Current counts and CI links are in the [validation record](../VALIDATION.md); storage behavior is in the [persistence audit](PERSISTENCE_AUDIT.md).

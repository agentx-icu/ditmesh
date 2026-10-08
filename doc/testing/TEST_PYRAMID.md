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

Add regressions at the lowest layer that can observe the behavior. Use widget tests for screen behavior, service integration for lifecycle and wiring, native tests for transport, and platform E2E for plugins. Current counts and CI links are in the [validation record](../VALIDATION.md); storage behavior is in the [persistence audit](PERSISTENCE_AUDIT.md).

[简体中文](./HANDOVER.zh-CN.md)

# DitMesh maintenance guide

Start with the [README](../README.md), [network guide](operations/NETWORK.md), [build guide](operations/BUILD_AND_DEPLOY.md) and [test pyramid](testing/TEST_PYRAMID.md). Contributor rules are in [`CLAUDE.md`](../CLAUDE.md). Executed checks and the current open findings are recorded in [VALIDATION.md](VALIDATION.md).

## Repository map

| Path | Contents |
|---|---|
| `apps/ditmesh` | The Flutter application ([layout](../apps/ditmesh/README.md)) |
| `packages/ditmesh_chat_api` | Pure-Dart chat contract and fakes ([README](../packages/ditmesh_chat_api/README.md)) |
| `packages/ditmesh_chat` | Tim2Tox backend; the only importer of Tim2Tox/Tencent code ([README](../packages/ditmesh_chat/README.md)) |
| `packages/morse_core`, `morse_dsp`, `morse_io`, `morse_trainer`, `radio_tools` | Morse engine, audio decoding, keying/sidetone I/O, practice logic and radio maths |
| `third_party/tim2tox` | Pinned upstream submodule; never edited in place |
| `third_party/overlays`, `third_party/stubs` | Tencent SDK overlay that removes native IM binaries; empty `tencent_cloud_chat_common` stub |
| `tool/` | Bootstrap, source guards, test pyramid, icon and telegraph-table generators |
| `tool/ci/` | Native build, packaging, release checks, [native overlays](../tool/ci/tim2tox-overlays/README.md) and [Dart overlays](../tool/ci/tim2tox-dart-overlays/README.md) |
| `tool/screenshots/` | Screenshot and visual-matrix capture ([guide](../tool/screenshots/README.md)) |
| `site/` | Public privacy, terms and support pages ([README](../site/README.md)) |
| `doc/` | This documentation ([index](README.md)) |

## Before submitting a change

Run strict analysis, package/application tests and source guards (`bash tool/test_pyramid.sh --level gates`, `--level unit` and `--level widget`, or the loop in the [README](../README.md#development-checks)). Keep Morse-only composing, direct/group delivery, encrypted backup restoration and queued sending covered when changing chat behavior. Network tests cover saved node selection, node probes, LAN hosting, reconnection and disposal. Appearance checks cover ten languages, five styles and phone/desktop layouts. User-facing documents are maintained as English + zh-CN pairs.

## CI workflows

| Workflow | Runs on | Covers |
|---|---|---|
| Analyze (`analyze.yml`) | Pushes to and pull requests targeting `main`/`master`; manual dispatch | Workflow/shell lint, strict analysis, complexity/import/UI-literal guards, release-version check, packaging and screenshot-import regressions, non-native tests |
| Layout (`layout.yml`) | Every push to `master` and every pull request | The four-shard layout crawler |
| Native (`native.yml`) | Pushes and pull requests that touch code, tools, workflows or the pin; every `v*` tag | Native libraries, application builds, real-peer tests, packages and the draft release |
| E2E, Visual matrix (`e2e.yml`, `visual-matrix.yml`) | `ci:e2e` label or manual dispatch | Platform integration tests and screenshots; 38-profile visual matrix |
| Native experimental (`native-experimental.yml`) | `ci:arm` label or manual dispatch | Optional ARM host jobs |
| Pages (`pages.yml`) | Pushes to `main`/`master` that touch `site/` or the workflow; manual dispatch | Public site deployment |

## Native transport

Apply native transport patches through the [source overlays](../tool/ci/tim2tox-overlays/README.md) and Dart service changes through the [Dart overlays](../tool/ci/tim2tox-dart-overlays/README.md). To move the Tim2Tox pin, update the `third_party/tim2tox` gitlink, re-run `dart run tool/bootstrap_deps.dart`, confirm `--offline-check-only` and that every overlay still applies, and update the pinned revision in the [keyed-rhythm RFC](rfcs/2026-10-09-keyed-rhythm.md). Fixes that belong upstream land in Tim2Tox first; other Tim2Tox clients such as toxee need the same pin bump.

## Device testing

For device testing, check touch and keyboard keying, sidetone, haptics, QR scanning, notification routing and background recovery. Use peers on different networks to check NAT connectivity. The checks still owed on real devices are listed in [VALIDATION.md](VALIDATION.md). For packaging and store configuration, follow the [release guide](release/APP_STORE.md).

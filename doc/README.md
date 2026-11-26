[简体中文](./README.zh-CN.md)

# DitMesh documentation

| If you want to | Start here |
|---|---|
| Install DitMesh and send a first Morse message | [Quick start](../README.md#install-and-start-chatting) |
| Fix an offline chat or use a LAN node | [Network guide](operations/NETWORK.md) |
| Build a native app or diagnose a missing library | [Build and troubleshooting](operations/BUILD_AND_DEPLOY.md) |
| Develop the UI without Tim2Tox | [App developer guide](../apps/ditmesh/README.md#ui-only-development) |
| Run a test on a device or with real Tox peers | [Test guide](testing/TEST_PYRAMID.md) |
| Prepare an installer or a store submission | [Signing and distribution matrix](release/STORE_READINESS.md) |

## Using and operating DitMesh

- [Application responsibilities](APP_SPLIT.md) — DitMesh chat versus the MorseCQ trainer
- [Bootstrap nodes and LAN hosting](operations/NETWORK.md)
- [Location and People nearby](reference/LOCATION_AND_NEARBY.md)
- [Public site: privacy, terms, support](../site/README.md)

## Building, testing and releasing

- [Build, CI and packaging](operations/BUILD_AND_DEPLOY.md)
- [Release and store requirements](release/APP_STORE.md)
- [Store readiness, evidence and owner blockers](release/STORE_READINESS.md)
- [Test pyramid](testing/TEST_PYRAMID.md)
- [Current persistence inventory](testing/PERSISTENCE_AUDIT.md)
- [Cross-platform audit and fixes](testing/CROSS_PLATFORM_AUDIT.md)
- [Native location and nearby interoperability with Toxee](testing/NEARBY_INTEROP.md)
- [Verification evidence and open findings](VALIDATION.md)
- [Maintenance guide](HANDOVER.md)

## Code guides

- [Application layout](../apps/ditmesh/README.md)
- [Chat contract](../packages/ditmesh_chat_api/README.md) and [Tim2Tox backend](../packages/ditmesh_chat/README.md)
- [Native source overlays](../tool/ci/tim2tox-overlays/README.md) and [Dart overlays](../tool/ci/tim2tox-dart-overlays/README.md)
- Morse packages: [core](../packages/morse_core/README.md), [audio decoding](../packages/morse_dsp/README.md), [keying and sidetone I/O](../packages/morse_io/README.md), [practice logic](../packages/morse_trainer/README.md), [radio tools](../packages/radio_tools/README.md)
- App modules: [notifications and background](../apps/ditmesh/lib/notifications/README.md), [desktop shell](../apps/ditmesh/lib/desktop/README.md), [localisation](../apps/ditmesh/lib/l10n/README.md)
- [Adding an interface language](i18n/ADDING_A_LANGUAGE.md)

## Protocols

- [Implemented original keyed-rhythm protocol](rfcs/2026-10-09-keyed-rhythm.md)

## Design and screenshots

- [Product design concept](designs/product-2026-10-08/README.md)
- [Signal-tower icon designs](designs/icon-2026-10-08/README.md)
- [Real UI screenshots](screenshots/README.md) and the [capture pipeline](../tool/screenshots/README.md)

[简体中文](./README.zh-CN.md)

# DitMesh documentation

## Using and operating DitMesh

- [Application responsibilities](APP_SPLIT.md) — DitMesh chat versus the MorseCQ trainer
- [Bootstrap nodes and LAN hosting](operations/NETWORK.md)
- [Public site: privacy, terms, support](../site/README.md)

## Building, testing and releasing

- [Build, CI and packaging](operations/BUILD_AND_DEPLOY.md)
- [Release and store requirements](release/APP_STORE.md)
- [Test pyramid](testing/TEST_PYRAMID.md)
- [Current persistence inventory](testing/PERSISTENCE_AUDIT.md)
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
- [Earlier message-annotation proposal](rfcs/2026-09-30-tim2tox-message-annotation.md) (superseded, kept for history)

## Design and screenshots

- [Product design concept](designs/product-2026-10-08/README.md)
- [Signal-tower icon designs](designs/icon-2026-10-08/README.md)
- [Real UI screenshots](screenshots/README.md) and the [capture pipeline](../tool/screenshots/README.md)

[简体中文](./HANDOVER.zh-CN.md)

# DitMesh maintenance guide

Start with the [README](../README.md), [network guide](operations/NETWORK.md), [build guide](operations/BUILD_AND_DEPLOY.md) and [test pyramid](testing/TEST_PYRAMID.md). Executed checks are recorded in [VALIDATION.md](VALIDATION.md).

Keep Morse-only composing, direct/group delivery, encrypted backup restoration and queued sending covered when changing chat behavior. Network tests cover saved node selection, node probes, LAN hosting, reconnection and disposal. Appearance checks cover ten languages, five styles and phone/desktop layouts.

For device testing, check touch and keyboard keying, sidetone, haptics, QR scanning, notification routing and background recovery. Use peers on different networks to check NAT connectivity. For packaging and store configuration, follow the [release guide](release/APP_STORE.md).

Run strict analysis, package/application tests and source guards before submitting changes. Apply native transport patches through the [source overlays](../tool/ci/tim2tox-overlays/README.md).

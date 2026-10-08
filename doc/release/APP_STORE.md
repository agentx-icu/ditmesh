[简体中文](./APP_STORE.zh-CN.md)

# DitMesh release and store configuration

## Packages and release metadata

- Match tag/version/build metadata and run the analyzer, tests and platform builds.
- Inspect bundled native/runtime dependencies and verify SHA256SUMS.
- Review the generated GitHub draft Release and current English/Chinese screenshots.
- Check backup restoration, queued sending, contacts, groups, blocking and data deletion.

## Distribution configuration

| Platform | Configuration |
|---|---|
| iOS | App Store Connect record, Apple team, distribution certificate, provisioning profile and archive upload |
| macOS | Developer ID signing and notarization |
| Android | Release/upload keystore, store account and APK/AAB signing |
| Windows / Linux | Installer runtime checks and publisher signing where applicable |

Store signing credentials in CI secrets or local signing configuration.

## Product and privacy metadata

Describe Morse-only direct/group chat, Tox identities and peer networking in the store listing. Complete encryption and privacy questionnaires using the application and native library behavior.

Camera access serves QR contacts; microphone access serves local Morse decoding; notifications provide message alerts. Link the public [privacy policy](../../site/privacy.md), [terms](../../site/terms.md) and [support page](../../site/support.md).

Explain contact blocking and peer-to-peer content handling in moderation metadata.

## Device checks

Check sidetone, silent-switch playback, haptics, touch/keyboard controls, camera scanning, notification routing, group persistence, background recovery and backup workflows. Executed automated checks are in the [validation record](../VALIDATION.md).

[简体中文](./APP_STORE.zh-CN.md)

# DitMesh release and store readiness

DitMesh is the Tox Morse chat app on all five platforms. MorseCQ is the independent offline trainer. This checklist documents preparation, not approval or an existing store listing.

## Repository release

- Match tag/version/build metadata and run the required analyzer/test/native/application jobs.
- Inspect platform packages, bundled FFI/runtime dependencies, independent DitMesh identifiers and SHA256SUMS.
- Review the generated draft Release before public publication. Do not label unsigned binaries as signed/notarized.
- Capture current direct/group/identity/reference screens and verify English/Chinese coverage.
- Confirm current DitMesh backup restore, offline queue, contacts/groups, blocking and data deletion.

## Owner credentials and external actions

| Platform | Owner work |
|---|---|
| iOS | App Store Connect app record `icu.agentx.ditmesh`, team, distribution certificate/provisioning, signed archive/IPA and upload |
| macOS | Developer ID signing, notarization and distribution review |
| Android | Release/upload keystore, store account and APK/AAB signing |
| Windows / Linux | Installer runtime verification and optional publisher signing |

No credentials are stored in this repository. Generated unsigned iOS packages need signing before installation.

## Product/privacy review

Chat input is Morse-only; there is no phone/e-mail registration or developer messaging server. Tox identities and peer networking still exist on iOS. Keep the network encryption declaration consistent with the actual native library; Complete the relevant store questionnaire against current behavior.

The app requests camera for QR contacts, microphone for local Morse decoding and local notifications as needed. Public [privacy](../../site/privacy.md), [terms](../../site/terms.md) and [support](../../site/support.md) must match shipped behavior; pages deployment is a separate repository setting/action.

Blocking exists, but there is no central service able to remove content from all peers. Store distribution suitability must be evaluated against the current review rules and actual peer-to-peer moderation model; this work does not assert approval.

## Physical-device pass

Check sidetone latency/silent switch, haptics, touch/keyboard controls, scan permission and camera, notification launch routing, group persistence, background restrictions and passphrase/backup file workflows. Simulator screenshots do not replace these checks. See [validation](../VALIDATION.md) for executed results.

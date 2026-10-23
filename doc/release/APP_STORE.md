[简体中文](./APP_STORE.zh-CN.md)

# DitMesh release and store configuration

## Packages and release metadata

- Match tag/version/build metadata and run the analyzer, tests and platform builds.
- Inspect bundled native/runtime dependencies and verify SHA256SUMS.
- Review the generated GitHub draft Release and current English/Chinese screenshots.
- Check backup restoration, queued sending, contacts, groups, blocking and data deletion.

## Distribution configuration

The [dated store audit and owner-action matrix](STORE_READINESS.md) distinguishes current GitHub validation packages from future store channels, including iOS/iPadOS/Mac App Store, Developer ID, Play, Microsoft MSI versus MSIX, and selected Linux/domestic Android candidates. No store is currently certified ready. `package_artifacts.sh --mode distribution` only supports Android signing preflight; other formal distribution paths fail explicitly until implemented and verified. Formal credentials belong in secret storage, never in Git.

## Product and privacy metadata

Describe Morse-only direct/group chat, Tox identities and peer networking in the store listing. Complete encryption and privacy questionnaires using the application and native library behavior.

Camera access serves QR contacts; microphone access serves local Morse decoding; notifications provide message alerts. Link the published pages: privacy policy <https://agentx-icu.github.io/ditmesh/privacy/>, terms <https://agentx-icu.github.io/ditmesh/terms/> and support <https://agentx-icu.github.io/ditmesh/support/> (sources: [privacy](../../site/privacy.md), [terms](../../site/terms.md), [support](../../site/support.md); the app links the same URLs from `account_routes.dart`).

Explain contact blocking and peer-to-peer content handling in moderation metadata.

## Android: SDK levels and 16 KB pages

Policy/SDK observations below were checked on **2026-10-23**; reopen the [official dynamic sources](STORE_READINESS.md#official-policysource-index) before each release.

| Setting | Value | Where |
|---|---|---|
| `compileSdk` | 36 | `apps/ditmesh/android/app/build.gradle.kts`, pinned (not inherited from the Flutter Gradle plugin) |
| `minSdk` | 24 | same; Flutter 3.41's floor and the level `NetworkPathChannel` needs |
| `targetSdk` | 36 | same; Google Play requires API 36 for new apps and updates since 2026-08-31 |
| NDK for plugin code | `flutter.ndkVersion` (28.2 on Flutter 3.41.9) | r28+ links 16 KB page-aligned by default; never pin it below r28 |
| `libtim2tox_ffi.so`, `libc++_shared.so` | linked with `-Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384` and `ANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON`; `tool/ci/build_tim2tox.sh` refuses an unaligned result, including the 4 KB `libc++_shared.so` of an NDK older than r27 | `tool/build_android_ffi.sh` → `tool/ci/build_tim2tox.sh` |

`test/platform/mobile_platform_config_test.dart` pins the three levels and the link flags. Raise the levels together and update this table.

Google Play requires 16 KB page support for every 64-bit native library in apps targeting Android 15+ (check the enforcement date on the Play "16 KB page size" policy page before each release; it was 2027-02-01 when this was written). Before a Play upload, check the final APK/AAB, not only the libraries this repository builds, because plugin libraries (`libflutter.so`, `libapp.so`, the ML Kit barcode libraries of `mobile_scanner`) come from their own toolchains:

```bash
zipalign -c -P 16 -v 4 app-release.apk          # build-tools 35+
unzip -o app-release.apk 'lib/arm64-v8a/*' 'lib/x86_64/*' -d apk
for so in apk/lib/*/*.so; do echo "$so"; llvm-readelf -lW "$so" | grep -E '^\s+LOAD'; done   # every Align >= 0x4000
```

Then run the app on a 16 KB device or emulator image (Pixel 8+ developer option "Boot with 16KB page size", or the `16k` system images) and open a chat: a 4 KB-only library fails at `DynamicLibrary.open`.

Predictive back is enabled (`android:enableOnBackInvokedCallback="true"`); Android 16 applies it to targetSdk 36 anyway, the attribute makes Android 13–15 behave the same.

## iOS: export compliance (`ITSAppUsesNonExemptEncryption`)

`Info.plist` retains `ITSAppUsesNonExemptEncryption = true` pending the release owner's documented classification of the actual Tox/libsodium use. Encryption's presence alone does not decide whether an exemption applies. Follow [Apple's current export questionnaire](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/) and obtain any applicable documents; record the decision, scope, date and responsible owner before submission. Add a compliance code only if Apple supplies one for that classification. Change the flag only when supported by the recorded classification; do not copy another app's answer or bypass the questions.

Decision log: none yet (owner action). The existing platform test conservatively pins the pending flag and rejects an empty compliance code; it does not classify export law.

## Data at rest on the device

- Android: the identity (Tox profile, history, settings) lives in the app's private files directory (`getApplicationSupportDirectory()` → `files/`). `allowBackup="false"`, `fullBackupContent="false"` and `data_extraction_rules.xml` exclude every domain from cloud backup and device-to-device transfer. Nothing is written to external storage; a share hands the share sheet a copy in the app's temporary directory that is deleted afterwards.
- iOS: `<Application Support>/ditmesh` is marked `isExcludedFromBackup` (channel `icu.agentx.ditmesh/backup_exclusion`). Data protection is the platform default, `NSFileProtectionCompleteUntilFirstUserAuthentication` (no `com.apple.developer.default-data-protection` entitlement): files are encrypted until the first unlock after boot and readable in the background afterwards, which the durability flush needs.
- A password-protected identity is additionally encrypted on disk by native code, at creation, while connected, after persist and after a live re-key (`packages/ditmesh_chat/test/native_encryption_test.dart`, tag `needs-native`).

## iPad multitasking and share sheets

iPhone supports portrait and both landscape orientations; iPad supports all four and `UIRequiresFullScreen` is not set, so Split View, Slide Over and Stage Manager apply down to 320 pt width. Every share action (backup export, LAN node info) anchors its popover to the tapped control through `sharePositionOrigin`; `test/platform/share_origin_guard_test.dart` fails on a share call without one.

## Android notification channels

Three channels (`ditmesh_messages`, `ditmesh_friend_requests`, `ditmesh_group_invites`). The in-app switch on the Me page is the user's preference, not the OS state: when the user blocks a channel in system settings, `areNotificationsEnabled()` stays true and posts to that channel are dropped by the OS. The app reads the blocked channels at start and on every return to the foreground; a blocked `ditmesh_messages` channel shows "Blocked in system settings" on the Me page. Details: [notifications guide](../../apps/ditmesh/lib/notifications/README.md#blocked-channels).

## Device checks

Check sidetone, silent-switch playback, haptics, touch/keyboard controls, camera scanning, notification routing, group persistence, background recovery and backup workflows. Executed automated checks are in the [validation record](../VALIDATION.md).

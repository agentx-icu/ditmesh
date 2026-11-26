[简体中文](./BUILD_AND_DEPLOY.zh-CN.md)

# Build, CI and packaging

Use Flutter 3.41.9 / Dart 3.11.5. From the repository root, initialise the submodules and resolve the workspace dependencies against the committed lockfile.

```bash
git submodule update --init --recursive
dart run tool/bootstrap_deps.dart
dart pub get --enforce-lockfile
```

The bootstrap pins/patches the Dart compatibility SDK, applies the repository overlay that removes Tencent's native IM plugin and writes ignored dependency overrides. Tim2Tox links c-toxcore and pinned static libsodium on Linux, macOS, Android and iOS; Windows uses vcpkg's libsodium and pthreads, captured as DLLs next to `tim2tox_ffi.dll` and bundled with it. ToxAV is disabled.

It also stages the pinned Tim2Tox Dart package into ignored `third_party/tim2tox_ditmesh` and applies `tool/ci/tim2tox-dart-overlays` for original rhythm transport. The root override and lock refer to that copy. Run `dart run tool/bootstrap_deps.dart --offline-check-only` to verify it against the upstream sources and reviewed patches; re-run bootstrap after changing either. Keep the upstream submodule clean.

macOS application packages require **13.0 or later** on Intel and ARM. This satisfies the bundled Objective-C framework. The packager checks the application minimum against every actual embedded Mach-O architecture before generating ZIP/PKG; a dependency requiring a newer system blocks packaging. The transport library may support a lower system version without lowering the application requirement.

## Local builds

Build and stage Tim2Tox from the repository root using the row for your destination.

| Destination | Host tools | Native build command |
|---|---|---|
| macOS (Apple silicon or Intel) | Xcode, CocoaPods, CMake | `bash tool/ci/build_tim2tox.sh --target macos` |
| Linux x86_64 | C/C++ toolchain, CMake, Ninja or Make, pkg-config and Flutter Linux desktop dependencies | `bash tool/ci/build_tim2tox.sh --target linux-x86_64` |
| Windows x64 | MSVC C++ toolchain, CMake, vcpkg packages and `VCPKG_ROOT`, Git Bash in the configured MSVC environment | `bash tool/ci/build_tim2tox.sh --target windows-x64` |
| Android | Android SDK and NDK `28.2.13676358`, JDK 17 | `ABIS=arm64-v8a,armeabi-v7a,x86_64 bash tool/build_android_ffi.sh` |
| iOS / iPadOS device or simulator | macOS, Xcode 26 with the iOS 26 SDK, CocoaPods, CMake | `bash tool/build_ios_ffi.sh` |

Use `bash tool/ci/build_tim2tox.sh --help` for native-build prerequisites and switches. Choose `macos-arm64` or `macos-x86_64` to build an explicit library architecture. Android uses a single `android` target with `--android-abis`. The wrapper passes the `ABIS` list. For iOS, the wrapper creates an XCFramework from the `ios-device` and `ios-simulator` targets. Select `--device-only` or `--simulator-only` if you need just that slice.

Then enter `apps/ditmesh` and run only the Flutter command for your destination. For interactive development, use `flutter devices` and `flutter run -d <device-id>` with the matching library already staged. A physical iOS device also requires development signing.

| Destination | Command in `apps/ditmesh` |
|---|---|
| macOS | `flutter build macos --release` |
| Linux | `flutter build linux --release` |
| Windows | `flutter build windows --release` |
| Android APK | `flutter build apk --release` |
| Android App Bundle | `flutter build appbundle --release` |
| iOS | `flutter build ios --release --no-codesign` |

Native outputs are under `build/native/<target>/` at the repository root. The native build also stages the macOS library in `apps/ditmesh/macos/Frameworks/`. Android reads `apps/ditmesh/android/app/src/main/jniLibs/` and iOS reads `apps/ditmesh/ios/Frameworks/tim2tox_ffi.xcframework`. Linux and Windows use the matching target directory when building the app.

After staging the native libraries, use `flutter build apk --release -PstoreRelease`
or `flutter build appbundle --release -PstoreRelease` for store builds. Provide
all four `DITMESH_ANDROID_*` keystore settings or configure
`apps/ditmesh/android/key.properties`. Gradle verifies the signed AAB and every
APK, including ABI splits, and rejects Android Debug certificates. Tagged
builds enable these checks through `DITMESH_DISTRIBUTION=1` and verify the final
APK and AAB against the owner's upload certificate.

Android SDK levels are pinned in `apps/ditmesh/android/app/build.gradle.kts` (`compileSdk` 36, `minSdk` 24, `targetSdk` 36) rather than inherited from the Flutter Gradle plugin, so a Flutter upgrade cannot move them silently; `ndkVersion` follows Flutter but must stay at r28 or newer. CI pins the same NDK (`ANDROID_NDK_VERSION` in `.github/workflows/native.yml`, 28.2.13676358 for Flutter 3.41.9) instead of the runner image's latest; `tool/ci/install_android_ndk.sh` installs it and fails if it differs from the Flutter SDK's `ndkVersion`, so bump both together. The Android native build links every library with 16 KB page-size flags and refuses to stage a `libtim2tox_ffi.so` or `libc++_shared.so` whose `PT_LOAD` segments are not 16 KB aligned (Google Play requirement for apps targeting Android 15+). CI repeats the check on the release APK, including the Flutter and plugin libraries, and verifies the APK's zip alignment with `zipalign -c -P 16`.

After the application build, run from the root:

```bash
bash tool/ci/package_artifacts.sh --target macos
# linux, windows, android and ios run on their respective build hosts.
```

`./build_all.sh --platform macos --mode release --package` combines bootstrap, native and app builds, and packaging. It writes `dist/macos/ditmesh-<version>-macos-<arch>.{pkg,zip}`, using the version from `apps/ditmesh/pubspec.yaml` and the Mac's architecture. Each platform writes its packages under `dist/`.

## CI and release

- Analyze runs strict app/package/tool analysis, complexity/layering/localization guards, screenshot importer checks and non-native tests.
- Native builds the required native libraries and application/package jobs. Dart/app/shared-package/pubspec changes trigger build coverage.
- Linux x86_64, Windows x64, macOS ARM/Intel, Android ARM64/ARMv7/x86_64 and iOS device/simulator transport are supported build targets. Experimental native ARM host jobs are separately opt-in.
- Tag release waits for validation and required applications. A `vX.Y.Z` tag must equal the `X.Y.Z` of `apps/ditmesh/pubspec.yaml` (`tool/ci/release_version.sh`, also run by Analyze), so bump the version before tagging. It verifies expected platform packages, generates SHA256SUMS and creates/updates a draft GitHub Release.
- Screenshots/E2E use seeded chat data and run on demand. Native integration tests exercise real Tox peers.

GitHub's workflow filter/needs behavior is documented in [workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax). Executed results are in the [verification record](../VALIDATION.md).

Packaging now checks actual PE/ELF/Mach-O architecture across the app, engine and plugins, with Windows MSI target metadata checked on the produced installer. Android checks all APK/AAB native libraries and final APK/AAB signatures; tag/distribution builds require the owner's expected certificate SHA-256 in `DITMESH_ANDROID_CERT_SHA256`. APK ZIP 16 KB placement applies to uncompressed `.so`; AAB-generated APK/device evidence remains required. macOS signs validation bundles inside out after staging, checks every final code signature/entitlement, and forbids `get-task-allow`. `--mode validation` is the default; unsupported formal `--mode distribution` paths fail rather than emit an unsigned/ad-hoc substitute. See the [channel matrix and commands](../release/STORE_READINESS.md).

## Signing

Configure Apple distribution certificates and provisioning for iOS, Developer ID signing and notarization for macOS, and a release/upload keystore for Android. Store credentials in CI secrets or local signing configuration. See [release requirements](../release/APP_STORE.md) and [Flutter iOS deployment](https://docs.flutter.dev/deployment/ios).

## Troubleshooting

| Symptom | Check |
|---|---|
| The workspace cannot resolve `tim2tox_dart` or the compatibility SDK | Run `dart run tool/bootstrap_deps.dart --offline-check-only` from the root. If the staged inputs are missing or stale, rerun bootstrap followed by `dart pub get --enforce-lockfile`. |
| Build or startup reports missing Tim2Tox | Stage the native library for the exact destination and CPU before running Flutter. For Android, include the device ABI. For iOS, check that the XCFramework contains the device or simulator slice you selected. |
| The app launches but stays offline | Test the selected node in the app. The network guide covers public-node failures, UDP limits and local-network permissions. [Bootstrap nodes and LAN hosting](NETWORK.md). |

For a UI-only run, see the app developer guide. The screenshot harness supplies its own demo data. [App developer guide](../../apps/ditmesh/README.md#run) · [Capture guide](../../tool/screenshots/README.md).

## Reproducibility

Record the source revision, Tim2Tox SHA, pinned Flutter/Dart versions and architecture with build results. `assert_no_test_hooks.sh` checks release FFI binaries.

Native builds apply the [source overlays](../../tool/ci/tim2tox-overlays/README.md) (group persistence, member connection status, isolated node probes) to a copied source tree. The pinned upstream checkout remains clean. Required Linux and both macOS jobs exercise real local UDP peers; a separate public-DHT smoke probe is opt-in. Refresh the reviewed bundled bootstrap node list against [official Tox node status](https://nodes.tox.chat/) before releases.

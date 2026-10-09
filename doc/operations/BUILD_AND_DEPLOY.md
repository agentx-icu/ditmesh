[简体中文](./BUILD_AND_DEPLOY.zh-CN.md)

# Build, CI and packaging

Use Flutter 3.41.9 / Dart 3.11.5 and a recursive checkout. Resolve only at the workspace root.

```bash
git submodule update --init --recursive
dart run tool/bootstrap_deps.dart
dart pub get
```

The bootstrap pins/patches the Dart compatibility SDK, applies the repository overlay that removes Tencent's native IM plugin and writes ignored dependency overrides. Tim2Tox links c-toxcore and pinned static libsodium; ToxAV is disabled.

It also stages the pinned Tim2Tox Dart package into ignored `third_party/tim2tox_ditmesh` and applies `tool/ci/tim2tox-dart-overlays` for original rhythm transport. The root override and lock refer to that copy. Run `dart run tool/bootstrap_deps.dart --offline-check-only` to verify it against the upstream sources and reviewed patches; re-run bootstrap after changing either. Keep the upstream submodule clean.

macOS application packages require **13.0 or later** on Intel and ARM. This satisfies the bundled Objective-C framework. The packager checks the application minimum against every actual embedded Mach-O architecture before generating ZIP/PKG; a dependency requiring a newer system blocks packaging. The transport library may support a lower system version without lowering the application requirement.

## Local target commands

```bash
# Run on a compatible target host/toolchain:
bash tool/ci/build_tim2tox.sh --target macos-arm64
# Other targets: macos-x86_64, linux-x86_64, windows-x64,
# android-arm64, android-armv7, android-x86_64, ios-device, ios-simulator

# Stage mobile libraries using the helpers:
bash tool/build_android_ffi.sh
bash tool/build_ios_ffi.sh

cd apps/ditmesh
flutter build macos --release
# On the corresponding host:
flutter build linux --release
flutter build windows --release
flutter build apk --release
flutter build appbundle --release
flutter build ios --release --no-codesign
```

Consult `--help` for the script's target spelling/options before a new host build. Desktop runner integration finds libraries in `build/native/`; Android stages jniLibs and iOS stages an XCFramework. Stage the required native libraries before building the application.

Android SDK levels are pinned in `apps/ditmesh/android/app/build.gradle.kts` (`compileSdk` 36, `minSdk` 24, `targetSdk` 36) rather than inherited from the Flutter Gradle plugin, so a Flutter upgrade cannot move them silently; `ndkVersion` follows Flutter but must stay at r28 or newer. The Android native build links every library with 16 KB page-size flags and refuses to stage a `libtim2tox_ffi.so` or `libc++_shared.so` whose `PT_LOAD` segments are not 16 KB aligned (Google Play requirement for apps targeting Android 15+). CI repeats the check on the release APK, including the Flutter and plugin libraries, and verifies the APK's zip alignment with `zipalign -c -P 16`.

After the application build, run from the root:

```bash
bash tool/ci/package_artifacts.sh --target macos
# linux, windows, android and ios run on their respective build hosts.
```

`./build_all.sh --platform macos --mode release --package` orchestrates native and application builds and writes `dist/macos/ditmesh-1.0.0-macos-arm64.{pkg,zip}`. Output packages are written to `dist/`.

## CI and release

- Analyze runs strict app/package/tool analysis, complexity/layering/localization guards, screenshot importer checks and non-native tests.
- Native builds the required native libraries and application/package jobs. Dart/app/shared-package/pubspec changes trigger build coverage.
- Linux x86_64, Windows x64, macOS ARM/Intel, Android ARM64/ARMv7/x86_64 and iOS device/simulator transport are supported build targets. Experimental native ARM host jobs are separately opt-in.
- Tag release waits for validation and required applications. It verifies expected platform packages, generates SHA256SUMS and creates/updates a draft GitHub Release.
- Screenshots/E2E use seeded chat data and run on demand. Native integration tests exercise real Tox peers.

GitHub's workflow filter/needs behavior is documented in [workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax). Executed results are in the [verification record](../VALIDATION.md).

## Signing

Configure Apple distribution certificates and provisioning for iOS, Developer ID signing and notarization for macOS, and a release/upload keystore for Android. Store credentials in CI secrets or local signing configuration. See [release requirements](../release/APP_STORE.md) and [Flutter iOS deployment](https://docs.flutter.dev/deployment/ios).

## Reproducibility and diagnostics

Record the source revision, Tim2Tox SHA, pinned Flutter/Dart versions and architecture with build results. `assert_no_test_hooks.sh` checks release FFI binaries. For UI development with seeded conversations, use `DITMESH_FAKE_BACKEND=true` and the missing-FFI option documented by the build scripts.

Native builds apply the [group-persistence overlay](../../tool/ci/tim2tox-overlays/README.md) to a copied source tree. The pinned upstream checkout remains clean. Required Linux and both macOS jobs exercise real local UDP peers; a separate public-DHT smoke probe is opt-in. Refresh the reviewed bundled bootstrap node list against [official Tox node status](https://nodes.tox.chat/) before releases.

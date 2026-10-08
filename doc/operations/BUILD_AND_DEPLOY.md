[简体中文](./BUILD_AND_DEPLOY.zh-CN.md)

# Build, CI and packaging

Use Flutter 3.41.9 / Dart 3.11.5 and a recursive checkout. Resolve only at the workspace root.

```bash
git submodule update --init --recursive
dart run tool/bootstrap_deps.dart
dart pub get
```

The bootstrap pins/patches the Dart compatibility SDK, applies the repository overlay that removes Tencent's native IM plugin and writes ignored dependency overrides. It is not a Tencent messaging-server integration. Tim2Tox links c-toxcore and pinned static libsodium; ToxAV is disabled.

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

Consult `--help` for the script's target spelling/options before a new host build. Desktop runner integration finds libraries in `build/native/`; Android stages jniLibs and iOS stages an XCFramework. Required libraries must be present; a complete release cannot silently become a UI demo.

After the application build, run from the root:

```bash
bash tool/ci/package_artifacts.sh --target macos
# linux, windows, android and ios run on their respective build hosts.
```

`./build_all.sh --platform macos --mode release --package` orchestrates native and application builds and writes `dist/macos/ditmesh-1.0.0-macos-arm64.{pkg,zip}`. Installers use DitMesh-specific product identifiers and upgrade identity. Output packages stay in ignored `dist/`, not Git.

## CI and release

- Analyze runs strict app/package/tool analysis, complexity/layering/localization guards, screenshot importer checks and non-native tests.
- Native builds the required native libraries and application/package jobs. Dart/app/shared-package/pubspec changes trigger build coverage.
- Linux x86_64, Windows x64, macOS ARM/Intel, Android ARM64/ARMv7/x86_64 and iOS device/simulator transport are supported build targets. Experimental native ARM host jobs are separately opt-in.
- Tag release waits for validation and required applications. It verifies expected platform packages, generates SHA256SUMS and creates/updates a draft GitHub Release.
- Screenshots/E2E use the explicitly fake backend and are opt-in. This is deliberate demo data, never production transport validation.

GitHub's workflow filter/needs behavior is documented in [workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax). A workflow definition alone is not a completed remote build; see [the exact verification record](../VALIDATION.md).

## Signing

Source/CI iOS IPA is unsigned; macOS artifacts are not notarized unless owner credentials and a separate signing step are configured. Android store upload requires a release/upload keystore. Keep secrets in CI secret storage and never commit them. See [release requirements](../release/APP_STORE.md) and [Flutter iOS deployment](https://docs.flutter.dev/deployment/ios).

## Reproducibility and diagnostics

Record the source revision, Tim2Tox SHA, pinned Flutter/Dart versions and architecture with build results. `assert_no_test_hooks.sh` checks release FFI binaries. Package checksums do not replace code signing. For deliberate fake UI-only development, use the documented missing-FFI escape plus `DITMESH_FAKE_BACKEND=true`; do not ship such builds as working chat clients.

Native builds apply the [group-persistence overlay](../../tool/ci/tim2tox-overlays/README.md) to a copied source tree. The pinned upstream checkout remains clean. Required Linux and both macOS jobs exercise real local UDP peers; a separate public-DHT smoke probe is opt-in. Refresh the reviewed bundled bootstrap node list against [official Tox node status](https://nodes.tox.chat/) before releases.

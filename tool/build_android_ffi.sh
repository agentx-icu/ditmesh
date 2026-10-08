#!/usr/bin/env bash
#
# build_android_ffi.sh — cross-compile libtim2tox_ffi.so for Android via the
# NDK and stage it into apps/ditmesh/android/app/src/main/jniLibs/<abi>/, where
# the Flutter Gradle build packages it (apps/ditmesh/android/app/build.gradle.kts
# packages exactly the ABIs that have a libtim2tox_ffi.so and refuses to build
# an APK without one).
#
# Thin wrapper over tool/ci/build_tim2tox.sh --target android (the one place the
# CMake flags — including the 16 KB page-size link flags Google Play requires
# for 64-bit libraries — the pinned static libsodium and the post-build gates
# live; an unaligned libtim2tox_ffi.so or libc++_shared.so fails the build).
# Equivalent of toxee's tool/build_android_ffi.sh with ToxAV permanently off.
#
# Env overrides:
#   ABIS         space- or comma-separated (default "arm64-v8a";
#                e.g. "arm64-v8a armeabi-v7a x86_64" — x86_64 for emulators)
#   ANDROID_API  lowest API level the .so targets (default 21; the app's
#                minSdk is 24, pinned in apps/ditmesh/android/app/build.gradle.kts,
#                so a 21 library runs on every supported device)
#   NDK / ANDROID_NDK_HOME / ANDROID_NDK_ROOT / ANDROID_HOME  NDK discovery
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
JNI_LIBS="$REPO_ROOT/apps/ditmesh/android/app/src/main/jniLibs"

ABIS="${ABIS:-arm64-v8a}"
ABIS_CSV="$(printf '%s' "$ABIS" | tr ' ' ',')"

GREEN='\033[0;32m'; NC='\033[0m'
info() { echo -e "${GREEN}[android-ffi]${NC} $*" >&2; }

info "ABIs: $ABIS_CSV (API ${ANDROID_API:-21})"
DITMESH_ANDROID_API="${ANDROID_API:-21}" \
  bash "$SCRIPT_DIR/ci/build_tim2tox.sh" --target android --android-abis "$ABIS_CSV" "$@"

info "DONE. jniLibs:"
ls -1 "$JNI_LIBS"/*/libtim2tox_ffi.so >&2
if command -v file >/dev/null 2>&1; then
  for so in "$JNI_LIBS"/*/libtim2tox_ffi.so; do file "$so" >&2; done
fi

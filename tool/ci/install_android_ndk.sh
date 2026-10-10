#!/usr/bin/env bash
#
# install_android_ndk.sh — make the CI Android NDK the pinned one.
#
# Usage: ANDROID_NDK_VERSION=<x.y.z> bash tool/ci/install_android_ndk.sh
#
# The runner image ships several NDKs and moves ANDROID_NDK_LATEST_HOME
# whenever it is updated, so taking "whatever the image calls latest" lets an
# image refresh change the toolchain that links libtim2tox_ffi.so and
# libc++_shared.so without a commit. This script:
#   1. refuses a pin that differs from the ndkVersion the Flutter SDK on PATH
#      gives the app (apps/ditmesh/android/app/build.gradle.kts uses
#      flutter.ndkVersion), so the native library and the plugin code are
#      linked by the same NDK; a Flutter bump must bump the pin with it;
#   2. installs the pinned NDK with sdkmanager unless the image has it;
#   3. exports ANDROID_NDK_HOME / ANDROID_NDK_ROOT to later steps
#      ($GITHUB_ENV), which find_android_ndk() in build_tim2tox.sh prefers.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tool/ci/common.sh
source "$SCRIPT_DIR/common.sh"

version="${ANDROID_NDK_VERSION:-}"
[[ -n "$version" ]] || ci_die "ANDROID_NDK_VERSION is not set"
sdk_root="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
[[ -n "$sdk_root" && -d "$sdk_root" ]] || ci_die "ANDROID_HOME / ANDROID_SDK_ROOT is not set to an SDK"

# 1. The pin must be the NDK Flutter selects for the app.
if command -v flutter >/dev/null 2>&1; then
  flutter_root="$(cd "$(dirname "$(command -v flutter)")/.." && pwd)"
  ext="$flutter_root/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt"
  [[ -f "$ext" ]] || ci_die "Cannot read Flutter's ndkVersion: $ext missing (update this check)"
  flutter_ndk="$(sed -n 's/.*val ndkVersion: String = "\([^"]*\)".*/\1/p' "$ext" | head -n 1)"
  [[ -n "$flutter_ndk" ]] || ci_die "Cannot parse ndkVersion from $ext (update this check)"
  [[ "$flutter_ndk" == "$version" ]] ||
    ci_die "ANDROID_NDK_VERSION=$version but Flutter's ndkVersion is $flutter_ndk; bump the pin with Flutter"
else
  ci_warn "flutter not on PATH; cannot compare the pin with Flutter's ndkVersion"
fi

# 2. Install unless present and complete.
ndk="$sdk_root/ndk/$version"
if [[ -f "$ndk/build/cmake/android.toolchain.cmake" ]]; then
  ci_log "Android NDK $version already installed at $ndk"
else
  sdkmanager=""
  for candidate in "$sdk_root/cmdline-tools/latest/bin/sdkmanager" "$(command -v sdkmanager || true)"; do
    if [[ -n "$candidate" && -x "$candidate" ]]; then sdkmanager="$candidate"; break; fi
  done
  [[ -n "$sdkmanager" ]] || ci_die "sdkmanager not found under $sdk_root/cmdline-tools/latest/bin or on PATH"
  for attempt in 1 2 3; do
    ci_log "Installing Android NDK $version (attempt $attempt)"
    if (yes 2>/dev/null || true) | "$sdkmanager" --sdk_root="$sdk_root" --install "ndk;$version" >/dev/null &&
      [[ -f "$ndk/build/cmake/android.toolchain.cmake" ]]; then
      break
    fi
    [[ $attempt -lt 3 ]] || ci_die "sdkmanager could not install ndk;$version"
    sleep $((attempt * 15))
  done
fi

source_properties="$ndk/source.properties"
installed="$(sed -n 's/^Pkg.Revision *= *//p' "$source_properties" 2>/dev/null | tr -d '[:space:]')"
[[ "$installed" == "$version" ]] ||
  ci_die "$ndk reports Pkg.Revision '$installed', expected $version"

# 3. Hand it to later steps.
if [[ -n "${GITHUB_ENV:-}" ]]; then
  {
    echo "ANDROID_NDK_HOME=$ndk"
    echo "ANDROID_NDK_ROOT=$ndk"
  } >> "$GITHUB_ENV"
fi
ci_log "ANDROID_NDK_HOME=$ndk (NDK $installed)"

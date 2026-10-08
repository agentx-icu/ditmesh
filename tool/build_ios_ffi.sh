#!/usr/bin/env bash
#
# build_ios_ffi.sh — build libtim2tox_ffi for iOS (device arm64 + universal
# simulator) and assemble apps/ditmesh/ios/Frameworks/tim2tox_ffi.xcframework,
# the artifact apps/ditmesh/ios/Podfile vendors (Frameworks/Tim2ToxFFI.podspec).
#
# Why an XCFramework rather than toxee's per-PLATFORM_NAME Xcode script phase:
# one artifact carries both the iphoneos and the iphonesimulator slice, so
# `flutter run` on a simulator, `flutter build ios` and an App Store archive all
# embed the right one through CocoaPods' standard vendored-framework path — no
# hand edits to project.pbxproj. The Dart loaders find it at
# <app>/Frameworks/tim2tox_ffi.framework/tim2tox_ffi.
#
# Usage: tool/build_ios_ffi.sh [--device-only | --simulator-only] [build_tim2tox.sh options]
# Env:   DITMESH_IOS_SIM_ARCHS (default "arm64 x86_64"), DITMESH_IOS_MIN (14.0)
#        DITMESH_IOS_XCFRAMEWORK_DIR (default apps/ditmesh/ios/Frameworks)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_IOS="$REPO_ROOT/apps/ditmesh/ios"
NATIVE_ROOT="${DITMESH_NATIVE_ARTIFACTS_DIR:-${DITMESH_NATIVE_BUILD_ROOT:-$REPO_ROOT/build/native}}"
XC_DIR="${DITMESH_IOS_XCFRAMEWORK_DIR:-$APP_IOS/Frameworks}"
XC_OUT="$XC_DIR/tim2tox_ffi.xcframework"

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}[ios-ffi]${NC} $*" >&2; }
err()  { echo -e "${RED}[ios-ffi]${NC} $*" >&2; }

[[ "$OSTYPE" == darwin* ]] || { err "macOS only (needs Xcode)"; exit 1; }
command -v xcodebuild >/dev/null || { err "xcodebuild missing"; exit 1; }

BUILD_DEVICE=1
BUILD_SIM=1
PASS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --device-only) BUILD_SIM=0; shift ;;
    --simulator-only) BUILD_DEVICE=0; shift ;;
    --help|-h)
      sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) PASS+=("$1"); shift ;;
  esac
done

SLICES=()
if [[ "$BUILD_DEVICE" -eq 1 ]]; then
  bash "$SCRIPT_DIR/ci/build_tim2tox.sh" --target ios-device "${PASS[@]}"
  SLICES+=("$NATIVE_ROOT/ios-device/tim2tox_ffi.framework")
fi
if [[ "$BUILD_SIM" -eq 1 ]]; then
  bash "$SCRIPT_DIR/ci/build_tim2tox.sh" --target ios-simulator "${PASS[@]}"
  SLICES+=("$NATIVE_ROOT/ios-simulator/tim2tox_ffi.framework")
fi

# A partial (single-slice) XCFramework is still valid; it just cannot serve
# the other destination. Never merge into an existing one — a stale slice from
# a previous build must not survive.
ARGS=()
for fw in "${SLICES[@]}"; do
  [[ -d "$fw" ]] || { err "missing slice: $fw"; exit 1; }
  ARGS+=(-framework "$fw")
done
mkdir -p "$XC_DIR"
rm -rf "$XC_OUT"
info "assembling $XC_OUT from ${#SLICES[@]} slice(s)"
xcodebuild -create-xcframework "${ARGS[@]}" -output "$XC_OUT"

# Gate the bytes about to be embedded (the podspec vendors this directory as-is).
bash "$SCRIPT_DIR/ci/assert_no_test_hooks.sh" "$XC_OUT"
codesign --force --sign - --deep "$XC_OUT" >/dev/null 2>&1 || true

# CocoaPods only picks the vendored pod up when Podfile is newer than
# Podfile.lock (flutter's pod-install trigger); make the next build re-install.
[[ -f "$APP_IOS/Podfile" ]] && touch "$APP_IOS/Podfile"

info "XCFramework: $XC_OUT"
find "$XC_OUT" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sed 's/^/  slice: /' >&2
echo -e "${GREEN}[ios-ffi] DONE${NC}" >&2

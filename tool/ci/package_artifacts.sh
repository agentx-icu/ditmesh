#!/usr/bin/env bash
# Turns one platform's release build into the files a GitHub release ships,
# under dist/<target>/ (modelled on toxee/tool/ci/package_artifacts.sh):
#
#   linux    ditmesh-<v>-linux-x86_64.{deb,rpm,tar.gz}   (CPack, tool/ci/linux-installer)
#   windows  ditmesh-<v>-windows-x64.{msi,zip}           (CPack + WiX v3, tool/ci/windows-installer)
#   macos    ditmesh-<v>-macos-<arm64|x86_64>.{pkg,zip} (pkgbuild into /Applications; ditto zip)
#   android  ditmesh-<v>-android.{apk,aab}
#   ios      ditmesh-<v>-ios-unsigned.ipa                (no signing identity on CI)
#
# Run from anywhere after the matching `flutter build <target> --release`
# (the Native workflow does both). <v> comes from apps/ditmesh/pubspec.yaml;
# tagged builds require an exactly matching vX.Y.Z tag. Every package must
# carry the Tox backend (libtim2tox_ffi); a build without it is refused.
#
#   tool/ci/package_artifacts.sh --target <linux|windows|macos|android|ios> [--arch <arm64|x86_64>]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tool/ci/common.sh
source "$SCRIPT_DIR/common.sh"

TARGET=""
ARCH=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --arch) ARCH="${2:-}"; shift 2 ;;
    --help|-h) sed -n '2,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) ci_die "Unknown option: $1" ;;
  esac
done
[[ -n "$TARGET" ]] || ci_die "--target is required"

REPO_ROOT="$(ci_repo_root)"
APP_DIR="$REPO_ROOT/apps/ditmesh"
BUILD_DIR="$APP_DIR/build"
DIST_DIR="$REPO_ROOT/dist/$TARGET"
ci_reset_dir "$DIST_DIR"

VERSION="$(bash "$SCRIPT_DIR/release_version.sh")"
BUILD_NUMBER="$(bash "$SCRIPT_DIR/release_version.sh" --build-number)"
BASE="ditmesh-$VERSION"

# Copies the single top-level file in <dir> matching <glob> to <dest>
# (CPack leaves its staging trees in subdirectories; only the root holds
# the finished package).
copy_one() {  # <dir> <glob> <dest>
  local -a hits=()
  while IFS= read -r f; do hits+=("$f"); done < <(find "$1" -maxdepth 1 -type f -name "$2")
  [[ ${#hits[@]} -eq 1 ]] || ci_die "expected exactly one $2 in $1, found ${#hits[@]}"
  cp "${hits[0]}" "$3"
}

# The Tox backend must be inside what ships, and must not carry the Tim2Tox
# auto_tests-only hooks.
require_ffi() {  # <path> <label>
  [[ -e "$1" ]] || ci_die "$2: libtim2tox_ffi missing at $1 -- refusing to package a build without the Tox backend"
  bash "$SCRIPT_DIR/assert_no_test_hooks.sh" "$1"
}

check_apple_metadata() {  # <Info.plist>
  local actual_version actual_build actual_id
  actual_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$1")"
  actual_build="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$1")"
  actual_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$1")"
  [[ "$actual_version" == "$VERSION" && "$actual_build" == "$BUILD_NUMBER" ]] ||
    ci_die "bundle version $actual_version+$actual_build does not match $VERSION+$BUILD_NUMBER"
  [[ "$actual_id" == icu.agentx.ditmesh ]] || ci_die "wrong bundle identifier: $actual_id"
}

package_linux() {
  local bundle="$BUILD_DIR/linux/x64/release/bundle" stage installer
  [[ -x "$bundle/ditmesh" ]] || ci_die "Linux bundle not found: $bundle"
  require_ffi "$bundle/lib/libtim2tox_ffi.so" linux

  stage="$DIST_DIR/.stage/ditmesh"
  mkdir -p "$stage"
  cp -a "$bundle/." "$stage/"
  tar -C "$DIST_DIR/.stage" -czf "$DIST_DIR/$BASE-linux-x86_64.tar.gz" ditmesh

  ci_require_cmd cpack
  installer="$REPO_ROOT/build/linux-installer"
  rm -rf "$installer"
  cmake -S "$SCRIPT_DIR/linux-installer" -B "$installer" \
    -DDITMESH_INSTALLER_SOURCE_DIR="$stage" \
    -DDITMESH_RELEASE_VERSION="$VERSION" \
    -DDITMESH_PACKAGE_ARCH=x86_64 \
    -DDITMESH_DEB_ARCH=amd64 \
    -DDITMESH_RPM_ARCH=x86_64 >/dev/null
  (cd "$installer" && cpack -G "DEB;RPM")
  copy_one "$installer" '*.deb' "$DIST_DIR/$BASE-linux-x86_64.deb"
  copy_one "$installer" '*.rpm' "$DIST_DIR/$BASE-linux-x86_64.rpm"
  rm -rf "$DIST_DIR/.stage"
}

package_windows() {
  local runner="$BUILD_DIR/windows/x64/runner/Release" stage installer
  [[ -f "$runner/ditmesh.exe" ]] || ci_die "Windows runner not found: $runner"
  require_ffi "$runner/tim2tox_ffi.dll" windows

  stage="$DIST_DIR/.stage/ditmesh"
  mkdir -p "$stage"
  cp -R "$runner/." "$stage/"
  (cd "$DIST_DIR/.stage" && 7z a -tzip -bd -bso0 "$(ci_windows_path "$DIST_DIR")/$BASE-windows-x64.zip" ditmesh)

  ci_require_cmd cpack
  installer="$REPO_ROOT/build/windows-installer"
  rm -rf "$installer"
  cmake -S "$SCRIPT_DIR/windows-installer" -B "$installer" \
    -DDITMESH_INSTALLER_SOURCE_DIR="$(ci_windows_path "$stage")" \
    -DDITMESH_RELEASE_VERSION="$VERSION" \
    -DDITMESH_PACKAGE_ARCH=x64 >/dev/null
  (cd "$installer" && cpack -C Release -G WIX)
  copy_one "$installer" '*.msi' "$DIST_DIR/$BASE-windows-x64.msi"
  rm -rf "$DIST_DIR/.stage"
}

package_macos() {
  local app="$BUILD_DIR/macos/Build/Products/Release/DitMesh.app" root plist
  [[ -d "$app" ]] || ci_die "macOS app not found: $app"
  require_ffi "$app/Contents/Frameworks/libtim2tox_ffi.dylib" macos
  [[ -n "$ARCH" ]] || ARCH="$(uname -m)"
  case "$ARCH" in arm64|x86_64) ;; *) ci_die "Unsupported macOS architecture: $ARCH" ;; esac
  lipo "$app/Contents/MacOS/DitMesh" -verify_arch "$ARCH"
  lipo "$app/Contents/Frameworks/libtim2tox_ffi.dylib" -verify_arch "$ARCH"
  check_apple_metadata "$app/Contents/Info.plist"

  python3 "$SCRIPT_DIR/macos_runtime.py" "$app"

  # ditto keeps the bundle's symlinks, modes and signature intact.
  ditto -c -k --sequesterRsrc --keepParent "$app" "$DIST_DIR/$BASE-macos-$ARCH.zip"

  # Installer package into /Applications. Not relocatable: without this,
  # Installer "upgrades" any other copy of the bundle id it finds on disk
  # (e.g. a debug build) instead of installing to /Applications.
  root="$DIST_DIR/.root"
  plist="$DIST_DIR/.component.plist"
  mkdir -p "$root"
  ditto "$app" "$root/DitMesh.app"
  pkgbuild --analyze --root "$root" "$plist" >/dev/null
  # pkgbuild lists nested frameworks before the app: index 0 is not the app.
  # Select the app by path and disallow relocation for its entire bundle tree.
  python3 "$SCRIPT_DIR/macos_components.py" "$plist"
  pkgbuild --root "$root" --component-plist "$plist" \
    --identifier icu.agentx.ditmesh --version "$VERSION" \
    --install-location /Applications "$DIST_DIR/$BASE-macos-$ARCH.pkg"
  rm -rf "$root" "$plist"
}

package_android() {
  local apk="$BUILD_DIR/app/outputs/flutter-apk/app-release.apk"
  local aab="$BUILD_DIR/app/outputs/bundle/release/app-release.aab"
  [[ -f "$apk" ]] || ci_die "Android APK not found: $apk"
  [[ -f "$aab" ]] || ci_die "Android App Bundle not found: $aab"
  # Listing captured first: `unzip | grep -q` under pipefail can SIGPIPE unzip.
  local listing lib abi archive prefix
  for archive in "$apk" "$aab"; do
    listing="$(unzip -Z1 "$archive")"
    prefix="lib"; [[ "$archive" == "$aab" ]] && prefix="base/lib"
    for abi in arm64-v8a armeabi-v7a x86_64; do
      for lib in libtim2tox_ffi.so libc++_shared.so; do
        grep -Fx "$prefix/$abi/$lib" <<<"$listing" >/dev/null ||
          ci_die "android: $archive carries no $abi $lib -- refusing to package"
        local staged="$DIST_DIR/.check-$abi-$lib"
        unzip -p "$archive" "$prefix/$abi/$lib" > "$staged"
        [[ -s "$staged" ]] || ci_die "android: empty $abi/$lib in $archive"
        [[ "$lib" != libtim2tox_ffi.so ]] || require_ffi "$staged" android
        rm -f "$staged"
      done
    done
  done
  cp "$apk" "$DIST_DIR/$BASE-android.apk"
  cp "$aab" "$DIST_DIR/$BASE-android.aab"
}

package_ios() {
  local app="$BUILD_DIR/ios/iphoneos/Runner.app" payload
  [[ -d "$app" ]] || ci_die "iOS app not found: $app"
  require_ffi "$app/Frameworks/tim2tox_ffi.framework/tim2tox_ffi" ios
  check_apple_metadata "$app/Info.plist"
  # Unsigned: sideload tools (AltStore, Sideloadly) or a re-sign step sign it.
  payload="$DIST_DIR/.ipa/Payload"
  mkdir -p "$payload"
  ditto "$app" "$payload/Runner.app"
  (cd "$DIST_DIR/.ipa" && zip -qry "$DIST_DIR/$BASE-ios-unsigned.ipa" Payload)
  rm -rf "$DIST_DIR/.ipa"
}

case "$TARGET" in
  linux) package_linux ;;
  windows) package_windows ;;
  macos) package_macos ;;
  android) package_android ;;
  ios) package_ios ;;
  *) ci_die "Unsupported target: $TARGET" ;;
esac

ci_log "[$TARGET] packages in $DIST_DIR:"
ls -l "$DIST_DIR"

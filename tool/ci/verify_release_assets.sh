#!/usr/bin/env bash
# Required platform packages must be complete before creating a draft release.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
[[ $# -eq 2 ]] || ci_die "Usage: verify_release_assets.sh <dist-dir> <vX.Y.Z>"
DIST_DIR="$1"
VERSION="$(GITHUB_REF_TYPE=tag GITHUB_REF_NAME="$2" bash "$SCRIPT_DIR/release_version.sh")"
BASE="ditmesh-$VERSION"
ASSETS=(
  "$BASE-linux-x86_64.deb" "$BASE-linux-x86_64.rpm" "$BASE-linux-x86_64.tar.gz"
  "$BASE-windows-x64.msi" "$BASE-windows-x64.zip"
  "$BASE-macos-arm64.pkg" "$BASE-macos-arm64.zip"
  "$BASE-macos-x86_64.pkg" "$BASE-macos-x86_64.zip"
  "$BASE-android.apk" "$BASE-android.aab" "$BASE-ios-unsigned.ipa"
)
[[ -d "$DIST_DIR" ]] || ci_die "Missing release directory: $DIST_DIR"
for asset in "${ASSETS[@]}"; do
  [[ -s "$DIST_DIR/$asset" ]] || ci_die "Required release asset missing or empty: $asset"
done
for path in "$DIST_DIR"/*; do
  name="$(basename "$path")"
  [[ "$name" != SHA256SUMS ]] || continue
  found=false
  for asset in "${ASSETS[@]}"; do
    [[ "$asset" != "$name" ]] || found=true
  done
  [[ "$found" == true ]] || ci_die "Unexpected release asset: $name"
done
(
  cd "$DIST_DIR"
  # Fixed array order and leaf names make the manifest portable across hosts.
  : > SHA256SUMS
  for asset in "${ASSETS[@]}"; do
    printf '%s  %s\n' "$(ci_sha256_file "$asset")" "$asset" >> SHA256SUMS
  done
)
ci_log "Verified ${#ASSETS[@]} required release assets; wrote $DIST_DIR/SHA256SUMS"

#!/usr/bin/env bash
# One version for bundle metadata, installer names and release assets.
# A vX.Y.Z tag must match the app pubspec exactly; bump it before tagging.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
APP_SPEC="${DITMESH_APP_PUBSPEC:-$(ci_repo_root)/apps/ditmesh/pubspec.yaml}"
VERSION="$(sed -nE 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+)\+[0-9]+[[:space:]]*$/\1/p' "$APP_SPEC")"
BUILD_NUMBER="$(sed -nE 's/^version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+\+([0-9]+)[[:space:]]*$/\1/p' "$APP_SPEC")"
[[ "$VERSION" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] ||
  ci_die "app version must be X.Y.Z+BUILD in $APP_SPEC"
if [[ "${GITHUB_REF_TYPE:-}" == tag ]]; then
  [[ "${GITHUB_REF_NAME:-}" == "v$VERSION" ]] ||
    ci_die "tag ${GITHUB_REF_NAME:-<missing>} does not match app version v$VERSION"
fi
case "${1:-}" in
  '') printf '%s\n' "$VERSION" ;;
  --build-number) printf '%s\n' "$BUILD_NUMBER" ;;
  *) ci_die "Usage: release_version.sh [--build-number]" ;;
esac

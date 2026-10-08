#!/usr/bin/env bash
# flutter_soloud stores generated CMake files inside the Pub package directory.
# Those files embed absolute Xcode/compiler paths and cannot move between SDKs.
set -euo pipefail
[[ $# -eq 1 ]] || { echo "Usage: clean_apple_plugin_cache.sh <macos|ios>" >&2; exit 1; }
case "$1" in
  macos|ios) platform="$1" ;;
  *) echo "Unsupported Apple platform: $1" >&2; exit 1 ;;
esac
cache_root="${PUB_CACHE:-$HOME/.pub-cache}"
shopt -s nullglob
for generated in "$cache_root"/hosted/*/flutter_soloud-*/"$platform"/cmake_build; do
  echo "Removing generated plugin output: $generated"
  rm -rf -- "$generated"
done

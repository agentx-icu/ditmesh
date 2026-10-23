#!/usr/bin/env bash
# Local archive/export using existing owner identity only; no account changes.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# argparse accepts only the reviewed helper options, never arbitrary Flutter/Xcode flags.
exec python3 "$repo/tool/ci/ios_store_export.py" "$@"

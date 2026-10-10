#!/usr/bin/env bash
# Runs every apps/ditmesh/integration_test/*_test.dart on one device with the
# in-memory backend, one `flutter test` per file: several integration files
# in one run fail to attach to the second app launch on a desktop device.
#
#   bash tool/ci/run_integration_tests.sh <device-id> [extra flutter test args]
#
# Every file runs even after a failure; the exit status is non-zero when any
# failed, and the summary names them.
set -uo pipefail
[[ $# -ge 1 ]] || { echo "Usage: run_integration_tests.sh <device-id> [args...]" >&2; exit 64; }
device="$1"; shift
cd "$(dirname "${BASH_SOURCE[0]}")/../../apps/ditmesh" || exit 1
failed=()
for f in integration_test/*_test.dart; do
  echo "::group::$f on $device"
  start=$SECONDS
  if flutter test "$f" -d "$device" --dart-define=DITMESH_FAKE_BACKEND=true "$@"; then
    echo "$f: passed in $((SECONDS - start)) s"
  else
    echo "::error::$f failed on $device"
    failed+=("$f")
  fi
  echo "::endgroup::"
done
if [[ ${#failed[@]} -gt 0 ]]; then
  echo "failed on $device: ${failed[*]}" >&2
  exit 1
fi
echo "every integration test passed on $device"

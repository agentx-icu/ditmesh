#!/usr/bin/env bash
# Boots an iPhone simulator of the newest installed iOS runtime and prints
# its UDID (the device id `flutter test -d` takes). Diagnostics go to stderr.
#
#   udid="$(bash tool/ci/boot_ios_simulator.sh)"
set -euo pipefail
udid="$(xcrun simctl list devices available -j | python3 -c '
import json, re, sys
devices = json.load(sys.stdin)["devices"]
def version(runtime):
    m = re.search(r"iOS-(\d+)-(\d+)", runtime)
    return (int(m.group(1)), int(m.group(2))) if m else None
for runtime in sorted((r for r in devices if version(r)), key=version, reverse=True):
    for device in devices[runtime]:
        if device["name"].startswith("iPhone"):
            print(device["udid"])
            sys.exit(0)
sys.exit("no available iPhone simulator")
')"
echo "booting simulator $udid" >&2
xcrun simctl boot "$udid" 2>/dev/null || true  # already booted is fine
xcrun simctl bootstatus "$udid" -b >&2
echo "$udid"

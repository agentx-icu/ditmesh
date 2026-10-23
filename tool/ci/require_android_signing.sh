#!/usr/bin/env bash
# Branch CI validates with a debug key. Tags/distribution require owner identity.
set -euo pipefail
[[ "${GITHUB_REF_TYPE:-}" == tag || "${DITMESH_DISTRIBUTION:-}" == 1 ]] || exit 0
for name in DITMESH_ANDROID_KEYSTORE DITMESH_ANDROID_KEYSTORE_PASSWORD \
            DITMESH_ANDROID_KEY_ALIAS DITMESH_ANDROID_KEY_PASSWORD DITMESH_ANDROID_CERT_SHA256; do
  if [[ -z "${!name:-}" ]]; then
    echo "Android release signing is required for tags/distribution; missing $name" >&2
    exit 1
  fi
done

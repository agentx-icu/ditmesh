#!/usr/bin/env bash
# Branch CI can validate without release credentials. Tags must be publishable.
set -euo pipefail
[[ "${GITHUB_REF_TYPE:-}" == tag ]] || exit 0
for name in DITMESH_ANDROID_KEYSTORE DITMESH_ANDROID_KEYSTORE_PASSWORD \
            DITMESH_ANDROID_KEY_ALIAS DITMESH_ANDROID_KEY_PASSWORD; do
  if [[ -z "${!name:-}" ]]; then
    echo "Android release signing is required for tags; missing $name" >&2
    exit 1
  fi
done

#!/usr/bin/env bash
#
# common.sh — shared helpers for the ditmesh native-library / CI scripts.
# Sourced by tool/ci/*.sh; not meant to be executed directly.
# Ported from toxee's tool/ci/common.sh (same org, same Tim2Tox bridge).

set -euo pipefail

# All diagnostics go to STDERR so that helpers whose stdout is captured with
# $(...) (fetch_libsodium_source, build_ios_slice, ...) return only their value.
ci_log() {
  printf '[ci] %s\n' "$*" >&2
}

ci_warn() {
  printf '[ci][warn] %s\n' "$*" >&2
}

ci_die() {
  printf '[ci][error] %s\n' "$*" >&2
  exit 1
}

ci_require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || ci_die "Missing required command: $cmd"
}

# Repository root (this file lives at <root>/tool/ci/common.sh).
ci_repo_root() {
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
  printf '%s\n' "$dir"
}

ci_host_os() {
  if [[ -n "${RUNNER_OS:-}" ]]; then
    # bash 3.x (macOS) has no ${var,,}; tr is portable.
    printf '%s\n' "$(printf '%s' "${RUNNER_OS}" | tr '[:upper:]' '[:lower:]')"
    return
  fi

  case "$(uname -s)" in
    Darwin) printf '%s\n' "macos" ;;
    Linux) printf '%s\n' "linux" ;;
    MINGW*|MSYS*|CYGWIN*) printf '%s\n' "windows" ;;
    *) printf '%s\n' "unknown" ;;
  esac
}

# Normalised host CPU: x86_64 | aarch64 | unknown.
ci_host_arch() {
  local m
  m="$(uname -m 2>/dev/null || printf 'unknown')"
  case "$m" in
    x86_64|amd64|AMD64) printf '%s\n' "x86_64" ;;
    aarch64|arm64|ARM64) printf '%s\n' "aarch64" ;;
    *) printf '%s\n' "unknown" ;;
  esac
}

ci_cpu_count() {
  if command -v nproc >/dev/null 2>&1; then
    nproc
    return
  fi

  if command -v sysctl >/dev/null 2>&1; then
    sysctl -n hw.ncpu
    return
  fi

  if command -v getconf >/dev/null 2>&1; then
    getconf _NPROCESSORS_ONLN
    return
  fi

  printf '%s\n' "4"
}

ci_mode_dirname() {
  case "$1" in
    debug) printf '%s\n' "Debug" ;;
    profile) printf '%s\n' "Profile" ;;
    release) printf '%s\n' "Release" ;;
    *) ci_die "Unknown build mode: $1" ;;
  esac
}

# Git Bash / MSYS path -> Windows-style path (cmake, pkgconf and MSBuild are
# native tools and cannot read /c/... paths).
ci_windows_path() {
  local path="$1"
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$path"
  else
    printf '%s\n' "$path"
  fi
}

ci_reset_dir() {
  local dir="$1"
  rm -rf "$dir"
  mkdir -p "$dir"
}

# Copy the first file under $1 whose basename matches glob $2 into $3.
# Prints the source path; returns 1 when nothing matched.
ci_copy_matching_file() {
  local search_root="$1"
  local pattern="$2"
  local destination_dir="$3"
  local match

  match="$(find "$search_root" -type f -name "$pattern" | head -n 1 || true)"
  if [[ -n "$match" ]]; then
    mkdir -p "$destination_dir"
    cp "$match" "$destination_dir/"
    printf '%s\n' "$match"
    return 0
  fi

  return 1
}

ci_sha256_file() {
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
    return
  fi

  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
    return
  fi

  ci_die "Missing sha256 tool"
}

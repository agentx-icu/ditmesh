#!/usr/bin/env bash
#
# build_tim2tox.sh — build libtim2tox_ffi (the Tim2Tox C++ FFI shim + c-toxcore
# + libsodium) for one ditmesh target and stage it where the app build picks it
# up.
#
# Ported from toxee's tool/ci/build_tim2tox.sh with ditmesh's defaults:
#   * ToxAV is OFF and cannot be turned on (ditmesh has no calls; opus/libvpx
#     are never fetched, never linked). `--toxav` is rejected, not ignored.
#   * sqlite3 is OFF by default on every platform (Tim2Tox only uses it for
#     V2TIMCommunityManager persistence, which ditmesh does not use), so the
#     desktop libraries have no system dependency beyond libc/libstdc++.
#     `--with-sqlite` restores toxee's desktop behaviour.
#   * libsodium 1.0.20 is built from the pinned, SHA-256-verified release
#     tarball and linked STATICALLY on Linux/macOS/Android/iOS, so exactly one
#     file per platform has to be bundled and no install-name / RUNPATH
#     rewriting toward a sibling libsodium is needed. Windows uses vcpkg's
#     libsodium + pthreads like toxee (captured next to the DLL).
#     `--system-libsodium` (Linux/macOS) uses pkg-config / Homebrew instead and
#     captures the shared libsodium the way toxee does.
#   * Targets are arch-explicit; `linux`/`macos`/`windows` resolve to the host
#     arch and `ios` to `ios-device`.
#   * Android libraries are linked 16 KB page-aligned (Google Play requirement
#     for 64-bit libraries) and every staged .so is checked with readelf; see
#     ANDROID_PAGE_SIZE_LDFLAGS / assert_android_page_alignment.
#   * Everything lands under build/native/ (artifacts in build/native/<target>/,
#     build trees in build/native/.work/, deps in build/native/.deps/), never
#     inside third_party/ (the submodule is read-only in this repo).
#
# Library name stays `tim2tox_ffi` on every platform: Tim2Tox's Dart loader
# (third_party/tim2tox/dart/lib/ffi/tim2tox_ffi.dart) and the patched Tencent
# SDK's NativeLibraryManager (`setNativeLibraryName('tim2tox_ffi')`, called by
# packages/ditmesh_chat NativeLibrarySetup) resolve libtim2tox_ffi.so /
# libtim2tox_ffi.dylib / tim2tox_ffi.dll / tim2tox_ffi.framework by that name.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tool/ci/common.sh
source "$SCRIPT_DIR/common.sh"

# Pinned libsodium release. Version AND SHA-256 are identical to toxee's pin
# (https://github.com/jedisct1/libsodium/releases/tag/1.0.20-RELEASE). Any
# mismatch is a hard failure — libsodium is the crypto floor; silent CDN
# poisoning here breaks message confidentiality.
LIBSODIUM_VERSION="1.0.20"
LIBSODIUM_SHA256="ebb65ef6ca439333c2bb41a0c1990587288da07f6c7fd07cb3a18cc18d30ce19"
LIBSODIUM_URL="https://github.com/jedisct1/libsodium/releases/download/${LIBSODIUM_VERSION}-RELEASE/libsodium-${LIBSODIUM_VERSION}.tar.gz"

# Minimum OS versions (doc/operations/BUILD_AND_DEPLOY.md, same as toxee).
MACOS_MIN="${DITMESH_MACOS_MIN:-10.15}"
IOS_MIN="${DITMESH_IOS_MIN:-14.0}"
ANDROID_API="${DITMESH_ANDROID_API:-21}"
# 16 KB page sizes: Google Play requires every 64-bit native library of an app
# targeting Android 15+ to be 16 KB page-aligned. The flags are passed
# explicitly so the result does not depend on which NDK a host has: r28+
# aligns by default, r27 only with ANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON,
# r26 and older never (and their prebuilt libc++_shared.so is 4 KB-aligned,
# which no flag can fix). CMake appends user CMAKE_SHARED_LINKER_FLAGS after
# the toolchain's own, so the explicit value wins on every NDK (verified with
# r26.3, r27.0 and r28.2). assert_android_page_alignment refuses an unaligned
# result for both libtim2tox_ffi.so and libc++_shared.so.
ANDROID_PAGE_SIZE=16384
ANDROID_PAGE_SIZE_LDFLAGS="-Wl,-z,max-page-size=$ANDROID_PAGE_SIZE -Wl,-z,common-page-size=$ANDROID_PAGE_SIZE"

TARGET=""
MODE="release"
# Desktop CMake configuration for the NATIVE library. Independent of --mode
# (the Flutter mode): the FFI shim is always optimised. Override with
# DITMESH_NATIVE_BUILD_TYPE=RelWithDebInfo for symbols.
NATIVE_BUILD_TYPE="${DITMESH_NATIVE_BUILD_TYPE:-Release}"
ENABLE_SQLITE=0
SYSTEM_LIBSODIUM=0
ENABLE_TEST_HOOKS=0
STAGE_ONLY=0
STAGE_APP=1
ANDROID_ABIS_CSV="${DITMESH_ANDROID_ABIS:-arm64-v8a}"
IOS_SIM_ARCHS="${DITMESH_IOS_SIM_ARCHS:-arm64 x86_64}"

usage() {
  cat <<'EOF'
Usage: build_tim2tox.sh --target <target> [options]

Targets:
  linux-x86_64 | linux-aarch64      (built natively on a matching host)
  windows-x64  | windows-arm64      (MSVC + vcpkg; run from Git Bash)
  macos-x86_64 | macos-arm64        (either can be built on either Mac)
  android                           (per ABI; --android-abis, default arm64-v8a)
  ios-device | ios-simulator        (simulator is universal arm64+x86_64)
  linux | macos | windows           (alias: host architecture)
  ios                               (alias: ios-device)

Options:
  --mode <debug|profile|release>    Flutter mode this build is for (label only;
                                    the native lib is always optimised —
                                    DITMESH_NATIVE_BUILD_TYPE overrides).
  --android-abis a,b,c              Android ABIs (arm64-v8a, armeabi-v7a, x86_64).
  --with-sqlite                     Link sqlite3 (TIM2TOX_DISABLE_SQLITE=OFF).
                                    Default OFF: ditmesh uses no communities.
  --system-libsodium                Linux/macOS: use the pkg-config / Homebrew
                                    libsodium instead of the pinned static
                                    build; the shared lib is captured next to
                                    the FFI library like toxee does.
  --stage-only                      Do not build; re-stage an existing
                                    build/native/<target>/ into the app
                                    (Android jniLibs, macOS Frameworks). Used
                                    by CI after a cache/artifact restore.
  --no-stage-app                    Build and capture only; skip copying into
                                    apps/ditmesh/... (packaging jobs).
  --enable-test-hooks               TEST ARTIFACT ONLY (Tim2Tox auto_tests
                                    hooks). Never packaged; hook gate skipped.
  --no-toxav                        Accepted (it is the only mode).
  --toxav                           REJECTED: ditmesh has no calls.

Output: build/native/<target>/  (DITMESH_NATIVE_ARTIFACTS_DIR overrides the
        parent). Build trees: build/native/.work/, deps: build/native/.deps/,
        downloads: build/native/.downloads/ (DITMESH_NATIVE_BUILD_ROOT
        overrides all three).

Host prerequisites:
  linux:   cmake, ninja or make, a C/C++ toolchain, pkg-config, Flutter on PATH
           (dart_api_dl.h); patchelf recommended for bundling.
  macos:   Xcode command line tools, cmake, Flutter on PATH.
  windows: Visual Studio 2022 (or 18) C++ tools, cmake, vcpkg with
           libsodium:<triplet> pthreads:<triplet> pkgconf:<triplet>, VCPKG_ROOT
           set, Flutter on PATH; run from Git Bash after vcvars.
  android: Android NDK (ANDROID_NDK_HOME / ANDROID_NDK_ROOT / $ANDROID_HOME/ndk).
  ios:     Xcode with the iphoneos + iphonesimulator SDKs.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --mode) MODE="${2:-}"; shift 2 ;;
    --android-abis) ANDROID_ABIS_CSV="${2:-}"; shift 2 ;;
    --with-sqlite) ENABLE_SQLITE=1; shift ;;
    --system-libsodium) SYSTEM_LIBSODIUM=1; shift ;;
    --stage-only) STAGE_ONLY=1; shift ;;
    --no-stage-app) STAGE_APP=0; shift ;;
    --enable-test-hooks) ENABLE_TEST_HOOKS=1; shift ;;
    --no-toxav) shift ;;
    --toxav)
      ci_die "--toxav is not supported: ditmesh ships no voice/video calls, so ToxAV (opus/libvpx) is never built. Use toxee's pipeline if you need a ToxAV-enabled libtim2tox_ffi."
      ;;
    --help|-h) usage; exit 0 ;;
    *) ci_die "Unknown option: $1 (see --help)" ;;
  esac
done

[[ -n "$TARGET" ]] || { usage >&2; ci_die "--target is required"; }
ci_mode_dirname "$MODE" >/dev/null

# ---------------------------------------------------------------------------
# Target resolution
# ---------------------------------------------------------------------------
HOST_OS="$(ci_host_os)"
HOST_ARCH="$(ci_host_arch)"

case "$TARGET" in
  linux)   [[ "$HOST_ARCH" != unknown ]] || ci_die "Cannot infer host arch for alias 'linux'"; TARGET="linux-$HOST_ARCH" ;;
  macos)   case "$HOST_ARCH" in aarch64) TARGET="macos-arm64" ;; x86_64) TARGET="macos-x86_64" ;; *) ci_die "Cannot infer host arch for alias 'macos'" ;; esac ;;
  windows) case "$HOST_ARCH" in aarch64) TARGET="windows-arm64" ;; *) TARGET="windows-x64" ;; esac ;;
  ios)     TARGET="ios-device" ;;
esac

FAMILY=""
ARCH=""
case "$TARGET" in
  linux-x86_64|linux-aarch64) FAMILY="linux"; ARCH="${TARGET#linux-}" ;;
  windows-x64|windows-arm64)  FAMILY="windows"; ARCH="${TARGET#windows-}" ;;
  macos-x86_64|macos-arm64)   FAMILY="macos"; ARCH="${TARGET#macos-}" ;;
  android)                    FAMILY="android" ;;
  ios-device|ios-simulator)   FAMILY="ios"; ARCH="${TARGET#ios-}" ;;
  *) ci_die "Unsupported target: $TARGET (see --help)" ;;
esac

REPO_ROOT="$(ci_repo_root)"
APP_DIR="$REPO_ROOT/apps/ditmesh"
TIM2TOX_DIR="$REPO_ROOT/third_party/tim2tox"
TIM2TOX_UPSTREAM_DIR="$TIM2TOX_DIR"
NATIVE_ROOT="${DITMESH_NATIVE_BUILD_ROOT:-$REPO_ROOT/build/native}"
WORK_ROOT="$NATIVE_ROOT/.work"
DEPS_ROOT="$NATIVE_ROOT/.deps"
DOWNLOAD_DIR="$NATIVE_ROOT/.downloads"
OUTPUT_DIR="${DITMESH_NATIVE_ARTIFACTS_DIR:-$NATIVE_ROOT}/$TARGET"

[[ -d "$TIM2TOX_DIR" ]] || ci_die "tim2tox submodule not found: $TIM2TOX_DIR (run: git submodule update --init --recursive)"
[[ -f "$TIM2TOX_DIR/ffi/CMakeLists.txt" ]] || ci_die "tim2tox submodule is not checked out: $TIM2TOX_DIR/ffi/CMakeLists.txt missing (run: git submodule update --init --recursive)"

# Tim2Tox's ffi/CMakeLists.txt compiles dart_api_dl.c from the Dart SDK inside
# the Flutter checkout. Without it, Dart_PostCObject_DL is missing and every
# native->Dart callback is dead. Precedence: an explicit FLUTTER_ROOT, then an
# explicit DITMESH_DART_SDK_DIR (see below), then `flutter` on PATH, then
# `dart` on PATH.
if [[ -z "${FLUTTER_ROOT:-}" && -z "${DITMESH_DART_SDK_DIR:-}" ]] && command -v flutter >/dev/null 2>&1; then
  FLUTTER_ROOT="$(cd "$(dirname "$(command -v flutter)")/.." && pwd)"
  export FLUTTER_ROOT
fi
# No Flutter checkout (Flutter publishes no Linux/Windows arm64 SDK archive,
# so those CI runners only get a standalone Dart SDK — the same Dart version
# Flutter bundles): the headers are all the native build needs, so stage
# <dart-sdk>/include under a shim FLUTTER_ROOT with the layout tim2tox's
# ffi/CMakeLists.txt probes (<root>/bin/cache/dart-sdk/include). An explicit
# DITMESH_DART_SDK_DIR must point at a real SDK (hard error otherwise);
# without it the SDK owning `dart` on PATH is used.
if [[ -z "${FLUTTER_ROOT:-}" ]]; then
  dart_sdk_dir="${DITMESH_DART_SDK_DIR:-}"
  if [[ -n "$dart_sdk_dir" ]]; then
    [[ -f "$dart_sdk_dir/include/dart_api_dl.h" && -f "$dart_sdk_dir/include/dart_api_dl.c" ]] || \
      ci_die "DITMESH_DART_SDK_DIR=$dart_sdk_dir has no include/dart_api_dl.h + dart_api_dl.c (not a Dart SDK root?)"
  elif command -v dart >/dev/null 2>&1; then
    dart_sdk_dir="$(cd "$(dirname "$(command -v dart)")/.." && pwd)"
  fi
  if [[ -n "$dart_sdk_dir" && -f "$dart_sdk_dir/include/dart_api_dl.h" && -f "$dart_sdk_dir/include/dart_api_dl.c" ]]; then
    dart_shim="$NATIVE_ROOT/.dart-sdk-shim"
    rm -rf "$dart_shim/bin/cache/dart-sdk/include"
    mkdir -p "$dart_shim/bin/cache/dart-sdk"
    cp -R "$dart_sdk_dir/include" "$dart_shim/bin/cache/dart-sdk/include"
    FLUTTER_ROOT="$dart_shim"
    export FLUTTER_ROOT
    ci_log "No Flutter checkout; using Dart SDK headers from $dart_sdk_dir (version: $(cat "$dart_sdk_dir/version" 2>/dev/null || echo unknown)) via $dart_shim"
  elif [[ -n "$dart_sdk_dir" ]]; then
    ci_warn "dart on PATH resolved to $dart_sdk_dir but it has no include/dart_api_dl.h + dart_api_dl.c"
  fi
  unset dart_sdk_dir dart_shim
fi
if [[ -n "${FLUTTER_ROOT:-}" ]]; then
  [[ -f "$FLUTTER_ROOT/bin/cache/dart-sdk/include/dart_api_dl.h" ]] || \
    ci_warn "dart_api_dl.h not found under $FLUTTER_ROOT/bin/cache/dart-sdk/include — run 'flutter precache' / 'flutter --version' once; the FFI build needs it"
else
  ci_warn "FLUTTER_ROOT unset and flutter not on PATH — the FFI build cannot find dart_api_dl.h"
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
bootstrap_tim2tox_submodules() {
  # c-toxcore (and its cmp) are nested submodules of tim2tox; a fresh
  # `git clone --recursive` of ditmesh brings them, a plain clone + bootstrap
  # does not. Idempotent.
  if [[ -f "$TIM2TOX_DIR/.gitmodules" ]] && { [[ -d "$TIM2TOX_DIR/.git" ]] || [[ -f "$TIM2TOX_DIR/.git" ]]; }; then
    ci_log "Ensuring tim2tox nested submodules (c-toxcore) are initialized"
    if ! git -C "$TIM2TOX_DIR" submodule update --init --recursive; then
      if [[ -f "$TIM2TOX_DIR/third_party/c-toxcore/CMakeLists.txt" ]]; then
        ci_warn "git submodule update failed but c-toxcore sources are present — continuing (read-only/mounted checkout)"
      else
        ci_die "git submodule update failed and c-toxcore sources are missing"
      fi
    fi
  fi
  [[ -f "$TIM2TOX_DIR/third_party/c-toxcore/CMakeLists.txt" ]] || \
    ci_die "c-toxcore sources missing under $TIM2TOX_DIR/third_party/c-toxcore"
  # Native product fixes are applied to a managed source copy. The pinned
  # submodule and its Dart package remain untouched on every platform.
  local python staged_source="$NATIVE_ROOT/.sources/$TARGET/tim2tox"
  if command -v python3 >/dev/null 2>&1; then python=python3
  elif command -v python >/dev/null 2>&1; then python=python
  else ci_die "Python 3 is required to prepare the reviewed native overlays"; fi
  "$python" "$SCRIPT_DIR/prepare_native_source.py" "$TIM2TOX_UPSTREAM_DIR" "$staged_source" ||
    ci_die "Failed to prepare the DitMesh native source overlays"
  TIM2TOX_DIR="$staged_source"
}

download_file_once() {
  local url="$1" dest="$2" temporary
  mkdir -p "$(dirname "$dest")"
  # A cached tarball is only reusable if it actually decompresses (curl can
  # exit 0 on a truncated body); a corrupt cache is deleted, not pinned.
  if [[ -f "$dest" ]] && ! tar tzf "$dest" >/dev/null 2>&1; then
    ci_warn "cached $(basename "$dest") is corrupt — re-downloading"
    rm -f "$dest"
  fi
  if [[ ! -f "$dest" ]]; then
    ci_log "Downloading $url"
    # Parallel platform builds share this cache. Only expose a complete file.
    temporary="$dest.part.$$.$RANDOM"
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL --retry 3 --retry-delay 2 --connect-timeout 30 -o "$temporary" "$url" || {
        rm -f "$temporary"
        ci_die "Failed to download $url"
      }
    elif command -v wget >/dev/null 2>&1; then
      wget -O "$temporary" "$url" || {
        rm -f "$temporary"
        ci_die "Failed to download $url"
      }
    else
      ci_die "Missing curl/wget for downloading $url"
    fi
    mv -f "$temporary" "$dest"
  fi
}

verify_sha256() {
  local path="$1" expected="$2" label="${3:-$(basename "$1")}"
  local actual
  [[ -f "$path" ]] || ci_die "$label: file missing for sha256 verification: $path"
  actual="$(ci_sha256_file "$path")"
  if [[ "$actual" != "$expected" ]]; then
    rm -f "$path"
    ci_die "$label: sha256 mismatch (got $actual, expected $expected). File removed; re-run to re-download."
  fi
  ci_log "$label: sha256 verified"
}

# Paths that end up inside CFLAGS/LDFLAGS (-isysroot …) are re-split on
# whitespace by autoconf, so they cannot be quoted through; refuse them early
# with a clear message instead of a baffling "cannot create executables".
ci_require_no_whitespace() {
  local value="$1" what="$2"
  [[ "$value" != *[[:space:]]* ]] || \
    ci_die "$what contains whitespace ('$value'); it is passed through CFLAGS/LDFLAGS and cannot be escaped. Move/select an SDK at a whitespace-free path (xcode-select -s …)."
}

# Extract the pinned libsodium tarball into $1/libsodium-<ver>; prints that dir.
fetch_libsodium_source() {
  local src_root="$1"
  local archive="$DOWNLOAD_DIR/libsodium-${LIBSODIUM_VERSION}.tar.gz"
  download_file_once "$LIBSODIUM_URL" "$archive"
  verify_sha256 "$archive" "$LIBSODIUM_SHA256" "libsodium-${LIBSODIUM_VERSION}"
  rm -rf "$src_root"
  mkdir -p "$src_root"
  tar -xzf "$archive" -C "$src_root"
  printf '%s\n' "$src_root/libsodium-${LIBSODIUM_VERSION}"
}

# Build a static, PIC libsodium into $prefix. Extra args after the prefix are
# passed to ./configure (e.g. --host=...); the caller sets CC/CFLAGS/... in the
# environment for cross builds. Idempotent on $prefix/lib/libsodium.a.
build_static_libsodium() {
  local prefix="$1"; shift
  local label="$1"; shift
  local src_dir
  if [[ -f "$prefix/lib/libsodium.a" ]]; then
    ci_log "[$label] libsodium ${LIBSODIUM_VERSION} cached at $prefix"
    return 0
  fi
  ci_log "[$label] building libsodium ${LIBSODIUM_VERSION} (static, PIC) into $prefix"
  src_dir="$(fetch_libsodium_source "$DEPS_ROOT/src-$label")" || return 1
  mkdir -p "$prefix"
  (
    cd "$src_dir"
    ./configure --prefix="$prefix" --enable-static --disable-shared --with-pic "$@" \
      >"$prefix/libsodium-configure.log" 2>&1 || {
        tail -30 "$prefix/libsodium-configure.log" >&2
        # configure's stdout only says "cannot create executables"; the actual
        # compiler/linker error lives in config.log. Surface it, so a CI run
        # (which does not upload the source tree) is diagnosable from its log.
        if [[ -f config.log ]]; then
          printf '[ci] ---- %s/config.log (compiler probe) ----\n' "$src_dir" >&2
          grep -n -B2 -A12 -E 'cannot create executables|error:' config.log | head -60 >&2 || true
          printf '[ci] CC=%s\n[ci] CFLAGS=%s\n[ci] LDFLAGS=%s\n' "${CC:-}" "${CFLAGS:-}" "${LDFLAGS:-}" >&2
        fi
        ci_die "[$label] libsodium configure failed (log: $prefix/libsodium-configure.log)"
      }
    make -j"$(ci_cpu_count)" >"$prefix/libsodium-make.log" 2>&1 || {
      tail -30 "$prefix/libsodium-make.log" >&2
      ci_die "[$label] libsodium make failed (log: $prefix/libsodium-make.log)"
    }
    make install >>"$prefix/libsodium-make.log" 2>&1
  ) || return 1
  [[ -f "$prefix/lib/libsodium.a" ]] || ci_die "[$label] libsodium build produced no lib/libsodium.a"
  [[ -f "$prefix/lib/pkgconfig/libsodium.pc" ]] || ci_die "[$label] libsodium build produced no libsodium.pc"
}

# Common CMake options for every target. Kept as an array; set_configure_arg
# replaces entries in place so toggles never append duplicates.
configure_args=(
  -DBUILD_FFI=ON
  -DBUILD_TOXAV=OFF
  -DMUST_BUILD_TOXAV=OFF
  -DDHT_BOOTSTRAP=OFF
  -DBOOTSTRAP_DAEMON=OFF
  -DENABLE_SHARED=OFF
  -DENABLE_STATIC=ON
  -DUNITTEST=OFF
  -DAUTOTEST=OFF
  -DBUILD_MISC_TESTS=OFF
  -DBUILD_FUN_UTILS=OFF
  -DBUILD_FUZZ_TESTS=OFF
  -DUSE_IPV6=ON
  -DEXPERIMENTAL_API=OFF
  -DSTRICT_ABI=OFF
  -DTIM2TOX_DISABLE_SQLITE=ON
  # Test-only FFI hooks are OFF and passed EXPLICITLY on every configure:
  # build trees under .work/ are reused, and a tree once configured with the
  # option ON keeps that cache entry forever.
  -DTIM2TOX_ENABLE_TEST_HOOKS=OFF
  -DERROR=ON
  -DWARNING=ON
  -DINFO=ON
  -DTRACE=OFF
  -DDEBUG=OFF
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
)

set_configure_arg() {
  local key="$1" value="$2" i
  for i in "${!configure_args[@]}"; do
    case "${configure_args[$i]}" in
      -D"${key}"=*) configure_args[$i]="-D${key}=${value}"; return 0 ;;
    esac
  done
  configure_args+=("-D${key}=${value}")
}

if [[ "$ENABLE_SQLITE" -eq 1 ]]; then
  set_configure_arg "TIM2TOX_DISABLE_SQLITE" "OFF"
fi
if [[ "$ENABLE_TEST_HOOKS" -eq 1 ]]; then
  set_configure_arg "TIM2TOX_ENABLE_TEST_HOOKS" "ON"
  ci_warn "TIM2TOX_ENABLE_TEST_HOOKS=ON — this is a TEST artifact. It must never be packaged."
fi

# Symbol table of a binary via an nm-like tool ($2, default nm); empty when the
# tool cannot read it. No `nm | grep -q` pipelines anywhere (SIGPIPE + pipefail
# = false negative).
symbols_of() {
  local lib="$1" nm_tool="${2:-nm}"
  if command -v "$nm_tool" >/dev/null 2>&1; then
    { "$nm_tool" -D "$lib" 2>/dev/null; "$nm_tool" -g "$lib" 2>/dev/null; } || true
  fi
}

# Byte-level gate on everything this script captures or stages (the CMake
# flag only speaks for trees WE configured; --stage-only never configured
# anything). The forbidden names live in ONE place: assert_no_test_hooks.sh.
assert_hook_free_artifact() {
  local lib="$1" nm_tool="${2:-}"
  [[ "$ENABLE_TEST_HOOKS" -eq 1 ]] && return 0
  if [[ -n "$nm_tool" ]]; then
    TIM2TOX_NM="$nm_tool" bash "$SCRIPT_DIR/assert_no_test_hooks.sh" "$lib"
  else
    bash "$SCRIPT_DIR/assert_no_test_hooks.sh" "$lib"
  fi
}

# The inverse of toxee's ToxAV assertion: the marker symbol
# tim2tox_ffi_av_backend_toxav exists ONLY under BUILD_TOXAV. ditmesh never
# builds ToxAV, so its presence means a foreign/stale library slipped in.
assert_no_toxav_artifact() {
  local lib="$1" nm_tool="${2:-nm}" label="${3:-$(basename "$1")}"
  local syms
  syms="$(symbols_of "$lib" "$nm_tool")"
  if [[ -z "$syms" ]]; then
    ci_warn "$label: no nm-like tool could read the symbol table; ToxAV-absence check skipped"
    return 0
  fi
  if [[ "$syms" == *tim2tox_ffi_av_backend_toxav* ]]; then
    ci_die "$label: exports tim2tox_ffi_av_backend_toxav — this library was built WITH ToxAV, which ditmesh never does. Stale or foreign artifact; delete build/native/$TARGET and rebuild."
  fi
  ci_log "$label: ToxAV absent (stub backend, as intended)"
}

# The Dart* binary-replacement entry points (DartInitSDK, ...) are what the
# patched Tencent SDK bindings resolve; strip/export lists must keep them.
assert_dart_entrypoints() {
  local lib="$1" nm_tool="${2:-nm}" label="${3:-$(basename "$1")}"
  local syms
  syms="$(symbols_of "$lib" "$nm_tool")"
  if [[ -z "$syms" ]]; then
    ci_warn "$label: no nm-like tool could read the symbol table; Dart* export check skipped"
    return 0
  fi
  if [[ "$syms" == *DartInitSDK* && "$syms" == *tim2tox_ffi_init* ]]; then
    ci_log "$label: exported Dart* + tim2tox_ffi_* entry points present"
  else
    ci_die "$label: DartInitSDK / tim2tox_ffi_init not exported — the Dart side could not bind this library"
  fi
}

# All three post-build checks on one captured library.
verify_artifact() {
  assert_no_toxav_artifact "$1" "${2:-nm}" "${3:-}"
  assert_dart_entrypoints "$1" "${2:-nm}" "${3:-}"
  assert_hook_free_artifact "$1" "${2:-}"
}

prepare_cmake_build_dir() {
  local build_dir="$1" previous_source
  if [[ -f "$build_dir/CMakeCache.txt" ]]; then
    previous_source="$(sed -n 's/^CMAKE_HOME_DIRECTORY:INTERNAL=//p' "$build_dir/CMakeCache.txt")"
    if [[ "$previous_source" != "$TIM2TOX_DIR" && "$previous_source" != "$(ci_windows_path "$TIM2TOX_DIR")" ]]; then
      ci_log "Replacing CMake cache configured from a different source tree"
      ci_reset_dir "$build_dir"
    fi
  fi
  mkdir -p "$build_dir"
}

configure_and_build() {
  # $1 build dir, $2 log label, rest = extra cmake args (prepended before
  # configure_args). Logs go next to the build dir so failures are inspectable.
  local build_dir="$1" label="$2"; shift 2
  prepare_cmake_build_dir "$build_dir"
  ci_log "[$label] configuring tim2tox ($NATIVE_BUILD_TYPE)"
  cmake -S "$TIM2TOX_DIR" -B "$build_dir" "$@" "${configure_args[@]}" \
    >"$build_dir/cmake-configure.log" 2>&1 || {
      tail -40 "$build_dir/cmake-configure.log" >&2
      ci_die "[$label] cmake configure failed (log: $build_dir/cmake-configure.log)"
    }
  ci_log "[$label] building tim2tox_ffi"
  cmake --build "$build_dir" --config "$NATIVE_BUILD_TYPE" --target tim2tox_ffi --parallel "$(ci_cpu_count)" \
    >"$build_dir/cmake-build.log" 2>&1 || {
      tail -40 "$build_dir/cmake-build.log" >&2
      ci_die "[$label] cmake build failed (log: $build_dir/cmake-build.log)"
    }
}

find_built() {
  local build_dir="$1" name="$2" hit
  hit="$(find "$build_dir" -type f -name "$name" | head -n 1 || true)"
  [[ -n "$hit" ]] || ci_die "Failed to locate $name under $build_dir"
  printf '%s\n' "$hit"
}

capture_linux_shared_library() {
  # Copy a shared lib and, when it is a SONAME symlink, its resolved file too.
  local library_path="$1" resolved
  [[ -n "$library_path" && -e "$library_path" ]] || return 0
  resolved="$(readlink -f "$library_path" 2>/dev/null || printf '%s\n' "$library_path")"
  cp -P "$library_path" "$OUTPUT_DIR/"
  if [[ "$resolved" != "$library_path" && -f "$resolved" ]]; then
    cp "$resolved" "$OUTPUT_DIR/"
  fi
}

# ---------------------------------------------------------------------------
# Linux
# ---------------------------------------------------------------------------
build_linux() {
  local arch="$1"
  local build_dir="$WORK_ROOT/$TARGET"
  local prefix="$DEPS_ROOT/$TARGET"
  local -a dep_args=()
  local built_lib

  [[ "$HOST_OS" == "linux" ]] || ci_die "$TARGET must be built on a Linux host (got $HOST_OS)"
  if [[ "$HOST_ARCH" != "$arch" && "${DITMESH_ALLOW_ARCH_MISMATCH:-0}" != "1" ]]; then
    ci_die "$TARGET requested on a $HOST_ARCH host. Linux builds are native (CI uses an arm64 runner for linux-aarch64); set CC/CXX for a cross toolchain and DITMESH_ALLOW_ARCH_MISMATCH=1 to override."
  fi
  ci_require_cmd cmake
  ci_require_cmd pkg-config
  bootstrap_tim2tox_submodules

  if [[ "$SYSTEM_LIBSODIUM" -eq 1 ]]; then
    pkg-config --exists libsodium || ci_die "--system-libsodium: pkg-config cannot find libsodium (apt install libsodium-dev)"
    ci_log "[$TARGET] using system libsodium $(pkg-config --modversion libsodium)"
  else
    build_static_libsodium "$prefix" "$TARGET"
    export PKG_CONFIG_PATH="$prefix/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
    dep_args=(-DCMAKE_PREFIX_PATH="$prefix" -DTIM2TOX_DEP_PREFIX="$prefix")
  fi

  local -a gen=()
  if command -v ninja >/dev/null 2>&1; then gen=(-G Ninja); fi

  configure_and_build "$build_dir" "$TARGET" \
    "${gen[@]}" \
    -DCMAKE_BUILD_TYPE="$NATIVE_BUILD_TYPE" \
    -DCMAKE_CXX_FLAGS="-Wno-error=deprecated-copy -Wno-error=format -include arpa/inet.h" \
    -DCMAKE_C_FLAGS="-Wno-error=format" \
    "${dep_args[@]}"

  built_lib="$(find_built "$build_dir" libtim2tox_ffi.so)"
  cp "$built_lib" "$OUTPUT_DIR/"
  ci_log "[$TARGET] captured $built_lib"

  if [[ "$SYSTEM_LIBSODIUM" -eq 1 ]]; then
    # Shared libsodium: capture it (SONAME link + real file) so the bundle is
    # self-contained; apps/ditmesh/linux/CMakeLists.txt installs libsodium.so*
    # next to the FFI lib and sets its RUNPATH to $ORIGIN.
    local dep_path
    dep_path="$(ldd "$built_lib" | awk '/libsodium/ {print $3; exit}' || true)"
    if [[ -n "$dep_path" && -e "$dep_path" ]]; then
      capture_linux_shared_library "$dep_path"
      ci_log "[$TARGET] captured libsodium runtime: $dep_path"
    else
      ci_warn "[$TARGET] could not resolve libsodium from $built_lib via ldd"
    fi
  else
    # Static libsodium: prove nothing dynamic is left over.
    if ldd "$OUTPUT_DIR/libtim2tox_ffi.so" | grep -q 'libsodium'; then
      ci_die "[$TARGET] libtim2tox_ffi.so still links a shared libsodium although the pinned static one was requested"
    fi
    ci_log "[$TARGET] libsodium linked statically (no libsodium.so dependency)"
  fi

  verify_artifact "$OUTPUT_DIR/libtim2tox_ffi.so" nm "$TARGET"
  ci_log "[$TARGET] runtime deps: $(ldd "$OUTPUT_DIR/libtim2tox_ffi.so" | awk '{print $1}' | tr '\n' ' ')"
}

# ---------------------------------------------------------------------------
# macOS
# ---------------------------------------------------------------------------
build_macos() {
  local arch="$1"           # x86_64 | arm64
  local build_dir="$WORK_ROOT/$TARGET"
  local prefix="$DEPS_ROOT/$TARGET"
  local -a dep_args=()
  local built_lib host_triple macos_sysroot

  [[ "$HOST_OS" == "macos" ]] || ci_die "$TARGET must be built on a macOS host (got $HOST_OS)"
  ci_require_cmd cmake
  ci_require_cmd xcrun
  ci_require_cmd install_name_tool
  bootstrap_tim2tox_submodules
  macos_sysroot="$(xcrun --sdk macosx --show-sdk-path)"
  [[ -d "$macos_sysroot" ]] || ci_die "[$TARGET] xcrun --sdk macosx --show-sdk-path returned no SDK (is Xcode / the Command Line Tools selected?)"
  ci_require_no_whitespace "$macos_sysroot" "[$TARGET] macOS SDK path"
  ci_log "[$TARGET] macOS SDK: $macos_sysroot"

  if [[ "$SYSTEM_LIBSODIUM" -eq 1 ]]; then
    ci_log "[$TARGET] using Homebrew/system libsodium (Tim2Tox CMake probes /opt/homebrew and /usr/local)"
    if [[ "$arch" != "$( [[ "$HOST_ARCH" == aarch64 ]] && echo arm64 || echo x86_64 )" ]]; then
      ci_warn "[$TARGET] --system-libsodium with a non-host arch: Homebrew only ships the host arch; the link will likely fail"
    fi
  else
    case "$arch" in
      arm64)  host_triple="aarch64-apple-darwin" ;;
      x86_64) host_triple="x86_64-apple-darwin" ;;
      *) ci_die "Unsupported macOS arch: $arch" ;;
    esac
    (
      # `xcrun -f clang` yields the raw toolchain binary
      # (…/XcodeDefault.xctoolchain/usr/bin/clang), which — unlike the
      # /usr/bin/clang shim — does NOT infer the SDK. Without -isysroot it
      # cannot find <stdio.h> and autoconf reports "C compiler cannot create
      # executables" (GitHub macos-15 runners: no SDKROOT in the environment;
      # reproduced on a dev Mac with `env -i`). Pin the macOS SDK explicitly,
      # exactly as build_ios_slice() does.
      export CC CFLAGS LDFLAGS SDKROOT
      CC="$(xcrun -f clang)"
      SDKROOT="$macos_sysroot"
      CFLAGS="-arch $arch -mmacosx-version-min=$MACOS_MIN -isysroot $macos_sysroot -O2"
      LDFLAGS="-arch $arch -mmacosx-version-min=$MACOS_MIN -isysroot $macos_sysroot"
      build_static_libsodium "$prefix" "$TARGET" --host="$host_triple"
    )
    export PKG_CONFIG_PATH="$prefix/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
    dep_args=(-DCMAKE_PREFIX_PATH="$prefix" -DTIM2TOX_DEP_PREFIX="$prefix")
  fi

  local -a gen=()
  if command -v ninja >/dev/null 2>&1; then gen=(-G Ninja); fi

  configure_and_build "$build_dir" "$TARGET" \
    "${gen[@]}" \
    -DCMAKE_BUILD_TYPE="$NATIVE_BUILD_TYPE" \
    -DCMAKE_OSX_SYSROOT="$macos_sysroot" \
    -DCMAKE_OSX_ARCHITECTURES="$arch" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$MACOS_MIN" \
    -DCMAKE_CXX_FLAGS="-Wno-error=deprecated-copy -Wno-error=format" \
    -DCMAKE_C_FLAGS="-Wno-error=format" \
    "${dep_args[@]}"

  built_lib="$(find_built "$build_dir" libtim2tox_ffi.dylib)"
  cp "$built_lib" "$OUTPUT_DIR/"
  local out_lib="$OUTPUT_DIR/libtim2tox_ffi.dylib"
  ci_log "[$TARGET] captured $built_lib"

  # CocoaPods links Runner against the vendored dylib (-ltim2tox_ffi) and
  # embeds it in Contents/Frameworks; Runner's LD_RUNPATH_SEARCH_PATHS has
  # @executable_path/../Frameworks, so the install name must be @rpath-based
  # or the app fails to launch with a dyld "image not found" for the build
  # tree path.
  install_name_tool -id "@rpath/libtim2tox_ffi.dylib" "$out_lib"

  if [[ "$SYSTEM_LIBSODIUM" -eq 1 ]]; then
    # Shared libsodium from Homebrew: capture it and rewrite the FFI lib's
    # reference to @loader_path so the pair works from any directory (toxee's
    # package_artifacts.sh does the same).
    local dep_path dep_name
    dep_path="$(otool -L "$out_lib" | awk '$1 ~ /libsodium.*dylib/ {print $1; exit}' || true)"
    if [[ -n "$dep_path" && -f "$dep_path" ]]; then
      dep_name="$(basename "$dep_path")"
      cp "$dep_path" "$OUTPUT_DIR/"
      install_name_tool -change "$dep_path" "@loader_path/$dep_name" "$out_lib"
      ci_log "[$TARGET] captured libsodium runtime: $dep_path (now @loader_path/$dep_name)"
    else
      ci_warn "[$TARGET] could not resolve libsodium from $out_lib via otool"
    fi
  else
    if otool -L "$out_lib" | grep -q 'libsodium'; then
      ci_die "[$TARGET] libtim2tox_ffi.dylib still links a shared libsodium although the pinned static one was requested"
    fi
    ci_log "[$TARGET] libsodium linked statically (no libsodium.dylib dependency)"
  fi

  # Ad-hoc sign so the raw dylib is loadable when used outside CocoaPods
  # (which re-signs whatever it embeds anyway).
  if command -v codesign >/dev/null 2>&1; then
    codesign --force --sign - "$out_lib" || ci_die "[$TARGET] codesign failed for $out_lib"
    [[ "$SYSTEM_LIBSODIUM" -eq 1 ]] && for f in "$OUTPUT_DIR"/libsodium*.dylib; do
      [[ -f "$f" ]] && codesign --force --sign - "$f"
    done
  fi

  verify_artifact "$out_lib" nm "$TARGET"
  ci_log "[$TARGET] $(lipo -info "$out_lib" 2>/dev/null || file "$out_lib")"
  stage_macos_into_app
}

stage_macos_into_app() {
  [[ "$STAGE_APP" -eq 1 ]] || return 0
  local src="$OUTPUT_DIR/libtim2tox_ffi.dylib"
  local dest_dir="$APP_DIR/macos/Frameworks"
  [[ -f "$src" ]] || ci_die "stage: $src missing"
  mkdir -p "$dest_dir"
  cp "$src" "$dest_dir/libtim2tox_ffi.dylib"
  # A Homebrew libsodium (only in --system-libsodium mode) travels with it.
  local f
  for f in "$OUTPUT_DIR"/libsodium*.dylib; do
    [[ -f "$f" ]] && cp "$f" "$dest_dir/"
  done
  # The vendored pod is declared in apps/ditmesh/macos/Podfile only when the
  # dylib exists; flutter re-runs `pod install` when the Podfile is newer than
  # Podfile.lock, so touching it makes the next `flutter build macos` embed.
  [[ -f "$APP_DIR/macos/Podfile" ]] && touch "$APP_DIR/macos/Podfile"
  ci_log "[$TARGET] staged libtim2tox_ffi.dylib into $dest_dir (Podfile touched so pod install re-runs)"
}

# ---------------------------------------------------------------------------
# Windows (Git Bash, MSVC, vcpkg) — ported from toxee unchanged except for the
# dropped ToxAV codec handling.
# ---------------------------------------------------------------------------
build_windows() {
  local arch="$1"           # x64 | arm64
  local build_dir="$WORK_ROOT/$TARGET"
  local vs_arch vcpkg_triplet source_dir_win build_dir_win built_lib
  local -a generator_args=()

  [[ "$HOST_OS" == "windows" ]] || ci_die "$TARGET must be built on a Windows host from Git Bash (got $HOST_OS)"
  ci_require_cmd cmake
  bootstrap_tim2tox_submodules

  case "$arch" in
    arm64) vs_arch="arm64"; vcpkg_triplet="arm64-windows" ;;
    x64|*) vs_arch="x64";   vcpkg_triplet="x64-windows" ;;
  esac
  [[ -n "${VCPKG_ROOT:-}" ]] || ci_die "VCPKG_ROOT is required on Windows (vcpkg install libsodium:$vcpkg_triplet pthreads:$vcpkg_triplet pkgconf:$vcpkg_triplet)"
  [[ -f "$VCPKG_ROOT/installed/$vcpkg_triplet/lib/pkgconfig/libsodium.pc" ]] || \
    ci_die "vcpkg libsodium missing for $vcpkg_triplet. Run: vcpkg install libsodium:$vcpkg_triplet pthreads:$vcpkg_triplet pkgconf:$vcpkg_triplet"

  source_dir_win="$(ci_windows_path "$TIM2TOX_DIR")"
  build_dir_win="$(ci_windows_path "$build_dir")"

  # Generator: env override > Ninja (arch from vcvars) > VS 18 > VS 17 2022.
  if [[ -n "${DITMESH_CMAKE_GENERATOR:-}" ]]; then
    generator_args=(-G "$DITMESH_CMAKE_GENERATOR")
  elif command -v ninja >/dev/null 2>&1; then
    generator_args=(-G "Ninja")
  elif [[ -d "/c/Program Files/Microsoft Visual Studio/18" ]]; then
    generator_args=(-G "Visual Studio 18" -A "$vs_arch")
  else
    generator_args=(-G "Visual Studio 17 2022" -A "$vs_arch")
  fi

  local vcpkg_root_win toolchain_file vcpkg_pc_dir_win
  vcpkg_root_win="$(ci_windows_path "$VCPKG_ROOT")"
  toolchain_file="${vcpkg_root_win}/scripts/buildsystems/vcpkg.cmake"
  # pkgconf (native tool): needs Windows-style .pc search paths.
  export PATH="$VCPKG_ROOT/installed/$vcpkg_triplet/tools/pkgconf:$PATH"
  vcpkg_pc_dir_win="$(ci_windows_path "$VCPKG_ROOT/installed/$vcpkg_triplet/lib/pkgconfig")"
  export PKG_CONFIG_PATH="$vcpkg_pc_dir_win"
  export PKG_CONFIG_LIBDIR="$vcpkg_pc_dir_win"
  # vcpkg's applocal.ps1 post-build step needs powershell.exe.
  export PATH="/c/WINDOWS/System32/WindowsPowerShell/v1.0:$PATH"

  # CMAKE_BUILD_TYPE is REQUIRED for single-config generators (Ninja): without
  # it the DLL links the DEBUG CRT and fails to load (error 126).
  # VCPKG_TARGET_TRIPLET must be EXPLICIT or the arm64 runners get x64 libs.
  prepare_cmake_build_dir "$build_dir"
  ci_log "[$TARGET] configuring tim2tox ($NATIVE_BUILD_TYPE, $vcpkg_triplet)"
  VCPKG_ROOT="$vcpkg_root_win" cmake -S "$source_dir_win" -B "$build_dir_win" \
    "${generator_args[@]}" \
    -DCMAKE_TOOLCHAIN_FILE="$toolchain_file" \
    -DVCPKG_TARGET_TRIPLET="$vcpkg_triplet" \
    -DCMAKE_BUILD_TYPE="$NATIVE_BUILD_TYPE" \
    "${configure_args[@]}" \
    >"$build_dir/cmake-configure.log" 2>&1 || {
      tail -40 "$build_dir/cmake-configure.log" >&2
      ci_die "[$TARGET] cmake configure failed (log: $build_dir/cmake-configure.log)"
    }
  ci_log "[$TARGET] building tim2tox_ffi"
  cmake --build "$build_dir_win" --config "$NATIVE_BUILD_TYPE" --target tim2tox_ffi --parallel "$(ci_cpu_count)" \
    >"$build_dir/cmake-build.log" 2>&1 || {
      tail -40 "$build_dir/cmake-build.log" >&2
      ci_die "[$TARGET] cmake build failed (log: $build_dir/cmake-build.log)"
    }

  built_lib="$(find_built "$build_dir" tim2tox_ffi.dll)"
  cp "$built_lib" "$OUTPUT_DIR/"
  ci_log "[$TARGET] captured $built_lib"
  if [[ -f "${built_lib%.dll}.pdb" ]]; then
    cp "${built_lib%.dll}.pdb" "$OUTPUT_DIR/"
    ci_log "[$TARGET] captured symbols ${built_lib%.dll}.pdb"
  fi

  # Runtime DLLs the FFI library imports: vcpkg libsodium (dynamic) and the
  # pthreads-win32 runtime c-toxcore links. A missing one = LoadLibrary error
  # 126 at app start. apps/ditmesh/windows/CMakeLists.txt installs both from
  # build/native/<target>/ next to ditmesh.exe.
  ci_copy_matching_file "$VCPKG_ROOT/installed/$vcpkg_triplet/bin" "libsodium.dll" "$OUTPUT_DIR" >/dev/null || \
    ci_copy_matching_file "$VCPKG_ROOT/installed/$vcpkg_triplet" "libsodium.dll" "$OUTPUT_DIR" >/dev/null || \
    ci_die "libsodium.dll not found under $VCPKG_ROOT/installed/$vcpkg_triplet"
  ci_copy_matching_file "$VCPKG_ROOT/installed/$vcpkg_triplet/bin" "pthreadVC3.dll" "$OUTPUT_DIR" >/dev/null || \
    ci_copy_matching_file "$VCPKG_ROOT/installed/$vcpkg_triplet" "pthreadVC3.dll" "$OUTPUT_DIR" >/dev/null || \
    ci_warn "pthreadVC3.dll not found under $VCPKG_ROOT/installed/$vcpkg_triplet (only needed if tim2tox_ffi.dll imports it)"

  verify_artifact "$OUTPUT_DIR/tim2tox_ffi.dll" nm "$TARGET"
}

# ---------------------------------------------------------------------------
# Android (per ABI, NDK clang, static libsodium)
# ---------------------------------------------------------------------------
android_ndk_toolchain_dir() {
  local ndk_path="$1" dir
  dir="$(ls -d "$ndk_path/toolchains/llvm/prebuilt/"* 2>/dev/null | head -n 1)"
  [[ -n "$dir" ]] || ci_die "NDK llvm prebuilt toolchain not found under $ndk_path"
  printf '%s\n' "$dir"
}

find_android_ndk() {
  local candidate sdk_root ndk
  for candidate in "${ANDROID_NDK_HOME:-}" "${ANDROID_NDK_ROOT:-}" "${NDK:-}"; do
    if [[ -n "$candidate" && -f "$candidate/build/cmake/android.toolchain.cmake" ]]; then
      printf '%s\n' "$candidate"; return
    fi
  done
  for sdk_root in "${ANDROID_SDK_ROOT:-}" "${ANDROID_HOME:-}" "$HOME/Library/Android/sdk" "$HOME/Android/Sdk"; do
    [[ -n "$sdk_root" && -d "$sdk_root" ]] || continue
    if [[ -d "$sdk_root/ndk" ]]; then
      # Highest version that is COMPLETE (a stalled download lacks build/cmake).
      while IFS= read -r ndk; do
        if [[ -f "$ndk/build/cmake/android.toolchain.cmake" ]]; then
          printf '%s\n' "$ndk"; return
        fi
      done < <(find "$sdk_root/ndk" -mindepth 1 -maxdepth 1 -type d | sort -Vr)
    fi
    if [[ -f "$sdk_root/ndk-bundle/build/cmake/android.toolchain.cmake" ]]; then
      printf '%s\n' "$sdk_root/ndk-bundle"; return
    fi
  done
  ci_die "Unable to locate a complete Android NDK (checked ANDROID_NDK_HOME, ANDROID_NDK_ROOT, NDK, ANDROID_SDK_ROOT/ndk, ANDROID_HOME/ndk)"
}

android_target_for_abi() {
  case "$1" in
    arm64-v8a)   printf '%s\n' "aarch64-linux-android" ;;
    armeabi-v7a) printf '%s\n' "armv7a-linux-androideabi" ;;
    x86_64)      printf '%s\n' "x86_64-linux-android" ;;
    *) ci_die "Unsupported Android ABI: $1 (arm64-v8a, armeabi-v7a, x86_64)" ;;
  esac
}

# Directory of the ABI's runtime libraries under the NDK sysroot (usr/lib/<x>).
# Not the compiler target: 32-bit ARM compiles as armv7a-… but its libs live in arm-….
android_sysroot_triple() {
  case "$1" in
    arm64-v8a)   printf '%s\n' "aarch64-linux-android" ;;
    armeabi-v7a) printf '%s\n' "arm-linux-androideabi" ;;
    x86_64)      printf '%s\n' "x86_64-linux-android" ;;
    *) ci_die "Unsupported Android ABI: $1 (arm64-v8a, armeabi-v7a, x86_64)" ;;
  esac
}

# readelf for the staged-artifact checks (--stage-only has no toolchain in
# hand): the NDK's llvm-readelf when an NDK is discoverable, else
# llvm-readelf / readelf on PATH. Dies rather than skipping: an unverified
# library must not be staged into the app.
android_readelf_tool() {
  local ndk_path tool candidate
  if ndk_path="$(find_android_ndk 2>/dev/null)"; then
    tool="$(android_ndk_toolchain_dir "$ndk_path")/bin/llvm-readelf"
    if [[ -x "$tool" ]]; then printf '%s\n' "$tool"; return; fi
  fi
  for candidate in llvm-readelf readelf; do
    if command -v "$candidate" >/dev/null 2>&1; then printf '%s\n' "$candidate"; return; fi
  done
  ci_die "No readelf found to verify 16 KB page alignment (install an Android NDK, or llvm / binutils on PATH)"
}

# 16 KB page-size gate for one packaged library (see ANDROID_PAGE_SIZE_LDFLAGS):
# every PT_LOAD of a 64-bit library must have p_align >= 16 KB, and the
# GNU_RELRO region, whose end bionic rounds UP to the device page size before
# mprotect'ing it read-only, must not then cover writable non-RELRO data —
# neither the rest of its own segment (GNU ld puts .data behind RELRO in one
# RW segment unless common-page-size says 16 KB) nor a later segment. The end
# itself need not be 16 KB-aligned: lld leaves RELRO in its own segment with a
# page gap behind it (the NDK r28 libc++_shared.so ends its RELRO on an 8 KB
# boundary and is fine). 32-bit ABIs are skipped: 16 KB kernels are 64-bit
# only. $1 library, $2 readelf (llvm-readelf or GNU readelf; -lW output has
# the same shape), $3 log label.
assert_android_page_alignment() {
  local so="$1" readelf="$2" label="$3"
  local header phdrs type vaddr memsz rest align bad=0 i
  local relro_start=-1 relro_end=-1 relro_up seg_start seg_end
  local -a load_start=() load_end=() load_rw=()
  local page="$ANDROID_PAGE_SIZE"
  [[ -f "$so" ]] || ci_die "[$label] $so missing (page-alignment check)"
  header="$("$readelf" -h "$so" 2>/dev/null)" || ci_die "[$label] $readelf -h failed for $so"
  if ! grep -q 'ELF64' <<<"$header"; then
    ci_log "[$label] $(basename "$so"): 32-bit, 16 KB page alignment not required"
    return 0
  fi
  phdrs="$("$readelf" -lW "$so" 2>/dev/null)" || ci_die "[$label] $readelf -lW failed for $so"
  # Columns: Type Offset VirtAddr PhysAddr FileSiz MemSiz Flg Align; Flg is
  # "R", "R E", "RW" or "RWE", so Align is read as the last field of the rest.
  while read -r type _ vaddr _ _ memsz rest; do
    align="${rest##* }"
    case "$type" in
      LOAD)
        if (( align < page )); then
          ci_warn "[$label] $(basename "$so"): LOAD segment at $vaddr has p_align $align (< $page)"
          bad=1
        fi
        # Only writable segments can be broken by the RELRO protection below.
        case "${rest% *}" in *W*) load_rw+=(1) ;; *) load_rw+=(0) ;; esac
        load_start+=("$(( vaddr ))")
        load_end+=("$(( vaddr + memsz ))") ;;
      GNU_RELRO)
        relro_start=$(( vaddr ))
        relro_end=$(( vaddr + memsz )) ;;
    esac
  done < <(grep -E '^[[:space:]]+(LOAD|GNU_RELRO)[[:space:]]' <<<"$phdrs")
  if (( ${#load_start[@]} == 0 )); then
    ci_die "[$label] $(basename "$so"): no LOAD segment parsed from $readelf -lW output"
  fi
  if (( relro_start >= 0 )); then
    # bionic mprotects every page RELRO touches: [relro_start, relro_up) ends
    # up read-only. Writable data inside that window, whether the rest of
    # RELRO's own segment or a later segment, would fault on first write;
    # writable data at or beyond relro_up is untouched, however the segment
    # is laid out (an aligned RELRO end followed by .data is fine).
    relro_up=$(( (relro_end + page - 1) / page * page ))
    for (( i = 0; i < ${#load_start[@]}; i++ )); do
      seg_start="${load_start[$i]}"; seg_end="${load_end[$i]}"
      (( load_rw[i] )) || continue
      if (( seg_start <= relro_start && relro_start < seg_end )); then
        # The segment holding RELRO: writable data between the RELRO end and
        # the rounded end (the RW .data of a GNU-ld layout) would be protected.
        if (( relro_end < relro_up && seg_end > relro_end )); then
          ci_warn "[$label] $(basename "$so"): RELRO ends at $(printf '0x%x' "$relro_end") and its segment continues to $(printf '0x%x' "$seg_end") inside the $page-byte page that bionic would protect"
          bad=1
        fi
      elif (( seg_start >= relro_end )); then
        # A later writable segment must not start inside the protected window.
        if (( seg_start < relro_up )); then
          ci_warn "[$label] $(basename "$so"): segment at $(printf '0x%x' "$seg_start") shares a $page-byte page with the RELRO end $(printf '0x%x' "$relro_end")"
          bad=1
        fi
      fi
    done
  fi
  if (( bad )); then
    ci_die "[$label] $(basename "$so") is not 16 KB page-aligned. Rebuild with tool/build_android_ffi.sh (the link flags are fixed there); if the offender is libc++_shared.so, the NDK is older than r27 and must be upgraded."
  fi
  ci_log "[$label] $(basename "$so"): 16 KB page alignment OK"
}

build_android_abi() {
  local abi="$1" ndk_path="$2"
  local target toolchain sysroot prefix build_dir built_lib
  target="$(android_target_for_abi "$abi")"
  toolchain="$(android_ndk_toolchain_dir "$ndk_path")"
  sysroot="$toolchain/sysroot"
  prefix="$DEPS_ROOT/android-$abi"
  build_dir="$WORK_ROOT/android-$abi"

  (
    export CC CXX AR RANLIB STRIP CFLAGS
    CC="$toolchain/bin/${target}${ANDROID_API}-clang"
    CXX="$toolchain/bin/${target}${ANDROID_API}-clang++"
    AR="$toolchain/bin/llvm-ar"
    RANLIB="$toolchain/bin/llvm-ranlib"
    STRIP="$toolchain/bin/llvm-strip"
    CFLAGS="-O2 -fPIC"
    build_static_libsodium "$prefix" "android-$abi" --host="$target" --with-sysroot="$sysroot" --disable-pie
  )

  mkdir -p "$OUTPUT_DIR/jniLibs/$abi"
  PKG_CONFIG_PATH="$prefix/lib/pkgconfig" PKG_CONFIG_LIBDIR="$prefix/lib/pkgconfig" PKG_CONFIG_SYSROOT_DIR="" \
  configure_and_build "$build_dir" "android-$abi" \
    -DCMAKE_BUILD_TYPE="$NATIVE_BUILD_TYPE" \
    -DCMAKE_TOOLCHAIN_FILE="$ndk_path/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI="$abi" \
    -DANDROID_PLATFORM="android-$ANDROID_API" \
    -DANDROID_STL=c++_shared \
    -DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON \
    -DCMAKE_SHARED_LINKER_FLAGS="$ANDROID_PAGE_SIZE_LDFLAGS" \
    -DCMAKE_PREFIX_PATH="$prefix" \
    -DTIM2TOX_DEP_PREFIX="$prefix" \
    -DCMAKE_FIND_ROOT_PATH="$prefix;$sysroot" \
    -DCMAKE_C_FLAGS="-Wno-error=format" \
    -DCMAKE_CXX_FLAGS="-Wno-error=deprecated-copy -Wno-error=format"

  built_lib="$(find_built "$build_dir" libtim2tox_ffi.so)"
  cp "$built_lib" "$OUTPUT_DIR/jniLibs/$abi/libtim2tox_ffi.so"
  # Strip debug info; the Android export map keeps only the C ABI in .dynsym,
  # and assert_dart_entrypoints below proves DartInitSDK survived.
  "$toolchain/bin/llvm-strip" --strip-unneeded "$OUTPUT_DIR/jniLibs/$abi/libtim2tox_ffi.so" || true
  # ANDROID_STL=c++_shared: the library NEEDs libc++_shared.so, which neither
  # Flutter (libflutter.so links libc++ statically) nor any plugin ships, so it
  # travels in the same jniLibs/<abi>/ (NDK "C++ library support"); without it
  # DynamicLibrary.open fails on the device.
  local stl
  stl="$sysroot/usr/lib/$(android_sysroot_triple "$abi")/libc++_shared.so"
  [[ -f "$stl" ]] || ci_die "[android-$abi] libc++_shared.so not found at $stl"
  cp "$stl" "$OUTPUT_DIR/jniLibs/$abi/libc++_shared.so"
  ci_log "[android-$abi] captured $built_lib (+ libc++_shared.so)"
  verify_artifact "$OUTPUT_DIR/jniLibs/$abi/libtim2tox_ffi.so" "$toolchain/bin/llvm-nm" "android-$abi"
  assert_android_page_alignment "$OUTPUT_DIR/jniLibs/$abi/libtim2tox_ffi.so" "$toolchain/bin/llvm-readelf" "android-$abi"
  assert_android_page_alignment "$OUTPUT_DIR/jniLibs/$abi/libc++_shared.so" "$toolchain/bin/llvm-readelf" "android-$abi"
}

build_android() {
  local ndk_path abi
  local -a abis=()
  ci_require_cmd cmake
  bootstrap_tim2tox_submodules
  ndk_path="$(find_android_ndk)"
  ci_log "[android] NDK=$ndk_path api=$ANDROID_API abis=$ANDROID_ABIS_CSV"
  IFS=',' read -r -a abis <<<"${ANDROID_ABIS_CSV// /,}"
  for abi in "${abis[@]}"; do
    [[ -n "$abi" ]] || continue
    build_android_abi "$abi" "$ndk_path"
  done
  stage_android_into_app
}

stage_android_into_app() {
  [[ "$STAGE_APP" -eq 1 ]] || return 0
  local jni="$APP_DIR/android/app/src/main/jniLibs"
  [[ -d "$OUTPUT_DIR/jniLibs" ]] || ci_die "stage: $OUTPUT_DIR/jniLibs missing"
  [[ -n "$(find "$OUTPUT_DIR/jniLibs" -type f -name libtim2tox_ffi.so -print -quit)" ]] || ci_die "stage: no libtim2tox_ffi.so under $OUTPUT_DIR/jniLibs"
  # Replace, do not merge: a stale ABI left behind would be packaged by Gradle.
  rm -rf "$jni"
  mkdir -p "$jni"
  cp -R "$OUTPUT_DIR/jniLibs"/. "$jni/"
  ci_log "[android] staged into $jni: $(cd "$jni" && ls -d */ | tr -d '/' | tr '\n' ' ')"
}

# ---------------------------------------------------------------------------
# iOS (device arm64; simulator universal arm64+x86_64), static libsodium,
# packaged as tim2tox_ffi.framework (+ raw dylib). tool/build_ios_ffi.sh
# combines the two into the XCFramework CocoaPods vendors.
# ---------------------------------------------------------------------------
ios_sdk_name() {
  case "$1" in
    device) printf '%s\n' "iphoneos" ;;
    simulator) printf '%s\n' "iphonesimulator" ;;
  esac
}

ios_triple() {
  local arch="$1" variant="$2"
  if [[ "$variant" == "simulator" ]]; then printf '%s\n' "${arch}-apple-ios${IOS_MIN}-simulator"
  else printf '%s\n' "${arch}-apple-ios${IOS_MIN}"; fi
}

build_ios_slice() {
  local arch="$1" variant="$2"
  local sdk sysroot triple tflags prefix build_dir clang built_lib host_triple
  sdk="$(ios_sdk_name "$variant")"
  sysroot="$(xcrun --sdk "$sdk" --show-sdk-path)"
  ci_require_no_whitespace "$sysroot" "[ios-$variant-$arch] $sdk SDK path"
  clang="$(xcrun --sdk "$sdk" -f clang)"
  triple="$(ios_triple "$arch" "$variant")"
  tflags="-target $triple -isysroot $sysroot"
  prefix="$DEPS_ROOT/ios-$variant-$arch"
  build_dir="$WORK_ROOT/ios-$variant-$arch"
  case "$arch" in
    arm64) host_triple="aarch64-apple-darwin" ;;
    x86_64) host_triple="x86_64-apple-darwin" ;;
    *) ci_die "Unsupported iOS arch: $arch" ;;
  esac

  (
    export CC CFLAGS LDFLAGS
    CC="$clang"
    CFLAGS="$tflags -O2"
    LDFLAGS="$tflags"
    build_static_libsodium "$prefix" "ios-$variant-$arch" --host="$host_triple" --disable-pie
  ) || return 1

  PKG_CONFIG_PATH="$prefix/lib/pkgconfig" PKG_CONFIG_LIBDIR="$prefix/lib/pkgconfig" \
  configure_and_build "$build_dir" "ios-$variant-$arch" \
    -DCMAKE_BUILD_TYPE="$NATIVE_BUILD_TYPE" \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT="$sysroot" \
    -DCMAKE_OSX_ARCHITECTURES="$arch" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$IOS_MIN" \
    -DCMAKE_C_COMPILER="$clang" \
    -DCMAKE_CXX_COMPILER="$(xcrun --sdk "$sdk" -f clang++)" \
    -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
    -DCMAKE_PREFIX_PATH="$prefix" \
    -DTIM2TOX_DEP_PREFIX="$prefix" \
    -DCMAKE_C_FLAGS="-target $triple -Wno-error=format" \
    -DCMAKE_CXX_FLAGS="-target $triple -Wno-error=deprecated-copy -Wno-error=format" \
    -DCMAKE_EXE_LINKER_FLAGS="-target $triple" \
    -DCMAKE_SHARED_LINKER_FLAGS="-target $triple" || return 1

  built_lib="$(find_built "$build_dir" libtim2tox_ffi.dylib)" || return 1
  printf '%s\n' "$built_lib"
}

build_ios() {
  local variant="$1"         # device | simulator
  local -a archs=() slices=()
  local arch dy universal fw_dir fw_platform

  [[ "$HOST_OS" == "macos" ]] || ci_die "$TARGET must be built on a macOS host (got $HOST_OS)"
  ci_require_cmd cmake
  ci_require_cmd xcrun
  ci_require_cmd lipo
  ci_require_cmd install_name_tool
  bootstrap_tim2tox_submodules

  if [[ "$variant" == "device" ]]; then
    archs=(arm64); fw_platform="iPhoneOS"
  else
    # Universal simulator slice: some plugin pods ship no arm64-simulator
    # slice and force the Runner to x86_64 (Rosetta) on Apple Silicon.
    read -r -a archs <<<"$IOS_SIM_ARCHS"; fw_platform="iPhoneSimulator"
  fi

  for arch in "${archs[@]}"; do
    dy="$(build_ios_slice "$arch" "$variant")" || ci_die "[$TARGET] $arch slice failed"
    ci_log "[$TARGET] built $arch slice: $dy"
    slices+=("$dy")
  done

  universal="$OUTPUT_DIR/libtim2tox_ffi.dylib"
  if [[ ${#slices[@]} -gt 1 ]]; then
    lipo -create "${slices[@]}" -output "$universal"
  else
    cp "${slices[0]}" "$universal"
  fi

  fw_dir="$OUTPUT_DIR/tim2tox_ffi.framework"
  rm -rf "$fw_dir"
  mkdir -p "$fw_dir"
  cp "$universal" "$fw_dir/tim2tox_ffi"
  install_name_tool -id "@rpath/tim2tox_ffi.framework/tim2tox_ffi" "$fw_dir/tim2tox_ffi"
  cat > "$fw_dir/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>tim2tox_ffi</string>
  <key>CFBundleIdentifier</key><string>icu.agentx.ditmesh.tim2tox-ffi</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>tim2tox_ffi</string>
  <key>CFBundlePackageType</key><string>FMWK</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>MinimumOSVersion</key><string>${IOS_MIN}</string>
  <key>CFBundleSupportedPlatforms</key><array><string>${fw_platform}</string></array>
</dict>
</plist>
PLIST
  # App Store privacy manifest of the framework (required-reason APIs).
  cp "$SCRIPT_DIR/ios/tim2tox_ffi.PrivacyInfo.xcprivacy" "$fw_dir/PrivacyInfo.xcprivacy" \
    || ci_die "[$TARGET] privacy manifest copy failed"
  install_name_tool -id "@rpath/libtim2tox_ffi.dylib" "$universal"
  # dlopen'd from the app bundle: a bad signature is a hard load failure.
  codesign --force --sign - "$fw_dir" || ci_die "[$TARGET] codesign framework failed"
  codesign --verify --strict "$fw_dir" || ci_die "[$TARGET] codesign --verify failed for framework"
  codesign --force --sign - "$universal" || ci_die "[$TARGET] codesign dylib failed"

  verify_artifact "$fw_dir/tim2tox_ffi" nm "$TARGET"
  ci_log "[$TARGET] $(lipo -info "$fw_dir/tim2tox_ffi")"
  ci_log "[$TARGET] $(vtool -show-build "$fw_dir/tim2tox_ffi" 2>/dev/null | grep -iE 'platform|minos' | tr '\n' ' ' || true)"
  ci_log "[$TARGET] framework: $fw_dir"
}

# ---------------------------------------------------------------------------
# Entry
# ---------------------------------------------------------------------------
if [[ "$STAGE_ONLY" -eq 1 ]]; then
  [[ -d "$OUTPUT_DIR" ]] || ci_die "--stage-only: $OUTPUT_DIR does not exist"
  case "$FAMILY" in
    android)
      while IFS= read -r so; do verify_artifact "$so" "" "android-staged"; done \
        < <(find "$OUTPUT_DIR/jniLibs" -type f -name libtim2tox_ffi.so)
      # Every library that will be packaged (libtim2tox_ffi.so and the
      # libc++_shared.so captured next to it) must be 16 KB page-aligned.
      readelf_tool="$(android_readelf_tool)"
      while IFS= read -r so; do assert_android_page_alignment "$so" "$readelf_tool" "android-staged"; done \
        < <(find "$OUTPUT_DIR/jniLibs" -type f -name '*.so')
      stage_android_into_app ;;
    macos)
      verify_artifact "$OUTPUT_DIR/libtim2tox_ffi.dylib" nm "$TARGET"
      stage_macos_into_app ;;
    ios)
      ci_log "iOS artifacts are combined into the XCFramework by tool/build_ios_ffi.sh; nothing to stage per slice"
      verify_artifact "$OUTPUT_DIR/tim2tox_ffi.framework/tim2tox_ffi" nm "$TARGET" ;;
    linux|windows)
      ci_log "$FAMILY: apps/ditmesh/$FAMILY/CMakeLists.txt reads build/native/$TARGET directly; nothing to stage"
      f="$OUTPUT_DIR/libtim2tox_ffi.so"; [[ "$FAMILY" == windows ]] && f="$OUTPUT_DIR/tim2tox_ffi.dll"
      verify_artifact "$f" nm "$TARGET" ;;
  esac
  ci_log "Done staging Tim2Tox artifacts for $TARGET"
  exit 0
fi

# Refuse impossible host/target pairs BEFORE touching the output directory so a
# wrong invocation leaves no empty build/native/<target>/ behind.
case "$FAMILY" in
  linux)      [[ "$HOST_OS" == "linux" ]]   || ci_die "$TARGET must be built on a Linux host (got $HOST_OS)" ;;
  macos|ios)  [[ "$HOST_OS" == "macos" ]]   || ci_die "$TARGET must be built on a macOS host (got $HOST_OS)" ;;
  windows)    [[ "$HOST_OS" == "windows" ]] || ci_die "$TARGET must be built on a Windows host from Git Bash (got $HOST_OS)" ;;
esac
ci_require_cmd cmake

mkdir -p "$WORK_ROOT" "$DEPS_ROOT" "$DOWNLOAD_DIR"
ci_reset_dir "$OUTPUT_DIR"
ci_log "target=$TARGET mode=$MODE native_build_type=$NATIVE_BUILD_TYPE toxav=OFF sqlite=$([[ $ENABLE_SQLITE -eq 1 ]] && echo ON || echo OFF) libsodium=$([[ $SYSTEM_LIBSODIUM -eq 1 ]] && echo system || echo "pinned-static-$LIBSODIUM_VERSION")"
ci_log "output=$OUTPUT_DIR"

case "$FAMILY" in
  linux)   build_linux "$ARCH" ;;
  macos)   build_macos "$ARCH" ;;
  windows) build_windows "$ARCH" ;;
  android) build_android ;;
  ios)     build_ios "$ARCH" ;;
esac

ci_log "Done preparing Tim2Tox artifacts for $TARGET ($MODE) -> $OUTPUT_DIR"

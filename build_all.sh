#!/usr/bin/env bash
#
# build_all.sh — build the Tim2Tox native library for a platform, then build the
# ditmesh Flutter app for it.
#
#   ./build_all.sh --platform <macos|linux|windows|android|ios> --mode <debug|profile|release> [--clean]
#
# Modelled on toxee's build_all.sh. Differences: the native step always goes
# through tool/ci/build_tim2tox.sh (toxee's build_ffi.sh convenience path is not
# used — it defaults the auto_tests test hooks ON and writes into third_party/),
# ToxAV is never built, and the Flutter build runs inside apps/ditmesh with
# --dart-define=DITMESH_FAKE_BACKEND=false so the real Tox backend is compiled in.
#
# Options:
#   --platform P         Repeatable. Default: every platform this host can build.
#   --mode M             debug | profile | release (default release)
#   --clean              flutter clean in apps/ditmesh before building
#   --skip-native        Do not (re)build libtim2tox_ffi; use what is staged
#   --skip-bootstrap     Skip dart run tool/bootstrap_deps.dart
#   --fake-backend       Build with DITMESH_FAKE_BACKEND=true (no Tox; UI only)
#   --android-abis a,b   ABIs (default arm64-v8a,armeabi-v7a,x86_64)
#   --package           Package the release outputs under dist/<platform>/
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
print_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/apps/ditmesh"
NATIVE_DIR="${DITMESH_NATIVE_ARTIFACTS_DIR:-${DITMESH_NATIVE_BUILD_ROOT:-$SCRIPT_DIR/build/native}}"
ASSERT_NO_TEST_HOOKS="$SCRIPT_DIR/tool/ci/assert_no_test_hooks.sh"
cd "$SCRIPT_DIR"

BUILD_MODE="release"
PLATFORMS=""
CLEAN=false
SKIP_NATIVE=false
SKIP_BOOTSTRAP=false
PACKAGE=false
FAKE_BACKEND="${DITMESH_FAKE_BACKEND:-false}"
ANDROID_ABIS="${DITMESH_ANDROID_ABIS:-arm64-v8a,armeabi-v7a,x86_64}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) BUILD_MODE="$2"; shift 2 ;;
    --platform) PLATFORMS="$PLATFORMS $2"; shift 2 ;;
    --clean) CLEAN=true; shift ;;
    --skip-native) SKIP_NATIVE=true; shift ;;
    --skip-bootstrap) SKIP_BOOTSTRAP=true; shift ;;
    --fake-backend) FAKE_BACKEND=true; shift ;;
    --android-abis) ANDROID_ABIS="$2"; shift 2 ;;
    --package) PACKAGE=true; shift ;;
    --help|-h)
      sed -n '3,25p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) print_error "Unknown option: $1 (see --help)"; exit 1 ;;
  esac
done

case "$BUILD_MODE" in
  debug|profile|release) ;;
  *) print_error "Invalid --mode '$BUILD_MODE' (debug|profile|release)"; exit 1 ;;
esac
if [[ "$PACKAGE" == true && ( "$BUILD_MODE" != release || "$FAKE_BACKEND" == true ) ]]; then
  print_error "--package requires --mode release and the real Tox backend"
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  print_error "Flutter is not installed or not in PATH"
  exit 1
fi
print_info "Flutter version: $(flutter --version | head -n 1)"

# Byte-level test-hook gate on whatever is about to be packaged (see
# tool/ci/assert_no_test_hooks.sh). Skipped when the location holds no FFI
# binary at all — "this platform was never built" is reported by the platform
# build itself, not here.
assert_hook_free_dir() {
  local dir="$1"
  if [[ -d "$dir" ]] && [[ -n "$(find "$dir" -type f \( -name 'libtim2tox_ffi.*' -o -name 'tim2tox_ffi.dll' -o -name 'tim2tox_ffi' \) -print -quit)" ]]; then
    bash "$ASSERT_NO_TEST_HOOKS" "$dir"
  fi
}

host_os() {
  case "$OSTYPE" in
    darwin*) echo macos ;;
    linux*) echo linux ;;
    msys*|cygwin*|mingw*|win32) echo windows ;;
    *) echo unknown ;;
  esac
}
HOST="$(host_os)"

if [[ -z "$PLATFORMS" ]]; then
  case "$HOST" in
    macos) PLATFORMS="macos ios android" ;;
    linux) PLATFORMS="linux android" ;;
    windows) PLATFORMS="windows" ;;
    *) print_error "Cannot infer platforms on host '$OSTYPE'; pass --platform"; exit 1 ;;
  esac
  print_info "Building for all platforms this host can build: $PLATFORMS"
else
  print_info "Building for: $PLATFORMS"
fi

# --- dependencies -----------------------------------------------------------
if [[ "$SKIP_BOOTSTRAP" == false ]]; then
  print_info "Bootstrapping dependencies (submodule + vendored SDK + pubspec_overrides)..."
  dart run tool/bootstrap_deps.dart
fi

if [[ "$CLEAN" == true ]]; then
  print_info "Cleaning apps/ditmesh..."
  (cd "$APP_DIR" && flutter clean)
fi

# Pub workspace: one resolution at the root covers every package/app. Only
# re-resolve when the lock is missing or older than the spec files.
need_pub_get=false
if [[ "$CLEAN" == true || ! -f pubspec.lock ]]; then
  need_pub_get=true
else
  for spec in pubspec.yaml pubspec_overrides.yaml apps/ditmesh/pubspec.yaml packages/*/pubspec.yaml; do
    if [[ -f "$spec" && "$spec" -nt pubspec.lock ]]; then need_pub_get=true; break; fi
  done
fi
if [[ "$need_pub_get" == true ]]; then
  print_info "Resolving workspace dependencies (dart pub get)..."
  dart pub get
else
  print_info "Workspace dependencies up to date — skipping pub get."
fi

# --- native library ---------------------------------------------------------
build_native() {
  local platform="$1"
  if [[ "$SKIP_NATIVE" == true ]]; then
    print_warn "--skip-native: using the already staged libtim2tox_ffi for $platform"
    return 0
  fi
  case "$platform" in
    linux|macos|windows)
      bash tool/ci/build_tim2tox.sh --target "$platform" --mode "$BUILD_MODE" ;;
    android)
      ABIS="$ANDROID_ABIS" bash tool/build_android_ffi.sh --mode "$BUILD_MODE" ;;
    ios)
      bash tool/build_ios_ffi.sh --mode "$BUILD_MODE" ;;
  esac
}

# --- flutter build ----------------------------------------------------------
DEFINES=(--dart-define="DITMESH_FAKE_BACKEND=$FAKE_BACKEND")
if [[ "$FAKE_BACKEND" == true ]]; then
  print_warn "DITMESH_FAKE_BACKEND=true — the app will run the in-memory backend, not Tox"
  export DITMESH_ALLOW_MISSING_FFI=1
fi

for PLATFORM in $PLATFORMS; do
  print_info "=== $PLATFORM ($BUILD_MODE) ==="
  case "$PLATFORM" in
    macos)
      if [[ "$HOST" != macos ]]; then print_warn "Skipping macOS build (not on macOS)"; continue; fi
      build_native macos
      assert_hook_free_dir "$APP_DIR/macos/Frameworks"
      (cd "$APP_DIR" && flutter build macos "--$BUILD_MODE" "${DEFINES[@]}")
      print_info "macOS build completed: $APP_DIR/build/macos/Build/Products/"
      ;;
    linux)
      if [[ "$HOST" != linux ]]; then print_warn "Skipping Linux build (not on Linux)"; continue; fi
      build_native linux
      assert_hook_free_dir "$NATIVE_DIR/linux-$(uname -m | sed 's/arm64/aarch64/')"
      (cd "$APP_DIR" && flutter build linux "--$BUILD_MODE" "${DEFINES[@]}")
      print_info "Linux build completed: $APP_DIR/build/linux/*/$BUILD_MODE/bundle/"
      ;;
    windows)
      if [[ "$HOST" != windows ]]; then print_warn "Skipping Windows build (not on Windows)"; continue; fi
      build_native windows
      (cd "$APP_DIR" && flutter build windows "--$BUILD_MODE" "${DEFINES[@]}")
      print_info "Windows build completed: $APP_DIR/build/windows/*/runner/"
      ;;
    android)
      build_native android
      # Gradle packages the staged jniLibs as-is, prebuilt or not.
      assert_hook_free_dir "$APP_DIR/android/app/src/main/jniLibs"
      (cd "$APP_DIR" && flutter build apk "--$BUILD_MODE" "${DEFINES[@]}")
      if [[ "$BUILD_MODE" == release ]]; then
        (cd "$APP_DIR" && flutter build appbundle --release "${DEFINES[@]}")
      fi
      print_info "Android build completed: $APP_DIR/build/app/outputs/flutter-apk/"
      ;;
    ios)
      if [[ "$HOST" != macos ]]; then print_warn "Skipping iOS build (not on macOS)"; continue; fi
      build_native ios
      # CocoaPods embeds whatever XCFramework is staged.
      assert_hook_free_dir "$APP_DIR/ios/Frameworks"
      (cd "$APP_DIR" && flutter build ios "--$BUILD_MODE" --no-codesign "${DEFINES[@]}")
      print_info "iOS build completed (unsigned): $APP_DIR/build/ios/iphoneos/"
      ;;
    *)
      print_error "Unknown platform: $PLATFORM"
      exit 1
      ;;
  esac
  if [[ "$PACKAGE" == true ]]; then
    bash tool/ci/package_artifacts.sh --target "$PLATFORM"
  fi
done

print_info "Build process completed!"

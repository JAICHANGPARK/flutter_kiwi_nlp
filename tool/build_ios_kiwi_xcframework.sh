#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_KIWI_SRC="${ROOT_DIR}/.tmp/kiwi-src-ios"
if [[ -d "${ROOT_DIR}/.tmp/kiwi-src-android/.git" ]]; then
  DEFAULT_KIWI_SRC="${ROOT_DIR}/.tmp/kiwi-src-android"
fi
KIWI_SRC="${DEFAULT_KIWI_SRC}"
KIWI_REPO_URL="${KIWI_REPO_URL:-https://github.com/bab2min/Kiwi}"
KIWI_REF="${KIWI_REF:-v0.22.2}"
BUILD_ROOT="${ROOT_DIR}/.tmp/kiwi-ios-build"
OUT_XCFRAMEWORK="${ROOT_DIR}/ios/Frameworks/Kiwi.xcframework"
JOBS="${JOBS:-8}"
SKIP_EXISTING=1

truthy() {
  case "${1:-}" in
    1|true|TRUE|True|yes|YES|on|ON)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

usage() {
  cat <<'EOF'
Usage: tool/build_ios_kiwi_xcframework.sh [options]

Options:
  --kiwi-src <path>          Existing Kiwi source root (default: ./.tmp/kiwi-src-ios, reuses ./.tmp/kiwi-src-android when available)
  --kiwi-ref <tag|branch>    Kiwi git ref to clone (default: v0.22.2)
  --kiwi-repo <url>          Kiwi git repository URL
  --jobs <n>                 Parallel build jobs (default: 8)
  --rebuild                  Rebuild even if ios/Frameworks/Kiwi.xcframework exists
  -h, --help                 Show this help

Environment:
  FLUTTER_KIWI_SKIP_IOS_FRAMEWORK_BUILD=true
      Skip iOS framework auto-build and exit 0.
  FLUTTER_KIWI_IOS_REBUILD=true
      Same as --rebuild.
  FLUTTER_KIWI_IOS_KIWI_SRC=/path/to/Kiwi
      Use local Kiwi source.
  FLUTTER_KIWI_IOS_KIWI_REF=v0.22.2
      Override clone ref.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kiwi-src)
      KIWI_SRC="${2:-}"
      shift 2
      ;;
    --kiwi-ref)
      KIWI_REF="${2:-}"
      shift 2
      ;;
    --kiwi-repo)
      KIWI_REPO_URL="${2:-}"
      shift 2
      ;;
    --jobs)
      JOBS="${2:-}"
      shift 2
      ;;
    --rebuild)
      SKIP_EXISTING=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[ios] Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -n "${FLUTTER_KIWI_IOS_KIWI_SRC:-}" ]]; then
  KIWI_SRC="${FLUTTER_KIWI_IOS_KIWI_SRC}"
fi
if [[ -n "${FLUTTER_KIWI_IOS_KIWI_REF:-}" ]]; then
  KIWI_REF="${FLUTTER_KIWI_IOS_KIWI_REF}"
fi
if truthy "${FLUTTER_KIWI_IOS_REBUILD:-false}"; then
  SKIP_EXISTING=0
fi

if truthy "${FLUTTER_KIWI_SKIP_IOS_FRAMEWORK_BUILD:-false}"; then
  echo "[ios] Skip auto-build (FLUTTER_KIWI_SKIP_IOS_FRAMEWORK_BUILD=true)."
  exit 0
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "[ios] Skip auto-build (requires macOS host)."
  exit 0
fi

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[ios] Required command not found: $cmd" >&2
    exit 1
  fi
}

need_cmd cmake
need_cmd git
need_cmd xcodebuild
need_cmd xcrun

if ! xcrun --sdk iphoneos --find clang >/dev/null 2>&1; then
  echo "[ios] iPhoneOS clang toolchain not found." >&2
  echo "[ios] Open Xcode once and verify 'xcode-select -p' is configured." >&2
  exit 1
fi
if ! xcrun --sdk iphonesimulator --find clang >/dev/null 2>&1; then
  echo "[ios] iPhoneSimulator clang toolchain not found." >&2
  echo "[ios] Open Xcode once and verify iOS SDKs are installed." >&2
  exit 1
fi

DERIVED_DATA_ROOT="${HOME}/Library/Developer/Xcode/DerivedData"
if ! mkdir -p "${DERIVED_DATA_ROOT}" >/dev/null 2>&1; then
  echo "[ios] Cannot write to Xcode DerivedData directory: ${DERIVED_DATA_ROOT}" >&2
  echo "[ios] Fix permission or use a user account with writable ~/Library/Developer/Xcode." >&2
  exit 1
fi

if [[ "$SKIP_EXISTING" -eq 1 && -f "${OUT_XCFRAMEWORK}/Info.plist" ]]; then
  echo "[ios] Reusing existing framework: $OUT_XCFRAMEWORK"
  exit 0
fi

prepare_kiwi_source() {
  if [[ -f "${KIWI_SRC}/CMakeLists.txt" ]]; then
    echo "[ios] Reusing Kiwi source: ${KIWI_SRC}"
  else
    echo "[ios] Cloning Kiwi source (${KIWI_REF}) to: ${KIWI_SRC}"
    rm -rf "${KIWI_SRC}"
    mkdir -p "$(dirname "${KIWI_SRC}")"
    GIT_LFS_SKIP_SMUDGE=1 \
      git -c filter.lfs.required=false -c filter.lfs.smudge= -c filter.lfs.process= \
      clone --depth 1 --branch "${KIWI_REF}" --recurse-submodules "${KIWI_REPO_URL}" "${KIWI_SRC}"
  fi

  if [[ ! -f "${KIWI_SRC}/CMakeLists.txt" ]]; then
    echo "[ios] Invalid Kiwi source (missing CMakeLists.txt): ${KIWI_SRC}" >&2
    exit 1
  fi

  if [[ -d "${KIWI_SRC}/.git" && -f "${KIWI_SRC}/.gitmodules" ]]; then
    git -C "${KIWI_SRC}" submodule update --init --recursive
  fi
}

build_for_sdk() {
  local name="$1"
  local sdk="$2"
  local archs="$3"
  local kiwi_cpu_arch="$4"
  local build_dir="${BUILD_ROOT}/${name}"
  local cc
  local cxx
  cc="$(xcrun --sdk "${sdk}" --find clang)"
  cxx="$(xcrun --sdk "${sdk}" --find clang++)"

  echo "[ios] Configure ${name} (sdk=${sdk}, archs=${archs})"
  rm -rf "${build_dir}"
  cmake -S "${KIWI_SRC}" -B "${build_dir}" -G Xcode \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT="${sdk}" \
    -DCMAKE_OSX_ARCHITECTURES="${archs}" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 \
    -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED=NO \
    -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY="" \
    -DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM="" \
    -DCMAKE_XCODE_ATTRIBUTE_GCC_TREAT_WARNINGS_AS_ERRORS=NO \
    -DCMAKE_C_COMPILER="${cc}" \
    -DCMAKE_CXX_COMPILER="${cxx}" \
    -DCMAKE_CXX_FLAGS="-Wno-shorten-64-to-32 -Wno-error=shorten-64-to-32" \
    -DKIWI_CPU_ARCH="${kiwi_cpu_arch}" \
    -DKIWI_BUILD_DYNAMIC=ON \
    -DKIWI_BUILD_CLI=OFF \
    -DKIWI_BUILD_EVALUATOR=OFF \
    -DKIWI_BUILD_MODEL_BUILDER=OFF \
    -DKIWI_BUILD_TEST=OFF \
    -DKIWI_JAVA_BINDING=OFF \
    -DKIWI_USE_CPUINFO=OFF

  echo "[ios] Build ${name}"
  cmake --build "${build_dir}" --config Release --target kiwi --parallel "${JOBS}" -- \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY= \
    GCC_TREAT_WARNINGS_AS_ERRORS=NO
}

resolve_dylib() {
  local build_dir="$1"
  local dylib_path
  dylib_path="$(
    find "${build_dir}" -type f -path '*/Release-*/libkiwi*.dylib' \
      | head -n 1
  )"
  if [[ -z "${dylib_path}" ]]; then
    dylib_path="$(find "${build_dir}" -type f -name 'libkiwi*.dylib' \
      | head -n 1)"
  fi
  if [[ -z "${dylib_path}" ]]; then
    echo "[ios] libkiwi*.dylib not found under ${build_dir}" >&2
    exit 1
  fi
  echo "${dylib_path}"
}

create_framework_bundle() {
  local dylib_path="$1"
  local framework_root="$2"
  local framework_dir="${framework_root}/Kiwi.framework"

  rm -rf "${framework_root}"
  mkdir -p "${framework_dir}/Headers" "${framework_dir}/Modules"
  cp -f "${dylib_path}" "${framework_dir}/Kiwi"

  if command -v install_name_tool >/dev/null 2>&1; then
    install_name_tool -id "@rpath/Kiwi.framework/Kiwi" "${framework_dir}/Kiwi" || true
  fi

  cp -f "${KIWI_SRC}"/include/kiwi/*.h "${framework_dir}/Headers/"
  cat > "${framework_dir}/Headers/Kiwi.h" <<'EOF'
#ifndef KIWI_FRAMEWORK_H
#define KIWI_FRAMEWORK_H

#include <Kiwi/capi.h>

#endif  // KIWI_FRAMEWORK_H
EOF

  cat > "${framework_dir}/Modules/module.modulemap" <<'EOF'
framework module Kiwi {
  umbrella header "Kiwi.h"
  export *
  module * { export * }
}
EOF

  cat > "${framework_dir}/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>Kiwi</string>
  <key>CFBundleIdentifier</key>
  <string>dev.flutter.flutter-kiwi-ffi.Kiwi</string>
  <key>CFBundleName</key>
  <string>Kiwi</string>
  <key>CFBundlePackageType</key>
  <string>FMWK</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
</dict>
</plist>
EOF
}

create_universal_simulator_framework() {
  local arm64_framework_root="$1"
  local x64_framework_root="$2"
  local out_framework_root="$3"
  local out_framework_dir="${out_framework_root}/Kiwi.framework"
  local arm64_binary="${arm64_framework_root}/Kiwi.framework/Kiwi"
  local x64_binary="${x64_framework_root}/Kiwi.framework/Kiwi"

  rm -rf "${out_framework_root}"
  mkdir -p "${out_framework_root}"
  cp -R "${arm64_framework_root}/Kiwi.framework" "${out_framework_dir}"

  xcrun lipo -create "${arm64_binary}" "${x64_binary}" \
    -output "${out_framework_dir}/Kiwi"
}

prepare_kiwi_source

mkdir -p "${BUILD_ROOT}" "$(dirname "${OUT_XCFRAMEWORK}")"
build_for_sdk "iphoneos-arm64" "iphoneos" "arm64" "arm64"
build_for_sdk "iphonesimulator-arm64" "iphonesimulator" "arm64" "arm64"
build_for_sdk "iphonesimulator-x86_64" "iphonesimulator" "x86_64" "x86_64"

DEVICE_DYLIB="$(resolve_dylib "${BUILD_ROOT}/iphoneos-arm64")"
SIM_ARM64_DYLIB="$(resolve_dylib "${BUILD_ROOT}/iphonesimulator-arm64")"
SIM_X64_DYLIB="$(resolve_dylib "${BUILD_ROOT}/iphonesimulator-x86_64")"

DEVICE_FRAMEWORK_ROOT="${BUILD_ROOT}/framework-iphoneos"
SIM_ARM64_FRAMEWORK_ROOT="${BUILD_ROOT}/framework-iphonesimulator-arm64"
SIM_X64_FRAMEWORK_ROOT="${BUILD_ROOT}/framework-iphonesimulator-x86_64"
SIM_UNIVERSAL_FRAMEWORK_ROOT="${BUILD_ROOT}/framework-iphonesimulator"
create_framework_bundle "${DEVICE_DYLIB}" "${DEVICE_FRAMEWORK_ROOT}"
create_framework_bundle "${SIM_ARM64_DYLIB}" "${SIM_ARM64_FRAMEWORK_ROOT}"
create_framework_bundle "${SIM_X64_DYLIB}" "${SIM_X64_FRAMEWORK_ROOT}"
create_universal_simulator_framework \
  "${SIM_ARM64_FRAMEWORK_ROOT}" \
  "${SIM_X64_FRAMEWORK_ROOT}" \
  "${SIM_UNIVERSAL_FRAMEWORK_ROOT}"

rm -rf "${OUT_XCFRAMEWORK}"
xcodebuild -create-xcframework \
  -framework "${DEVICE_FRAMEWORK_ROOT}/Kiwi.framework" \
  -framework "${SIM_UNIVERSAL_FRAMEWORK_ROOT}/Kiwi.framework" \
  -output "${OUT_XCFRAMEWORK}"

echo "[ios] Generated: ${OUT_XCFRAMEWORK}"

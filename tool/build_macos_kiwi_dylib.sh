#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_KIWI_SRC="${ROOT_DIR}/.tmp/kiwi-src-macos"
if [[ -d "${ROOT_DIR}/.tmp/kiwi-src-android/.git" ]]; then
  DEFAULT_KIWI_SRC="${ROOT_DIR}/.tmp/kiwi-src-android"
fi
KIWI_SRC="${DEFAULT_KIWI_SRC}"
KIWI_REPO_URL="${KIWI_REPO_URL:-https://github.com/bab2min/Kiwi}"
KIWI_REF="${KIWI_REF:-v0.22.2}"
BUILD_ROOT="${ROOT_DIR}/.tmp/kiwi-macos-build"
OUT_DYLIB="${ROOT_DIR}/macos/Frameworks/libkiwi.dylib"
ARCHS="arm64,x86_64"
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
Usage: tool/build_macos_kiwi_dylib.sh [options]

Options:
  --kiwi-src <path>          Existing Kiwi source root
                             (default: ./.tmp/kiwi-src-macos,
                              reuses ./.tmp/kiwi-src-android when available)
  --kiwi-ref <tag|branch>    Kiwi git ref to clone (default: v0.22.2)
  --kiwi-repo <url>          Kiwi git repository URL
  --archs <csv>              Target arch list (default: arm64,x86_64)
  --jobs <n>                 Parallel build jobs (default: 8)
  --rebuild                  Rebuild even if macos/Frameworks/libkiwi.dylib
                             already exists
  -h, --help                 Show this help

Environment:
  FLUTTER_KIWI_SKIP_MACOS_LIBRARY_BUILD=true
      Skip macOS library auto-build and exit 0.
  FLUTTER_KIWI_MACOS_REBUILD=true
      Same as --rebuild.
  FLUTTER_KIWI_MACOS_KIWI_SRC=/path/to/Kiwi
      Use local Kiwi source.
  FLUTTER_KIWI_MACOS_KIWI_REF=v0.22.2
      Override clone ref.
  FLUTTER_KIWI_MACOS_ARCHS=arm64,x86_64
      Override target arch list.
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
    --archs)
      ARCHS="${2:-}"
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
      echo "[macos] Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -n "${FLUTTER_KIWI_MACOS_KIWI_SRC:-}" ]]; then
  KIWI_SRC="${FLUTTER_KIWI_MACOS_KIWI_SRC}"
fi
if [[ -n "${FLUTTER_KIWI_MACOS_KIWI_REF:-}" ]]; then
  KIWI_REF="${FLUTTER_KIWI_MACOS_KIWI_REF}"
fi
if [[ -n "${FLUTTER_KIWI_MACOS_ARCHS:-}" ]]; then
  ARCHS="${FLUTTER_KIWI_MACOS_ARCHS}"
fi
if truthy "${FLUTTER_KIWI_MACOS_REBUILD:-false}"; then
  SKIP_EXISTING=0
fi

if truthy "${FLUTTER_KIWI_SKIP_MACOS_LIBRARY_BUILD:-false}"; then
  echo "[macos] Skip auto-build (FLUTTER_KIWI_SKIP_MACOS_LIBRARY_BUILD=true)."
  exit 0
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "[macos] Skip auto-build (requires macOS host)."
  exit 0
fi

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[macos] Required command not found: $cmd" >&2
    exit 1
  fi
}

need_cmd cmake
need_cmd git
need_cmd xcrun

if ! xcrun --sdk macosx --find clang >/dev/null 2>&1; then
  echo "[macos] macOS clang toolchain not found." >&2
  echo "[macos] Open Xcode once and verify 'xcode-select -p' is configured." >&2
  exit 1
fi

if [[ "$SKIP_EXISTING" -eq 1 && -s "${OUT_DYLIB}" ]]; then
  echo "[macos] Reusing existing library: ${OUT_DYLIB}"
  exit 0
fi

prepare_kiwi_source() {
  if [[ -f "${KIWI_SRC}/CMakeLists.txt" ]]; then
    echo "[macos] Reusing Kiwi source: ${KIWI_SRC}"
  else
    echo "[macos] Cloning Kiwi source (${KIWI_REF}) to: ${KIWI_SRC}"
    rm -rf "${KIWI_SRC}"
    mkdir -p "$(dirname "${KIWI_SRC}")"
    GIT_LFS_SKIP_SMUDGE=1 \
      git -c filter.lfs.required=false -c filter.lfs.smudge= \
      -c filter.lfs.process= clone --depth 1 --branch "${KIWI_REF}" \
      --recurse-submodules "${KIWI_REPO_URL}" "${KIWI_SRC}"
  fi

  if [[ ! -f "${KIWI_SRC}/CMakeLists.txt" ]]; then
    echo "[macos] Invalid Kiwi source (missing CMakeLists.txt): ${KIWI_SRC}" >&2
    exit 1
  fi

  if [[ -d "${KIWI_SRC}/.git" && -f "${KIWI_SRC}/.gitmodules" ]]; then
    git -C "${KIWI_SRC}" submodule update --init --recursive
  fi
}

build_for_arch() {
  local arch="$1"
  local kiwi_cpu_arch="$2"
  local build_dir="${BUILD_ROOT}/${arch}"
  local cc
  local cxx
  cc="$(xcrun --sdk macosx --find clang)"
  cxx="$(xcrun --sdk macosx --find clang++)"

  echo "[macos] Configure arch=${arch}"
  rm -rf "${build_dir}"
  cmake -S "${KIWI_SRC}" -B "${build_dir}" -G Xcode \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_SYSROOT=macosx \
    -DCMAKE_OSX_ARCHITECTURES="${arch}" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=10.11 \
    -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
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

  echo "[macos] Build arch=${arch}"
  cmake --build "${build_dir}" --config Release --target kiwi --parallel \
    "${JOBS}"
}

resolve_dylib() {
  local build_dir="$1"
  local dylib_path
  dylib_path="$(
    find "${build_dir}" -type f -path '*/Release-*/libkiwi*.dylib' \
      | head -n 1
  )"
  if [[ -z "${dylib_path}" ]]; then
    dylib_path="$(
      find "${build_dir}" -type f -name 'libkiwi*.dylib' | head -n 1
    )"
  fi
  if [[ -z "${dylib_path}" ]]; then
    echo "[macos] libkiwi*.dylib not found under ${build_dir}" >&2
    exit 1
  fi
  echo "${dylib_path}"
}

parse_archs() {
  local raw
  local arch
  local existing
  IFS=',' read -r -a RAW_ARCHS <<<"${ARCHS}"
  TARGET_ARCHS=()
  for raw in "${RAW_ARCHS[@]-}"; do
    arch="$(echo "${raw}" | xargs)"
    if [[ -z "${arch}" ]]; then
      continue
    fi
    case "${arch}" in
      arm64|x86_64)
        ;;
      *)
        echo "[macos] Unsupported arch: ${arch}" >&2
        exit 1
        ;;
    esac

    local duplicate=0
    for existing in "${TARGET_ARCHS[@]-}"; do
      if [[ "${existing}" == "${arch}" ]]; then
        duplicate=1
        break
      fi
    done
    if [[ "${duplicate}" -eq 0 ]]; then
      TARGET_ARCHS+=("${arch}")
    fi
  done

  if [[ "${#TARGET_ARCHS[@]}" -eq 0 ]]; then
    echo "[macos] Empty arch list." >&2
    exit 1
  fi
}

prepare_kiwi_source
parse_archs

mkdir -p "${BUILD_ROOT}" "$(dirname "${OUT_DYLIB}")"
DYLIBS=()
for arch in "${TARGET_ARCHS[@]-}"; do
  build_for_arch "${arch}" "${arch}"
  DYLIBS+=("$(resolve_dylib "${BUILD_ROOT}/${arch}")")
done

if [[ "${#DYLIBS[@]}" -eq 1 ]]; then
  cp -f "${DYLIBS[0]}" "${OUT_DYLIB}"
else
  need_cmd lipo
  xcrun lipo -create "${DYLIBS[@]}" -output "${OUT_DYLIB}"
fi

if command -v install_name_tool >/dev/null 2>&1; then
  install_name_tool -id "@rpath/libkiwi.dylib" "${OUT_DYLIB}" || true
fi

echo "[macos] Generated: ${OUT_DYLIB}"

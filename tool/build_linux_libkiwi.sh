#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_KIWI_SRC="${ROOT_DIR}/.tmp/kiwi-src-linux"
if [[ -d "${ROOT_DIR}/.tmp/kiwi-src-android/.git" ]]; then
  DEFAULT_KIWI_SRC="${ROOT_DIR}/.tmp/kiwi-src-android"
fi
KIWI_SRC="${DEFAULT_KIWI_SRC}"
KIWI_REPO_URL="${KIWI_REPO_URL:-https://github.com/bab2min/Kiwi}"
KIWI_REF="${KIWI_REF:-v0.22.2}"
BUILD_ROOT="${ROOT_DIR}/.tmp/kiwi-linux-build"
OUT_SO="${ROOT_DIR}/linux/prebuilt/libkiwi.so"
ARCH=""
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
Usage: tool/build_linux_libkiwi.sh [options]

Options:
  --kiwi-src <path>          Existing Kiwi source root
                             (default: ./.tmp/kiwi-src-linux,
                              reuses ./.tmp/kiwi-src-android when available)
  --kiwi-ref <tag|branch>    Kiwi git ref to clone (default: v0.22.2)
  --kiwi-repo <url>          Kiwi git repository URL
  --arch <name>              Target arch (default: host arch)
  --jobs <n>                 Parallel build jobs (default: 8)
  --rebuild                  Rebuild even if linux/prebuilt/libkiwi.so exists
  -h, --help                 Show this help

Environment:
  FLUTTER_KIWI_SKIP_LINUX_LIBRARY_BUILD=true
      Skip Linux library auto-build and exit 0.
  FLUTTER_KIWI_LINUX_REBUILD=true
      Same as --rebuild.
  FLUTTER_KIWI_LINUX_KIWI_SRC=/path/to/Kiwi
      Use local Kiwi source.
  FLUTTER_KIWI_LINUX_KIWI_REF=v0.22.2
      Override clone ref.
  FLUTTER_KIWI_LINUX_ARCH=x86_64
      Override target arch.
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
    --arch)
      ARCH="${2:-}"
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
      echo "[linux] Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -n "${FLUTTER_KIWI_LINUX_KIWI_SRC:-}" ]]; then
  KIWI_SRC="${FLUTTER_KIWI_LINUX_KIWI_SRC}"
fi
if [[ -n "${FLUTTER_KIWI_LINUX_KIWI_REF:-}" ]]; then
  KIWI_REF="${FLUTTER_KIWI_LINUX_KIWI_REF}"
fi
if [[ -n "${FLUTTER_KIWI_LINUX_ARCH:-}" ]]; then
  ARCH="${FLUTTER_KIWI_LINUX_ARCH}"
fi
if truthy "${FLUTTER_KIWI_LINUX_REBUILD:-false}"; then
  SKIP_EXISTING=0
fi

if truthy "${FLUTTER_KIWI_SKIP_LINUX_LIBRARY_BUILD:-false}"; then
  if [[ -s "${OUT_SO}" ]]; then
    echo "[linux] Skip auto-build (FLUTTER_KIWI_SKIP_LINUX_LIBRARY_BUILD=true)."
    exit 0
  fi
  echo "[linux] Skip requested, but output is missing: ${OUT_SO}" >&2
  exit 1
fi

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "[linux] Skip auto-build (requires Linux host)."
  exit 0
fi

resolve_arch() {
  local machine
  machine="$(uname -m)"
  case "${machine}" in
    x86_64|amd64)
      echo "x86_64"
      ;;
    aarch64|arm64)
      echo "arm64"
      ;;
    ppc64le)
      echo "ppc64le"
      ;;
    *)
      echo "${machine}"
      ;;
  esac
}

if [[ -z "${ARCH}" ]]; then
  ARCH="$(resolve_arch)"
fi

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[linux] Required command not found: $cmd" >&2
    exit 1
  fi
}

need_cmd cmake
need_cmd git

if [[ "$SKIP_EXISTING" -eq 1 && -s "${OUT_SO}" ]]; then
  echo "[linux] Reusing existing library: ${OUT_SO}"
  exit 0
fi

map_release_arch() {
  case "${1}" in
    x86_64)
      echo "x86_64"
      ;;
    arm64|aarch64)
      echo "aarch64"
      ;;
    ppc64le)
      echo "ppc64le"
      ;;
    *)
      return 1
      ;;
  esac
}

try_download_prebuilt() {
  if [[ ! "${KIWI_REF}" =~ ^v[0-9] ]]; then
    return 1
  fi

  local release_arch
  release_arch="$(map_release_arch "${ARCH}")" || return 1

  need_cmd curl
  need_cmd tar

  local version_no_v="${KIWI_REF#v}"
  local asset="kiwi_lnx_${release_arch}_v${version_no_v}.tgz"
  local url
  url="https://github.com/bab2min/Kiwi/releases/download/${KIWI_REF}/${asset}"
  local download_dir="${BUILD_ROOT}/download"
  local extract_dir="${BUILD_ROOT}/extract-${release_arch}"
  local archive_path="${download_dir}/${asset}"
  local extracted_lib="${extract_dir}/lib/libkiwi.so"

  mkdir -p "${download_dir}" "${extract_dir}" "$(dirname "${OUT_SO}")"
  echo "[linux] Try prebuilt asset: ${asset}"
  if ! curl -fL --retry 3 --retry-delay 1 -o "${archive_path}" "${url}"; then
    echo "[linux] Prebuilt asset download failed; fallback to source build."
    return 1
  fi

  rm -rf "${extract_dir}"
  mkdir -p "${extract_dir}"
  if ! tar -xzf "${archive_path}" -C "${extract_dir}"; then
    echo "[linux] Prebuilt asset extract failed; fallback to source build."
    return 1
  fi

  if [[ ! -f "${extracted_lib}" ]]; then
    echo "[linux] Prebuilt asset missing libkiwi.so; fallback to source build."
    return 1
  fi

  cp -f "${extracted_lib}" "${OUT_SO}"
  echo "[linux] Generated from prebuilt: ${OUT_SO}"
  return 0
}

prepare_kiwi_source() {
  if [[ -f "${KIWI_SRC}/CMakeLists.txt" ]]; then
    echo "[linux] Reusing Kiwi source: ${KIWI_SRC}"
  else
    echo "[linux] Cloning Kiwi source (${KIWI_REF}) to: ${KIWI_SRC}"
    rm -rf "${KIWI_SRC}"
    mkdir -p "$(dirname "${KIWI_SRC}")"
    GIT_LFS_SKIP_SMUDGE=1 \
      git -c filter.lfs.required=false -c filter.lfs.smudge= \
      -c filter.lfs.process= clone --depth 1 --branch "${KIWI_REF}" \
      --recurse-submodules "${KIWI_REPO_URL}" "${KIWI_SRC}"
  fi

  if [[ ! -f "${KIWI_SRC}/CMakeLists.txt" ]]; then
    echo "[linux] Invalid Kiwi source (missing CMakeLists.txt): ${KIWI_SRC}" >&2
    exit 1
  fi

  if [[ -d "${KIWI_SRC}/.git" && -f "${KIWI_SRC}/.gitmodules" ]]; then
    git -C "${KIWI_SRC}" submodule update --init --recursive
  fi
}

resolve_so() {
  local build_dir="$1"
  local so_path
  so_path="$(
    find "${build_dir}" -type f -name 'libkiwi.so' | head -n 1
  )"
  if [[ -z "${so_path}" ]]; then
    echo "[linux] libkiwi.so not found under ${build_dir}" >&2
    exit 1
  fi
  echo "${so_path}"
}

if try_download_prebuilt; then
  exit 0
fi

prepare_kiwi_source

BUILD_DIR="${BUILD_ROOT}/${ARCH}"
echo "[linux] Configure arch=${ARCH}"
rm -rf "${BUILD_DIR}"
cmake -S "${KIWI_SRC}" -B "${BUILD_DIR}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DKIWI_CPU_ARCH="${ARCH}" \
  -DKIWI_BUILD_DYNAMIC=ON \
  -DKIWI_BUILD_CLI=OFF \
  -DKIWI_BUILD_EVALUATOR=OFF \
  -DKIWI_BUILD_MODEL_BUILDER=OFF \
  -DKIWI_BUILD_TEST=OFF \
  -DKIWI_JAVA_BINDING=OFF \
  -DKIWI_USE_CPUINFO=OFF

echo "[linux] Build arch=${ARCH}"
cmake --build "${BUILD_DIR}" --target kiwi --parallel "${JOBS}"

mkdir -p "$(dirname "${OUT_SO}")"
cp -f "$(resolve_so "${BUILD_DIR}")" "${OUT_SO}"

echo "[linux] Generated: ${OUT_SO}"

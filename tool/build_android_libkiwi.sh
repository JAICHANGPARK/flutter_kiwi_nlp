#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KIWI_SRC="${ROOT_DIR}/.tmp/kiwi-src-android"
BUILD_ROOT="${ROOT_DIR}/.tmp/kiwi-android-build"
ABIS="arm64-v8a,x86_64"
ANDROID_PLATFORM=21
JOBS="${JOBS:-8}"

usage() {
  cat <<'EOF'
Usage: tool/build_android_libkiwi.sh [options]

Options:
  --kiwi-src <path>          Existing Kiwi source root (default: ./.tmp/kiwi-src-android)
  --abis <csv>               ABI list (default: arm64-v8a,x86_64)
  --android-platform <num>   Android API level (default: 21)
  --jobs <n>                 Parallel build jobs (default: 8)
  -h, --help                 Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kiwi-src)
      KIWI_SRC="${2:-}"
      shift 2
      ;;
    --abis)
      ABIS="${2:-}"
      shift 2
      ;;
    --android-platform)
      ANDROID_PLATFORM="${2:-}"
      shift 2
      ;;
    --jobs)
      JOBS="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[android] Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[android] Required command not found: $cmd" >&2
    exit 1
  fi
}

resolve_ndk() {
  if [[ -n "${ANDROID_NDK_HOME:-}" && -d "${ANDROID_NDK_HOME}" ]]; then
    echo "$ANDROID_NDK_HOME"
    return
  fi
  if [[ -n "${ANDROID_NDK_ROOT:-}" && -d "${ANDROID_NDK_ROOT}" ]]; then
    echo "$ANDROID_NDK_ROOT"
    return
  fi

  local sdk_ndk="${HOME}/Library/Android/sdk/ndk"
  if [[ -d "$sdk_ndk" ]]; then
    local latest
    latest="$(find "$sdk_ndk" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1)"
    if [[ -n "$latest" ]]; then
      echo "$latest"
      return
    fi
  fi
}

need_cmd cmake
need_cmd git

ANDROID_NDK_DIR="$(resolve_ndk || true)"
if [[ -z "${ANDROID_NDK_DIR}" || ! -d "${ANDROID_NDK_DIR}" ]]; then
  echo "[android] Android NDK not found." >&2
  echo "[android] Set ANDROID_NDK_HOME (or ANDROID_NDK_ROOT) and retry." >&2
  exit 1
fi

TOOLCHAIN_FILE="${ANDROID_NDK_DIR}/build/cmake/android.toolchain.cmake"
if [[ ! -f "$TOOLCHAIN_FILE" ]]; then
  echo "[android] Missing NDK toolchain file: $TOOLCHAIN_FILE" >&2
  exit 1
fi

if [[ ! -d "$KIWI_SRC/.git" ]]; then
  echo "[android] Cloning Kiwi source to: $KIWI_SRC"
  rm -rf "$KIWI_SRC"
  GIT_LFS_SKIP_SMUDGE=1 \
  git -c filter.lfs.required=false -c filter.lfs.smudge= -c filter.lfs.process= \
    clone --depth 1 --recurse-submodules https://github.com/bab2min/Kiwi "$KIWI_SRC"
fi

IFS=',' read -r -a ABI_LIST <<<"$ABIS"
if [[ ${#ABI_LIST[@]} -eq 0 ]]; then
  echo "[android] Empty ABI list." >&2
  exit 1
fi

for ABI in "${ABI_LIST[@]}"; do
  ABI="$(echo "$ABI" | xargs)"
  if [[ -z "$ABI" ]]; then
    continue
  fi

  case "$ABI" in
    arm64-v8a|armeabi-v7a|x86_64|x86)
      ;;
    *)
      echo "[android] Unsupported ABI: $ABI" >&2
      exit 1
      ;;
  esac

  BUILD_DIR="${BUILD_ROOT}/${ABI}"
  OUT_LIB_DIR="${ROOT_DIR}/android/src/main/jniLibs/${ABI}"
  OUT_LIB="${OUT_LIB_DIR}/libkiwi.so"

  echo "[android] Configure ABI=${ABI}"
  cmake -S "$KIWI_SRC" -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
    -DANDROID_ABI="$ABI" \
    -DANDROID_PLATFORM="android-${ANDROID_PLATFORM}" \
    -DKIWI_BUILD_DYNAMIC=ON \
    -DKIWI_BUILD_CLI=OFF \
    -DKIWI_BUILD_EVALUATOR=OFF \
    -DKIWI_BUILD_MODEL_BUILDER=OFF \
    -DKIWI_BUILD_TEST=OFF \
    -DKIWI_JAVA_BINDING=OFF \
    -DKIWI_USE_CPUINFO=OFF

  echo "[android] Build ABI=${ABI}"
  cmake --build "$BUILD_DIR" --target kiwi -j "$JOBS"

  mkdir -p "$OUT_LIB_DIR"
  if [[ -f "${BUILD_DIR}/libkiwi.so" ]]; then
    cp -f "${BUILD_DIR}/libkiwi.so" "$OUT_LIB"
  elif [[ -f "${BUILD_DIR}/lib/libkiwi.so" ]]; then
    cp -f "${BUILD_DIR}/lib/libkiwi.so" "$OUT_LIB"
  else
    echo "[android] libkiwi.so not found for ABI=${ABI}" >&2
    exit 1
  fi

  echo "[android] Installed: $OUT_LIB"
done

echo "[android] Done."

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="latest"
LINUX_ARCH="x86_64"
WINDOWS_ARCH="x64"
MODEL_ROOT="${ROOT_DIR}/.kiwi"
DOWNLOAD_DIR="${ROOT_DIR}/.tmp/kiwi-release"

FETCH_MACOS=1
FETCH_LINUX=1
FETCH_WINDOWS=1
FETCH_MODEL=1
FETCH_ANDROID=1

usage() {
  cat <<'EOF'
Usage: tool/fetch_kiwi_release_assets.sh [options]

Options:
  --version <tag|latest>     Kiwi release tag (example: v0.22.2). Default: latest
  --linux-arch <arch>        Linux asset arch: x86_64, aarch64, ppc64le. Default: x86_64
  --windows-arch <arch>      Windows asset arch: x64, Win32. Default: x64
  --model-root <path>        Directory where model archive is extracted. Default: ./.kiwi
  --download-dir <path>      Temporary download directory. Default: ./.tmp/kiwi-release
  --no-macos                 Skip macOS library fetch
  --no-linux                 Skip Linux library fetch
  --no-windows               Skip Windows library fetch
  --no-model                 Skip model fetch
  --no-android               Skip Android notice
  -h, --help                 Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="${2:-}"
      shift 2
      ;;
    --linux-arch)
      LINUX_ARCH="${2:-}"
      shift 2
      ;;
    --windows-arch)
      WINDOWS_ARCH="${2:-}"
      shift 2
      ;;
    --model-root)
      MODEL_ROOT="${2:-}"
      shift 2
      ;;
    --download-dir)
      DOWNLOAD_DIR="${2:-}"
      shift 2
      ;;
    --no-macos)
      FETCH_MACOS=0
      shift
      ;;
    --no-linux)
      FETCH_LINUX=0
      shift
      ;;
    --no-windows)
      FETCH_WINDOWS=0
      shift
      ;;
    --no-model)
      FETCH_MODEL=0
      shift
      ;;
    --no-android)
      FETCH_ANDROID=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[kiwi] Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

need_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[kiwi] Required command not found: $cmd" >&2
    exit 1
  fi
}

need_cmd curl
need_cmd jq
need_cmd tar
need_cmd unzip

mkdir -p "$DOWNLOAD_DIR"

if [[ "$VERSION" == "latest" ]]; then
  RELEASE_API="https://api.github.com/repos/bab2min/Kiwi/releases/latest"
else
  RELEASE_API="https://api.github.com/repos/bab2min/Kiwi/releases/tags/${VERSION}"
fi

echo "[kiwi] Fetch release metadata: $RELEASE_API"
RELEASE_JSON="$(curl -fsSL "$RELEASE_API")"
TAG_NAME="$(jq -r '.tag_name // empty' <<<"$RELEASE_JSON")"

if [[ -z "$TAG_NAME" || "$TAG_NAME" == "null" ]]; then
  echo "[kiwi] Could not resolve release tag from API response." >&2
  exit 1
fi

VERSION_NO_V="${TAG_NAME#v}"
echo "[kiwi] Resolved tag: $TAG_NAME"

asset_url() {
  local asset_name="$1"
  jq -r --arg n "$asset_name" '.assets[] | select(.name == $n) | .browser_download_url' <<<"$RELEASE_JSON" | head -n 1
}

download_asset() {
  local asset_name="$1"
  local output_path="$2"
  local url
  url="$(asset_url "$asset_name")"
  if [[ -z "$url" ]]; then
    echo "[kiwi] Asset not found in $TAG_NAME: $asset_name" >&2
    exit 1
  fi
  echo "[kiwi] Download: $asset_name"
  curl -fL --retry 3 --retry-delay 1 -o "$output_path" "$url"
}

extract_tgz() {
  local archive_path="$1"
  local output_dir="$2"
  rm -rf "$output_dir"
  mkdir -p "$output_dir"
  tar -xzf "$archive_path" -C "$output_dir"
}

if [[ "$FETCH_MACOS" -eq 1 ]]; then
  MAC_ARM_ARCHIVE="$DOWNLOAD_DIR/kiwi_mac_arm64_v${VERSION_NO_V}.tgz"
  MAC_X64_ARCHIVE="$DOWNLOAD_DIR/kiwi_mac_x86_64_v${VERSION_NO_V}.tgz"
  MAC_ARM_DIR="$DOWNLOAD_DIR/extract-macos-arm64"
  MAC_X64_DIR="$DOWNLOAD_DIR/extract-macos-x86_64"
  MAC_OUT_LIB="$ROOT_DIR/macos/Frameworks/libkiwi.dylib"

  download_asset "kiwi_mac_arm64_v${VERSION_NO_V}.tgz" "$MAC_ARM_ARCHIVE"
  download_asset "kiwi_mac_x86_64_v${VERSION_NO_V}.tgz" "$MAC_X64_ARCHIVE"
  extract_tgz "$MAC_ARM_ARCHIVE" "$MAC_ARM_DIR"
  extract_tgz "$MAC_X64_ARCHIVE" "$MAC_X64_DIR"

  ARM_LIB="$MAC_ARM_DIR/lib/libkiwi.dylib"
  X64_LIB="$MAC_X64_DIR/lib/libkiwi.dylib"

  mkdir -p "$(dirname "$MAC_OUT_LIB")"
  if command -v lipo >/dev/null 2>&1; then
    lipo -create -output "$MAC_OUT_LIB" "$ARM_LIB" "$X64_LIB"
    echo "[kiwi] macOS universal library created: $MAC_OUT_LIB"
  else
    if [[ "$(uname -m)" == "arm64" ]]; then
      cp -f "$ARM_LIB" "$MAC_OUT_LIB"
    else
      cp -f "$X64_LIB" "$MAC_OUT_LIB"
    fi
    echo "[kiwi] macOS single-arch library copied: $MAC_OUT_LIB"
  fi

  if command -v install_name_tool >/dev/null 2>&1; then
    install_name_tool -id "@rpath/libkiwi.dylib" "$MAC_OUT_LIB" || true
  fi
fi

if [[ "$FETCH_LINUX" -eq 1 ]]; then
  case "$LINUX_ARCH" in
    x86_64|aarch64|ppc64le) ;;
    *)
      echo "[kiwi] Unsupported --linux-arch: $LINUX_ARCH" >&2
      exit 1
      ;;
  esac

  LINUX_ARCHIVE="$DOWNLOAD_DIR/kiwi_lnx_${LINUX_ARCH}_v${VERSION_NO_V}.tgz"
  LINUX_DIR="$DOWNLOAD_DIR/extract-linux-${LINUX_ARCH}"
  LINUX_OUT_LIB="$ROOT_DIR/linux/prebuilt/libkiwi.so"

  download_asset "kiwi_lnx_${LINUX_ARCH}_v${VERSION_NO_V}.tgz" "$LINUX_ARCHIVE"
  extract_tgz "$LINUX_ARCHIVE" "$LINUX_DIR"
  mkdir -p "$(dirname "$LINUX_OUT_LIB")"
  cp -f "$LINUX_DIR/lib/libkiwi.so" "$LINUX_OUT_LIB"
  echo "[kiwi] Linux library copied: $LINUX_OUT_LIB"
fi

if [[ "$FETCH_WINDOWS" -eq 1 ]]; then
  case "$WINDOWS_ARCH" in
    x64|Win32) ;;
    *)
      echo "[kiwi] Unsupported --windows-arch: $WINDOWS_ARCH" >&2
      exit 1
      ;;
  esac

  WINDOWS_ARCHIVE="$DOWNLOAD_DIR/kiwi_win_${WINDOWS_ARCH}_v${VERSION_NO_V}.zip"
  WINDOWS_DIR="$DOWNLOAD_DIR/extract-win-${WINDOWS_ARCH}"
  WINDOWS_OUT_DLL="$ROOT_DIR/windows/prebuilt/kiwi.dll"

  download_asset "kiwi_win_${WINDOWS_ARCH}_v${VERSION_NO_V}.zip" "$WINDOWS_ARCHIVE"
  rm -rf "$WINDOWS_DIR"
  mkdir -p "$WINDOWS_DIR"
  unzip -q "$WINDOWS_ARCHIVE" -d "$WINDOWS_DIR"
  mkdir -p "$(dirname "$WINDOWS_OUT_DLL")"
  cp -f "$WINDOWS_DIR/lib/kiwi.dll" "$WINDOWS_OUT_DLL"
  echo "[kiwi] Windows DLL copied: $WINDOWS_OUT_DLL"
fi

if [[ "$FETCH_MODEL" -eq 1 ]]; then
  MODEL_ARCHIVE="$DOWNLOAD_DIR/kiwi_model_v${VERSION_NO_V}_base.tgz"
  download_asset "kiwi_model_v${VERSION_NO_V}_base.tgz" "$MODEL_ARCHIVE"
  mkdir -p "$MODEL_ROOT"
  tar -xzf "$MODEL_ARCHIVE" -C "$MODEL_ROOT"
  echo "[kiwi] Model extracted to: $MODEL_ROOT/models/cong/base"
  echo "[kiwi] Export this for local run:"
  echo "       FLUTTER_KIWI_NLP_MODEL_PATH=$MODEL_ROOT/models/cong/base"
fi

if [[ "$FETCH_ANDROID" -eq 1 ]]; then
  cat <<'EOF'
[kiwi] Android note:
       GitHub Releases currently ship Android as libKiwiJava.so (JNI wrapper),
       not libkiwi.so (C API). flutter_kiwi_nlp uses Kiwi C API symbols, so
       Android prebuilt is not auto-installed by this script.
       For Android FFI, build libkiwi.so from source for each ABI.
EOF
fi

echo "[kiwi] Done."

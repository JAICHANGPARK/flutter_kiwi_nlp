# Runtime and Build Notes

## Model path resolution

Native priority in `kiwi_analyzer_native.dart`:

1. `modelPath` argument
2. `assetModelPath` argument
3. `FLUTTER_KIWI_NLP_MODEL_PATH` (env)
4. `FLUTTER_KIWI_NLP_ASSET_MODEL_PATH` (`--dart-define`)
5. Built-in asset candidates
6. Archive download and local cache fallback

Web priority in `kiwi_analyzer_web.dart`:

1. `modelPath` or `assetModelPath`
2. `FLUTTER_KIWI_NLP_WEB_MODEL_BASE_URL`
3. Built-in package asset base URL
4. Archive fallback if URL loading fails

Legacy `FLUTTER_KIWI_FFI_*` keys remain compatibility aliases.

## Auto-prepare scripts

- Android: `tool/build_android_libkiwi.sh`
- iOS: `tool/build_ios_kiwi_xcframework.sh`
- macOS: `tool/build_macos_kiwi_dylib.sh`
- Linux: `tool/build_linux_libkiwi.sh`
- Windows: `tool/build_windows_kiwi_dll.ps1`
- Release assets helper: `tool/fetch_kiwi_release_assets.sh`

## Hook points

- Android: `android/build.gradle`
- iOS pod prepare: `ios/flutter_kiwi_nlp.podspec`
- macOS pod prepare: `macos/flutter_kiwi_nlp.podspec`
- Linux: `linux/CMakeLists.txt`
- Windows: `windows/CMakeLists.txt`

## Validation focus

- Preserve failure visibility (`KiwiException` details).
- Keep desktop scripts preferring official prebuilt artifacts, with source
  fallback.
- Keep checksum or archive verification behavior intact when touching download
  logic.

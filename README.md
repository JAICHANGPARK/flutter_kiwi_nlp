# flutter_kiwi_nlp

Native-first Flutter plugin for Korean morphological analysis powered by Kiwi.

> Note:
> This branch currently declares package name `flutter_kiwi_ffi` in `pubspec.yaml`.
> Until the package rename is applied, use dependency and import names with `flutter_kiwi_ffi`.

## Features

- One `KiwiAnalyzer` API for native (FFI) and web (WASM).
- Typed analysis result models (`KiwiAnalyzeResult`, `KiwiCandidate`, `KiwiToken`).
- Runtime user dictionary update via `addUserWord`.
- Built-in default model asset (`assets/kiwi-models/cong/base`).
- Native fallback: automatic default model download and local cache when no local model path is provided.
- Web fallback: tries same-origin model URLs first, then falls back to release archive download.

## Platform Support

| Platform | Backend | Notes |
| --- | --- | --- |
| Android | FFI + `libkiwi.so` | `arm64-v8a` and `x86_64` are included in this repo. Build additional ABIs if needed. |
| iOS | FFI + `Kiwi.xcframework` | Not bundled by default. Add `ios/Frameworks/Kiwi.xcframework` manually. |
| macOS | FFI + `libkiwi.dylib` | Looks up `macos/Frameworks/libkiwi.dylib` and framework/dylib candidates. |
| Linux | FFI + `libkiwi.so` | Uses `linux/prebuilt/libkiwi.so` when present. |
| Windows | FFI + `kiwi.dll` | Uses `windows/prebuilt/kiwi.dll` when present. |
| Web | `kiwi-nlp` WASM | Loads JS module, WASM, and model files from URL/file map. |

## Install

Add the plugin to your app `pubspec.yaml`.

```yaml
dependencies:
  flutter_kiwi_ffi:
    path: ../flutter_kiwi_nlp
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:flutter_kiwi_ffi/flutter_kiwi_ffi.dart';

Future<void> runDemo() async {
  final KiwiAnalyzer analyzer = await KiwiAnalyzer.create();

  final KiwiAnalyzeResult result = await analyzer.analyze(
    'Why are you picking a fight?',
    options: const KiwiAnalyzeOptions(topN: 1),
  );

  for (final KiwiCandidate c in result.candidates) {
    for (final KiwiToken t in c.tokens) {
      print('${t.form}/${t.tag} (${t.start}, ${t.length})');
    }
  }

  await analyzer.addUserWord('OpenAI', tag: 'NNP');
  await analyzer.close();
}
```

## Model Path Resolution

### Native (`dart:io`)

`KiwiAnalyzer.create()` resolves model path in this order:

1. `modelPath` argument
2. `assetModelPath` argument (extracts Flutter assets to temp directory)
3. `FLUTTER_KIWI_FFI_MODEL_PATH` (runtime environment variable)
4. `FLUTTER_KIWI_FFI_ASSET_MODEL_PATH` (`--dart-define`)
5. Built-in asset candidates:
   - `assets/kiwi-models/cong/base`
   - `packages/flutter_kiwi_ffi_models/assets/kiwi-models/cong/base`
   - `packages/flutter_kiwi_ffi/assets/kiwi-models/cong/base`
6. Default model archive download + extract to temp cache

Default native archive URL:

- `https://github.com/bab2min/Kiwi/releases/download/v0.22.2/kiwi_model_v0.22.2_base.tgz`

### Web

Web build first uses URL model files:

1. `modelPath` / `assetModelPath` argument
2. `FLUTTER_KIWI_FFI_WEB_MODEL_BASE_URL` (`--dart-define`)
3. Default base URL:
   - `assets/packages/flutter_kiwi_ffi/assets/kiwi-models/cong/base`

If URL-based build fails with asset-style paths, it falls back to archive download:

- direct URL candidates (`FLUTTER_KIWI_FFI_WEB_MODEL_ARCHIVE_URL` then default release URL)
- GitHub release API lookup

For predictable web behavior, host model files on same-origin assets and set `FLUTTER_KIWI_FFI_WEB_MODEL_BASE_URL`.

## Configuration

### Native variables

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `FLUTTER_KIWI_FFI_MODEL_PATH` | env var | empty | Absolute/relative model directory path at runtime. |
| `FLUTTER_KIWI_FFI_ASSET_MODEL_PATH` | `--dart-define` | empty | Asset base path to extract from Flutter assets. |
| `FLUTTER_KIWI_FFI_MODEL_ARCHIVE_URL` | `--dart-define` | Kiwi release URL | Default archive download URL for native fallback. |
| `FLUTTER_KIWI_FFI_MODEL_ARCHIVE_SHA256` | `--dart-define` | hardcoded hash | Optional archive checksum verification. |
| `FLUTTER_KIWI_FFI_MODEL_CACHE_KEY` | `--dart-define` | `v0.22.2_base` | Cache key segment under temp model cache directory. |
| `FLUTTER_KIWI_FFI_LIBRARY_PATH` | env var | empty | Override dynamic Kiwi library path (`libkiwi.*` / framework). |

### Web variables

| Name | Type | Default |
| --- | --- | --- |
| `FLUTTER_KIWI_FFI_WEB_MODULE_URL` | `--dart-define` | `https://cdn.jsdelivr.net/npm/kiwi-nlp@0.22.1/dist/index.js` |
| `FLUTTER_KIWI_FFI_WEB_WASM_URL` | `--dart-define` | `https://cdn.jsdelivr.net/npm/kiwi-nlp@0.22.1/dist/kiwi-wasm.wasm` |
| `FLUTTER_KIWI_FFI_WEB_MODEL_BASE_URL` | `--dart-define` | empty |
| `FLUTTER_KIWI_FFI_WEB_MODEL_ARCHIVE_URL` | `--dart-define` | empty |
| `FLUTTER_KIWI_FFI_WEB_MODEL_ARCHIVE_SHA256` | `--dart-define` | empty |
| `FLUTTER_KIWI_FFI_WEB_MODEL_GITHUB_REPO` | `--dart-define` | `bab2min/Kiwi` |
| `FLUTTER_KIWI_FFI_WEB_MODEL_ARCHIVE_VERSION` | `--dart-define` | `v0.22.2` |
| `FLUTTER_KIWI_FFI_WEB_MODEL_ARCHIVE_NAME` | `--dart-define` | `kiwi_model_v0.22.2_base.tgz` |

## Utility Scripts

### Fetch prebuilt release assets

```bash
./tool/fetch_kiwi_release_assets.sh --version v0.22.2
```

This fetches and places:

- macOS `libkiwi.dylib`
- Linux `libkiwi.so`
- Windows `kiwi.dll`
- default model archive (extracted under `.kiwi/models/cong/base`)

### Build Android `libkiwi.so` from source

```bash
./tool/build_android_libkiwi.sh --abis arm64-v8a,x86_64
```

Requirements:

- Android NDK (`ANDROID_NDK_HOME` or `ANDROID_NDK_ROOT`)
- `cmake`, `git`

Output location:

- `android/src/main/jniLibs/<abi>/libkiwi.so`

## API Summary

```dart
class KiwiAnalyzer {
  static Future<KiwiAnalyzer> create({
    String? modelPath,
    String? assetModelPath,
    int numThreads = -1,
    int buildOptions = KiwiBuildOption.defaultOption,
    int matchOptions = KiwiMatchOption.allWithNormalizing,
  });

  Future<KiwiAnalyzeResult> analyze(
    String text, {
    KiwiAnalyzeOptions options = const KiwiAnalyzeOptions(),
  });

  Future<void> addUserWord(String word, {String tag = 'NNP', double score = 0.0});
  Future<void> close();
  String get nativeVersion;
}
```

`KiwiBuildOption` and `KiwiMatchOption` are bitmask constants to control model loading and token matching behavior.

## Troubleshooting

- `Failed to load Kiwi dynamic library`
  - Verify native library exists for your platform.
  - Optionally set `FLUTTER_KIWI_FFI_LIBRARY_PATH`.
- `Model path is required` or model-not-found errors
  - Pass `modelPath`/`assetModelPath`, or set `FLUTTER_KIWI_FFI_MODEL_PATH`.
  - On web, prefer same-origin asset hosting and set `FLUTTER_KIWI_FFI_WEB_MODEL_BASE_URL`.
- First run is slow
  - Initial model download/extraction can take time, especially on web debug builds.

## License

See `LICENSE`.

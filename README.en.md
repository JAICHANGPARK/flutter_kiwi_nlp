# flutter_kiwi_nlp (English)

Native-first Flutter plugin for Korean morphological analysis powered by Kiwi.

## Package Name

Current package name in `pubspec.yaml` is `flutter_kiwi_ffi`.
Until rename is completed, use `flutter_kiwi_ffi` in dependency and import statements.

## Supported Platforms

| Platform | Status | Notes |
| --- | --- | --- |
| Android | Supported | Builds `libkiwi.so` automatically during Android `preBuild` if missing. |
| iOS | Supported (manual setup) | Add `ios/Frameworks/Kiwi.xcframework` manually. |
| macOS | Supported | Uses `macos/Frameworks/libkiwi.dylib` or framework candidates. |
| Linux | Supported | Uses `linux/prebuilt/libkiwi.so` when present. |
| Windows | Supported | Uses `windows/prebuilt/kiwi.dll` when present. |
| Web | Supported | Uses `kiwi-nlp` WASM backend. |

## Unsupported Platforms

| Platform | Status | Notes |
| --- | --- | --- |
| Fuchsia | Not supported | No Fuchsia backend implementation. |

## Features

- Unified `KiwiAnalyzer` API on native (FFI) and web (WASM).
- Typed result models: `KiwiAnalyzeResult`, `KiwiCandidate`, `KiwiToken`.
- Runtime user dictionary update via `addUserWord`.
- Built-in default model assets (`assets/kiwi-models/cong/base`).
- Native fallback default model download/cache.
- Web fallback from same-origin asset URL loading to archive download.

## Install

```yaml
dependencies:
  flutter_kiwi_ffi:
    path: ../flutter_kiwi_nlp
```

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
      print('${t.form}/${t.tag}');
    }
  }
  await analyzer.close();
}
```

## Model Path Resolution

### Native (`dart:io`)

Order used by `KiwiAnalyzer.create()`:

1. `modelPath` argument
2. `assetModelPath` argument
3. `FLUTTER_KIWI_FFI_MODEL_PATH` (env)
4. `FLUTTER_KIWI_FFI_ASSET_MODEL_PATH` (`--dart-define`)
5. Built-in asset candidates
6. Default model archive download/extract

Default archive URL:

- `https://github.com/bab2min/Kiwi/releases/download/v0.22.2/kiwi_model_v0.22.2_base.tgz`

### Web

Primary model source order:

1. `modelPath` / `assetModelPath` argument
2. `FLUTTER_KIWI_FFI_WEB_MODEL_BASE_URL`
3. `assets/packages/flutter_kiwi_ffi/assets/kiwi-models/cong/base`

If URL-based loading fails for asset-style paths, it falls back to archive download.

## Android Auto Build

The plugin runs `tool/build_android_libkiwi.sh` from `android/build.gradle` (`preBuild` dependency).

- Script skips existing ABI outputs by default.
- Force rebuild with `--rebuild`.
- Skip automatic build for one run with:
  - `-Pflutter.kiwi.skipAndroidLibBuild=true`

## Common Issues

- `Failed to load Kiwi dynamic library`
  - Verify native library exists for your platform.
  - Optionally set `FLUTTER_KIWI_FFI_LIBRARY_PATH`.
- Android auto-build fails (`cmake`/`git`/NDK not found)
  - Set `ANDROID_NDK_HOME` or `ANDROID_NDK_ROOT`.
  - Ensure `cmake` and `git` are on PATH.
- Model not found
  - Pass `modelPath` or `assetModelPath`.
  - Or set `FLUTTER_KIWI_FFI_MODEL_PATH`.

## License

See `LICENSE`.

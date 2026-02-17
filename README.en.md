# flutter_kiwi_nlp (English)

Native-first Flutter plugin for Korean morphological analysis powered by Kiwi.

## Package Name

Package name in `pubspec.yaml` is `flutter_kiwi_nlp`.
Use `flutter_kiwi_nlp` for dependency and import statements.

## Supported Platforms

| Platform | Status | Notes |
| --- | --- | --- |
| Android | Supported | Builds `libkiwi.so` automatically during Android `preBuild` if missing. |
| iOS | Supported | Generates `Kiwi.xcframework` automatically during `pod install` when missing. |
| macOS | Supported | Builds `libkiwi.dylib` automatically during `pod install` when missing. |
| Linux | Supported | Builds `libkiwi.so` automatically during Linux build when missing. |
| Windows | Supported | Builds `kiwi.dll` automatically during Windows build when missing. |
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

## Available APIs (Quick Table)

### Core API

| API | Signature | Description |
| --- | --- | --- |
| `KiwiAnalyzer.create` | `Future<KiwiAnalyzer> create({String? modelPath, String? assetModelPath, int numThreads = -1, int buildOptions = KiwiBuildOption.defaultOption, int matchOptions = KiwiMatchOption.allWithNormalizing})` | Creates an analyzer instance. You can control model path, build options, and match options. |
| `KiwiAnalyzer.nativeVersion` | `String get nativeVersion` | Returns a backend version string (for example native version or web/wasm version). |
| `KiwiAnalyzer.analyze` | `Future<KiwiAnalyzeResult> analyze(String text, {KiwiAnalyzeOptions options = const KiwiAnalyzeOptions()})` | Runs morphological analysis and returns candidate results. |
| `KiwiAnalyzer.addUserWord` | `Future<void> addUserWord(String word, {String tag = 'NNP', double score = 0.0})` | Adds a runtime user dictionary entry. |
| `KiwiAnalyzer.close` | `Future<void> close()` | Closes the analyzer and releases resources. |

On unsupported platforms, creating or calling `KiwiAnalyzer` throws
`KiwiException`.

### Options/Constants API

| API | Type | Description |
| --- | --- | --- |
| `KiwiAnalyzeOptions(topN, matchOptions)` | class | Option object for `analyze`. Defaults: `topN = 1`, `matchOptions = KiwiMatchOption.allWithNormalizing`. |
| `KiwiBuildOption.integrateAllomorph` | `int` bit flag | Integrate allomorph option. |
| `KiwiBuildOption.loadDefaultDict` | `int` bit flag | Load default dictionary option. |
| `KiwiBuildOption.loadTypoDict` | `int` bit flag | Load typo dictionary option. |
| `KiwiBuildOption.loadMultiDict` | `int` bit flag | Load multi-word dictionary option. |
| `KiwiBuildOption.modelTypeDefault` | `int` | Model type constant. |
| `KiwiBuildOption.modelTypeLargest` | `int` | Model type constant. |
| `KiwiBuildOption.modelTypeKnlm` | `int` | Model type constant. |
| `KiwiBuildOption.modelTypeSbg` | `int` | Model type constant. |
| `KiwiBuildOption.modelTypeCong` | `int` | Model type constant. |
| `KiwiBuildOption.modelTypeCongGlobal` | `int` | Model type constant. |
| `KiwiBuildOption.defaultOption` | `int` | Recommended default build option combination. |
| `KiwiMatchOption.url`/`email`/`hashtag`/`mention`/`serial` | `int` bit flag | URL/email/hashtag/mention/serial detection options. |
| `KiwiMatchOption.normalizeCoda` | `int` bit flag | Coda normalization option. |
| `KiwiMatchOption.joinNounPrefix`/`joinNounSuffix` | `int` bit flag | Noun prefix/suffix joining options. |
| `KiwiMatchOption.joinVerbSuffix`/`joinAdjSuffix`/`joinAdvSuffix` | `int` bit flag | Verb/adjective/adverb suffix joining options. |
| `KiwiMatchOption.splitComplex` | `int` bit flag | Complex form split option. |
| `KiwiMatchOption.zCoda` | `int` bit flag | Coda-related matching option. |
| `KiwiMatchOption.compatibleJamo` | `int` bit flag | Compatibility jamo option. |
| `KiwiMatchOption.splitSaisiot`/`mergeSaisiot` | `int` bit flag | Saisiot split/merge options. |
| `KiwiMatchOption.all` | `int` | Baseline match option bundle. |
| `KiwiMatchOption.allWithNormalizing` | `int` | `all + normalizeCoda` bundle. |

### Result/Exception Model API

| API | Type | Description |
| --- | --- | --- |
| `KiwiAnalyzeResult.candidates` | `List<KiwiCandidate>` | Candidate list for analysis output. |
| `KiwiCandidate.probability` | `double` | Candidate score/probability. |
| `KiwiCandidate.tokens` | `List<KiwiToken>` | Token list for the candidate. |
| `KiwiToken.form` | `String` | Token surface form. |
| `KiwiToken.tag` | `String` | Part-of-speech tag. |
| `KiwiToken.start`/`length` | `int` | Start offset and length in input text. |
| `KiwiToken.wordPosition`/`sentPosition` | `int` | Word/sentence index positions. |
| `KiwiToken.score`/`typoCost` | `double` | Token score and typo cost. |
| `KiwiException` | `Exception` | Plugin error type. Check the `message` field for details. |

## Size Impact (Approx.) and `kiwipiepy` Comparison

As of `2026-02-17`:

| Item | Basis | Size (Approx.) | Notes |
| --- | --- | --- | --- |
| `flutter_kiwi_nlp` default model | Uncompressed model directory (`assets/kiwi-models/cong/base`) | `95MB` | Actual model file set that may be bundled as app assets |
| `flutter_kiwi_nlp` default model (tgz) | Same directory compressed locally (`/tmp/flutter_kiwi_model_base.tgz`) | `76MB` | Local compressed-size reference for fair comparison |
| `kiwipiepy_model 0.22.1` | PyPI source distribution (`.tar.gz`) | `79.5MB` | Published compressed package size on PyPI |
| Android `libkiwi.so` (reference) | Workspace build outputs in this repo | `159MB (arm64-v8a)`, `191MB (x86_64)` | Current binaries are `with debug_info`, `not stripped` |

Why do the numbers look different?

- Different measurement bases produce different numbers.
- `76MB`/`79.5MB` are compressed archives, while `95MB` is uncompressed model
  contents.
- Android native binaries are per-ABI, and size grows significantly when debug
  symbols are included.
- Store delivery size is usually smaller due to strip/compress/split in release
  pipelines.

References:

- https://pypi.org/project/kiwipiepy-model/
- https://pypi.org/project/kiwipiepy/

## Install

### 1) Install from pub.dev (recommended)

```bash
flutter pub add flutter_kiwi_nlp
```

Or edit `pubspec.yaml` directly:

```yaml
dependencies:
  flutter_kiwi_nlp: ^0.0.1
```

```bash
flutter pub get
```

### 2) Install from a local path (plugin development/testing)

```yaml
dependencies:
  flutter_kiwi_nlp:
    path: ../flutter_kiwi_nlp
```

```bash
flutter pub get
```

## Integrate Into a Flutter App

### 1) Import

```dart
import 'package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart';
```

### 2) Initialize and dispose safely in a `StatefulWidget`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart';

class KiwiDemoPage extends StatefulWidget {
  const KiwiDemoPage({super.key});

  @override
  State<KiwiDemoPage> createState() => _KiwiDemoPageState();
}

class _KiwiDemoPageState extends State<KiwiDemoPage> {
  KiwiAnalyzer? _analyzer;
  bool _loading = false;
  String? _error;
  String _resultText = '';

  @override
  void initState() {
    super.initState();
    _initializeAnalyzer();
  }

  Future<void> _initializeAnalyzer() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final KiwiAnalyzer analyzer = await KiwiAnalyzer.create();
      if (!mounted) {
        await analyzer.close();
        return;
      }
      setState(() => _analyzer = analyzer);
    } on KiwiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _analyzeSample() async {
    final KiwiAnalyzer? analyzer = _analyzer;
    if (analyzer == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final KiwiAnalyzeResult result = await analyzer.analyze(
        'Why are you picking a fight?',
        options: const KiwiAnalyzeOptions(
          topN: 1,
          matchOptions: KiwiMatchOption.allWithNormalizing,
        ),
      );

      final String line = result.candidates.first.tokens
          .map((KiwiToken token) => '${token.form}/${token.tag}')
          .join(' ');

      if (!mounted) return;
      setState(() => _resultText = line);
    } on KiwiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _analyzer?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FilledButton(
          onPressed: _loading ? null : _analyzeSample,
          child: const Text('Analyze'),
        ),
        if (_error != null) Text('Error: $_error'),
        if (_resultText.isNotEmpty) Text(_resultText),
      ],
    );
  }
}
```

Dart/Flutter notes:

- `KiwiAnalyzer.create()` and `analyze()` return `Future`s, so use `await`
  inside `try-catch`.
- `_analyzer` uses `KiwiAnalyzer?` due to null safety; it can be `null`
  before initialization.
- After an `await`, check `mounted` before calling `setState`.

## Common Usage Patterns

### Add user dictionary entries

```dart
await analyzer.addUserWord(
  'FlutterKiwi',
  tag: 'NNP',
  score: 2.0,
);
```

### Tune analyze options

```dart
const KiwiAnalyzeOptions options = KiwiAnalyzeOptions(
  topN: 3,
  matchOptions: KiwiMatchOption.url |
      KiwiMatchOption.email |
      KiwiMatchOption.hashtag |
      KiwiMatchOption.normalizeCoda,
);
```

`matchOptions` uses bitwise OR (`|`) composition.

### Iterate through results

```dart
final KiwiAnalyzeResult result = await analyzer.analyze('Input a sentence.');
for (final KiwiCandidate candidate in result.candidates) {
  debugPrint('candidate p=${candidate.probability}');
  for (final KiwiToken token in candidate.tokens) {
    debugPrint('${token.form}\t${token.tag}');
  }
}
```

## Model Path Configuration Guide

### A. Use the built-in default model (simplest)

No extra setup required:

```dart
final KiwiAnalyzer analyzer = await KiwiAnalyzer.create();
```

### B. Use model files from your app assets

Declare assets in your app `pubspec.yaml` and pass `assetModelPath`.

```yaml
flutter:
  assets:
    - assets/kiwi-models/cong/base/
```

```dart
final KiwiAnalyzer analyzer = await KiwiAnalyzer.create(
  assetModelPath: 'assets/kiwi-models/cong/base',
);
```

### C. Use an absolute file-system path

```dart
final KiwiAnalyzer analyzer = await KiwiAnalyzer.create(
  modelPath: '/absolute/path/to/kiwi-models/cong/base',
);
```

You can also use environment variables on desktop/CI:

```bash
FLUTTER_KIWI_NLP_MODEL_PATH=/absolute/path/to/model flutter run -d macos
```

PowerShell:

```powershell
$env:FLUTTER_KIWI_NLP_MODEL_PATH='C:\kiwi\model\cong\base'
flutter run -d windows
```

### D. Set defaults with `--dart-define`

```bash
flutter run \
  --dart-define=FLUTTER_KIWI_NLP_ASSET_MODEL_PATH=assets/kiwi-models/cong/base
```

To fix web model base URL:

```bash
flutter run -d chrome \
  --dart-define=FLUTTER_KIWI_NLP_WEB_MODEL_BASE_URL=/assets/kiwi-models/cong/base
```

## Model Path Resolution

### Native (`dart:io`)

Order used by `KiwiAnalyzer.create()`:

1. `modelPath` argument
2. `assetModelPath` argument
3. `FLUTTER_KIWI_NLP_MODEL_PATH` (env)
4. `FLUTTER_KIWI_NLP_ASSET_MODEL_PATH` (`--dart-define`)
5. Built-in asset candidates
6. Default model archive download/extract

Default archive URL:

- `https://github.com/bab2min/Kiwi/releases/download/v0.22.2/kiwi_model_v0.22.2_base.tgz`

### Web

Primary model source order:

1. `modelPath` / `assetModelPath` argument
2. `FLUTTER_KIWI_NLP_WEB_MODEL_BASE_URL`
3. `assets/packages/flutter_kiwi_nlp/assets/kiwi-models/cong/base`

If URL-based loading fails for asset-style paths, it falls back to archive
download.

## Android Auto Build

The plugin runs `tool/build_android_libkiwi.sh` from `android/build.gradle`
(`preBuild` dependency).

- Script skips existing ABI outputs by default.
- Force rebuild with `--rebuild`.
- Skip automatic build for one run with:
  - `-Pflutter.kiwi.skipAndroidLibBuild=true`

## iOS Auto Prepare

The plugin runs `tool/build_ios_kiwi_xcframework.sh` from
`ios/flutter_kiwi_nlp.podspec` (`prepare_command`).

- If `ios/Frameworks/Kiwi.xcframework` is missing, it is generated during
  `pod install`.
- Required tools: macOS, Xcode (Command Line Tools), `cmake`, `git`.
- Skip automatic build for one run with:
  - `FLUTTER_KIWI_SKIP_IOS_FRAMEWORK_BUILD=true flutter run -d ios`
- Force rebuild with:
  - `FLUTTER_KIWI_IOS_REBUILD=true flutter run -d ios`

## macOS Auto Prepare

The plugin runs `tool/build_macos_kiwi_dylib.sh` from
`macos/flutter_kiwi_nlp.podspec` (`prepare_command`).

- If `macos/Frameworks/libkiwi.dylib` is missing, it is generated during
  `pod install`.
- Default target archs: `arm64,x86_64` (universal binary via `lipo`).
- Required tools: macOS, Xcode (Command Line Tools), `cmake`, `git`.
- Skip automatic build for one run with:
  - `FLUTTER_KIWI_SKIP_MACOS_LIBRARY_BUILD=true flutter run -d macos`
- Force rebuild with:
  - `FLUTTER_KIWI_MACOS_REBUILD=true flutter run -d macos`
- Override target arch list with:
  - `FLUTTER_KIWI_MACOS_ARCHS=arm64 flutter run -d macos`

## Linux Auto Prepare

The plugin runs `tool/build_linux_libkiwi.sh` from
`linux/CMakeLists.txt` (custom build target).

- If `linux/prebuilt/libkiwi.so` is missing, it is generated during Linux
  build.
- Default target arch: host arch (`x86_64`, `arm64`, etc.).
- Required tools: Linux host, `cmake`, `git`, C/C++ build toolchain.
- Skip automatic build for one run with:
  - `FLUTTER_KIWI_SKIP_LINUX_LIBRARY_BUILD=true flutter run -d linux`
- Force rebuild with:
  - `FLUTTER_KIWI_LINUX_REBUILD=true flutter run -d linux`
- Override target arch with:
  - `FLUTTER_KIWI_LINUX_ARCH=x86_64 flutter run -d linux`

## Windows Auto Prepare

The plugin runs `tool/build_windows_kiwi_dll.ps1` from
`windows/CMakeLists.txt` (custom build target).

- If `windows/prebuilt/kiwi.dll` is missing, it is generated during
  Windows build.
- Default target arch: CMake generator platform (`x64`, `Win32`, `arm64`).
- Required tools: Windows host, PowerShell, Visual Studio C++ toolchain,
  `cmake`, `git`.
- Skip automatic build for one run with:
  - `$env:FLUTTER_KIWI_SKIP_WINDOWS_LIBRARY_BUILD='true'; flutter run -d windows`
- Force rebuild with:
  - `$env:FLUTTER_KIWI_WINDOWS_REBUILD='true'; flutter run -d windows`
- Override target arch with:
  - `$env:FLUTTER_KIWI_WINDOWS_ARCH='x64'; flutter run -d windows`

## Common Issues

- `Failed to load Kiwi dynamic library`
  - Verify native library exists for your platform.
  - Optionally set `FLUTTER_KIWI_NLP_LIBRARY_PATH`.
- Android auto-build fails (`cmake`/`git`/NDK not found)
  - Set `ANDROID_NDK_HOME` or `ANDROID_NDK_ROOT`.
  - Ensure `cmake` and `git` are on PATH.
- iOS auto-build fails (`xcodebuild`/`cmake`/`git` not found)
  - Open Xcode once to finish first-time setup and license acceptance.
  - Check `xcode-select --install`.
  - Ensure `cmake` and `git` are on PATH.
- macOS auto-build fails (`xcrun`/`cmake`/`git` not found)
  - Open Xcode once to finish first-time setup and license acceptance.
  - Check `xcode-select --install`.
  - Ensure `cmake` and `git` are on PATH.
- Linux auto-build fails (`cmake`/`git`/compiler not found)
  - Install build-essential (or equivalent) plus `cmake` and `git`.
  - Ensure required commands are on PATH.
- Windows auto-build fails (`powershell`/`cmake`/`git`/MSVC not found)
  - Install Visual Studio C++ build tools (Desktop development with C++).
  - Run from a shell where `cmake`, `git`, and MSVC toolchain are available.
- Model not found
  - Pass `modelPath` or `assetModelPath`.
  - Or set `FLUTTER_KIWI_NLP_MODEL_PATH`.

## License

See `LICENSE`.

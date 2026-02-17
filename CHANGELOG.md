## 0.1.1

* Add cross-runtime benchmark tooling for `flutter_kiwi_nlp` vs `kiwipiepy`:
  `tool/benchmark/run_compare.py`,
  `tool/benchmark/kiwipiepy_benchmark.py`, and
  `tool/benchmark/compare_results.py`.
* Add benchmark runner entrypoint and corpus in example app:
  `example/lib/benchmark_main.dart` and
  `example/assets/benchmark_corpus_ko.txt`.
* Add in-app benchmark flow in example analyzer UI/ViewModel, including model
  asset materialization helpers for local benchmark runs.
* Expand docs (`README.md`, `README.en.md`, `README.ko.md`) with benchmark
  guide, generated artifacts, and usage options.
* Add Medium-style deep-dive docs in `doc/` (Korean and English).
* Bump package version to `0.1.1`.

## 0.1.0

* Add `llms.txt` in repository root using `llmstxt.org`-style link sections
  for docs, API/runtime files, build scripts, examples, and optional resources.
* Add `skills/flutter-kiwi-nlp` repository skill package:
  `SKILL.md`, `agents/openai.yaml`, references, and
  `scripts/verify_plugin.sh`.
* Add AI usage guides to `README.md`, `README.en.md`, and `README.ko.md`
  covering `llms.txt`, skill invocation, and verification flow.
* Bump package version to `0.1.0`.

## 0.0.2

* Fix macOS prepare script for Bash 3.2 `set -u` empty-array handling.
* Fix Linux desktop build failure caused by `Digest` import conflict in
  `kiwi_analyzer_native.dart`.
* Improve Linux/Windows native library preparation to try official Kiwi
  release prebuilts first, then fallback to source build.
* Improve Windows failure visibility in the build script with explicit
  error output.
* Run desktop CI builds with verbose logging (`flutter build -v`) to
  make platform failure diagnosis easier.
* Update docs for platform auto-prepare behavior and install version.

## 0.0.1

* Bootstrap a native-first Flutter FFI plugin structure for Kiwi.
* Replace template `sum` API with `KiwiAnalyzer` APIs (`create`, `analyze`, `addUserWord`, `close`).
* Add match/build option constants and typed analysis result models.
* Add conditional Dart export so web builds fail gracefully with `KiwiException`.
* Introduce C wrapper API in `src/flutter_kiwi_ffi.h` and dynamic Kiwi C API bridge in `src/flutter_kiwi_ffi.c`.
* Replace example app with a Kiwi GUI-style analyzer demo.
* Add platform prebuilt layout hooks for bundling Kiwi binaries (`android jniLibs`, `linux/prebuilt`, `windows/prebuilt`, `ios/macos Frameworks`).
* Add `tool/fetch_kiwi_release_assets.sh` to download official Kiwi release binaries/models into plugin paths.
* Document Android release limitation (`libKiwiJava.so` only) for C API FFI usage.
* Add `tool/build_android_libkiwi.sh` to build Android `libkiwi.so` for selected ABIs using Android NDK.
* Add web backend (`kiwi-nlp` WASM) with `modelPath` URL-based loading.
* Add native `assetModelPath` support: Kiwi model files can be bundled as Flutter assets and auto-extracted to temp storage for FFI initialization.
* Add zero-argument initialization path discovery:
  native auto-detects default asset model locations.
* Add native default-model auto-download fallback (first run) with local cache, so integrations can call `KiwiAnalyzer.create()` without app-side model asset setup.
* Update web backend defaults to `kiwi-nlp@0.22.1`.
* Improve web zero-config model loading:
  first try known same-origin asset bases, then fallback to release archive download (direct URL + GitHub API metadata fallback).
* Bundle default Kiwi base model files in package assets (`assets/kiwi-models/cong/base`) so no app-side asset declaration is required for default usage.
* Expand web initialization error messages with per-attempt details (asset base and archive URL/API attempts).
* Switch web default model loading to URL-based `modelFiles` (`assets/packages/flutter_kiwi_nlp/...`) to avoid `rootBundle/AssetManifest` runtime issues in DDC.
* Add Android ABI filters (`arm64-v8a`, `x86_64`) to avoid packaging unsupported 32-bit runtime combinations.
* Make example error messages selectable (`SelectableText`) and print all caught errors to logs via `debugPrint`/`debugPrintStack`.
* Add GitHub Actions desktop CI matrix at `.github/workflows/desktop-build.yml` to build example on Linux and Windows.
* Add macOS auto-build flow via `tool/build_macos_kiwi_dylib.sh` and `macos/flutter_kiwi_nlp.podspec` `prepare_command`, so `libkiwi.dylib` is generated during macOS pod install when missing.
* Add Linux auto-build flow via `tool/build_linux_libkiwi.sh` and `linux/CMakeLists.txt` custom target, so `libkiwi.so` is generated during Linux build when missing.
* Add Windows auto-build flow via `tool/build_windows_kiwi_dll.ps1` and `windows/CMakeLists.txt` custom target, so `kiwi.dll` is generated during Windows build when missing.
* Improve Linux/Windows native preparation to prefer official Kiwi release prebuilt assets and fallback to source build when prebuilt fetch is unavailable.

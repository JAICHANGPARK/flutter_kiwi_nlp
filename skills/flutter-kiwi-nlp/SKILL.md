---
name: flutter-kiwi-nlp
description: >-
  Integrate, use, and maintain the flutter_kiwi_nlp Korean morphological
  analyzer plugin for Flutter (Android, iOS, macOS, Linux, Windows, Web).
  Use when adding Korean NLP features in a Flutter app—such as morphological
  analysis (analyze, analyzeBatch), POS tagging, spacing correction (space),
  context-aware chunk joining (glue), or custom user dictionary words
  (addUserWord)—or when maintaining native FFI and web WASM backends in this
  repository. Triggers on Korean prompts such as "한국어 형태소 분석", "품사 태깅",
  "띄어쓰기 교정", "문장 이어붙이기", "사용자 사전 추가", "KiwiAnalyzer 연동".
---

# Flutter Kiwi NLP Skill

## Overview

`flutter_kiwi_nlp` provides Korean morphological analysis (`KiwiAnalyzer`) across
Flutter Native (`dart:ffi` on Android, iOS, macOS, Linux, Windows) and Flutter
Web (`kiwi-nlp` WASM) with a single unified Dart API.

Use this skill in two scenarios:
1. **Using `flutter_kiwi_nlp` in a Flutter App**: Integrating `KiwiAnalyzer` for
   tokenization, POS tagging (`analyze`, `analyzeBatch`), spacing correction
   (`space`), chunk joining (`glue`), or custom dictionary words (`addUserWord`).
2. **Maintaining the `flutter_kiwi_nlp` Plugin**: Updating native C++ FFI / Web
   WASM backends, model loading, or platform auto-build scripts with strict
   native-web parity.

---

## Scenario A: Using `flutter_kiwi_nlp` in a Flutter App

### Quick Workflow

1. **Import only the public entrypoint**:
   ```dart
   import 'package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart';
   ```
2. **Initialize once and reuse**:
   - Call `await KiwiAnalyzer.create()` once per controller/service lifecycle
     (never inside `build()`).
   - Call `await analyzer.close()` when disposing the owner.
3. **Choose the right API for the task**:
   - Morphological analysis / POS tagging (single text):
     `await analyzer.analyze(text, options: const KiwiAnalyzeOptions(topN: 1))`
   - Batch morphological analysis (multiple sentences):
     `await analyzer.analyzeBatch(texts, options: ...)`
   - Fast token count only:
     `await analyzer.analyzeTokenCount(text, options: ...)`
   - Runtime user dictionary registration:
     `await analyzer.addUserWord('단어', tag: 'NNP', score: 0.0)`
   - Automatic Korean spacing correction:
     `await analyzer.space(text, resetWhitespace: false)`
   - Context-aware chunk/sentence joining:
     `await analyzer.glue(chunks, insertNewLines: ...)` -> returns
     `KiwiGlueResult(text, spaceInsertions)`
4. **Handle errors explicitly**:
   - Catch `KiwiException` for initialization, invalid arguments, use-after-close,
     or unsupported platform errors.

For complete copy-pasteable code templates (including `ChangeNotifier` state
management, POS filtering, `space`, `glue`, and custom model paths), read:
- [usage-recipes.md](./references/usage-recipes.md)

---

## Scenario B: Maintaining & Extending the Plugin Repository

### Workflow

1. **Collect context**:
   - Read `README.en.md`, `lib/flutter_kiwi_nlp.dart`, and affected files under
     `lib/src/`.
   - If API contracts or options change, inspect `lib/src/kiwi_options.dart`,
     `lib/src/kiwi_types.dart`, and `src/flutter_kiwi_ffi.h`.
2. **Implement with Native-Web Parity**:
   - Apply equivalent behavior in `lib/src/kiwi_analyzer_native.dart` (and
     `src/flutter_kiwi_ffi.cpp`) and `lib/src/kiwi_analyzer_web.dart`.
   - Keep unsupported targets explicit in `lib/src/kiwi_analyzer_stub.dart`
     (throwing `KiwiException`).
   - If `src/flutter_kiwi_ffi.h` changes, regenerate FFI bindings via:
     `dart run ffigen --config ffigen.yaml`
3. **Validate**:
   - Run [verify_plugin.sh](./scripts/verify_plugin.sh).
   - If platform build scripts changed, validate the corresponding script under
     `tool/` and platform hook (`android/build.gradle`, `ios/*.podspec`,
     `macos/*.podspec`, `linux/CMakeLists.txt`, `windows/CMakeLists.txt`).
4. **Document**:
   - Update `README.md`, `README.en.md`, and `README.ko.md` for API or behavior
     changes.
   - Add a `CHANGELOG.md` entry and keep `llms.txt` synchronized.

### Decision Rules

- Treat API parity as mandatory across native and web for:
  `create`, `nativeVersion`, `analyze`, `analyzeBatch`, `analyzeTokenCount`,
  `addUserWord`, `space`, `glue`, and `close`.
- For model loading bugs, verify precedence and fallback logic before changing
  defaults (`nounchr.mdl` and base model files in `assets/kiwi-models/cong/base`).
- For platform build issues, fix auto-prepare scripts under `tool/` rather than
  requiring manual user steps.

---

## Resources

- App integration & usage code recipes: [usage-recipes.md](./references/usage-recipes.md)
- Public API & parity contract: [api-surface.md](./references/api-surface.md)
- Runtime model resolution & build hooks: [runtime-and-build.md](./references/runtime-and-build.md)
- Automated plugin verification script: [verify_plugin.sh](./scripts/verify_plugin.sh)

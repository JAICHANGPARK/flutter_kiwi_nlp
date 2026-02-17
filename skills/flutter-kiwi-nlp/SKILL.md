---
name: flutter-kiwi-nlp
description: Maintain and extend the flutter_kiwi_nlp plugin. Use when working
  in this repository to implement features or fixes across native FFI and web
  WASM backends, adjust model loading behavior, update platform build scripts,
  and validate analyzer API parity before release.
---

# Flutter Kiwi NLP

## Overview

Use a parity-first workflow.
Keep `KiwiAnalyzer` behavior aligned across native and web.
Preserve public API compatibility unless a breaking change is requested.

## Workflow

1. Collect context.
- Read `README.en.md`, `lib/flutter_kiwi_nlp.dart`, and the affected files
  under `lib/src/`.
- If API contracts change, inspect `lib/src/kiwi_options.dart` and
  `lib/src/kiwi_types.dart`.

2. Implement change.
- Apply equivalent behavior in native and web backends when feasible.
- Keep unsupported targets explicit in `lib/src/kiwi_analyzer_stub.dart`
  (`KiwiException`).
- Preserve clear runtime errors for integration debugging.

3. Validate.
- Run `skills/flutter-kiwi-nlp/scripts/verify_plugin.sh`.
- If platform scripts changed, validate the related script under `tool/` and
  the platform hook (`android/build.gradle`, `ios/*.podspec`,
  `macos/*.podspec`, `linux/CMakeLists.txt`, `windows/CMakeLists.txt`).

4. Document.
- Update `README.en.md` and `README.ko.md` for behavior/config changes.
- Add a `CHANGELOG.md` entry for user-visible changes.
- Keep `llms.txt` links aligned with newly added or moved docs.

## Decision rules

- Treat API parity as required for:
  `create`, `nativeVersion`, `analyze`, `addUserWord`, and `close`.
- For model loading bugs, verify precedence and fallback logic before changing
  defaults.
- For platform build issues, prefer fixing auto-prepare scripts before adding
  manual steps.

## Resources

- API and parity contract: `references/api-surface.md`
- Runtime/build references: `references/runtime-and-build.md`
- Reusable checks runner: `scripts/verify_plugin.sh`

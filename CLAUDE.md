# CLAUDE.md — flutter_kiwi_nlp

Korean morphological analyzer Flutter plugin powered by Kiwi (`v0.24.0`), supporting Android, iOS, macOS, Linux, Windows (`dart:ffi`), and Web (`kiwi-nlp` WASM) with a unified `KiwiAnalyzer` API.

## Project Skills (Claude Code, Codex, Antigravity)

This repository includes pre-configured skills in the project folder so AI agents can immediately discover and use them:

- **Canonical Skill Path**: [`skills/flutter-kiwi-nlp/SKILL.md`](skills/flutter-kiwi-nlp/SKILL.md)
- **Claude Code Auto-Discovery Path**: `.claude/skills/flutter-kiwi-nlp/SKILL.md` (invoke with `/flutter-kiwi-nlp` or automatically by task description)
- **Antigravity & Codex Auto-Discovery Path**: `.agents/skills/flutter-kiwi-nlp/SKILL.md` and `.agents/skills.json` (invoke with `$flutter-kiwi-nlp` or automatically)
- **App Integration & Usage Recipes**: [`skills/flutter-kiwi-nlp/references/usage-recipes.md`](skills/flutter-kiwi-nlp/references/usage-recipes.md)
- **Public API & Parity Contract**: [`skills/flutter-kiwi-nlp/references/api-surface.md`](skills/flutter-kiwi-nlp/references/api-surface.md)
- **Runtime & Build Reference**: [`skills/flutter-kiwi-nlp/references/runtime-and-build.md`](skills/flutter-kiwi-nlp/references/runtime-and-build.md)
- **Verification Script**: [`skills/flutter-kiwi-nlp/scripts/verify_plugin.sh`](skills/flutter-kiwi-nlp/scripts/verify_plugin.sh)

## Common Commands

```bash
# Run full plugin verification (pub get, analyze, unit tests, example tests)
./skills/flutter-kiwi-nlp/scripts/verify_plugin.sh

# Regenerate FFI bindings after modifying src/flutter_kiwi_ffi.h
dart run ffigen --config ffigen.yaml
```

## Key Guidelines

1. **Single Public Entrypoint**: Always import `package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart`. Never import internal files under `lib/src/`.
2. **Native-Web Parity**: Keep `KiwiAnalyzer` behavior (`create`, `nativeVersion`, `analyze`, `analyzeBatch`, `analyzeTokenCount`, `addUserWord`, `space`, `glue`, `close`) aligned across `lib/src/kiwi_analyzer_native.dart`, `lib/src/kiwi_analyzer_web.dart`, and `lib/src/kiwi_analyzer_stub.dart`.
3. **Coding Standards**: Follow [`AGENTS.md`](AGENTS.md) for Flutter/Dart coding style and architecture rules.

# API Surface and Parity Contract

## Public export

- Entry point: `lib/flutter_kiwi_nlp.dart`
- Exports:
  - `kiwi_analyzer_*` implementation via conditional export (`native`, `web`, `stub`)
  - `kiwi_exception.dart` (`KiwiException`)
  - `kiwi_options.dart` (`KiwiAnalyzeOptions`, `KiwiBuildOption`, `KiwiMatchOption`)
  - `kiwi_types.dart` (`KiwiAnalyzeResult`, `KiwiCandidate`, `KiwiToken`, `KiwiGlueResult`)

## Required analyzer methods

Keep these APIs available and behaviorally aligned across Native (FFI) and Web (WASM):

- `KiwiAnalyzer.create({String? modelPath, String? assetModelPath, int numThreads, int buildOptions, int matchOptions}) -> Future<KiwiAnalyzer>`
- `KiwiAnalyzer.nativeVersion -> String`
- `KiwiAnalyzer.analyze(String text, {KiwiAnalyzeOptions options}) -> Future<KiwiAnalyzeResult>`
- `KiwiAnalyzer.analyzeBatch(List<String> texts, {KiwiAnalyzeOptions options}) -> Future<List<KiwiAnalyzeResult>>`
- `KiwiAnalyzer.analyzeTokenCount(String text, {KiwiAnalyzeOptions options}) -> Future<int>`
- `KiwiAnalyzer.analyzeTokenCountBatch(List<String> texts, {KiwiAnalyzeOptions options}) -> Future<List<int>>`
- `KiwiAnalyzer.analyzeTokenCountBatchRepeated(List<String> texts, {int runs, KiwiAnalyzeOptions options}) -> Future<int>`
- `KiwiAnalyzer.addUserWord(String word, {String tag = 'NNP', double score = 0.0}) -> Future<void>`
- `KiwiAnalyzer.space(String text, {bool resetWhitespace = false}) -> Future<String>`
- `KiwiAnalyzer.glue(List<String> chunks, {List<bool>? insertNewLines}) -> Future<KiwiGlueResult>`
- `KiwiAnalyzer.close() -> Future<void>`

## Options and constants

- `KiwiAnalyzeOptions`:
  - `topN` (default `1`, must be `>= 1`)
  - `matchOptions` (default `KiwiMatchOption.allWithNormalizing`)
- `KiwiBuildOption`:
  - Bit flags: `integrateAllomorph`, `loadDefaultDict`, `loadTypoDict`, `loadMultiDict`
  - Model types: `modelTypeDefault`, `modelTypeLargest`, `modelTypeKnlm`, `modelTypeSbg`, `modelTypeCong`, `modelTypeCongGlobal`
  - Bundle: `defaultOption`
- `KiwiMatchOption`:
  - Detection flags: `none`, `url`, `email`, `hashtag`, `mention`, `serial`, `emoji`
  - Normalization & affix flags: `normalizeCoda`, `joinNounPrefix`, `joinNounSuffix`, `joinVerbSuffix`, `joinAdjSuffix`, `joinAdvSuffix`, `joinVSuffix`, `joinAffix`, `splitComplex`, `zCoda`, `compatibleJamo`, `splitSaisiot`, `mergeSaisiot`, `joinParticleYo`, `useOldSplitter`
  - OOV modes: `oovRuleOnly`, `oovChrModel`, `oovChrFreqModel`, `oovChrFreqBranchModel`, `oovMask`
  - Bundles: `all`, `allWithNormalizing`

## Behavior expectations

- Throw `KiwiException` for plugin/runtime failures and invalid arguments (e.g., empty user word, mismatched `insertNewLines` length, `topN <= 0`).
- Reject use-after-close with explicit `KiwiException('KiwiAnalyzer is already closed.')`.
- Keep null-safe signatures and JSON serialization (`fromJson` / `toJson`) stable on `KiwiAnalyzeResult`, `KiwiCandidate`, `KiwiToken`, and `KiwiGlueResult`.

## Change checklist

- If API changes, update:
  - `lib/flutter_kiwi_nlp.dart`
  - `lib/src/kiwi_analyzer_native.dart` (and `src/flutter_kiwi_ffi.h` / `src/flutter_kiwi_ffi.cpp` if native C bridge changes)
  - `lib/src/kiwi_analyzer_web.dart`
  - `lib/src/kiwi_analyzer_stub.dart`
  - `skills/flutter-kiwi-nlp/references/usage-recipes.md`
  - `README.md`, `README.en.md`, `README.ko.md`, `CHANGELOG.md`

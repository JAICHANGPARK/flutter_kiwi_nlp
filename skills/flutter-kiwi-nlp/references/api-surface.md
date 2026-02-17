# API Surface and Parity Contract

## Public export

- Entry point: `lib/flutter_kiwi_nlp.dart`
- Exports:
  - `kiwi_analyzer_*` implementation via conditional export
  - `kiwi_exception.dart`
  - `kiwi_options.dart`
  - `kiwi_types.dart`

## Required analyzer methods

Keep these APIs available and behaviorally aligned:

- `KiwiAnalyzer.create(...) -> Future<KiwiAnalyzer>`
- `KiwiAnalyzer.nativeVersion -> String`
- `KiwiAnalyzer.analyze(...) -> Future<KiwiAnalyzeResult>`
- `KiwiAnalyzer.addUserWord(...) -> Future<void>`
- `KiwiAnalyzer.close() -> Future<void>`

## Behavior expectations

- Throw `KiwiException` for plugin/runtime failures.
- Reject use-after-close with explicit error.
- Keep null-safe signatures stable.
- Keep result model structure stable:
  `KiwiAnalyzeResult -> KiwiCandidate -> KiwiToken`.

## Change checklist

- If API changes, update:
  - `lib/flutter_kiwi_nlp.dart`
  - `lib/src/kiwi_analyzer_native.dart`
  - `lib/src/kiwi_analyzer_web.dart`
  - `lib/src/kiwi_analyzer_stub.dart`
  - `README.en.md`, `README.ko.md`, `CHANGELOG.md`

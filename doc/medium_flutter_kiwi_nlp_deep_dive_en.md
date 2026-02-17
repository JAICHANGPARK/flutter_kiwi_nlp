# How to Ship On-Device Korean Morphological Analysis in Flutter with Kiwi

Subtitle: A practical deep dive into `flutter_kiwi_nlp` architecture, API
design, benchmark methodology, and production trade-offs

---

When teams add Korean NLP to Flutter apps, the same three issues show up
quickly:

1. Server dependency increases latency and ongoing cost.
2. Quality degrades hard in offline or unstable-network environments.
3. Implementation diverges by platform (Android, iOS, macOS, Windows, Linux,
   Web).

`flutter_kiwi_nlp` addresses this with a pragmatic design:

- one Dart API for native (FFI) and web (WASM),
- on-device execution of the Kiwi Korean morphological analyzer,
- runtime user dictionary updates for domain adaptation.

This article goes beyond a basic quickstart and covers:

- why this architecture works in real products,
- how to structure maintainable application code around it,
- how to benchmark fairly,
- and how to interpret measured results.

---

## TL;DR

- Use `KiwiAnalyzer.create()` and call `analyze()`.
- The API is `Future`-based, so it fits Flutter async flows without blocking UI.
- Add domain words at runtime with `addUserWord`.
- Measured on February 17, 2026 (`macOS arm64`, identical corpus/settings):
  - throughput (analyses/s): `flutter_kiwi_nlp` 2408.41 vs `kiwipiepy`
    3666.54
  - avg latency (ms): `flutter_kiwi_nlp` 0.42 vs `kiwipiepy` 0.27
- Python reference is faster in this run, but Flutter on-device integration has
  strong architecture and product benefits.

---

## AI User Guide (LLMs + Skills)

This project is significantly easier to operate when you drive changes with an
AI coding assistant using repository-specific context.

Recommended references:

- LLM index: `llms.txt`
- repository skill: `skills/flutter-kiwi-nlp/SKILL.md`
- API surface reference:
  `skills/flutter-kiwi-nlp/references/api-surface.md`
- runtime/build reference:
  `skills/flutter-kiwi-nlp/references/runtime-and-build.md`
- verification script: `skills/flutter-kiwi-nlp/scripts/verify_plugin.sh`

Prompt template you can paste into an AI assistant:

```text
Use $flutter-kiwi-nlp to implement and validate this change.

Goal:
- Add a domain dictionary bootstrap for ecommerce terms.
- Keep native/web API parity.
- Do not break benchmark scripts.

Validation:
- Run analyze/lint/tests used in this repo.
- Run ./skills/flutter-kiwi-nlp/scripts/verify_plugin.sh.
- Summarize behavioral changes and benchmark impact.
```

Execution tips:

- always specify goals and constraints together,
- require file-level evidence for decisions,
- include benchmark-path validation (`tool/benchmark/`) in every change request,
- attach generated benchmark artifacts to PR descriptions.

---

## 1) Why On-Device Korean NLP

Server-side NLP is powerful, but app teams pay hidden costs:

- network round-trip and tail-latency amplification,
- per-call infrastructure cost,
- privacy/compliance risk from sending raw text,
- poor offline behavior.

On-device analysis is attractive when your product needs:

- immediate response on short, repeated text operations,
- offline resilience,
- privacy-friendly local processing,
- faster product iteration without backend coupling.

`flutter_kiwi_nlp` adds two major practical wins:

- API parity across native and web,
- runtime dictionary adaptation without retraining.

---

## 2) Minimal Working Example

Install:

```bash
flutter pub add flutter_kiwi_nlp
```

Basic usage:

```dart
import 'dart:developer' as developer;

import 'package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart';

Future<void> runBasicAnalysis() async {
  final KiwiAnalyzer analyzer = await KiwiAnalyzer.create(
    numThreads: -1,
    matchOptions: KiwiMatchOption.allWithNormalizing,
  );

  try {
    final KiwiAnalyzeResult result = await analyzer.analyze(
      'On-device NLP can reduce both latency and cost.',
      options: const KiwiAnalyzeOptions(topN: 1),
    );

    if (result.candidates.isEmpty) {
      developer.log('No candidate returned.');
      return;
    }

    for (final KiwiToken token in result.candidates.first.tokens) {
      developer.log('${token.form}/${token.tag}');
    }
  } finally {
    await analyzer.close();
  }
}
```

### Dart-specific notes

- `Future` + `async`/`await`:
  - model initialization and inference are asynchronous,
  - `await` keeps control flow readable and error handling explicit.
- null safety:
  - the candidate-empty check avoids unsafe access patterns.
- resource lifecycle:
  - always `close()` to release native resources deterministically.
- why not `Stream` here:
  - morphology calls are one-shot requests, so `Future` is the right primitive;
    use `Stream` only for continuous event pipelines.

---

## 3) Production-Friendly Layering (Service Wrapper)

As soon as your app grows, do not expose analyzer lifecycle directly in UI
widgets. Wrap it behind a service boundary:

```dart
import 'package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart';

class KiwiNlpService {
  KiwiAnalyzer? _analyzer;

  bool get isReady => _analyzer != null;

  Future<void> initialize({
    String? modelPath,
    String? assetModelPath,
    int numThreads = -1,
  }) async {
    await dispose();
    _analyzer = await KiwiAnalyzer.create(
      modelPath: modelPath,
      assetModelPath: assetModelPath,
      numThreads: numThreads,
      matchOptions: KiwiMatchOption.allWithNormalizing,
    );
  }

  Future<List<KiwiToken>> tokenize(
    String sentence, {
    int topN = 1,
    int matchOptions = KiwiMatchOption.allWithNormalizing,
  }) async {
    final KiwiAnalyzer? analyzer = _analyzer;
    if (analyzer == null) {
      throw const KiwiException('Analyzer is not initialized.');
    }

    final KiwiAnalyzeResult result = await analyzer.analyze(
      sentence,
      options: KiwiAnalyzeOptions(
        topN: topN,
        matchOptions: matchOptions,
      ),
    );

    if (result.candidates.isEmpty) {
      return const <KiwiToken>[];
    }
    return result.candidates.first.tokens;
  }

  Future<void> addDomainWord(String word, {String tag = 'NNP'}) async {
    final KiwiAnalyzer? analyzer = _analyzer;
    if (analyzer == null) {
      throw const KiwiException('Analyzer is not initialized.');
    }
    await analyzer.addUserWord(word, tag: tag);
  }

  Future<void> dispose() async {
    final KiwiAnalyzer? analyzer = _analyzer;
    _analyzer = null;
    if (analyzer != null) {
      await analyzer.close();
    }
  }
}
```

Why this matters:

- clean separation between presentation and domain logic,
- easier testing with fake service implementations,
- explicit control of analyzer lifecycle and error boundaries.

---

## 4) User Dictionary: Fastest Path to Domain Quality

In many Korean production workloads, runtime dictionary tuning gives the biggest
quality gain per engineering hour.

```dart
await analyzer.addUserWord('OnDeviceNLP', tag: 'NNP');
```

Typical domain examples:

- commerce: product names, brand aliases, SKU patterns,
- fintech: account/card/payment terms,
- SaaS: internal feature names and acronyms.

This is often more practical than immediate retraining and redeployment.

---

## 5) Expose Accuracy-vs-Latency Trade-offs in Code

`KiwiAnalyzeOptions` and bitwise `KiwiMatchOption` flags let you define behavior
for your domain:

```dart
final KiwiAnalyzeOptions options = KiwiAnalyzeOptions(
  topN: 3,
  matchOptions: KiwiMatchOption.url |
      KiwiMatchOption.email |
      KiwiMatchOption.hashtag |
      KiwiMatchOption.normalizeCoda |
      KiwiMatchOption.splitSaisiot,
);

final KiwiAnalyzeResult result = await analyzer.analyze(text, options: options);
```

Guidelines:

- keep `topN=1` when throughput matters most,
- increase `topN` when reranking or ambiguity handling is required,
- only enable pattern flags you truly need in the target domain.

---

## 6) Fair Benchmarking: Method First, Numbers Second

Benchmark comparisons are easy to misread unless conditions are identical.
This repository includes an automation script:

```bash
uv run --with kiwipiepy python tool/benchmark/run_compare.py \
  --device macos \
  --mode release
```

What it does:

1. runs the Flutter benchmark app (`example/lib/benchmark_main.dart`),
2. runs `kiwipiepy` on the same corpus
   (`tool/benchmark/kiwipiepy_benchmark.py`),
3. generates one markdown comparison table
   (`tool/benchmark/compare_results.py`).

Outputs:

- `benchmark/results/flutter_kiwi_benchmark.json`
- `benchmark/results/kiwipiepy_benchmark.json`
- `benchmark/results/comparison.md`

---

## 7) Measured Results (February 17, 2026, macOS arm64)

Run conditions:

- device: macOS desktop (`darwin-arm64`)
- Flutter mode: `release`
- corpus: `example/assets/benchmark_corpus_ko.txt` (40 sentences)
- shared params: `warmup=3`, `measure=15`, `top_n=1`

| Metric | flutter_kiwi_nlp | kiwipiepy | Ratio (Flutter/Kiwi) |
| --- | ---: | ---: | ---: |
| Init time (ms, lower better) | 1353.39 | 917.27 | 1.48x (slower) |
| Throughput (analyses/s, higher better) | 2408.41 | 3666.54 | 0.66x (slower) |
| Throughput (chars/s, higher better) | 81645.10 | 124295.69 | 0.66x (slower) |
| Throughput (tokens/s, higher better) | 38775.40 | 58939.62 | 0.66x (slower) |
| Avg latency (ms, lower better) | 0.42 | 0.27 | 1.52x (slower) |
| Avg token latency (us/token, lower better) | 25.79 | 16.97 | 1.52x (slower) |

Artifacts:

- `benchmark/results/comparison.md`
- `benchmark/results/flutter_kiwi_benchmark.json`
- `benchmark/results/kiwipiepy_benchmark.json`

---

## 8) Interpreting the Gap Correctly

In this run, `kiwipiepy` is faster across all measured metrics. That is useful
data, but not the whole decision frame.

Possible contributors:

- runtime boundary overhead:
  - Flutter path crosses Dart <-> FFI <-> native boundaries,
  - JSON serialization/deserialization is part of end-to-end cost.
- init overhead:
  - model loading, bridge setup, runtime bootstrapping.
- slight token-count mismatch:
  - this run shows `9660` vs `9645`, indicating tiny differences in payload or
    counting path.

Why Flutter on-device still matters:

- single API inside application code,
- no network dependency for inference,
- multi-platform consistency,
- fast domain adaptation through runtime dictionary updates.

Use throughput numbers together with system architecture cost, not in isolation.

---

## 9) Immediate Optimization Checklist

1. Reuse analyzer instances.
2. Keep `topN` minimal unless business logic needs more candidates.
3. Benchmark sentence batching strategy per product flow.
4. Maintain a curated user dictionary for domain vocabulary.
5. Move long-running loops to background isolates where appropriate.

---

## 10) Protecting UI Responsiveness with `compute`

The example app isolates benchmark loops off the UI path:

```dart
final Map<String, Object?> rawResult = kIsWeb
    ? await _runBenchmarkInBackground(payload)
    : await compute<Map<String, Object>, Map<String, Object?>>(
        _runBenchmarkInBackground,
        payload,
        debugLabel: 'kiwi-benchmark',
      );
```

Benefits:

- lower frame-drop risk in interactive screens,
- cleaner separation between rendering and heavy processing,
- explicit platform branch for execution model differences.

---

## 11) Production Concerns You Will Hit

Model path strategy:

- standardize path policy (local path vs asset path vs env-driven),
- validate model bundle integrity in CI for release artifacts.

Error handling:

- split user-facing messages from diagnostic logs,
- include context (options/input size/model path) in internal logs.

Observability:

- track init time, analyze latency, and failure rate over releases,
- add benchmark regression checks to CI.

---

## 12) Reproducible Experiment Template

Lock these four dimensions in every team benchmark:

1. corpus,
2. run params (`warmup`, `measure`, `top_n`),
3. device/OS,
4. build mode (`debug`/`profile`/`release`).

Suggested command:

```bash
uv run --with kiwipiepy python tool/benchmark/run_compare.py \
  --device macos \
  --mode release \
  --warmup-runs 3 \
  --measure-runs 15 \
  --top-n 1
```

Attach the generated report to pull requests so review discussions stay
evidence-driven.

---

## 13) Final Takeaway

`flutter_kiwi_nlp` is less about winning a single synthetic metric and more
about making Korean morphological analysis deployable and maintainable in real
Flutter products.

Core value:

- developer productivity: one API, multiple platforms,
- operational resilience: on-device runtime plus dictionary control,
- measurable engineering loop: built-in comparison tooling.

Recommended next steps:

1. build a product-specific corpus,
2. map accuracy-latency curves across option presets,
3. automate benchmark reports in your release pipeline.

---

## Appendix A) Key Raw Values from This Run

```text
flutter_kiwi_nlp:
  init_ms=1353.393
  analyses_per_sec=2408.4101683077306
  avg_latency_ms=0.4152116666666667

kiwipiepy:
  init_ms=917.2669580148067
  analyses_per_sec=3666.539433756072
  avg_latency_ms=0.2727367366605904
```

This is a single-machine, single-run snapshot. For robust conclusions, run
multiple trials and compare variance, not only means.

# Mobile Single vs Batch Benchmark Summary (2026-02-18)

## Scope

- Trials: 3
- Warmup/Measure: 3 / 15
- topN: 1
- Corpus: `example/assets/benchmark_corpus_ko.txt` (40 sentences)
- Sample POS outputs: 10 sentences
- Flutter analyze path: `token_count`
- Python baseline: `kiwipiepy analyze`

## Environment Note

- iOS run was on simulator (`iPhone 17`) in `debug` mode.
- Android run was on emulator (`emulator-5554`) in `release` mode.
- `kiwipiepy` runs on host macOS Python runtime, so mobile comparison is
  cross-runtime reference (not same-device head-to-head).

## Warm Path (Primary, Init Excluded)

| Platform | Mode | Flutter warm analyses/s | Kiwi warm analyses/s | Ratio | Flutter avg warm latency (ms) | Kiwi avg warm latency (ms) | Latency ratio |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| iOS (debug) | single | 1975.94 | 2579.29 | 0.77x (slower) | 0.51 | 0.39 | 1.31x (slower) |
| iOS (debug) | batch | 12116.00 | 2546.63 | 4.76x (faster) | 0.08 | 0.39 | 0.21x (faster) |
| Android (release) | single | 1855.28 | 2502.68 | 0.74x (slower) | 0.54 | 0.40 | 1.35x (slower) |
| Android (release) | batch | 5138.55 | 2398.63 | 2.14x (faster) | 0.20 | 0.42 | 0.47x (faster) |

## Flutter Boundary Overhead (JSON)

| Platform | Mode | Pure throughput (analyses/s) | Full throughput (analyses/s) | JSON overhead ratio (%) |
| --- | --- | ---: | ---: | ---: |
| iOS (debug) | single | 1975.94 | 1723.83 | 12.76 |
| iOS (debug) | batch | 12116.00 | 7580.33 | 37.15 |
| Android (release) | single | 1855.28 | 1657.19 | 10.68 |
| Android (release) | batch | 5138.55 | 4340.49 | 15.30 |

## Cold Start (Init Median)

| Platform | Mode | Flutter init median (ms) | Kiwi init median (ms) | Ratio |
| --- | --- | ---: | ---: | ---: |
| iOS (debug) | single | 1712.87 | 896.87 | 1.91x (slower) |
| iOS (debug) | batch | 1672.65 | 859.78 | 1.95x (slower) |
| Android (release) | single | 3714.72 | 936.95 | 3.96x (slower) |
| Android (release) | batch | 3570.64 | 961.12 | 3.72x (slower) |

## Source Reports

- `benchmark/results/ios_debug_t3_token_count_single_s10_v1/comparison.md`
- `benchmark/results/ios_debug_t3_token_count_batch_s10_v1/comparison.md`
- `benchmark/results/android_release_t3_token_count_single_s10_v1/comparison.md`
- `benchmark/results/android_release_t3_token_count_batch_s10_v1/comparison.md`

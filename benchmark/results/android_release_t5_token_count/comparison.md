# Benchmark Comparison: flutter_kiwi_nlp vs kiwipiepy

## Run Metadata

| Field | flutter_kiwi_nlp | kiwipiepy |
| --- | --- | --- |
| runtime | flutter_kiwi_nlp | kiwipiepy |
| platform | android | macOS-15.7.4-arm64-arm-64bit-Mach-O |
| generated_at_utc (first trial) | 2026-02-17T23:38:51.452013Z | 2026-02-17T23:39:04Z |
| trials | 5 | 5 |
| sentence_count | 40 | 40 |
| sample_count | 0 | 0 |
| warmup_runs | 3 | 3 |
| measure_runs | 15 | 15 |
| top_n | 1 | 1 |
| build_options | 1039 | 1039 |
| create_match_options | 8454175 | 8454175 |
| analyze_match_options | 8454175 | 8454175 |
| analyze_impl | token_count | analyze |
| num_threads / num_workers | -1 | -1 |

> Caution: `analyze_impl` differs between runtimes, so this table is not a strict apples-to-apples API-path comparison.

> Mobile caveat: Flutter measurements are from the target mobile runtime, while `kiwipiepy` runs on the host Python environment. Treat this as a cross-runtime reference, not a same-device head-to-head.

## Flutter JSON Serialization/Parsing Overhead

| Metric | flutter_kiwi_nlp (mean ± std) |
| --- | ---: |
| Pure processing elapsed (ms) | 359.68 ± 162.50 |
| Full analyze elapsed (ms) | 379.40 ± 116.89 |
| JSON overhead elapsed (ms) | 38.79 ± 49.83 |
| JSON overhead per analysis (ms) | 0.0646 ± 0.0831 |
| JSON overhead per token (us) | 4.0151 ± 5.1585 |
| JSON overhead ratio (%) | 10.13 ± 12.49 |

## Warm Path Comparison (Primary, Init Excluded)

| Metric | flutter_kiwi_nlp (mean ± std) | kiwipiepy (mean ± std) | Ratio (Flutter mean / Kiwi mean) |
| --- | ---: | ---: | ---: |
| Throughput (analyses/s, higher better) | 1859.85 ± 533.72 | 3158.63 ± 722.91 | 0.59x (slower) |
| Throughput (chars/s, higher better) | 63048.79 ± 18093.05 | 107077.58 ± 24506.65 | 0.59x (slower) |
| Throughput (tokens/s, higher better) | 29943.52 ± 8592.87 | 50774.99 ± 11620.78 | 0.59x (slower) |
| Avg warm latency (ms, lower better) | 0.60 ± 0.27 | 0.34 ± 0.11 | 1.78x (slower) |
| Avg warm token latency (us/token, lower better) | 37.23 ± 16.82 | 20.95 ± 6.88 | 1.78x (slower) |

## Layered Throughput Breakdown

| Layer | Throughput (mean ± std, analyses/s) |
| --- | ---: |
| Flutter pure (`token_count`) | 1859.85 ± 533.72 |
| Flutter full (`json`) | 1694.69 ± 471.25 |
| kiwipiepy current API path (`analyze`) | 3158.63 ± 722.91 |

| Derived ratio | Value |
| --- | ---: |
| Flutter pure / kiwi | 0.59x (slower) |
| Flutter full / kiwi | 0.54x (slower) |
| Flutter boundary loss (full vs pure) | 8.88% |


## Cold Start Comparison (Reported Separately)

| Metric | flutter_kiwi_nlp | kiwipiepy | Ratio |
| --- | ---: | ---: | ---: |
| Init time (ms, lower better) | median 3554.05, p95 5154.49 | median 1236.50, p95 1316.35 | 2.87x (slower) |

## Session-Length Effective Throughput (Init Included)

| Session analyses | flutter_kiwi_nlp effective analyses/s (mean ± std) | kiwipiepy effective analyses/s (mean ± std) | Ratio (Flutter mean / Kiwi mean) |
| ---: | ---: | ---: | ---: |
| 1 | 0.27 ± 0.08 | 0.92 ± 0.19 | 0.29x (slower) |
| 10 | 2.69 ± 0.78 | 9.13 ± 1.89 | 0.29x (slower) |
| 100 | 26.56 ± 7.65 | 88.91 ± 18.24 | 0.30x (slower) |
| 1000 | 234.13 ± 66.15 | 704.56 ± 138.18 | 0.33x (slower) |

## Per-Trial Raw Snapshot

| Trial | Flutter init (ms) | Kiwi init (ms) | Flutter warm analyses/s | Kiwi warm analyses/s |
| ---: | ---: | ---: | ---: | ---: |
| 1 | 5012.34 | 932.97 | 2110.28 | 3578.52 |
| 2 | 2613.59 | 1323.83 | 2246.96 | 1870.69 |
| 3 | 3554.05 | 856.95 | 1949.63 | 3403.52 |
| 4 | 3421.01 | 1236.50 | 2068.14 | 3446.26 |
| 5 | 5190.03 | 1286.43 | 924.22 | 3494.17 |

> Note: Warm metrics are the primary steady-state indicators. Cold start is reported separately using median and p95 to reduce single-run volatility. Session-length effective throughput includes init overhead and illustrates short-session user impact.

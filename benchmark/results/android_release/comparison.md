# Benchmark Comparison: flutter_kiwi_nlp vs kiwipiepy

## Run Metadata

| Field | flutter_kiwi_nlp | kiwipiepy |
| --- | --- | --- |
| runtime | flutter_kiwi_nlp | kiwipiepy |
| platform | android | macOS-15.7.4-arm64-arm-64bit-Mach-O |
| generated_at_utc (first trial) | 2026-02-17T14:31:35.302456Z | 2026-02-17T14:31:41Z |
| trials | 5 | 5 |
| sentence_count | 40 | 40 |
| warmup_runs | 3 | 3 |
| measure_runs | 15 | 15 |
| top_n | 1 | 1 |
| build_options | 1039 | 1039 |
| create_match_options | 8454175 | 8454175 |
| analyze_match_options | 8454175 | 8454175 |
| num_threads / num_workers | -1 | -1 |

## Warm Path Comparison (Primary, Init Excluded)

| Metric | flutter_kiwi_nlp (mean ± std) | kiwipiepy (mean ± std) | Ratio (Flutter mean / Kiwi mean) |
| --- | ---: | ---: | ---: |
| Throughput (analyses/s, higher better) | 1684.94 ± 401.21 | 3082.58 ± 414.13 | 0.55x (slower) |
| Throughput (chars/s, higher better) | 57119.46 ± 13601.10 | 104499.50 ± 14039.17 | 0.55x (slower) |
| Throughput (tokens/s, higher better) | 27127.53 ± 6459.52 | 49552.49 ± 6657.22 | 0.55x (slower) |
| Avg warm latency (ms, lower better) | 0.63 ± 0.20 | 0.33 ± 0.05 | 1.92x (slower) |
| Avg warm token latency (us/token, lower better) | 39.24 ± 12.63 | 20.49 ± 2.88 | 1.92x (slower) |

## Cold Start Comparison (Reported Separately)

| Metric | flutter_kiwi_nlp | kiwipiepy | Ratio |
| --- | ---: | ---: | ---: |
| Init time (ms, lower better) | median 4957.73, p95 7990.71 | median 1202.30, p95 1678.45 | 4.12x (slower) |

## Session-Length Effective Throughput (Init Included)

| Session analyses | flutter_kiwi_nlp effective analyses/s (mean ± std) | kiwipiepy effective analyses/s (mean ± std) | Ratio (Flutter mean / Kiwi mean) |
| ---: | ---: | ---: | ---: |
| 1 | 0.18 ± 0.05 | 0.77 ± 0.14 | 0.24x (slower) |
| 10 | 1.85 ± 0.55 | 7.68 ± 1.37 | 0.24x (slower) |
| 100 | 18.29 ± 5.39 | 75.08 ± 13.19 | 0.24x (slower) |
| 1000 | 166.17 ± 47.80 | 613.84 ± 97.21 | 0.27x (slower) |

## Per-Trial Raw Snapshot

| Trial | Flutter init (ms) | Kiwi init (ms) | Flutter warm analyses/s | Kiwi warm analyses/s |
| ---: | ---: | ---: | ---: | ---: |
| 1 | 8064.88 | 1202.30 | 1012.41 | 2665.05 |
| 2 | 4182.77 | 1729.68 | 1993.12 | 2604.43 |
| 3 | 4957.73 | 1096.57 | 1657.17 | 3453.69 |
| 4 | 4349.63 | 1177.23 | 1978.35 | 3282.63 |
| 5 | 7694.03 | 1473.51 | 1783.65 | 3407.12 |

> Note: Warm metrics are the primary steady-state indicators. Cold start is reported separately using median and p95 to reduce single-run volatility. Session-length effective throughput includes init overhead and illustrates short-session user impact.

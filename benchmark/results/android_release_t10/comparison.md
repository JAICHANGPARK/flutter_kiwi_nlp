# Benchmark Comparison: flutter_kiwi_nlp vs kiwipiepy

## Run Metadata

| Field | flutter_kiwi_nlp | kiwipiepy |
| --- | --- | --- |
| runtime | flutter_kiwi_nlp | kiwipiepy |
| platform | android | macOS-15.7.4-arm64-arm-64bit-Mach-O |
| generated_at_utc (first trial) | 2026-02-17T15:52:16.620588Z | 2026-02-17T15:52:19Z |
| trials | 10 | 10 |
| sentence_count | 40 | 40 |
| warmup_runs | 5 | 5 |
| measure_runs | 30 | 30 |
| top_n | 1 | 1 |
| build_options | 1039 | 1039 |
| create_match_options | 8454175 | 8454175 |
| analyze_match_options | 8454175 | 8454175 |
| num_threads / num_workers | -1 | -1 |

## Warm Path Comparison (Primary, Init Excluded)

| Metric | flutter_kiwi_nlp (mean ± std) | kiwipiepy (mean ± std) | Ratio (Flutter mean / Kiwi mean) |
| --- | ---: | ---: | ---: |
| Throughput (analyses/s, higher better) | 1981.83 ± 250.89 | 3222.94 ± 415.19 | 0.61x (slower) |
| Throughput (chars/s, higher better) | 67183.98 ± 8505.33 | 109257.81 ± 14074.97 | 0.61x (slower) |
| Throughput (tokens/s, higher better) | 31907.43 ± 4039.41 | 51808.83 ± 6674.19 | 0.62x (slower) |
| Avg warm latency (ms, lower better) | 0.51 ± 0.08 | 0.32 ± 0.05 | 1.63x (slower) |
| Avg warm token latency (us/token, lower better) | 31.88 ± 4.84 | 19.64 ± 2.97 | 1.62x (slower) |

## Cold Start Comparison (Reported Separately)

| Metric | flutter_kiwi_nlp | kiwipiepy | Ratio |
| --- | ---: | ---: | ---: |
| Init time (ms, lower better) | median 4093.05, p95 5573.90 | median 1098.48, p95 1307.90 | 3.73x (slower) |

## Session-Length Effective Throughput (Init Included)

| Session analyses | flutter_kiwi_nlp effective analyses/s (mean ± std) | kiwipiepy effective analyses/s (mean ± std) | Ratio (Flutter mean / Kiwi mean) |
| ---: | ---: | ---: | ---: |
| 1 | 0.24 ± 0.04 | 0.93 ± 0.12 | 0.26x (slower) |
| 10 | 2.42 ± 0.43 | 9.28 ± 1.21 | 0.26x (slower) |
| 100 | 23.92 ± 4.18 | 90.31 ± 11.42 | 0.26x (slower) |
| 1000 | 215.45 ± 35.75 | 716.48 ± 69.80 | 0.30x (slower) |

## Per-Trial Raw Snapshot

| Trial | Flutter init (ms) | Kiwi init (ms) | Flutter warm analyses/s | Kiwi warm analyses/s |
| ---: | ---: | ---: | ---: | ---: |
| 1 | 4076.03 | 1084.25 | 2006.81 | 3602.29 |
| 2 | 4574.69 | 1343.04 | 2162.98 | 3146.38 |
| 3 | 3783.10 | 1264.95 | 2045.03 | 3634.09 |
| 4 | 4675.89 | 1112.70 | 2055.98 | 3596.66 |
| 5 | 3401.15 | 937.80 | 1831.75 | 3468.34 |
| 6 | 3944.02 | 1138.45 | 2061.71 | 3256.63 |
| 7 | 3249.94 | 1193.06 | 2366.12 | 3061.88 |
| 8 | 4499.36 | 910.65 | 1875.38 | 2777.16 |
| 9 | 4110.06 | 951.09 | 2009.41 | 3352.04 |
| 10 | 6308.65 | 985.40 | 1403.10 | 2333.96 |

> Note: Warm metrics are the primary steady-state indicators. Cold start is reported separately using median and p95 to reduce single-run volatility. Session-length effective throughput includes init overhead and illustrates short-session user impact.

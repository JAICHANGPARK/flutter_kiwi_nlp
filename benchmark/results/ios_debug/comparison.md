# Benchmark Comparison: flutter_kiwi_nlp vs kiwipiepy

## Run Metadata

| Field | flutter_kiwi_nlp | kiwipiepy |
| --- | --- | --- |
| runtime | flutter_kiwi_nlp | kiwipiepy |
| platform | ios | macOS-15.7.4-arm64-arm-64bit-Mach-O |
| generated_at_utc (first trial) | 2026-02-17T14:25:44.466778Z | 2026-02-17T14:25:46Z |
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
| Throughput (analyses/s, higher better) | 1921.81 ± 174.19 | 3337.56 ± 130.48 | 0.58x (slower) |
| Throughput (chars/s, higher better) | 65149.50 ± 5904.89 | 113143.17 ± 4423.43 | 0.58x (slower) |
| Throughput (tokens/s, higher better) | 30941.21 ± 2804.39 | 53651.22 ± 2097.54 | 0.58x (slower) |
| Avg warm latency (ms, lower better) | 0.52 ± 0.05 | 0.30 ± 0.01 | 1.75x (slower) |
| Avg warm token latency (us/token, lower better) | 32.53 ± 2.95 | 18.66 ± 0.76 | 1.74x (slower) |

## Cold Start Comparison (Reported Separately)

| Metric | flutter_kiwi_nlp | kiwipiepy | Ratio |
| --- | ---: | ---: | ---: |
| Init time (ms, lower better) | median 1467.43, p95 1770.09 | median 722.39, p95 1021.90 | 2.03x (slower) |

## Session-Length Effective Throughput (Init Included)

| Session analyses | flutter_kiwi_nlp effective analyses/s (mean ± std) | kiwipiepy effective analyses/s (mean ± std) | Ratio (Flutter mean / Kiwi mean) |
| ---: | ---: | ---: | ---: |
| 1 | 0.65 ± 0.06 | 1.32 ± 0.23 | 0.50x (slower) |
| 10 | 6.52 ± 0.63 | 13.11 ± 2.30 | 0.50x (slower) |
| 100 | 63.24 ± 5.96 | 126.49 ± 21.57 | 0.50x (slower) |
| 1000 | 487.01 ± 40.09 | 937.84 ± 123.96 | 0.52x (slower) |

## Per-Trial Raw Snapshot

| Trial | Flutter init (ms) | Kiwi init (ms) | Flutter warm analyses/s | Kiwi warm analyses/s |
| ---: | ---: | ---: | ---: | ---: |
| 1 | 1828.15 | 753.66 | 1871.84 | 3453.25 |
| 2 | 1537.86 | 666.97 | 1967.61 | 3341.52 |
| 3 | 1467.43 | 1088.96 | 1689.79 | 3428.23 |
| 4 | 1454.81 | 722.39 | 1907.55 | 3122.02 |
| 5 | 1419.06 | 688.64 | 2172.28 | 3342.76 |

> Note: Warm metrics are the primary steady-state indicators. Cold start is reported separately using median and p95 to reduce single-run volatility. Session-length effective throughput includes init overhead and illustrates short-session user impact.

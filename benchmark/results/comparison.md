# Benchmark Comparison: flutter_kiwi_nlp vs kiwipiepy

## Run Metadata

| Field | flutter_kiwi_nlp | kiwipiepy |
| --- | --- | --- |
| runtime | flutter_kiwi_nlp | kiwipiepy |
| platform | ios | macOS-15.7.4-arm64-arm-64bit-Mach-O |
| generated_at_utc (first trial) | 2026-02-17T14:09:07.396007Z | 2026-02-17T14:09:09Z |
| trials | 1 | 1 |
| sentence_count | 40 | 40 |
| warmup_runs | 1 | 1 |
| measure_runs | 2 | 2 |
| top_n | 1 | 1 |
| build_options | 1039 | 1039 |
| create_match_options | 8454175 | 8454175 |
| analyze_match_options | 8454175 | 8454175 |
| num_threads / num_workers | -1 | -1 |

## Warm Path Comparison (Primary, Init Excluded)

| Metric | flutter_kiwi_nlp (mean ± std) | kiwipiepy (mean ± std) | Ratio (Flutter mean / Kiwi mean) |
| --- | ---: | ---: | ---: |
| Throughput (analyses/s, higher better) | 1768.74 ± 0.00 | 3539.51 ± 0.00 | 0.50x (slower) |
| Throughput (chars/s, higher better) | 59960.20 ± 0.00 | 119989.38 ± 0.00 | 0.50x (slower) |
| Throughput (tokens/s, higher better) | 28476.67 ± 0.00 | 56897.62 ± 0.00 | 0.50x (slower) |
| Avg warm latency (ms, lower better) | 0.57 ± 0.00 | 0.28 ± 0.00 | 2.00x (slower) |
| Avg warm token latency (us/token, lower better) | 35.12 ± 0.00 | 17.58 ± 0.00 | 2.00x (slower) |

## Cold Start Comparison (Reported Separately)

| Metric | flutter_kiwi_nlp | kiwipiepy | Ratio |
| --- | ---: | ---: | ---: |
| Init time (ms, lower better) | median 1532.40, p95 1532.40 | median 743.25, p95 743.25 | 2.06x (slower) |

## Session-Length Effective Throughput (Init Included)

| Session analyses | flutter_kiwi_nlp effective analyses/s (mean ± std) | kiwipiepy effective analyses/s (mean ± std) | Ratio (Flutter mean / Kiwi mean) |
| ---: | ---: | ---: | ---: |
| 1 | 0.65 ± 0.00 | 1.34 ± 0.00 | 0.49x (slower) |
| 10 | 6.50 ± 0.00 | 13.40 ± 0.00 | 0.49x (slower) |
| 100 | 62.94 ± 0.00 | 129.62 ± 0.00 | 0.49x (slower) |
| 1000 | 476.70 ± 0.00 | 974.87 ± 0.00 | 0.49x (slower) |

## Per-Trial Raw Snapshot

| Trial | Flutter init (ms) | Kiwi init (ms) | Flutter warm analyses/s | Kiwi warm analyses/s |
| ---: | ---: | ---: | ---: | ---: |
| 1 | 1532.40 | 743.25 | 1768.74 | 3539.51 |

> Note: Warm metrics are the primary steady-state indicators. Cold start is reported separately using median and p95 to reduce single-run volatility. Session-length effective throughput includes init overhead and illustrates short-session user impact.

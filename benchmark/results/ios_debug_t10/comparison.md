# Benchmark Comparison: flutter_kiwi_nlp vs kiwipiepy

## Run Metadata

| Field | flutter_kiwi_nlp | kiwipiepy |
| --- | --- | --- |
| runtime | flutter_kiwi_nlp | kiwipiepy |
| platform | ios | macOS-15.7.4-arm64-arm-64bit-Mach-O |
| generated_at_utc (first trial) | 2026-02-17T16:00:21.419500Z | 2026-02-17T16:00:23Z |
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
| Throughput (analyses/s, higher better) | 2065.58 ± 243.45 | 3423.38 ± 181.54 | 0.60x (slower) |
| Throughput (chars/s, higher better) | 70023.12 ± 8253.07 | 116052.70 ± 6154.21 | 0.60x (slower) |
| Throughput (tokens/s, higher better) | 33255.82 ± 3919.60 | 55030.89 ± 2918.26 | 0.60x (slower) |
| Avg warm latency (ms, lower better) | 0.49 ± 0.06 | 0.29 ± 0.02 | 1.67x (slower) |
| Avg warm token latency (us/token, lower better) | 30.45 ± 3.65 | 18.22 ± 1.01 | 1.67x (slower) |

## Cold Start Comparison (Reported Separately)

| Metric | flutter_kiwi_nlp | kiwipiepy | Ratio |
| --- | ---: | ---: | ---: |
| Init time (ms, lower better) | median 1439.55, p95 1660.40 | median 749.96, p95 931.24 | 1.92x (slower) |

## Session-Length Effective Throughput (Init Included)

| Session analyses | flutter_kiwi_nlp effective analyses/s (mean ± std) | kiwipiepy effective analyses/s (mean ± std) | Ratio (Flutter mean / Kiwi mean) |
| ---: | ---: | ---: | ---: |
| 1 | 0.69 ± 0.06 | 1.34 ± 0.18 | 0.52x (slower) |
| 10 | 6.89 ± 0.61 | 13.31 ± 1.84 | 0.52x (slower) |
| 100 | 66.88 ± 5.89 | 128.55 ± 17.19 | 0.52x (slower) |
| 1000 | 516.79 ± 43.34 | 957.88 ± 100.17 | 0.54x (slower) |

## Per-Trial Raw Snapshot

| Trial | Flutter init (ms) | Kiwi init (ms) | Flutter warm analyses/s | Kiwi warm analyses/s |
| ---: | ---: | ---: | ---: | ---: |
| 1 | 1261.28 | 791.96 | 2262.18 | 3526.48 |
| 2 | 1336.36 | 677.04 | 2443.91 | 3604.54 |
| 3 | 1713.27 | 652.76 | 2200.39 | 3630.75 |
| 4 | 1347.13 | 901.51 | 2011.24 | 3217.77 |
| 5 | 1405.49 | 638.80 | 2344.73 | 3452.48 |
| 6 | 1509.13 | 766.37 | 1669.71 | 3355.84 |
| 7 | 1595.77 | 955.57 | 2026.61 | 3328.75 |
| 8 | 1443.81 | 659.04 | 1977.52 | 3060.88 |
| 9 | 1520.19 | 733.54 | 1890.38 | 3536.88 |
| 10 | 1435.28 | 842.24 | 1829.13 | 3519.45 |

> Note: Warm metrics are the primary steady-state indicators. Cold start is reported separately using median and p95 to reduce single-run volatility. Session-length effective throughput includes init overhead and illustrates short-session user impact.

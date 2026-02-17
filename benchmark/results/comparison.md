# Benchmark Comparison: flutter_kiwi_nlp vs kiwipiepy

## Run Metadata

| Field | flutter_kiwi_nlp | kiwipiepy |
| --- | --- | --- |
| runtime | flutter_kiwi_nlp | kiwipiepy |
| platform | macos | macOS-15.7.4-arm64-arm-64bit-Mach-O |
| generated_at_utc | 2026-02-17T10:14:25.268892Z | 2026-02-17T10:14:27Z |
| sentence_count | 40 | 40 |
| warmup_runs | 3 | 3 |
| measure_runs | 15 | 15 |
| top_n | 1 | 1 |

## Comparison

| Metric | flutter_kiwi_nlp | kiwipiepy | Ratio (Flutter/Kiwi) |
| --- | ---: | ---: | ---: |
| Init time (ms, lower better) | 1315.84 | 615.45 | 2.14x (slower) |
| Throughput (analyses/s, higher better) | 2600.33 | 3659.41 | 0.71x (slower) |
| Throughput (chars/s, higher better) | 88151.17 | 124054.08 | 0.71x (slower) |
| Throughput (tokens/s, higher better) | 41865.30 | 58825.05 | 0.71x (slower) |
| Avg latency (ms, lower better) | 0.38 | 0.27 | 1.41x (slower) |
| Avg token latency (us/token, lower better) | 23.89 | 17.00 | 1.41x (slower) |

> Note: Use identical corpus, warmup, top_n, and hardware settings.

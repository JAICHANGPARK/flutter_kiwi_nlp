# Benchmark Comparison: flutter_kiwi_nlp vs kiwipiepy

## Run Metadata

| Field | flutter_kiwi_nlp | kiwipiepy |
| --- | --- | --- |
| runtime | flutter_kiwi_nlp | kiwipiepy |
| platform | macos | macOS-15.7.4-arm64-arm-64bit-Mach-O |
| generated_at_utc | 2026-02-17T09:06:09.622240Z | 2026-02-17T09:06:11Z |
| sentence_count | 40 | 40 |
| warmup_runs | 3 | 3 |
| measure_runs | 15 | 15 |
| top_n | 1 | 1 |

## Comparison

| Metric | flutter_kiwi_nlp | kiwipiepy | Ratio (Flutter/Kiwi) |
| --- | ---: | ---: | ---: |
| Init time (ms, lower better) | 1353.39 | 917.27 | 1.48x (slower) |
| Throughput (analyses/s, higher better) | 2408.41 | 3666.54 | 0.66x (slower) |
| Throughput (chars/s, higher better) | 81645.10 | 124295.69 | 0.66x (slower) |
| Throughput (tokens/s, higher better) | 38775.40 | 58939.62 | 0.66x (slower) |
| Avg latency (ms, lower better) | 0.42 | 0.27 | 1.52x (slower) |
| Avg token latency (us/token, lower better) | 25.79 | 16.97 | 1.52x (slower) |

> Note: Use identical corpus, warmup, top_n, and hardware settings.

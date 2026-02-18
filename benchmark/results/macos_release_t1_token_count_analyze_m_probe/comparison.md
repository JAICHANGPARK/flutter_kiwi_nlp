# Benchmark Comparison: flutter_kiwi_nlp vs kiwipiepy

## Run Metadata

| Field | flutter_kiwi_nlp | kiwipiepy |
| --- | --- | --- |
| runtime | flutter_kiwi_nlp | kiwipiepy |
| platform | macos | macOS-15.7.4-arm64-arm-64bit-Mach-O |
| generated_at_utc (first trial) | 2026-02-18T02:38:10.408184Z | 2026-02-18T02:38:12Z |
| trials | 1 | 1 |
| sentence_count | 40 | 40 |
| sample_count | 10 | 10 |
| warmup_runs | 3 | 3 |
| measure_runs | 15 | 15 |
| top_n | 1 | 1 |
| build_options | 1039 | 1039 |
| create_match_options | 8454175 | 8454175 |
| analyze_match_options | 8454175 | 8454175 |
| analyze_impl | token_count | analyze |
| num_threads / num_workers | -1 | -1 |

> Caution: `analyze_impl` differs between runtimes, so this table is not a strict apples-to-apples API-path comparison.

## Flutter JSON Serialization/Parsing Overhead

| Metric | flutter_kiwi_nlp (mean ± std) |
| --- | ---: |
| Pure processing elapsed (ms) | 43.41 ± 0.00 |
| Full analyze elapsed (ms) | 331.57 ± 0.00 |
| JSON overhead elapsed (ms) | 288.16 ± 0.00 |
| JSON overhead per analysis (ms) | 0.4803 ± 0.0000 |
| JSON overhead per token (us) | 28.0858 ± 0.0000 |
| JSON overhead ratio (%) | 86.91 ± 0.00 |

## Warm Path Comparison (Primary, Init Excluded)

| Metric | flutter_kiwi_nlp (mean ± std) | kiwipiepy (mean ± std) | Ratio (Flutter mean / Kiwi mean) |
| --- | ---: | ---: | ---: |
| Throughput (analyses/s, higher better) | 13822.34 ± 0.00 | 2694.80 ± 0.00 | 5.13x (faster) |
| Throughput (chars/s, higher better) | 468577.22 ± 0.00 | 91353.77 ± 0.00 | 5.13x (faster) |
| Throughput (tokens/s, higher better) | 236361.96 ± 0.00 | 43318.93 ± 0.00 | 5.46x (faster) |
| Avg warm latency (ms, lower better) | 0.07 ± 0.00 | 0.37 ± 0.00 | 0.19x (faster) |
| Avg warm token latency (us/token, lower better) | 4.23 ± 0.00 | 23.08 ± 0.00 | 0.18x (faster) |

## Layered Throughput Breakdown

| Layer | Throughput (mean ± std, analyses/s) |
| --- | ---: |
| Flutter pure (`token_count`) | 13822.34 ± 0.00 |
| Flutter full (`json`) | 1809.58 ± 0.00 |
| kiwipiepy current API path (`analyze`) | 2694.80 ± 0.00 |

| Derived ratio | Value |
| --- | ---: |
| Flutter pure / kiwi | 5.13x (faster) |
| Flutter full / kiwi | 0.67x (slower) |
| Flutter boundary loss (full vs pure) | 86.91% |

> Reading: Flutter core path is competitive, but boundary materialization/parsing overhead reduces end-to-end API throughput.


## Cold Start Comparison (Reported Separately)

| Metric | flutter_kiwi_nlp | kiwipiepy | Ratio |
| --- | ---: | ---: | ---: |
| Init time (ms, lower better) | median 1729.89, p95 1729.89 | median 860.55, p95 860.55 | 2.01x (slower) |

## Session-Length Effective Throughput (Init Included)

| Session analyses | flutter_kiwi_nlp effective analyses/s (mean ± std) | kiwipiepy effective analyses/s (mean ± std) | Ratio (Flutter mean / Kiwi mean) |
| ---: | ---: | ---: | ---: |
| 1 | 0.58 ± 0.00 | 1.16 ± 0.00 | 0.50x (slower) |
| 10 | 5.78 ± 0.00 | 11.57 ± 0.00 | 0.50x (slower) |
| 100 | 57.57 ± 0.00 | 111.40 ± 0.00 | 0.52x (slower) |
| 1000 | 554.87 ± 0.00 | 811.93 ± 0.00 | 0.68x (slower) |

## Per-Trial Raw Snapshot

| Trial | Flutter init (ms) | Kiwi init (ms) | Flutter warm analyses/s | Kiwi warm analyses/s |
| ---: | ---: | ---: | ---: | ---: |
| 1 | 1729.89 | 860.55 | 13822.34 | 2694.80 |

## Sample POS Output Comparison (Top1)

| # | Sentence | flutter_kiwi_nlp top1 | kiwipiepy top1 | Match |
| ---: | --- | --- | --- | --- |
| 1 | 오늘 회의는 오전 아홉 시에 시작하고 점심 전에 끝낼 예정입니다. | 오늘/NNG 회의/NNG 는/JX 오전/NNG 아홉/NR 시/NNB 에/JKB 시작/NNG 하/XSV 고/EC 점심/NNG 전/NNG 에/JKB 끝내/VV ᆯ/ETM 예정/NNG 이/VCP ᆸ니다/EF ./SF | 오늘/NNG 회의/NNG 는/JX 오전/NNG 아홉/NR 시/NNB 에/JKB 시작/NNG 하/XSV 고/EC 점심/NNG 전/NNG 에/JKB 끝내/VV ᆯ/ETM 예정/NNG 이/VCP ᆸ니다/EF ./SF | same |
| 2 | 새로 배포한 앱에서 로그인 지연 이슈가 간헐적으로 보고되었습니다. | 새로/MAG 배포/NNG 하/XSV ᆫ/ETM 앱/NNG 에서/JKB 로그인/NNG 지연/NNG 이슈/NNG 가/JKS 간헐/NNG 적/XSN 으로/JKB 보/VV 고/EC 되/VV 었/EP 습니다/EF ./SF | 새로/MAG 배포/NNG 하/XSV ᆫ/ETM 앱/NNG 에서/JKB 로그인/NNG 지연/NNG 이슈/NNG 가/JKS 간헐/NNG 적/XSN 으로/JKB 보고/NNG 되/XSV 었/EP 습니다/EF ./SF | diff |
| 3 | 사용자 피드백을 반영해서 온보딩 문구를 더 짧게 수정했습니다. | 사용자/NNG 피드백/NNG 을/JKO 반영/NNG 하/XSV 어서/EC 온/MM 보/NNG 딩/MAG 문구/NNG 를/JKO 더/MAG 짧/VA 게/EC 수정/NNG 하/XSV 었/EP 습니다/EF ./SF | 사용자/NNG 피드백/NNG 을/JKO 반영/NNG 하/XSV 어서/EC 온/MM 보/NNG 딩/MAG 문구/NNG 를/JKO 더/MAG 짧/VA 게/EC 수정/NNG 하/XSV 었/EP 습니다/EF ./SF | same |
| 4 | 이번 분기 목표는 검색 정확도 개선과 응답 속도 단축입니다. | 이번/NNG 분기/NNG 목표/NNG 는/JX 검색/NNG 정확도/NNG 개선/NNG 과/JC 응답/NNG 속도/NNG 단축/NNG 이/VCP ᆸ니다/EF ./SF | 이번/NNG 분기/NNG 목표/NNG 는/JX 검색/NNG 정확도/NNG 개선/NNG 과/JC 응답/NNG 속도/NNG 단축/NNG 이/VCP ᆸ니다/EF ./SF | same |
| 5 | 문서 링크는 사내 위키에서 확인할 수 있습니다. | 문서/NNG 링크/NNG 는/JX 사내/NNG 위키/NNP 에서/JKB 확인/NNG 하/XSV ᆯ/ETM 수/NNB 있/VA 습니다/EF ./SF | 문서/NNG 링크/NNG 는/JX 사내/NNG 위키/NNP 에서/JKB 확인/NNG 하/XSV ᆯ/ETM 수/NNB 있/VA 습니다/EF ./SF | same |
| 6 | 주문번호 ORD-2026-004219 상태를 조회해 주세요. | 주문/NNG 번호/NNG ORD/SL -/SO 2026-004219/W_SERIAL 상태/NNG 를/JKO 조회/NNG 하/XSV 어/EC 주/VX 세요/EF ./SF | 주문/NNG 번호/NNG ORD/SL -/SO 2026-004219/W_SERIAL 상태/NNG 를/JKO 조회/NNG 하/XSV 어/EC 주/VX 세요/EF ./SF | same |
| 7 | 문의는 support@example.com 으로 보내 주시면 순차적으로 답변드립니다. | 문의/NNG 는/JX support@example.com/W_EMAIL 으로/JKB 보내/VV 어/EC 주/VX 시/EP 면/EC 순차/NNG 적/XSN 으로/JKB 답변/NNG 드리/VV ᆸ니다/EF ./SF | 문의/NNG 는/JX support@example.com/W_EMAIL 으로/JKB 보내/VV 어/EC 주/VX 시/EP 면/EC 순차/NNG 적/XSN 으로/JKB 답변/NNG 드리/VV ᆸ니다/EF ./SF | same |
| 8 | OpenAI 업데이트 소식은 https://openai.com 에서 확인했습니다. | OpenAI/SL 업데이트/NNG 소식/NNG 은/JX https://openai.com/W_URL 에서/JKB 확인/NNG 하/XSV 었/EP 습니다/EF ./SF | OpenAI/SL 업데이트/NNG 소식/NNG 은/JX https://openai.com/W_URL 에서/JKB 확인/NNG 하/XSV 었/EP 습니다/EF ./SF | same |
| 9 | #Flutter #NLP 해시태그가 포함된 게시글을 수집해 보겠습니다. | #Flutter/W_HASHTAG #NLP/W_HASHTAG 해시태그/NNG 가/JKS 포함/NNG 되/XSV ᆫ/ETM 게시/NNG 글/NNG 을/JKO 수집/NNG 하/XSV 어/EC 보/VX 겠/EP 습니다/… | #Flutter/W_HASHTAG #NLP/W_HASHTAG 해시태그/NNG 가/JKS 포함/NNG 되/XSV ᆫ/ETM 게시/NNG 글/NNG 을/JKO 수집/NNG 하/XSV 어/EC 보/VX 겠/EP 습니다/… | same |
| 10 | @product-team 오늘 데모 리허설 일정 공유 부탁드립니다. | @product-team/W_MENTION 오늘/MAG 데모/NNG 리허설/NNG 일정/NNG 공유/NNG 부탁/NNG 드리/VV ᆸ니다/EF ./SF | @product-team/W_MENTION 오늘/MAG 데모/NNG 리허설/NNG 일정/NNG 공유/NNG 부탁/NNG 드리/VV ᆸ니다/EF ./SF | same |

> Note: Warm metrics are the primary steady-state indicators. Cold start is reported separately using median and p95 to reduce single-run volatility. Session-length effective throughput includes init overhead and illustrates short-session user impact.

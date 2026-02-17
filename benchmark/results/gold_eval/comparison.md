# Gold Corpus Accuracy Comparison

## Overall

| Metric | flutter_kiwi_nlp | kiwipiepy | Delta (Flutter - Kiwi) |
| --- | ---: | ---: | ---: |
| Token agreement | 88.39% | 88.58% | -0.19 pp |
| POS agreement | 84.90% | 85.55% | -0.65 pp |
| Sentence exact match | 1.57% | 2.62% | -1.05 pp |
| Token-sequence exact match | 3.66% | 3.66% | +0.00 pp |

## Per Dataset

| Dataset | Runtime | Token agreement | POS agreement | Sentence exact |
| --- | --- | ---: | ---: | ---: |
| gold_eval_web_ko | flutter_kiwi_nlp | 87.79% | 84.04% | 1.90% |
| gold_eval_web_ko | kiwipiepy | 88.03% | 84.80% | 2.53% |
| gold_eval_written_ko | flutter_kiwi_nlp | 90.86% | 88.42% | 0.00% |
| gold_eval_written_ko | kiwipiepy | 90.86% | 88.61% | 3.03% |

## Counts

- Sentences: 191 (same gold set for both runtimes).
- Gold tokens: 7990.
- Agreement metrics are based on sequence-level Levenshtein distance normalization.

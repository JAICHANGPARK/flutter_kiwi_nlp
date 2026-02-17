# Flutter + Kiwi 한국어 형태소 분석 플러그인 개발기: 온디바이스 구현, 코드 예제, 벤치마크까지

부제: `flutter_kiwi_nlp` 아키텍처, API 사용법, 성능 벤치마크, 운영 팁까지 한 번에 정리

---

한국어 NLP를 모바일/데스크톱 앱에 붙일 때 가장 많이 겪는 문제는 크게 세 가지입니다.

1. 서버 의존성 때문에 지연 시간과 비용이 증가한다.
2. 오프라인 환경이나 네트워크 품질 저하 상황에서 품질이 급격히 떨어진다.
3. 플랫폼(Android, iOS, macOS, Windows, Linux, Web)별로 구현이 갈라진다.

`flutter_kiwi_nlp`는 이 문제를 꽤 현실적인 방식으로 해결합니다.  
핵심은 **같은 Dart API로 네이티브(FFI)와 웹(WASM)을 모두 지원**하고, 한국어 형태소 분석기 Kiwi를 온디바이스로 실행한다는 점입니다.

이 글에서는 단순 사용법을 넘어서 아래를 다룹니다.

- 왜 이 접근이 실무에서 유리한지
- 코드 레벨에서 어떻게 구성하면 유지보수가 쉬운지
- 벤치마크를 어떻게 공정하게 측정해야 하는지
- 실제 측정 결과(실행 로그 기반)와 해석

---

## TL;DR

- `KiwiAnalyzer.create()`로 분석기 인스턴스를 만들고 `analyze()`를 호출하면 된다.
- API는 `Future` 기반 비동기 모델이라 UI 스레드를 막지 않는다.
- 사용자 사전(`addUserWord`)을 런타임에 추가할 수 있다.
- 동일 코퍼스/동일 조건에서 비교한 실측 결과(2026-02-17, macOS arm64) 기준:
  - 처리량(analyses/s): `flutter_kiwi_nlp` 2408.41, `kiwipiepy` 3666.54
  - 평균 지연(ms): `flutter_kiwi_nlp` 0.42, `kiwipiepy` 0.27
- 결론: Python 레퍼런스 대비 느린 구간이 있지만, 앱 내 직접 탑재와 단일 Flutter API라는 장점이 크다.

---

## AI 사용자 활용 가이드 (LLM + Skills)

이 프로젝트는 AI 코딩 도우미와 함께 사용할 때 생산성이 크게 올라갑니다.
핵심은 모델에게 "레포 구조 + 스킬 + 검증 루틴"을 함께 주는 것입니다.

권장 레퍼런스:

- LLM 인덱스: `llms.txt`
- 저장소 스킬: `skills/flutter-kiwi-nlp/SKILL.md`
- API 표면 참조: `skills/flutter-kiwi-nlp/references/api-surface.md`
- 런타임/빌드 참조:
  `skills/flutter-kiwi-nlp/references/runtime-and-build.md`
- 검증 스크립트: `skills/flutter-kiwi-nlp/scripts/verify_plugin.sh`

AI에게 바로 쓸 수 있는 프롬프트 예시:

```text
Use $flutter-kiwi-nlp to implement and validate this change.

Goal:
- Add a domain dictionary bootstrap for ecommerce terms.
- Keep native/web API parity.
- Do not break benchmark scripts.

Validation:
- Run analyze/lint/tests used in this repo.
- Run ./skills/flutter-kiwi-nlp/scripts/verify_plugin.sh.
- Summarize behavioral changes and benchmark impact.
```

활용 팁:

- 작업 요청 시 목표와 제약을 같이 적기
- "어떤 파일을 근거로 판단했는지"를 반드시 보고받기
- 기능 변경 후 벤치마크 경로(`tool/benchmark/`)까지 검증시키기
- PR 설명에 생성된 산출물(`benchmark/results/*.json`, `comparison.md`) 첨부하기

---

## 1) 왜 온디바이스 한국어 NLP인가

서버 기반 NLP는 강력하지만, 모바일/클라이언트 앱 입장에서는 아래 비용이 숨어 있습니다.

- 네트워크 왕복 지연(RTT) + 혼잡 구간에서 tail latency 증가
- API 호출 비용 누적
- 텍스트 데이터 외부 전송에 따른 개인정보/보안 이슈
- 오프라인 모드 부재

반면 온디바이스 분석은 다음이 강점입니다.

- 입력 즉시 응답(특히 짧은 문장 반복 분석에서 체감 큼)
- 오프라인 대응
- 프라이버시 친화적 아키텍처
- 기능 개발 속도(서버 스펙 변경 없이 앱 레벨 반복 가능)

`flutter_kiwi_nlp`는 여기에 더해, 앱 개발자가 흔히 원하는 두 가지를 제공합니다.

- 공통 API: 네이티브/웹에서 동일한 `KiwiAnalyzer` 인터페이스
- 런타임 사용자 사전: 도메인 용어를 즉시 반영

---

## 2) 최소 동작 코드: 10분 안에 붙이기

먼저 의존성을 추가합니다.

```bash
flutter pub add flutter_kiwi_nlp
```

기본 형태소 분석 흐름은 아래와 같습니다.

```dart
import 'package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart';

Future<void> runBasicAnalysis() async {
  final KiwiAnalyzer analyzer = await KiwiAnalyzer.create(
    numThreads: -1,
    matchOptions: KiwiMatchOption.allWithNormalizing,
  );

  try {
    final KiwiAnalyzeResult result = await analyzer.analyze(
      '온디바이스 NLP는 지연 시간과 비용을 동시에 줄일 수 있습니다.',
      options: const KiwiAnalyzeOptions(topN: 1),
    );

    for (final KiwiToken token in result.candidates.first.tokens) {
      // 예: 온디바이스/NNG, NLP/SL ...
      print('${token.form}/${token.tag}');
    }
  } finally {
    await analyzer.close();
  }
}
```

### 코드 설명

- `Future`/`async`/`await`
  - 모델 로딩과 분석은 I/O/연산이 포함되므로 비동기입니다.
  - `await`를 사용하면 콜백 체인보다 읽기 쉽고 에러 처리(`try/catch`)가 명확합니다.
- Null safety
  - `result.candidates.first`를 사용하기 전에 후보가 비어 있는지 확인하는 방어 코드가 실무에서는 더 안전합니다.
- 리소스 정리
  - `analyzer.close()`를 반드시 호출해 네이티브 리소스 누수를 방지합니다.

---

## 3) 실무형 래퍼: 서비스 계층으로 격리하기

앱 규모가 커질수록 `KiwiAnalyzer`를 UI에 직접 노출하지 않는 것이 좋습니다.  
아래처럼 서비스 계층을 두면 테스트와 교체가 쉬워집니다.

```dart
import 'package:flutter_kiwi_nlp/flutter_kiwi_nlp.dart';

class KiwiNlpService {
  KiwiAnalyzer? _analyzer;

  bool get isReady => _analyzer != null;

  Future<void> initialize({
    String? modelPath,
    String? assetModelPath,
    int numThreads = -1,
  }) async {
    await dispose();
    _analyzer = await KiwiAnalyzer.create(
      modelPath: modelPath,
      assetModelPath: assetModelPath,
      numThreads: numThreads,
      matchOptions: KiwiMatchOption.allWithNormalizing,
    );
  }

  Future<List<KiwiToken>> tokenize(
    String sentence, {
    int topN = 1,
    int matchOptions = KiwiMatchOption.allWithNormalizing,
  }) async {
    final KiwiAnalyzer? analyzer = _analyzer;
    if (analyzer == null) {
      throw const KiwiException('Analyzer is not initialized.');
    }

    final KiwiAnalyzeResult result = await analyzer.analyze(
      sentence,
      options: KiwiAnalyzeOptions(
        topN: topN,
        matchOptions: matchOptions,
      ),
    );

    if (result.candidates.isEmpty) {
      return const <KiwiToken>[];
    }
    return result.candidates.first.tokens;
  }

  Future<void> addDomainWord(String word, {String tag = 'NNP'}) async {
    final KiwiAnalyzer? analyzer = _analyzer;
    if (analyzer == null) {
      throw const KiwiException('Analyzer is not initialized.');
    }
    await analyzer.addUserWord(word, tag: tag);
  }

  Future<void> dispose() async {
    final KiwiAnalyzer? analyzer = _analyzer;
    _analyzer = null;
    if (analyzer != null) {
      await analyzer.close();
    }
  }
}
```

### 왜 이 구조가 중요한가

- UI와 도메인 로직 분리
  - 화면 코드는 입력/출력에 집중하고, NLP 수명주기는 서비스에서 관리합니다.
- 테스트 용이성
  - 나중에 fake service를 주입하면 UI 테스트가 쉬워집니다.
- 운영 안전성
  - 재초기화, 종료, 예외 처리 포인트가 한 곳으로 모입니다.

---

## 4) 사용자 사전은 품질 개선의 지름길

한국어 서비스에서 실무 성능(체감 정확도)을 끌어올리는 가장 빠른 방법은 대개 사용자 사전입니다.

```dart
await analyzer.addUserWord('온디바이스NLP', tag: 'NNP');
```

도메인별 예시:

- 커머스: 상품명, 브랜드명, SKU 패턴
- 핀테크: 계좌/카드 도메인 용어
- B2B SaaS: 사내 제품명, 기능명, 약어

포인트는 복잡한 모델 재학습 없이도 앱 런타임에서 즉시 튜닝이 가능하다는 점입니다.

---

## 5) 옵션 설계: 정확도와 속도의 트레이드오프를 코드로 노출하기

`KiwiAnalyzeOptions`와 `KiwiMatchOption` 조합으로 분석 동작을 세밀하게 조절할 수 있습니다.

```dart
final KiwiAnalyzeOptions options = KiwiAnalyzeOptions(
  topN: 3,
  matchOptions: KiwiMatchOption.url |
      KiwiMatchOption.email |
      KiwiMatchOption.hashtag |
      KiwiMatchOption.normalizeCoda |
      KiwiMatchOption.splitSaisiot,
);

final KiwiAnalyzeResult result = await analyzer.analyze(text, options: options);
```

튜닝 가이드:

- `topN`
  - 후보를 여러 개 보고 후처리에서 재랭킹하려면 2~5로 올립니다.
  - 순수 속도가 우선이면 1이 일반적으로 유리합니다.
- `matchOptions`
  - URL/이메일/해시태그 같은 패턴 인식이 필요하면 해당 플래그를 켭니다.
  - 입력 특성에 맞지 않는 옵션은 과감히 끄고 측정합니다.

---

## 6) 벤치마크를 공정하게 측정하는 방법

형태소 분석 벤치마크는 비교 조건이 조금만 달라도 숫자가 크게 바뀝니다.  
이 프로젝트는 비교 자동화 스크립트를 제공합니다.

```bash
uv run --with kiwipiepy python tool/benchmark/run_compare.py \
  --device macos \
  --mode release
```

이 스크립트가 하는 일:

1. Flutter benchmark app 실행(`example/lib/benchmark_main.dart`)
2. 동일 코퍼스로 `kiwipiepy` 실행(`tool/benchmark/kiwipiepy_benchmark.py`)
3. 비교 리포트 생성(`tool/benchmark/compare_results.py`)

생성 파일:

- `benchmark/results/flutter_kiwi_benchmark.json`
- `benchmark/results/kiwipiepy_benchmark.json`
- `benchmark/results/comparison.md`

---

## 7) 실측 결과 (2026-02-17, macOS arm64)

실행 조건:

- 디바이스: macOS desktop (`darwin-arm64`)
- Flutter 모드: `release`
- 코퍼스: `example/assets/benchmark_corpus_ko.txt` (40문장)
- 공통 파라미터: `warmup=3`, `measure=15`, `top_n=1`

비교표:

| Metric | flutter_kiwi_nlp | kiwipiepy | Ratio (Flutter/Kiwi) |
| --- | ---: | ---: | ---: |
| Init time (ms, lower better) | 1353.39 | 917.27 | 1.48x (slower) |
| Throughput (analyses/s, higher better) | 2408.41 | 3666.54 | 0.66x (slower) |
| Throughput (chars/s, higher better) | 81645.10 | 124295.69 | 0.66x (slower) |
| Throughput (tokens/s, higher better) | 38775.40 | 58939.62 | 0.66x (slower) |
| Avg latency (ms, lower better) | 0.42 | 0.27 | 1.52x (slower) |
| Avg token latency (us/token, lower better) | 25.79 | 16.97 | 1.52x (slower) |

원본 산출물:

- `benchmark/results/comparison.md`
- `benchmark/results/flutter_kiwi_benchmark.json`
- `benchmark/results/kiwipiepy_benchmark.json`

---

## 8) 결과 해석: 숫자 너머에서 봐야 할 것들

이번 측정에서는 `kiwipiepy`가 전 지표에서 앞섰습니다.  
하지만 실무 의사결정은 단순 최대 처리량 비교보다 조금 더 입체적으로 해야 합니다.

### 8-1. 왜 차이가 날 수 있나

- 런타임 경로 차이
  - Flutter 쪽은 Dart <-> FFI <-> 네이티브 경계를 반복 통과합니다.
  - 결과를 JSON으로 직렬화/역직렬화하는 구간 비용도 포함됩니다.
- 초기화 비용
  - 모델 로딩, 브리지 초기화, 런타임 세팅 비용이 포함됩니다.
- 토큰 카운트 차이
  - 이번 결과에서 total_tokens가 `9660` vs `9645`로 약간 달랐습니다.
  - 구현/집계 방식 차이(후보/토큰 처리 차이)가 미세하게 반영될 수 있습니다.

### 8-2. 그래도 Flutter 온디바이스가 갖는 가치

- 앱 코드 안에서 즉시 사용 가능한 단일 API
- 서버 호출 없이 동작
- 멀티플랫폼 동시 대응
- 사용자 사전 기반 빠른 도메인 튜닝

즉, 절대 수치 하나만으로 선택하기보다 **아키텍처 비용 전체**를 같이 봐야 합니다.

---

## 9) 성능 개선 체크리스트

아래는 앱에서 바로 적용 가능한 최적화 포인트입니다.

1. 분석기 재사용
   - 요청마다 `create()` 하지 말고, 앱 수명주기에서 재사용합니다.
2. `topN` 최소화
   - 후처리에서 여러 후보가 반드시 필요하지 않다면 `topN=1`.
3. 배치 입력 전략
   - 작은 문장을 지나치게 잘게 쪼개지 말고, 문장 단위 묶음 처리 실험.
4. 사용자 사전 설계
   - 정확도 향상으로 재분석/재시도 횟수를 줄여 전체 지연 개선.
5. isolate 활용
   - 긴 분석 루프나 대량 처리 UI 작업은 백그라운드로 분리.

---

## 10) UI 스레드 보호: `compute`로 백그라운드 실행

예제 앱은 벤치마크 루프를 분리 실행합니다.

```dart
final Map<String, Object?> rawResult = kIsWeb
    ? await _runBenchmarkInBackground(payload)
    : await compute<Map<String, Object>, Map<String, Object?>>(
        _runBenchmarkInBackground,
        payload,
        debugLabel: 'kiwi-benchmark',
      );
```

핵심 포인트:

- 메인 isolate의 프레임 드롭 위험을 줄입니다.
- 긴 반복 연산이 UI 상호작용을 막는 상황을 완화합니다.
- `kIsWeb` 분기처럼 플랫폼별 실행 모델 차이를 코드에 명시적으로 표현합니다.

---

## 11) 운영 관점에서 자주 부딪히는 이슈

### 모델 경로

- 로컬 경로, 에셋 경로, 환경 변수 등 경로 정책을 팀 내에서 통일하세요.
- 릴리스 빌드에서 번들 누락이 없는지 CI에서 검증하세요.

### 에러 처리

- `KiwiException`을 UI 메시지와 내부 로그로 분리하세요.
- 사용자에게는 간결한 메시지, 로그에는 맥락(옵션/입력 크기/경로)을 남기세요.

### 관측성

- 초기화 시간, 분석 시간, 실패율을 지표로 수집하세요.
- 릴리스마다 벤치마크를 자동 실행해 회귀를 조기 탐지하세요.

---

## 12) 재현 가능한 실험 템플릿

팀 내에서 성능 회의를 할 때는 아래 4가지를 항상 고정하세요.

1. 코퍼스
2. 파라미터(`warmup`, `measure`, `top_n`)
3. 디바이스/OS
4. 빌드 모드(debug/profile/release)

추천 커맨드:

```bash
uv run --with kiwipiepy python tool/benchmark/run_compare.py \
  --device macos \
  --mode release \
  --warmup-runs 3 \
  --measure-runs 15 \
  --top-n 1
```

결과 파일은 PR 아티팩트로 첨부하면, 리뷰에서 감정 대신 데이터로 논의할 수 있습니다.

---

## 13) 마무리

`flutter_kiwi_nlp`는 "최고 절대 성능"만을 노리는 도구라기보다,  
**Flutter 앱에서 한국어 형태소 분석을 실용적으로 운영 가능하게 만드는 도구**에 가깝습니다.

핵심은 다음입니다.

- 개발 생산성: 멀티플랫폼 공통 API
- 운영 안정성: 온디바이스 실행 + 사용자 사전
- 성능 관리: 비교 벤치마크 스크립트 내장

다음 단계로는 프로젝트 요구사항에 맞춰 아래를 진행하는 것을 권장합니다.

1. 실제 서비스 문장으로 전용 코퍼스를 구성한다.
2. `topN`/옵션 플래그 조합을 실험해 정확도-지연 곡선을 만든다.
3. 릴리스 파이프라인에 벤치마크 비교 리포트를 자동 포함한다.

---

## 부록 A) 이번 실행의 원본 로그 핵심 라인

```text
flutter_kiwi_nlp:
  init_ms=1353.393
  analyses_per_sec=2408.4101683077306
  avg_latency_ms=0.4152116666666667

kiwipiepy:
  init_ms=917.2669580148067
  analyses_per_sec=3666.539433756072
  avg_latency_ms=0.2727367366605904
```

위 값은 단일 머신 단일 실행 결과입니다.  
정확한 비교를 위해서는 동일 조건 반복 측정(최소 5회 이상)과 분산/신뢰구간 확인을 권장합니다.
